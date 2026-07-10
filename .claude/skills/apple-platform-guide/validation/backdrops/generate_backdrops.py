#!/usr/bin/env python3
"""
generate_backdrops.py -- Backdrop library generator for HIG validation captures.

Produces 13 PNG backdrop files using pure Python stdlib (struct + zlib).
No Pillow / numpy / third-party libraries required.

Backdrop catalogue
------------------
macOS contexts (2400 x 1800):
  sheet-backdrop-amber-gradient-light.png   -- cream-to-peach radial gradient
  sheet-backdrop-amber-gradient-dark.png    -- amber-to-deep-ember radial gradient
  sidebar-backdrop-amber-inbox-light.png    -- mock Amber inbox list (cream bg)
  sidebar-backdrop-amber-inbox-dark.png     -- mock Amber inbox list (deep-ember bg)
  menu-backdrop-amber-document-light.png    -- mock Amber journal card (cream bg)
  menu-backdrop-amber-document-dark.png     -- mock Amber journal card (deep-ember bg)
  finder-mail-backdrop-light.png            -- 2-column list + content area (light)
  finder-mail-backdrop-dark.png             -- 2-column list + content area (dark)

iOS contexts (1170 x 2532):
  home-screen-amber-wallpaper-light.png     -- cream-to-peach radial, no icons
  home-screen-amber-wallpaper-dark.png      -- amber-to-deep-ember radial, no icons

Lock screen (1170 x 2532, dark only):
  lock-screen-amber-dark.png               -- dark deep-ember gradient

Regeneration:
  python3 generate_backdrops.py
"""
from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path

OUT = Path(__file__).resolve().parent


# ---------------------------------------------------------------------------
# Amber palette (hex -> (r, g, b) tuples)
# ---------------------------------------------------------------------------

def hex_to_rgb(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


CREAM        = hex_to_rgb("FAF6F0")  # light mode surface
DEEP_EMBER   = hex_to_rgb("2A1A08")  # dark mode surface (burnt amber, warm hue 25deg)
EMBER_GLASS  = hex_to_rgb("3D2614")  # dark glass tint (ember, warm hue 22deg)
PEACH        = hex_to_rgb("FF8C5A")  # warning / gradient edge (light)
PLUM_LIGHT   = hex_to_rgb("5B3A94")  # accent light
PLUM_DARK    = hex_to_rgb("7D59B8")  # accent dark (used for emphasis, not dark BG)
AMBER_GOLD   = hex_to_rgb("FFAD33")  # primary
AMBER_DARK   = hex_to_rgb("FFB84D")  # primary dark
SAGE         = hex_to_rgb("6EAD77")  # success
SEPARATOR    = hex_to_rgb("E5E5EA")  # light separator
SEPARATOR_DK = hex_to_rgb("4A3520")  # dark separator (warm brown, not cool gray)
LABEL_LT     = hex_to_rgb("1D1D1F")  # primary label light
LABEL_DK     = hex_to_rgb("F5F5F7")  # primary label dark
LABEL2_LT    = hex_to_rgb("636366")  # secondary label light
LABEL2_DK    = hex_to_rgb("B8A898")  # secondary label dark (warm gray, not cool)


# ---------------------------------------------------------------------------
# Pure-Python PNG writer (no Pillow)
# ---------------------------------------------------------------------------

def _png_chunk(tag: bytes, data: bytes) -> bytes:
    chunk = tag + data
    return struct.pack(">I", len(data)) + chunk + struct.pack(">I", zlib.crc32(chunk) & 0xFFFFFFFF)


def encode_png(width: int, height: int, pixels: list[tuple[int, int, int]]) -> bytes:
    """
    Encode an RGB image (pixels is a flat list of (r, g, b) tuples, row-major)
    as a PNG byte string.
    """
    # Build raw scanlines -- each row prefixed with filter byte 0 (None)
    raw = bytearray()
    for y in range(height):
        raw.append(0)  # filter byte
        for x in range(width):
            r, g, b = pixels[y * width + x]
            raw.append(r)
            raw.append(g)
            raw.append(b)

    compressed = zlib.compress(bytes(raw), 6)

    sig = b"\x89PNG\r\n\x1a\n"
    ihdr_data = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    ihdr = _png_chunk(b"IHDR", ihdr_data)
    idat = _png_chunk(b"IDAT", compressed)
    iend = _png_chunk(b"IEND", b"")
    return sig + ihdr + idat + iend


def write_png(path: Path, width: int, height: int, pixels: list[tuple[int, int, int]]) -> None:
    data = encode_png(width, height, pixels)
    path.write_bytes(data)
    kb = len(data) // 1024
    print(f"  wrote {path.name}  ({width}x{height}, {kb} KB)")


# ---------------------------------------------------------------------------
# Pixel generators
# ---------------------------------------------------------------------------

def lerp_color(
    c0: tuple[int, int, int],
    c1: tuple[int, int, int],
    t: float,
) -> tuple[int, int, int]:
    """Linear interpolate two RGB tuples by t in [0, 1]."""
    t = max(0.0, min(1.0, t))
    return (
        int(c0[0] + (c1[0] - c0[0]) * t),
        int(c0[1] + (c1[1] - c0[1]) * t),
        int(c0[2] + (c1[2] - c0[2]) * t),
    )


def radial_gradient(
    width: int,
    height: int,
    center_color: tuple[int, int, int],
    edge_color: tuple[int, int, int],
    radius_scale: float = 1.0,
) -> list[tuple[int, int, int]]:
    """
    Radial gradient centered on the image.
    radius_scale: fraction of half-diagonal at which the gradient ends (1.0 = full corner).
    """
    cx = width / 2.0
    cy = height / 2.0
    max_r = math.sqrt(cx * cx + cy * cy) * radius_scale
    pixels = []
    for y in range(height):
        for x in range(width):
            dx = x - cx
            dy = y - cy
            r = math.sqrt(dx * dx + dy * dy)
            t = min(r / max_r, 1.0)
            # Apply smoothstep for a gentle falloff
            t = t * t * (3.0 - 2.0 * t)
            pixels.append(lerp_color(center_color, edge_color, t))
    return pixels


def solid(
    width: int,
    height: int,
    color: tuple[int, int, int],
) -> list[tuple[int, int, int]]:
    return [color] * (width * height)


def fill_rect(
    pixels: list[tuple[int, int, int]],
    width: int,
    x0: int, y0: int, x1: int, y1: int,
    color: tuple[int, int, int],
) -> None:
    """Fill a rectangle in-place."""
    for y in range(max(0, y0), y1):
        for x in range(max(0, x0), x1):
            pixels[y * width + x] = color


def draw_hline(
    pixels: list[tuple[int, int, int]],
    width: int,
    y: int, x0: int, x1: int,
    color: tuple[int, int, int],
) -> None:
    if y < 0:
        return
    for x in range(x0, x1):
        if 0 <= x < width:
            pixels[y * width + x] = color


def draw_color_bar(
    pixels: list[tuple[int, int, int]],
    width: int,
    y: int, x0: int,
    color: tuple[int, int, int],
    bar_width: int = 8,
) -> None:
    """Draw a colored indicator bar (SF Symbol stand-in) at (x0, y)."""
    for dy in range(24):
        for dx in range(bar_width):
            px = x0 + dx
            py = y + dy - 4
            if 0 <= px < width and 0 <= py < len(pixels) // width:
                pixels[py * width + px] = color


# ---------------------------------------------------------------------------
# Backdrop implementations
# ---------------------------------------------------------------------------

# --- 1. Sheet / generic gradient backdrops ---

def make_sheet_gradient(
    width: int, height: int, dark: bool
) -> list[tuple[int, int, int]]:
    if dark:
        # Warm amber center fading to deep ember edge -- sunset-into-night feel.
        # Center is AMBER_GOLD (#FFAD33) at 60% luminance for visible warmth;
        # edge is DEEP_EMBER (#2A1A08) at ~8% luminance.  The radial gradient
        # produces a visually warm tint even through the NSVisualEffectView material.
        return radial_gradient(width, height, AMBER_GOLD, DEEP_EMBER, radius_scale=0.8)
    else:
        return radial_gradient(width, height, CREAM, PEACH, radius_scale=1.2)


# --- 2. Sidebar inbox mock ---

def make_sidebar_inbox(width: int, height: int, dark: bool) -> list[tuple[int, int, int]]:
    """
    A mock Amber inbox list. Sidebar panel occupies the left ~280px of the full
    image width; right portion is the content area (gradient fill).
    Layout is purely color-block approximation -- no text rasterization.
    """
    bg = DEEP_EMBER if dark else CREAM
    content_bg = (45, 28, 10) if dark else (245, 240, 233)
    sep = SEPARATOR_DK if dark else SEPARATOR
    label_color = LABEL_DK if dark else LABEL_LT
    label2_color = LABEL2_DK if dark else LABEL2_LT
    amber_bar = AMBER_DARK if dark else AMBER_GOLD

    pixels = solid(width, height, bg)

    # Left sidebar panel: 280px
    sidebar_w = 280
    fill_rect(pixels, width, 0, 0, sidebar_w, height, bg)

    # Section header MEMORIES at y=48
    section_y = [48, 240, 420]
    section_colors = [
        AMBER_DARK if dark else AMBER_GOLD,
        PLUM_DARK if dark else PLUM_LIGHT,
        SAGE,
    ]
    rows_per_section = [
        # (label_color_hint, has_amber_indicator, badge_bool)
        [(label_color, True, True),    # Inbox (12)
         (label2_color, False, False),  # Dreamed
         (label2_color, False, False),  # Noted
         (label2_color, False, False)], # Archived
        [(label_color, False, False),   # Morning Pages
         (label2_color, False, False),  # Sketches
         (label2_color, False, False),  # Rituals
         (label2_color, False, False)], # Code Spells
        [(label_color, False, False),   # Shared with rift
         (label2_color, False, False)], # Public artifacts
    ]

    y = 60
    for sec_idx, sec_y_start in enumerate(section_y):
        # Section header bar (thin color stripe)
        draw_hline(pixels, width, sec_y_start, 16, 140, section_colors[sec_idx])
        # Section header text block (gray rect)
        fill_rect(pixels, width, 16, sec_y_start - 4, 120, sec_y_start + 4, label2_color)

        y = sec_y_start + 20
        for row_cfg in rows_per_section[sec_idx]:
            row_lc, has_indicator, has_badge = row_cfg
            # Indicator dot
            if has_indicator:
                fill_rect(pixels, width, 8, y - 4, 12, y + 4, amber_bar)
            # Row text block (two gray rects of different widths = bold + preview)
            fill_rect(pixels, width, 20, y - 7, 20 + 100, y - 1, row_lc)
            fill_rect(pixels, width, 20, y + 2, 20 + 70, y + 6, label2_color)
            # Badge (rounded rect approximation)
            if has_badge:
                fill_rect(pixels, width, sidebar_w - 32, y - 8, sidebar_w - 8, y + 8, amber_bar)
            # Separator
            draw_hline(pixels, width, y + 14, 16, sidebar_w - 8, sep)
            y += 44

    # Content area: right of sidebar
    fill_rect(pixels, width, sidebar_w, 0, width, height, content_bg)

    # Mock content rows in the right panel (5 message-row approximations)
    content_x = sidebar_w + 20
    row_height = 72
    for i in range(min(8, height // row_height)):
        row_top = i * row_height + 16
        # Sender name
        fill_rect(pixels, width, content_x, row_top + 8, content_x + 120, row_top + 18,
                  label_color)
        # Subject
        fill_rect(pixels, width, content_x, row_top + 24, content_x + 200, row_top + 32,
                  label_color)
        # Preview line
        fill_rect(pixels, width, content_x, row_top + 38, content_x + 280, row_top + 44,
                  label2_color)
        # Amber dot for unread (first 3 rows)
        if i < 3:
            fill_rect(pixels, width, content_x - 12, row_top + 18, content_x - 4, row_top + 26,
                      amber_bar)
        # Separator
        draw_hline(pixels, width, row_top + row_height - 1, content_x, width - 20, sep)

    return pixels


# --- 3. Menu / document backdrop ---

def make_menu_document(width: int, height: int, dark: bool) -> list[tuple[int, int, int]]:
    """
    A mock Amber journal card (document canvas) behind a context menu.
    The card is centered in the image with a rounded-rect approximation.
    """
    bg = DEEP_EMBER if dark else CREAM
    card_bg = (52, 32, 16) if dark else (255, 254, 250)
    sep = SEPARATOR_DK if dark else SEPARATOR
    label_color = LABEL_DK if dark else LABEL_LT
    label2_color = LABEL2_DK if dark else LABEL2_LT

    pixels = solid(width, height, bg)

    # Card: centered, 60% of width, 50% of height
    card_w = int(width * 0.6)
    card_h = int(height * 0.5)
    card_x = (width - card_w) // 2
    card_y = (height - card_h) // 2

    fill_rect(pixels, width, card_x, card_y, card_x + card_w, card_y + card_h, card_bg)

    # Card border
    draw_hline(pixels, width, card_y, card_x, card_x + card_w, sep)
    draw_hline(pixels, width, card_y + card_h, card_x, card_x + card_w, sep)

    # Heading "Yesterday's thread"
    heading_y = card_y + 32
    heading_color = AMBER_DARK if dark else AMBER_GOLD
    fill_rect(pixels, width, card_x + 24, heading_y, card_x + 24 + 220, heading_y + 14,
              heading_color)

    # Body text lines (5 lines)
    body_y = heading_y + 28
    line_widths = [320, 290, 310, 260, 180]
    for i, lw in enumerate(line_widths):
        fill_rect(pixels, width, card_x + 24, body_y + i * 22,
                  card_x + 24 + lw, body_y + i * 22 + 8, label_color)

    # Divider
    div_y = body_y + 5 * 22 + 16
    draw_hline(pixels, width, div_y, card_x + 24, card_x + card_w - 24, sep)

    # Timestamp footer
    footer_y = div_y + 12
    fill_rect(pixels, width, card_x + 24, footer_y, card_x + 24 + 100, footer_y + 8,
              label2_color)

    return pixels


# --- 4. Home-screen wallpaper ---

def make_home_screen_wallpaper(
    width: int, height: int, dark: bool
) -> list[tuple[int, int, int]]:
    # Same gradient as sheet but portrait-oriented for iPhone
    if dark:
        return radial_gradient(width, height, AMBER_GOLD, DEEP_EMBER, radius_scale=0.9)
    else:
        return radial_gradient(width, height, CREAM, PEACH, radius_scale=1.3)


# --- 5. Lock screen (dark only) ---

def make_lock_screen_dark(width: int, height: int) -> list[tuple[int, int, int]]:
    """
    Warm ember gradient backdrop + time "10:14" and date blocks.
    Text is rendered as color-block approximations.
    """
    pixels = radial_gradient(width, height, AMBER_GOLD, DEEP_EMBER, radius_scale=0.9)

    # Time display: centered, upper-third of screen
    time_cx = width // 2
    time_cy = height // 3

    # "10:14" -- render as a wide white block to suggest large text
    time_w, time_h = 260, 64
    fill_rect(pixels, width,
              time_cx - time_w // 2, time_cy - time_h // 2,
              time_cx + time_w // 2, time_cy + time_h // 2,
              LABEL_DK)

    # Date line below time
    date_y = time_cy + time_h // 2 + 12
    date_w, date_h = 180, 18
    fill_rect(pixels, width,
              time_cx - date_w // 2, date_y,
              time_cx + date_w // 2, date_y + date_h,
              (210, 200, 230))  # slightly muted white

    return pixels


# --- 6. Finder / mail 2-column backdrop ---

def make_finder_mail(width: int, height: int, dark: bool) -> list[tuple[int, int, int]]:
    """
    2-column layout: left a list of Amber memories (5 rows), right a content area.
    Approximates a macOS finder/mail column view.
    """
    bg = DEEP_EMBER if dark else CREAM
    list_bg = (36, 22, 8) if dark else (240, 236, 230)
    content_bg = (48, 28, 10) if dark else (253, 251, 248)
    sep = SEPARATOR_DK if dark else SEPARATOR
    label_color = LABEL_DK if dark else LABEL_LT
    label2_color = LABEL2_DK if dark else LABEL2_LT
    amber_bar = AMBER_DARK if dark else AMBER_GOLD

    pixels = solid(width, height, bg)

    # Left list column: 320px
    list_w = 320
    fill_rect(pixels, width, 0, 0, list_w, height, list_bg)

    # Toolbar strip
    toolbar_h = 44
    toolbar_bg = (55, 33, 12) if dark else (235, 230, 222)
    fill_rect(pixels, width, 0, 0, list_w, toolbar_h, toolbar_bg)
    draw_hline(pixels, width, toolbar_h, 0, list_w, sep)

    # SF Symbol color bars + rows
    sf_colors = [amber_bar, PLUM_DARK if dark else PLUM_LIGHT, SAGE, AMBER_DARK if dark else AMBER_GOLD, LABEL2_DK if dark else LABEL2_LT]
    row_labels_w = [110, 130, 100, 90, 80]   # widths of label text blocks
    row_labels2_w = [80, 95, 70, 60, 55]      # widths of secondary text blocks

    for i in range(5):
        row_y = toolbar_h + 8 + i * 56
        # SF Symbol color dot
        fill_rect(pixels, width, 12, row_y + 8, 36, row_y + 32, sf_colors[i])
        # Primary label block
        fill_rect(pixels, width, 44, row_y + 10, 44 + row_labels_w[i], row_y + 20,
                  label_color)
        # Secondary label block
        fill_rect(pixels, width, 44, row_y + 26, 44 + row_labels2_w[i], row_y + 34,
                  label2_color)
        # Separator
        draw_hline(pixels, width, row_y + 55, 8, list_w - 8, sep)

    # Right content area
    fill_rect(pixels, width, list_w, 0, width, height, content_bg)
    draw_hline(pixels, width, 0, list_w, list_w + 1, sep)

    # Content toolbar
    fill_rect(pixels, width, list_w, 0, width, toolbar_h, toolbar_bg)
    draw_hline(pixels, width, toolbar_h, list_w, width, sep)

    # Content heading
    heading_y = toolbar_h + 28
    heading_color = amber_bar
    fill_rect(pixels, width, list_w + 24, heading_y,
              list_w + 24 + 240, heading_y + 18, heading_color)

    # Content body paragraphs (2 blocks of text lines)
    para_y = heading_y + 36
    para_colors = [label_color, label2_color]
    para_widths = [
        [340, 310, 290, 320],   # first paragraph
        [200, 180],             # second paragraph
    ]
    y = para_y
    for para_idx, lines in enumerate(para_widths):
        for lw in lines:
            fill_rect(pixels, width, list_w + 24, y, list_w + 24 + lw, y + 10,
                      para_colors[para_idx])
            y += 18
        y += 12  # paragraph gap

    return pixels


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

MACOS_W, MACOS_H = 2400, 1800
IOS_W, IOS_H = 1170, 2532


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    print(f"[backdrops] Writing to {OUT}")

    # 1. Sheet gradient (macOS + iOS)
    print("\n[1/6] Sheet gradient backdrops")
    for dark in (False, True):
        suffix = "dark" if dark else "light"
        # macOS
        px = make_sheet_gradient(MACOS_W, MACOS_H, dark)
        write_png(OUT / f"sheet-backdrop-amber-gradient-{suffix}.png", MACOS_W, MACOS_H, px)
        # iOS  (same palette, portrait dimensions)
        px2 = make_sheet_gradient(IOS_W, IOS_H, dark)
        write_png(OUT / f"sheet-backdrop-amber-gradient-ios-{suffix}.png", IOS_W, IOS_H, px2)

    # 2. Sidebar inbox (macOS)
    print("\n[2/6] Sidebar inbox backdrops")
    for dark in (False, True):
        suffix = "dark" if dark else "light"
        px = make_sidebar_inbox(MACOS_W, MACOS_H, dark)
        write_png(OUT / f"sidebar-backdrop-amber-inbox-{suffix}.png", MACOS_W, MACOS_H, px)

    # 3. Menu document (macOS)
    print("\n[3/6] Menu document backdrops")
    for dark in (False, True):
        suffix = "dark" if dark else "light"
        px = make_menu_document(MACOS_W, MACOS_H, dark)
        write_png(OUT / f"menu-backdrop-amber-document-{suffix}.png", MACOS_W, MACOS_H, px)

    # 4. Home-screen wallpaper (iOS)
    print("\n[4/6] Home-screen wallpaper backdrops")
    for dark in (False, True):
        suffix = "dark" if dark else "light"
        px = make_home_screen_wallpaper(IOS_W, IOS_H, dark)
        write_png(OUT / f"home-screen-amber-wallpaper-{suffix}.png", IOS_W, IOS_H, px)

    # 5. Lock screen (iOS, dark only)
    print("\n[5/6] Lock screen backdrop (dark only)")
    px = make_lock_screen_dark(IOS_W, IOS_H)
    write_png(OUT / "lock-screen-amber-dark.png", IOS_W, IOS_H, px)

    # 6. Finder / mail 2-column (macOS)
    print("\n[6/6] Finder/mail 2-column backdrops")
    for dark in (False, True):
        suffix = "dark" if dark else "light"
        px = make_finder_mail(MACOS_W, MACOS_H, dark)
        write_png(OUT / f"finder-mail-backdrop-{suffix}.png", MACOS_W, MACOS_H, px)

    print("\n[backdrops] All backdrops written.")
    print("[backdrops] Regenerate at any time: python3 generate_backdrops.py")


if __name__ == "__main__":
    main()
