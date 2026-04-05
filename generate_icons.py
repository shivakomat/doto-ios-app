#!/usr/bin/env python3
from PIL import Image, ImageDraw

NAVY = (30, 58, 138)   # #1E3A8A
WHITE = (255, 255, 255)

# iOS required icon sizes: (filename, pixel size)
sizes = [
    ("icon-20@2x.png", 40),
    ("icon-20@3x.png", 60),
    ("icon-29@2x.png", 58),
    ("icon-29@3x.png", 87),
    ("icon-40@2x.png", 80),
    ("icon-40@3x.png", 120),
    ("icon-60@2x.png", 120),
    ("icon-60@3x.png", 180),
    ("icon-1024.png", 1024),
]

output_dir = "doto-ios/Doto/Assets.xcassets/AppIcon.appiconset"

for filename, size in sizes:
    img = Image.new("RGB", (size, size), NAVY)
    draw = ImageDraw.Draw(img)

    r = size * 0.12
    gap = size * 0.18
    c = size / 2.0

    dots = [
        (c - gap, c - gap),
        (c + gap, c - gap),
        (c - gap, c + gap),
        (c + gap, c + gap),
    ]
    for x, y in dots:
        draw.ellipse([x - r, y - r, x + r, y + r], fill=WHITE)

    img.save(f"{output_dir}/{filename}")
    print(f"Generated {filename} ({size}x{size})")

print("Done.")
