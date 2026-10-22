import express from "express";
import cors from "cors";
import { sql, s3, STORAGE_BUCKET, authConfig } from "./neon-services.js";
import { PutObjectCommand, ListObjectsV2Command } from "@aws-sdk/client-s3";
const app = express();
app.use(cors());
app.use(express.json());
// Health check endpoint
app.get("/health", (req, res) => {
    res.json({
        status: "ok",
        services: ["postgres", "auth", "object-storage"],
        branch: process.env.NEON_BRANCH || "production",
    });
});
// 1. Neon Postgres: initialize table if not exists & list credentials
app.get("/api/init-db", async (req, res) => {
    try {
        await sql `
      CREATE TABLE IF NOT EXISTS credentials (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        title VARCHAR(100) NOT NULL,
        category VARCHAR(50) DEFAULT 'General',
        username_or_email TEXT NOT NULL,
        encrypted_password TEXT NOT NULL,
        iv TEXT NOT NULL,
        website_url TEXT,
        created_at TIMESTAMPTZ DEFAULT NOW(),
        updated_at TIMESTAMPTZ DEFAULT NOW()
      );
    `;
        res.json({ success: true, message: "Neon Postgres initialized table 'credentials'" });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// Credentials CRUD backed by Neon Postgres
app.get("/api/credentials", async (req, res) => {
    try {
        const rows = await sql `SELECT * FROM credentials ORDER BY created_at DESC;`;
        res.json({ success: true, data: rows });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.post("/api/credentials", async (req, res) => {
    try {
        const { title, category, username_or_email, encrypted_password, iv, website_url } = req.body;
        const inserted = await sql `
      INSERT INTO credentials (title, category, username_or_email, encrypted_password, iv, website_url)
      VALUES (${title}, ${category || 'General'}, ${username_or_email}, ${encrypted_password}, ${iv}, ${website_url || null})
      RETURNING *;
    `;
        res.json({ success: true, data: inserted[0] });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// 2. Neon Object Storage: test uploading & listing files in the "assets" bucket
app.post("/api/storage/test-upload", async (req, res) => {
    try {
        const key = `test-${Date.now()}.txt`;
        const content = `Neon Object Storage test file generated at ${new Date().toISOString()}`;
        await s3.send(new PutObjectCommand({
            Bucket: STORAGE_BUCKET,
            Key: key,
            Body: Buffer.from(content),
            ContentType: "text/plain",
        }));
        res.json({ success: true, message: "File uploaded successfully to Neon Object Storage", key });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
app.get("/api/storage/files", async (req, res) => {
    try {
        const result = await s3.send(new ListObjectsV2Command({
            Bucket: STORAGE_BUCKET,
            MaxKeys: 10,
        }));
        res.json({
            success: true,
            bucket: STORAGE_BUCKET,
            files: result.Contents?.map((item) => ({ key: item.Key, size: item.Size, lastModified: item.LastModified })) || [],
        });
    }
    catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});
// 3. Neon Auth configuration status endpoint
app.get("/api/auth/status", async (req, res) => {
    res.json({
        success: true,
        authBaseUrl: authConfig.baseUrl,
        jwksUrl: authConfig.jwksUrl,
        mode: "Managed Better Auth via Neon Auth",
    });
});
const PORT = process.env.PORT || 3000;
if (process.env.NODE_ENV !== "test") {
    app.listen(PORT, () => {
        console.log(`🚀 Neon Backend API server running on http://localhost:${PORT}`);
    });
}
export default app;
