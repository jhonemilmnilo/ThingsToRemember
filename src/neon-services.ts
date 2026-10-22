import { neon, Pool } from "@neondatabase/serverless";
import { S3Client, PutObjectCommand, GetObjectCommand, ListObjectsV2Command } from "@aws-sdk/client-s3";
import dotenv from "dotenv";

// Load .env.local or fallback to .env
dotenv.config({ path: ".env.local" });
dotenv.config();

/**
 * 1. POSTGRES SERVICE WIRING
 * Following the `neon-postgres` skill:
 * - Use `@neondatabase/serverless` pool or http client with DATABASE_URL
 */
const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.warn("⚠️ DATABASE_URL not found in environment variables.");
}

export const sql = neon(databaseUrl || "");
export const pool = new Pool({ connectionString: databaseUrl || "" });

/**
 * 2. OBJECT STORAGE SERVICE WIRING
 * Following the `neon-object-storage` skill:
 * - S3-compatible, requires forcePathStyle: true
 * - Uses AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ENDPOINT_URL_S3, AWS_REGION
 */
export const s3 = new S3Client({
  forcePathStyle: true,
  endpoint: process.env.AWS_ENDPOINT_URL_S3,
  region: process.env.AWS_REGION || "ap-southeast-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || "",
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || "",
  },
});

export const STORAGE_BUCKET = "assets";

/**
 * 3. NEON AUTH SERVICE CONFIG
 * Following `neon-auth` skill:
 * - Uses NEON_AUTH_BASE_URL and NEON_AUTH_JWKS_URL
 */
export const authConfig = {
  baseUrl: process.env.NEON_AUTH_BASE_URL,
  jwksUrl: process.env.NEON_AUTH_JWKS_URL,
};
