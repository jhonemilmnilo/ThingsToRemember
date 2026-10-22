# 🔐 PassKeep: Login & Authentication Specification

> **Aesthetic**: Matcha Modern (Calm, Minimalist, High-Trust FinTech Vibe)  
> **Auth Engine**: Neon Auth (Managed Better Auth) + OAuth 2.0 (Google & Facebook) + Email/Password fallback

---

## 1. Visual Hierarchy & Wireframe Structure

```
+------------------------------------------------------+
|                     [ Oat Milk #F8F6F0 ]             |
|                                                      |
|                  [ Matcha Padlock Icon ]             |
|                        PassKeep                      |
|          "Your serene personal password vault"       |
|                                                      |
|   +----------------------------------------------+   |
|   |  [G]  Continue with Google                   |   |  <- Primary White Card
|   +----------------------------------------------+   |
|                                                      |
|   +----------------------------------------------+   |
|   |  [f]  Continue with Facebook                 |   |  <- Secondary Slate/Navy Card
|   +----------------------------------------------+   |
|                                                      |
|   ------------  or continue with email  ------------  |
|                                                      |
|   [  Email Address                              ]    |  <- Rounded Input (#FFFFFF)
|   [  Master Password               [Eye Icon]   ]    |  <- Rounded Input (#FFFFFF)
|                                                      |
|   +----------------------------------------------+   |
|   |             Unlock Vault                     |   |  <- Solid Matcha #2D5A27
|   +----------------------------------------------+   |
|                                                      |
|             [ Biometric / Touch ID Pill ]            |  <- For Returning Users
|                                                      |
|             🔒 End-to-End Encrypted via Neon          |
+------------------------------------------------------+
```

---

## 2. Component Specifications

### A. Branding Header
- **Logo**: 72x72 dp rounded app icon container with soft shadow (`blurRadius: 16`, `opacity: 0.08`).
- **App Title**: 28sp Bold, Deep Forest Slate (`#1A2418`).
- **Tagline**: 14sp Regular, Sage Ash (`#6E7A6B`).

### B. Social Auth Buttons
1. **Google Button**:
   - Background: Pure White (`#FFFFFF`) with 1px border (`#E2E7DE`).
   - Text: Medium 15sp `#1A2418`.
   - Left Icon: Official Multicolor Google 'G' icon.
2. **Facebook Button**:
   - Background: Soft Blue-Slate tint (`#F0F4FA`) with border (`#D4E0F0`).
   - Text: Medium 15sp `#1877F2`.
   - Left Icon: Facebook 'f' glyph.

### C. Email & Master Password Inputs
- **Container**: White `#FFFFFF` with 1.5px border (`#E2E7DE`), focused state (`#2D5A27`).
- **Corner Radius**: 14dp rounded rectangle.
- **Suffix Icon**: Eye / EyeOff toggle for password visibility.

### D. Main Action Button
- **Label**: *"Unlock Vault"* (or *"Create Master Vault"* for signups).
- **Background**: Solid Matcha Green (`#2D5A27`).
- **Text**: White `#FFFFFF`, 16sp Bold with 52dp tap height.

---

## 3. Data Flow & Security Model

| Step | Actor | Action | Payload / Result |
| :--- | :--- | :--- | :--- |
| **1** | User | Taps "Continue with Google" or "Facebook" | Opens OAuth Consent Window via Neon Auth |
| **2** | Neon Auth | Exchanges OAuth code for identity tokens | Generates or fetches user profile |
| **3** | Neon DB | Upserts user record in Postgres | `users` table updated |
| **4** | Client | Receives verified JWT session | Saved to `flutter_secure_storage` |
| **5** | Vault Key | Client derives local encryption key | Unlocks local credentials using client secret |

---

## 4. State Management & Navigation Flow
- **States**:
  - `Initial`: Form ready.
  - `Authenticating`: Buttons disabled with smooth Matcha circular progress indicator.
  - `Authenticated`: Auto-transitions to Vault Home Screen (`VaultHomeScreen`).
  - `Error`: Inline banner (Dried Persimmon `#D1493A`) with auto-dismiss.
