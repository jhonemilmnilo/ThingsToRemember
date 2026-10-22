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
    .map((b) => b.toString(16).padLeft ? b.toString(16).padStart(2, '0') : (b < 16 ? '0' : '') + b.toString(16))
    .join('');
}

async function getKey(rawHexKey: string): Promise<CryptoKey> {
  const keyBytes = hexToBytes(rawHexKey);
  return await crypto.subtle.importKey(
    'raw',
    keyBytes,
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
        iv,
      },
      key,
      cipherBytes
    );

    return new TextDecoder().decode(decryptedBuffer);
  } catch (err) {
    // Return original string if decryption fails or key mismatch
    return cipherText;
  }
}
