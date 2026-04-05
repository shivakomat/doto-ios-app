# Doto — App Icon & Logo iOS Spec
**Version:** 1.0
**Scope:** App icon, launch screen logo, wordmark, in-app usage
**Design decision:** Option 3 — single colour navy mark (navy background, white dots)

---

## 1. The Mark — Design Spec

### Concept
Four circles arranged as a family group. Two larger circles (parents) on the top
row, two smaller circles (children) on the bottom row. White on navy. No colour
variation in the icon itself — the simplicity makes it scale cleanly to 20px.

### Colours
| Element | Value |
|---|---|
| Background | `#1E2761` (Doto app navy — matches the dashboard header exactly) |
| Parent dots | `#FFFFFF` at 100% opacity |
| Child dots | `#FFFFFF` at 70% opacity |
| Corner radius | 22.5% of icon width (iOS standard — system applies mask automatically) |

### Geometry (proportional — scales to any size)
All values are expressed as percentages of the icon's total width/height.

| Element | Centre X | Centre Y | Radius |
|---|---|---|---|
| Parent dot 1 (left) | 33.75% | 37.5% | 11.25% |
| Parent dot 2 (right) | 62.5% | 37.5% | 11.25% |
| Child dot 1 (left) | 27.5% | 66.25% | 8.125% |
| Child dot 2 (right) | 70% | 66.25% | 8.125% |

For an 80×80 canvas (the source SVG):

| Element | cx | cy | r |
|---|---|---|---|
| Parent dot 1 | 27 | 30 | 9 |
| Parent dot 2 | 50 | 30 | 9 |
| Child dot 1 | 22 | 53 | 6.5 |
| Child dot 2 | 56 | 53 | 6.5 |

---

## 2. SVG Source Files

### 2.1 Icon Mark (square — use for all app icon sizes)

Save as `doto-icon.svg` in the project root or `Resources/` folder.
Windsurf should use this as the source to generate all PNG sizes.

```svg
<svg width="1024" height="1024" viewBox="0 0 80 80"
     fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect width="80" height="80" rx="18" fill="#1E2761"/>
  <circle cx="27" cy="30" r="9" fill="white"/>
  <circle cx="50" cy="30" r="9" fill="white"/>
  <circle cx="22" cy="53" r="6.5" fill="white" fill-opacity="0.7"/>
  <circle cx="56" cy="53" r="6.5" fill="white" fill-opacity="0.7"/>
</svg>
```

**Note on the `rx="18"` rect:** iOS applies its own squircle mask over the icon —
you do not need to match the corner radius exactly in the source. The `rx` on the
background rect is only visible in contexts where iOS does not apply a mask (e.g.
notification badges, iPad settings). Setting it to 18 on an 80px canvas gives a
visually consistent result at small sizes.

### 2.2 Horizontal Wordmark (for in-app use)

Save as `doto-wordmark.svg` in `Resources/` or use as a SwiftUI view (see §4).

```svg
<svg width="210" height="56" viewBox="0 0 210 56"
     fill="none" xmlns="http://www.w3.org/2000/svg">
  <!-- Icon badge -->
  <rect width="48" height="48" rx="11" fill="#1E2761" x="0" y="4"/>
  <circle cx="16" cy="22" r="5.5" fill="white"/>
  <circle cx="30" cy="22" r="5.5" fill="white"/>
  <circle cx="13" cy="36" r="4" fill="white" fill-opacity="0.7"/>
  <circle cx="33" cy="36" r="4" fill="white" fill-opacity="0.7"/>
  <!-- Wordmark -->
  <text x="62" y="42"
        font-family="-apple-system, BlinkMacSystemFont, sans-serif"
        font-size="32"
        font-weight="600"
        fill="#1E2761"
        letter-spacing="-0.5">doto</text>
</svg>
```

---

## 3. Xcode Assets.xcassets — App Icon Setup

### 3.1 AppIcon.appiconset

All sizes must be placed in `Assets.xcassets/AppIcon.appiconset/`.
The `Contents.json` below is the complete file — replace any existing one.

**Required PNG sizes to generate from `doto-icon.svg`:**

| Filename | Size (px) | Usage |
|---|---|---|
| `icon-20@2x.png` | 40×40 | Notification @2x |
| `icon-20@3x.png` | 60×60 | Notification @3x |
| `icon-29@2x.png` | 58×58 | Settings @2x |
| `icon-29@3x.png` | 87×87 | Settings @3x |
| `icon-38@2x.png` | 76×76 | Spotlight @2x |
| `icon-38@3x.png` | 114×114 | Spotlight @3x |
| `icon-60@2x.png` | 120×120 | Home screen @2x |
| `icon-60@3x.png` | 180×180 | Home screen @3x |
| `icon-1024.png` | 1024×1024 | App Store (no alpha channel) |

### 3.2 Contents.json

```json
{
  "images": [
    {
      "idiom": "iphone",
      "scale": "2x",
      "size": "20x20",
      "filename": "icon-20@2x.png"
    },
    {
      "idiom": "iphone",
      "scale": "3x",
      "size": "20x20",
      "filename": "icon-20@3x.png"
    },
    {
      "idiom": "iphone",
      "scale": "2x",
      "size": "29x29",
      "filename": "icon-29@2x.png"
    },
    {
      "idiom": "iphone",
      "scale": "3x",
      "size": "29x29",
      "filename": "icon-29@3x.png"
    },
    {
      "idiom": "iphone",
      "scale": "2x",
      "size": "40x40",
      "filename": "icon-38@2x.png"
    },
    {
      "idiom": "iphone",
      "scale": "3x",
      "size": "40x40",
      "filename": "icon-38@3x.png"
    },
    {
      "idiom": "iphone",
      "scale": "2x",
      "size": "60x60",
      "filename": "icon-60@2x.png"
    },
    {
      "idiom": "iphone",
      "scale": "3x",
      "size": "60x60",
      "filename": "icon-60@3x.png"
    },
    {
      "idiom": "ios-marketing",
      "scale": "1x",
      "size": "1024x1024",
      "filename": "icon-1024.png"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

### 3.3 Generating the PNGs

Windsurf should run the following shell commands to rasterise the SVG into all
required PNG sizes using `rsvg-convert` (part of `librsvg`) or `cairosvg`:

```bash
# Install cairosvg if not present
pip install cairosvg

# Generate all required sizes from the source SVG
python3 - <<'EOF'
import cairosvg, os

sizes = [
    ("icon-20@2x.png",  40),
    ("icon-20@3x.png",  60),
    ("icon-29@2x.png",  58),
    ("icon-29@3x.png",  87),
    ("icon-38@2x.png",  76),
    ("icon-38@3x.png", 114),
    ("icon-60@2x.png", 120),
    ("icon-60@3x.png", 180),
    ("icon-1024.png", 1024),
]

src = "doto-icon.svg"
out = "doto-ios/Assets.xcassets/AppIcon.appiconset"
os.makedirs(out, exist_ok=True)

for filename, size in sizes:
    cairosvg.svg2png(
        url=src,
        write_to=f"{out}/{filename}",
        output_width=size,
        output_height=size
    )
    print(f"Generated {filename} ({size}x{size})")

print("Done.")
EOF
```

Adjust the `out` path to match the actual Xcode project folder structure.

**Important for the 1024×1024 App Store image:** Apple rejects icons with an
alpha channel. `cairosvg` produces PNG-24 without alpha by default as long as
the SVG has a fully opaque background rect — which `doto-icon.svg` does
(`fill="#1E2761"` with no opacity attribute). No extra step needed.

---

## 4. In-App Usage — SwiftUI Components

### 4.1 DotoLogoMark (icon only)

Used on the launch/splash screen and anywhere a standalone icon is needed.

```swift
// Shared/Components/DotoLogoMark.swift
import SwiftUI

struct DotoLogoMark: View {
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225)
                .fill(Color.appNavy)
                .frame(width: size, height: size)

            let parentR  = size * 0.1125
            let childR   = size * 0.08125
            let topY     = size * -0.125     // relative to centre
            let botY     = size *  0.1625
            let leftX    = size * -0.1625
            let rightX   = size *  0.125
            let cLeftX   = size * -0.25
            let cRightX  = size *  0.2

            // Parent dots
            Circle()
                .fill(Color.white)
                .frame(width: parentR * 2, height: parentR * 2)
                .offset(x: leftX, y: topY)
            Circle()
                .fill(Color.white)
                .frame(width: parentR * 2, height: parentR * 2)
                .offset(x: rightX, y: topY)

            // Child dots (slightly transparent)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: childR * 2, height: childR * 2)
                .offset(x: cLeftX, y: botY)
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: childR * 2, height: childR * 2)
                .offset(x: cRightX, y: botY)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        DotoLogoMark(size: 80)
        DotoLogoMark(size: 48)
        DotoLogoMark(size: 32)
        DotoLogoMark(size: 20)
    }
    .padding()
    .background(Color.white)
}
```

### 4.2 DotoWordmark (icon + text lockup)

Used on the launch screen, onboarding landing view, and auth header.

```swift
// Shared/Components/DotoWordmark.swift
import SwiftUI

struct DotoWordmark: View {
    // .light = navy text on white bg (default, most screens)
    // .dark  = white text on navy bg (headers, splash)
    enum Style { case light, dark }

    var style: Style = .light
    var iconSize: CGFloat = 36

    private var textColor: Color {
        style == .dark ? .white : Color.appNavy
    }

    var body: some View {
        HStack(spacing: 10) {
            DotoLogoMark(size: iconSize)
            Text("doto")
                .font(.system(size: iconSize * 0.72, weight: .semibold, design: .default))
                .foregroundColor(textColor)
                .kerning(-0.5)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        DotoWordmark(style: .light, iconSize: 40)
            .padding(24)
            .background(Color.white)

        DotoWordmark(style: .dark, iconSize: 40)
            .padding(24)
            .background(Color.appNavy)
    }
}
```

---

## 5. Launch Screen

**File:** `LaunchScreen.storyboard` (or SwiftUI `LaunchScreen` scene if configured
in Info.plist as `UILaunchScreen`)

### Using LaunchScreen.storyboard (classic)

1. Open `LaunchScreen.storyboard` in Xcode
2. Delete any existing content
3. Add a `UIView` filling the screen, background colour `#1E2761`
4. Add a `UIImageView` centred horizontally and vertically:
   - Image: `AppIcon` (from Assets — use the 1024px version)
   - Width/Height: 80×80 (constant constraints)
   - Content mode: Aspect Fit
5. Add a `UILabel` below the image:
   - Text: `doto`
   - Font: SF Pro Display Semibold 28pt
   - Colour: white
   - Alignment: centre
   - Top space to image: 14pt

### Using SwiftUI LaunchScreen (Info.plist key `UILaunchScreen`)

Add to `Info.plist`:
```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>LaunchBackground</string>
    <key>UIImageName</key>
    <string>LaunchLogo</string>
</dict>
```

Add a `LaunchBackground` colour set in `Assets.xcassets`:
- Any appearance: `#1E2761`
- Dark appearance: `#1E2761` (same — launch screen is always navy)

Add a `LaunchLogo` image set in `Assets.xcassets`:
- Use the 1024px PNG at 1×, or a separate SVG-rendered 120×120 PNG

---

## 6. Where the Wordmark Appears In-App

| Screen | Component | Style |
|---|---|---|
| `LandingView` (onboarding) | `DotoWordmark(style: .light, iconSize: 42)` | Centred, light |
| `SignInView` header | `DotoLogoMark(size: 40)` | Icon only, centred |
| Launch screen | Storyboard (see §5) | Full-screen navy |
| Settings header (optional) | `DotoLogoMark(size: 28)` | Icon only, inline |
| Email / share text | Text: `"doto"` — no image needed | — |

The wordmark is **not** used inside the main app navigation — the dark navy
tab headers use the screen title text ("Home", "Schedule" etc.) not the logo.
The logo appears only on entry/auth screens where brand identity matters most.

---

## 7. Do Not

- Do not add a drop shadow to the icon mark — it conflicts with the iOS squircle mask
- Do not use the coloured variant (Option 1) as the actual app icon — Apple's review
  guidelines recommend a single strong colour palette per icon, not multiple accent colours
- Do not place the wordmark inside the tab bar or navigation bar titles
- Do not use the SVG directly in `Image()` without the SwiftUI component wrapper —
  the proportions need to be controlled via `DotoLogoMark` to stay consistent
- Do not add the App Store 1024×1024 PNG to a regular image set — it lives exclusively
  in `AppIcon.appiconset` and is referenced by Xcode automatically
