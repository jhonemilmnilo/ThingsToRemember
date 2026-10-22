# 🍵 UI Color Palette & Design System: Matcha Modern

> **Concept**: A serene, premium Japanese matcha aesthetic mixed with warm oat milk neutrals and subtle botanical accents. Clean, distraction-free, and calming for a personal vault/archive app.

---

## 🎨 Color Palette Tokens

| Role | Color Name | Hex Code | Preview | Usage Description |
| :--- | :--- | :--- | :--- | :--- |
| **Primary** | Matcha Green | `#2D5A27` | 🟩 | Main buttons, active tab indicators, app branding |
| **Primary Light** | Fresh Sprout | `#528A44` | 🟢 | Badges, success highlights, hover/pressed state |
| **Secondary / Accent**| Warm Toasted Sesame | `#C8963E` | 🟨 | Starred items, secure tags, secondary highlights |
| **Background (Light)**| Oat Milk / Cream | `#F8F6F0` | 🥛 | Main app scaffold background |
| **Surface (Light)** | Porcelain White | `#FFFFFF` | ⚪ | Cards, bottom sheets, dialogue boxes |
| **Text Primary** | Deep Forest Slate | `#1A2418` | ⬛ | Main headers, titles, high-contrast text |
| **Text Muted** | Sage Ash | `#6E7A6B` | 🔘 | Subtitles, timestamps, meta info, inactive icons |
| **Border / Divider** | Muted Moss Tint | `#E2E7DE` | ▫️ | Card outlines, dividers, input borders |
| **Destructive / Alert**| Dried Persimmon | `#D1493A` | 🟥 | Delete credential, errors, alerts |

---

## 🌙 Dark Mode Harmonization (Matcha Night)

| Token | Hex Code | Role |
| :--- | :--- | :--- |
| **Dark Background** | `#121712` | Deep charcoal with dark forest undertone |
| **Dark Surface** | `#1C241B` | Elevated card container |
| **Dark Primary** | `#6EAB5F` | High-visibility matcha green for dark mode |
| **Dark Text** | `#EDF2EC` | Soft white text (anti-eye strain) |

---

## 🧱 Flutter ColorScheme Code Preview

```dart
// Theme definition preview
static const ColorScheme matchaLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF2D5A27),
  onPrimary: Colors.white,
  secondary: Color(0xFFC8963E),
  onSecondary: Colors.white,
  error: Color(0xFFD1493A),
  onError: Colors.white,
  surface: Color(0xFFFFFFFF),
  onSurface: Color(0xFF1A2418),
);
```

---

## 📱 UI Components Styling Guidelines
1. **App Bar**: Transparent or Oat Milk `#F8F6F0` with subtle Matcha typography.
2. **Vault Cards**: White `#FFFFFF` with 1px border `#E2E7DE`, soft elevation (`blurRadius: 10`, `opacity: 0.04`).
3. **Floating Action Button (FAB)**: Solid Matcha `#2D5A27` with white plus icon.
4. **Category Chips**: Pastel Sprout tint (`#E9F2E6`) with Matcha Green text.
