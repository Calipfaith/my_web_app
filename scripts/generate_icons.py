from math import cos, pi, sin
from pathlib import Path

from PIL import Image, ImageDraw


AMBER = (245, 166, 35, 255)
CREAM = (255, 248, 231, 255)
NEAR_BLACK = (43, 43, 43, 255)
SCALE = 4
ROOT = Path(__file__).resolve().parents[1]


def rounded_hexagon(draw, center, radius, corner_radius, fill):
    """Draw a flat-top hexagon with softened corners."""
    cx, cy = center
    vertices = [
        (cx + radius * cos(angle), cy + radius * sin(angle))
        for angle in (pi / 6, pi / 2, 5 * pi / 6, 7 * pi / 6, 3 * pi / 2, 11 * pi / 6)
    ]
    scaled_radius = corner_radius * SCALE
    draw.polygon(vertices, fill=fill)
    draw.line(
        vertices + [vertices[0]],
        fill=fill,
        width=max(1, int(scaled_radius * 2)),
        joint="curve",
    )


def rotated_ellipse(width, height, fill, angle):
    wing = Image.new("RGBA", (width * 2, height * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(wing)
    draw.ellipse((width // 2, height // 2, width + width // 2, height + height // 2), fill=fill)
    return wing.rotate(angle, resample=Image.Resampling.BICUBIC, expand=False)


def draw_bee(size, maskable=False):
    canvas_size = size * SCALE
    background = CREAM if maskable else (0, 0, 0, 0)
    image = Image.new("RGBA", (canvas_size, canvas_size), background)
    draw = ImageDraw.Draw(image)

    hex_radius = size * (0.72 if maskable else 0.53) * SCALE
    rounded_hexagon(
        draw,
        (canvas_size / 2, canvas_size / 2),
        hex_radius,
        size * (0.12 if maskable else 0.08),
        AMBER,
    )

    wing_width = int(size * 0.23 * SCALE)
    wing_height = int(size * 0.31 * SCALE)
    left_wing = rotated_ellipse(wing_width, wing_height, CREAM, 28)
    right_wing = rotated_ellipse(wing_width, wing_height, CREAM, -28)
    image.alpha_composite(
        left_wing,
        (int(size * 0.25 * SCALE) - wing_width, int(size * 0.42 * SCALE) - wing_height),
    )
    image.alpha_composite(
        right_wing,
        (int(size * 0.75 * SCALE) - wing_width, int(size * 0.42 * SCALE) - wing_height),
    )

    body_box = (
        int(size * 0.35 * SCALE),
        int(size * 0.36 * SCALE),
        int(size * 0.65 * SCALE),
        int(size * 0.78 * SCALE),
    )
    body_mask = Image.new("L", (canvas_size, canvas_size), 0)
    mask_draw = ImageDraw.Draw(body_mask)
    mask_draw.ellipse(body_box, fill=255)

    body = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    body_draw = ImageDraw.Draw(body)
    body_draw.ellipse(body_box, fill=NEAR_BLACK)
    stripe_height = size * 0.055 * SCALE
    for y in (size * 0.49 * SCALE, size * 0.62 * SCALE):
        body_draw.rectangle(
            (int(size * 0.30 * SCALE), int(y), int(size * 0.70 * SCALE), int(y + stripe_height)),
            fill=AMBER,
        )
    body.putalpha(Image.composite(body.getchannel("A"), Image.new("L", body.size, 0), body_mask))
    image.alpha_composite(body)

    head_center = (size * 0.50 * SCALE, size * 0.30 * SCALE)
    head_radius = size * 0.12 * SCALE
    draw.ellipse(
        (
            int(head_center[0] - head_radius),
            int(head_center[1] - head_radius),
            int(head_center[0] + head_radius),
            int(head_center[1] + head_radius),
        ),
        fill=NEAR_BLACK,
    )

    antenna_width = max(1, int(size * 0.018 * SCALE))
    for direction in (-1, 1):
        start = (int(size * (0.46 if direction < 0 else 0.54) * SCALE), int(size * 0.21 * SCALE))
        bend = (int(size * (0.40 if direction < 0 else 0.60) * SCALE), int(size * 0.13 * SCALE))
        tip = (int(size * (0.37 if direction < 0 else 0.63) * SCALE), int(size * 0.10 * SCALE))
        draw.line((start, bend, tip), fill=NEAR_BLACK, width=antenna_width)
        dot_radius = size * 0.025 * SCALE
        draw.ellipse(
            (
                int(tip[0] - dot_radius),
                int(tip[1] - dot_radius),
                int(tip[0] + dot_radius),
                int(tip[1] + dot_radius),
            ),
            fill=NEAR_BLACK,
        )

    return image.resize((size, size), Image.Resampling.LANCZOS)


def main():
    outputs = {
        ROOT / "web/favicon.png": (32, False),
        ROOT / "web/icons/Icon-192.png": (192, False),
        ROOT / "web/icons/Icon-512.png": (512, False),
        ROOT / "web/icons/Icon-maskable-192.png": (192, True),
        ROOT / "web/icons/Icon-maskable-512.png": (512, True),
        ROOT / "assets/frenzybees_logo.png": (192, False),
    }
    for path, (size, maskable) in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        draw_bee(size, maskable=maskable).save(path, format="PNG", optimize=True)
        print(f"Wrote {path.relative_to(ROOT)} ({size}x{size})")


if __name__ == "__main__":
    main()
