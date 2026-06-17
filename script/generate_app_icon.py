#!/usr/bin/env python3
import argparse
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


def rounded_rect_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def make_base_icon(size: int = 1024) -> Image.Image:
    scale = size / 1024
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    mask = rounded_rect_mask(size, int(230 * scale))

    background = Image.new("RGBA", (size, size), (20, 72, 132, 255))
    draw = ImageDraw.Draw(background)
    for y in range(size):
        t = y / max(1, size - 1)
        r = int(18 + 18 * t)
        g = int(91 + 58 * t)
        b = int(170 + 28 * (1 - t))
        draw.line((0, y, size, y), fill=(r, g, b, 255))

    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        (int(110 * scale), int(90 * scale), int(920 * scale), int(900 * scale)),
        fill=(75, 190, 255, 70),
    )
    glow = glow.filter(ImageFilter.GaussianBlur(int(42 * scale)))
    background.alpha_composite(glow)

    image.paste(background, (0, 0), mask)
    draw = ImageDraw.Draw(image)

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (int(170 * scale), int(190 * scale), int(854 * scale), int(810 * scale)),
        radius=int(76 * scale),
        fill=(0, 0, 0, 115),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(26 * scale)))
    image.alpha_composite(shadow)

    panel = (int(160 * scale), int(170 * scale), int(864 * scale), int(790 * scale))
    draw.rounded_rectangle(panel, radius=int(78 * scale), fill=(236, 248, 255, 238))

    # Gauge arc
    arc_box = (int(270 * scale), int(260 * scale), int(754 * scale), int(744 * scale))
    draw.arc(arc_box, start=132, end=408, fill=(28, 67, 112, 58), width=int(62 * scale))
    draw.arc(arc_box, start=132, end=326, fill=(0, 123, 255, 255), width=int(62 * scale))

    center = (int(512 * scale), int(512 * scale))
    needle_end = (int(665 * scale), int(395 * scale))
    draw.line((center, needle_end), fill=(13, 50, 95, 255), width=int(30 * scale))
    draw.ellipse(
        (
            int(468 * scale),
            int(468 * scale),
            int(556 * scale),
            int(556 * scale),
        ),
        fill=(13, 50, 95, 255),
    )
    draw.ellipse(
        (
            int(488 * scale),
            int(488 * scale),
            int(536 * scale),
            int(536 * scale),
        ),
        fill=(255, 255, 255, 255),
    )

    # Activity bars
    bar_color = (0, 123, 255, 255)
    for x, h in [(332, 86), (426, 142), (520, 104), (614, 172)]:
        x0 = int(x * scale)
        y1 = int(676 * scale)
        draw.rounded_rectangle(
            (x0, y1 - int(h * scale), x0 + int(42 * scale), y1),
            radius=int(18 * scale),
            fill=bar_color,
        )

    return image


def write_iconset(base: Image.Image, iconset_dir: Path) -> None:
    specs = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    iconset_dir.mkdir(parents=True, exist_ok=True)
    for dimension, filename in specs:
        resized = base.resize((dimension, dimension), Image.Resampling.LANCZOS)
        resized.save(iconset_dir / filename)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate SystemWatch .icns app icon.")
    parser.add_argument("--output", required=True, help="Path to the output .icns file.")
    args = parser.parse_args()

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="systemwatch-icon-") as temp_dir:
        iconset = Path(temp_dir) / "SystemWatch.iconset"
        write_iconset(make_base_icon(), iconset)
        subprocess.run(["/usr/bin/iconutil", "-c", "icns", str(iconset), "-o", str(output)], check=True)

    if not output.exists():
        raise RuntimeError(f"Icon generation failed: {output}")


if __name__ == "__main__":
    main()
