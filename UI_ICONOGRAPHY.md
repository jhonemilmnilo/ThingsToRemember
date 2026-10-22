# 🍵 Iconography System: "My Things To Save"

> **Style Rule**: Minimalist, rounded line icons (`stroke-width: 1.5px` to `2px`) with soft curved edges. Complements the organic, calm Matcha aesthetic.

---

## 1. App Icon / Logo Concept

| Option | Concept | Visual Description | Vibe |
| :--- | :--- | :--- | :--- |
| **Option A (Recommended)** | **Matcha Leaf Vault** | A stylized tea leaf whose stem curls into a modern padlock keyhole. | Calm, ultra-secure, distinctive. |
| **Option B** | **Zen Bento Box / Safe** | Minimalist rounded square container with a single botanical line inside. | Modern Japanese organization. |
| **Option C** | **Floating Sprout Shield** | Clean shield silhouette cradling a 2-petal matcha sprout. | Privacy & growth protection. |

---

## 2. Icon Library Recommendation for Flutter

Use **`lucide_icons`** (or **`hugeicons`** / **`remixicon`**):
- Outlines are consistent in optical weight.
- Fits modern, clean iOS & Android designs much better than standard generic material icons.

```yaml
# pubspec.yaml
dependencies:
  lucide_icons: ^0.257.0 # Clean minimalist line icons
```

---

## 3. Core App Navigation & Action Icons

| UI Section | Recommended Icon | Lucide Icon Name | Visual Function |
| :--- | :--- | :--- | :--- |
| **Vault / All Items** | Safe Box / Archive | `LucideIcons.archive` or `LucideIcons.vault` | Main list of saved items |
| **Passwords / Credentials** | Key / Lock | `LucideIcons.keyRound` / `LucideIcons.shieldCheck` | Credential entries |
| **Notes / Text Snippets** | Sticky Note / Feather | `LucideIcons.fileText` | Quick saved notes |
| **Media / Files** | Paperclip / Image | `LucideIcons.paperclip` / `LucideIcons.folderClosed` | Neon Object Storage attachments |
| **Favorites / Starred** | Star / Bookmark | `LucideIcons.bookmark` (Warm Sesame accent) | Pinned priority items |
| **Search** | Magnifying Glass | `LucideIcons.search` | Real-time filter & search |
| **Add New Item** | Plus in Circle | `LucideIcons.plus` | Main Floating Action Button |
| **Copy Credential** | Double Sheet | `LucideIcons.copy` | Instant clipboard copy action |
| **Show/Hide Password** | Eye / Eye Off | `LucideIcons.eye` / `LucideIcons.eyeOff` | Reveal sensitive text |
| **Settings / Profile** | Sliders / Nut | `LucideIcons.slidersHorizontal` | User & Neon DB sync status |

---

## 4. Category Badges & Color Pairings

| Category | Icon | Icon Tint | Background Chip Tint |
| :--- | :--- | :--- | :--- |
| **Logins / Accounts** | `keyRound` | `#2D5A27` (Matcha) | `#EBF3EA` (Pale Mint) |
| **Bank / Finance** | `creditCard` | `#C8963E` (Sesame Gold) | `#FAF3E7` (Soft Oat) |
| **Personal Docs** | `fileCheck2` | `#356B7A` (Muted Teal) | `#E8F2F5` (Ice Blue) |
| **Private Notes** | `lock` | `#6E7A6B` (Sage Ash) | `#F0F3EF` (Light Sage) |

---

## 5. Design Principle for Icons
- **Inactive State**: `Sage Ash (#6E7A6B)` at 70% opacity.
- **Active / Focused State**: `Matcha Green (#2D5A27)` with subtle pill container.
- **Touch Target**: Minimum 44x44 dp bounding box with 20–24 dp icon glyph size.
