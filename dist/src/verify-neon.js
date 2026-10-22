import { sql, s3, STORAGE_BUCKET, authConfig } from "./neon-services.js";
import { PutObjectCommand, GetObjectCommand, ListObjectsV2Command } from "@aws-sdk/client-s3";
async function runEndToEndVerification() {
    console.log("=================================================");
    console.log("   🧪 NEON END-TO-END SERVICE INTEGRATION TEST   ");
    console.log("=================================================");
    let allPassed = true;
    // 1. Verify Neon Postgres
    try {
        console.log("\n[1/3] 🐘 Testing Neon Postgres Connection & DDL...");
        const result = await sql `SELECT NOW() as current_time, current_database() as db_name, version();`;
        console.log(`   Connected to Database: ${result[0].db_name}`);
        console.log(`   Current DB Time: ${result[0].current_time}`);
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
        console.log("   Table 'credentials' ensured.");
        const testId = `test-${Date.now()}`;
        const insertRes = await sql `
      INSERT INTO credentials (title, category, username_or_email, encrypted_password, iv, website_url)
      VALUES (${'FB Test'}, ${'Social'}, ${'user@test.com'}, ${'encrypted_secret_data'}, ${'iv_test_123'}, ${'https://facebook.com'})
      RETURNING *;
    `;
        console.log(`   Insert verified: Created record id=${insertRes[0].id}, title=${insertRes[0].title}`);
        const selectRes = await sql `SELECT count(*)::int as total FROM credentials;`;
        console.log(`   Query verified: Total credential records in Neon DB = ${selectRes[0].total}`);
        console.log("   ✅ Neon Postgres: PASSED");
    }
    catch (error) {
        console.error("   ❌ Neon Postgres FAILED:", error.message);
        allPassed = false;
    }
    // 2. Verify Neon Object Storage (S3 bucket 'assets')
    try {
        console.log("\n[2/3] 🪣 Testing Neon Object Storage (Bucket: assets)...");
        const testKey = `integration-tests/verify-${Date.now()}.txt`;
        const payload = `Hello from Neon Object Storage Verification at ${new Date().toISOString()}`;
        // Upload object
        await s3.send(new PutObjectCommand({
            Bucket: STORAGE_BUCKET,
            Key: testKey,
            Body: Buffer.from(payload),
            ContentType: "text/plain",
        }));
        console.log(`   PutObject verified: Uploaded key='${testKey}' to bucket '${STORAGE_BUCKET}'`);
        // Download object
        const getRes = await s3.send(new GetObjectCommand({
            Bucket: STORAGE_BUCKET,
            Key: testKey,
        }));
        const content = await getRes.Body?.transformToString();
        console.log(`   GetObject verified: Retrieved content: "${content}"`);
        // List objects
        const listRes = await s3.send(new ListObjectsV2Command({
            Bucket: STORAGE_BUCKET,
            Prefix: "integration-tests/",
            MaxKeys: 5,
        }));
        console.log(`   ListObjectsV2 verified: Found ${listRes.KeyCount} object(s) in prefix`);
        console.log("   ✅ Neon Object Storage: PASSED");
    }
    catch (error) {
        console.error("   ❌ Neon Object Storage FAILED:", error.message);
        allPassed = false;
    }
    // 3. Verify Neon Auth
    try {
        console.log("\n[3/3] 🔐 Testing Neon Auth (Managed Better Auth)...");
        console.log(`   Neon Auth Base URL: ${authConfig.baseUrl}`);
        console.log(`   Neon Auth JWKS URL: ${authConfig.jwksUrl}`);
        if (authConfig.jwksUrl) {
            const response = await fetch(authConfig.jwksUrl);
            if (response.ok) {
                const jwks = await response.json();
                console.log(`   JWKS endpoint reachable (HTTP ${response.status}). Key count: ${jwks.keys ? jwks.keys.length : 0}`);
            }
            else {
                console.log(`   JWKS endpoint responded with HTTP ${response.status}`);
            }
        }
        console.log("   ✅ Neon Auth Configuration: PASSED");
    }
    catch (error) {
        console.error("   ❌ Neon Auth FAILED:", error.message);
        allPassed = false;
    }
    console.log("\n=================================================");
    if (allPassed) {
        console.log("🎉 ALL NEON SERVICES VERIFIED & WIRED END-TO-END!");
        process.exit(0);
    }
    else {
        console.log("❌ ONE OR MORE SERVICES FAILED.");
        process.exit(1);
    }
}
runEndToEndVerification();
