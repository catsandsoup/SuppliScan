#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SETTINGS = ROOT / ".asc" / "shots.settings.json"
SCREENSHOTS = ROOT / ".asc" / "screenshots.json"

WIDTH = 1290
HEIGHT = 2796
PHONE_W = 1012
PHONE_H = 2192
PHONE_X = (WIDTH - PHONE_W) // 2
PHONE_Y = 476
RADIUS = 70


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def fit_text(draw: ImageDraw.ImageDraw, text: str, max_width: int, start_size: int) -> ImageFont.ImageFont:
    size = start_size
    while size >= 42:
        selected = font(size, bold=True)
        bbox = draw.textbbox((0, 0), text, font=selected)
        if bbox[2] - bbox[0] <= max_width:
            return selected
        size -= 4
    return font(42, bold=True)


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def compose(raw_path: Path, caption: str, detail: str, output_path: Path) -> None:
    raw = Image.open(raw_path).convert("RGB")

    canvas = Image.new("RGB", (WIDTH, HEIGHT), "#f6f5f2")
    draw = ImageDraw.Draw(canvas)

    # Editorial clinical canvas: warm surface first, jade/risk accents second.
    for y in range(HEIGHT):
        blend = y / HEIGHT
        red = int(246 * (1 - blend) + 230 * blend)
        green = int(245 * (1 - blend) + 244 * blend)
        blue = int(242 * (1 - blend) + 238 * blend)
        draw.line([(0, y), (WIDTH, y)], fill=(red, green, blue))

    draw.polygon([(0, 1760), (390, 1470), (226, HEIGHT), (0, HEIGHT)], fill=(12, 124, 104))
    draw.polygon([(934, 0), (WIDTH, 0), (WIDTH, 940), (1056, 1020)], fill=(221, 239, 233))
    draw.polygon([(0, 0), (226, 0), (148, 830), (0, 960)], fill=(236, 248, 243))
    draw.line([(112, 350), (696, 292)], fill=(12, 124, 104), width=3)
    draw.line([(112, 382), (696, 324)], fill=(210, 105, 42), width=2)
    draw.line([(112, 414), (696, 356)], fill=(204, 70, 59), width=2)

    shadow = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (PHONE_X - 24, PHONE_Y - 10, PHONE_X + PHONE_W + 24, PHONE_Y + PHONE_H + 34),
        radius=RADIUS + 28,
        fill=(5, 40, 33, 58),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB")
    draw = ImageDraw.Draw(canvas)

    draw.rounded_rectangle(
        (PHONE_X - 22, PHONE_Y - 22, PHONE_X + PHONE_W + 22, PHONE_Y + PHONE_H + 22),
        radius=RADIUS + 24,
        fill=(239, 255, 248),
        outline=(92, 196, 162),
        width=3,
    )

    screenshot = raw.resize((PHONE_W, PHONE_H), Image.Resampling.LANCZOS)
    mask = rounded_mask((PHONE_W, PHONE_H), RADIUS)
    canvas.paste(screenshot, (PHONE_X, PHONE_Y), mask)

    title_font = fit_text(draw, caption, WIDTH - 172, 78)
    title_bbox = draw.textbbox((0, 0), caption, font=title_font)
    title_w = title_bbox[2] - title_bbox[0]
    draw.text(((WIDTH - title_w) / 2, 96), caption, font=title_font, fill=(22, 24, 28))

    subtitle = detail
    subtitle_font = font(32)
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_w = subtitle_bbox[2] - subtitle_bbox[0]
    draw.text(((WIDTH - subtitle_w) / 2, 198), subtitle, font=subtitle_font, fill=(91, 96, 104))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path, "PNG", optimize=True)


def main() -> None:
    settings = json.loads(SETTINGS.read_text())
    screenshots = json.loads(SCREENSHOTS.read_text())["screenshots"]
    raw_dir = ROOT / settings["rawOutput"]
    framed_dir = ROOT / settings["framedOutput"]
    framed_dir.mkdir(parents=True, exist_ok=True)
    for stale_png in framed_dir.glob("*.png"):
        stale_png.unlink()

    for item in screenshots:
        raw_path = raw_dir / item["raw"]
        if not raw_path.exists():
            print(f"Skipping missing raw screenshot: {raw_path}")
            continue
        output_path = framed_dir / item["framed"]
        compose(raw_path, item["caption"], item.get("detail", ""), output_path)
        print(output_path)


if __name__ == "__main__":
    main()
