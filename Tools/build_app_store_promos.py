#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
SETTINGS = ROOT / ".asc" / "shots.settings.json"
SCREENSHOTS = ROOT / ".asc" / "screenshots.json"

WIDTH = 1290
HEIGHT = 2796
PHONE_W = 1012
PHONE_H = 2192
PHONE_X = (WIDTH - PHONE_W) // 2
PHONE_Y = 458
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


def compose(raw_path: Path, caption: str, output_path: Path) -> None:
    raw = Image.open(raw_path).convert("RGB")

    canvas = Image.new("RGB", (WIDTH, HEIGHT), "#071f19")
    draw = ImageDraw.Draw(canvas)

    # Calm clinical background with a subtle green-to-charcoal sweep.
    for y in range(HEIGHT):
        green = int(32 + 32 * (1 - y / HEIGHT))
        blue = int(28 + 22 * (1 - y / HEIGHT))
        draw.line([(0, y), (WIDTH, y)], fill=(6, green, blue))

    draw.polygon([(0, 0), (430, 0), (250, HEIGHT), (0, HEIGHT)], fill=(20, 86, 59))
    draw.polygon([(850, 0), (WIDTH, 0), (WIDTH, HEIGHT), (1030, HEIGHT)], fill=(7, 85, 88))
    draw.polygon([(0, 0), (WIDTH, 0), (WIDTH, 56), (0, 118)], fill=(8, 50, 42))
    draw.line([(0, 118), (WIDTH, 56)], fill=(110, 214, 161), width=2)
    draw.rounded_rectangle(
        (PHONE_X - 22, PHONE_Y - 22, PHONE_X + PHONE_W + 22, PHONE_Y + PHONE_H + 22),
        radius=RADIUS + 24,
        fill=(232, 255, 243),
        outline=(140, 231, 178),
        width=3,
    )

    screenshot = raw.resize((PHONE_W, PHONE_H), Image.Resampling.LANCZOS)
    mask = rounded_mask((PHONE_W, PHONE_H), RADIUS)
    canvas.paste(screenshot, (PHONE_X, PHONE_Y), mask)

    title_font = fit_text(draw, caption, WIDTH - 172, 82)
    title_bbox = draw.textbbox((0, 0), caption, font=title_font)
    title_w = title_bbox[2] - title_bbox[0]
    draw.text(((WIDTH - title_w) / 2, 108), caption, font=title_font, fill=(238, 255, 246))

    subtitle = "Supplement analysis for practitioner review"
    subtitle_font = font(34)
    subtitle_bbox = draw.textbbox((0, 0), subtitle, font=subtitle_font)
    subtitle_w = subtitle_bbox[2] - subtitle_bbox[0]
    draw.text(((WIDTH - subtitle_w) / 2, 216), subtitle, font=subtitle_font, fill=(178, 221, 200))

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
        compose(raw_path, item["caption"], output_path)
        print(output_path)


if __name__ == "__main__":
    main()
