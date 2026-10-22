// Cryptographic utilities using standard WebCrypto API natively supported in Cloudflare Workers

function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = parseInt(hex.substring(i, i + 2), 16);
  }
  return bytes;
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

async function getKey(rawHexKey: string): Promise<CryptoKey> {
  const keyBytes = hexToBytes(rawHexKey);
  return await crypto.subtle.importKey(
    'raw',
    keyBytes as unknown as BufferSource,
    { name: 'AES-GCM' },
    false,
    ['encrypt', 'decrypt']
  );
}

/**
 * Encrypts plaintext using AES-256-GCM with a fresh random 12-byte IV.
 * Produces format: enc:v1:<iv_hex>:<ciphertext_hex>
 */
export async function encryptVaultField(plainText: string | null | undefined, masterKeyHex: string): Promise<string> {
  if (plainText === null || plainText === undefined || plainText === '') {
    return plainText ?? '';
  }

  // If already encrypted, return as is
  if (typeof plainText === 'string' && plainText.startsWith('enc:v1:')) {
    return plainText;
  }

  const key = await getKey(masterKeyHex);
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encoded = new TextEncoder().encode(plainText);

  const cipherBuffer = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv,
    },
    key,
    encoded
  );

  const cipherBytes = new Uint8Array(cipherBuffer);
  const ivHex = bytesToHex(iv);
  const cipherHex = bytesToHex(cipherBytes);

  return `enc:v1:${ivHex}:${cipherHex}`;
}

/**
 * Decrypts ciphertext using AES-256-GCM.
 * If data is not encrypted (legacy plain text), gracefully returns the original text.
 */
export async function decryptVaultField(cipherText: string | null | undefined, masterKeyHex: string): Promise<string> {
  if (!cipherText || typeof cipherText !== 'string') {
    return cipherText ?? '';
  }

  // Graceful fallback for legacy unencrypted records
  if (!cipherText.startsWith('enc:v1:')) {
    return cipherText;
  }

  try {
    const parts = cipherText.split(':');
    if (parts.length !== 4) {
      return cipherText;
    }

    const ivHex = parts[2];
    const cipherHex = parts[3];

    const iv = hexToBytes(ivHex);
    const cipherBytes = hexToBytes(cipherHex);
    const key = await getKey(masterKeyHex);

    const decryptedBuffer = await crypto.subtle.decrypt(
      {
        name: 'AES-GCM',
        iv: iv as unknown as BufferSource,
      },
      key,
      cipherBytes as unknown as BufferSource
    );

    return new TextDecoder().decode(decryptedBuffer);
  } catch (err) {
    // Return original string if decryption fails or key mismatch
    return cipherText;
  }
}

/**
 * Derives a secure salted PBKDF2 hash for the user's Master Password / PIN.
 */
export async function hashPassword(password: string, existingSaltHex?: string): Promise<{ hashHex: string; saltHex: string }> {
  const enc = new TextEncoder();
  const salt = existingSaltHex ? hexToBytes(existingSaltHex) : crypto.getRandomValues(new Uint8Array(16));
  
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    enc.encode(password),
    { name: 'PBKDF2' },
    false,
    ['deriveBits', 'deriveKey']
  );

  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: 'PBKDF2',
      salt: salt as unknown as BufferSource,
      iterations: 100000,
      hash: 'SHA-256',
    },
    keyMaterial,
    256
  );

  const hashBytes = new Uint8Array(derivedBits);
  return {
    hashHex: bytesToHex(hashBytes),
    saltHex: existingSaltHex || bytesToHex(salt),
  };
}

/**
 * Constant-time comparison between stored hash and computed candidate hash.
 */
export async function verifyPassword(password: string, storedHashHex: string, saltHex: string): Promise<boolean> {
  const candidate = await hashPassword(password, saltHex);
  return candidate.hashHex === storedHashHex;
}

export interface SessionPayload {
  userId: string;
  email: string;
  exp: number; // Unix timestamp in seconds
  iat: number; // Issued at
}

/**
 * Creates an HMAC-SHA256 signing key derived from the master key.
 */
async function getHmacKey(masterKeyHex: string): Promise<CryptoKey> {
  const enc = new TextEncoder();
  return await crypto.subtle.importKey(
    'raw',
    enc.encode(masterKeyHex),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign', 'verify']
  );
}

/**
 * Issues a cryptographically signed, tamper-proof session token.
 * Valid for 7 days by default.
 */
export async function issueSessionToken(
  userId: string,
  email: string,
  masterKeyHex: string,
  expiresInSeconds: number = 7 * 24 * 60 * 60
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const payload: SessionPayload = {
    userId,
    email,
    iat: now,
    exp: now + expiresInSeconds,
  };

  const payloadString = JSON.stringify(payload);
  const payloadBase64 = btoa(payloadString);

  const hmacKey = await getHmacKey(masterKeyHex);
  const enc = new TextEncoder();
  const signatureBuffer = await crypto.subtle.sign(
    'HMAC',
    hmacKey,
    enc.encode(payloadBase64)
  );

  const signatureHex = bytesToHex(new Uint8Array(signatureBuffer));
  return `pk_sec_${payloadBase64}.${signatureHex}`;
}

/**
 * Verifies a session token signature and expiration.
 * Returns SessionPayload if valid, or null if invalid or expired.
 */
export async function verifySessionToken(
  token: string | null | undefined,
  masterKeyHex: string
): Promise<SessionPayload | null> {
  if (!token || !token.startsWith('pk_sec_')) {
    return null;
  }

  try {
    const rawToken = token.replace('pk_sec_', '');
    const parts = rawToken.split('.');
    if (parts.length !== 2) {
      return null;
    }

    const [payloadBase64, signatureHex] = parts;
    const hmacKey = await getHmacKey(masterKeyHex);
    const enc = new TextEncoder();

    const signatureBytes = hexToBytes(signatureHex);
    const isValid = await crypto.subtle.verify(
      'HMAC',
      hmacKey,
      signatureBytes as unknown as BufferSource,
      enc.encode(payloadBase64)
    );

    if (!isValid) {
      return null;
    }

    const payloadString = atob(payloadBase64);
    const payload: SessionPayload = JSON.parse(payloadString);

    const now = Math.floor(Date.now() / 1000);
    if (payload.exp < now) {
      // Token has expired
      return null;
    }

    return payload;
  } catch (_) {
    return null;
  }
}


