#!/usr/bin/env python3
# gen_logo.py
# Input: BW PNG grid of character cells
# Outputs: preview.bin, fontdata.h
# Deduplicates identical slices; fontdata.h uses #define GLYPH_HEIGHT and #define GLYPH_COUNT
# Requires Pillow: pip install pillow

from PIL import Image
from pathlib import Path
import sys, math

# ----- Configuration -----
GRID_COLS = 17
GRID_ROWS = 3
CELL_W = 8
CELL_H = 16        # change here if your PNG cell height differs
GLYPH_HEIGHT = CELL_H
START_CODEPOINT = 0xC0
WHITE_IS_ZERO = True   # white->0, black->1
PREVIEW_NAME = "preview.bin"
HFILE_NAME = "fontdata.h"
# --------------------------------

def load_image(path):
    im = Image.open(path)
    return im.convert("1")  # 1-bit BW (white=255, black=0)

def cell_is_empty(img, left, top, w, h):
    for y in range(top, top+h):
        for x in range(left, left+w):
            if img.getpixel((x,y)) != 255:
                return False
    return True

def cell_to_slices(img, left, top, w, h):
    slices = []
    n = math.ceil(w/8)
    for s in range(n):
        slice_left = left + s*8
        rows = []
        for y in range(top, top+h):
            byte = 0
            for bit in range(8):
                xx = slice_left + bit
                if xx >= left + w:
                    pixel_on = False
                else:
                    pixel = img.getpixel((xx,y))
                    pixel_on = (pixel != 255)
                # WHITE_IS_ZERO: white->0, black->1
                bitval = 1 if pixel_on else 0 if WHITE_IS_ZERO else 0 if pixel_on else 1
                if bitval:
                    byte |= (1 << (7 - bit))  # MSB = leftmost
            rows.append(byte)
        slices.append(tuple(rows))
    return slices

def main():
    if len(sys.argv) != 2:
        print("Usage: python gen_logo.py input.png")
        sys.exit(1)
    in_png = Path(sys.argv[1])
    if not in_png.exists():
        print("Input PNG not found:", in_png)
        sys.exit(2)

    img = load_image(in_png)
    iw, ih = img.size
    need_w = GRID_COLS * CELL_W
    need_h = GRID_ROWS * CELL_H
    if iw < need_w or ih < need_h:
        print(f"Error: image too small: got {iw}x{ih}, need {need_w}x{need_h}")
        sys.exit(3)

    if GLYPH_HEIGHT != CELL_H:
        print("Note: GLYPH_HEIGHT != CELL_H; rows will be padded/truncated")

    # preview table (256 slots) initially zeroed
    preview = [ [0]*GLYPH_HEIGHT for _ in range(256) ]

    # dedup structures
    glyph_to_index = {}      # maps tuple(rows) -> index in packed_glyphs
    packed_glyphs = []       # list of unique glyph tuples
    slice_codepoint = []     # maps packed index -> preview codepoint

    # cell_map row-major
    cell_map = [[0x20 for _ in range(GRID_COLS)] for _ in range(GRID_ROWS)]

    codepoint = START_CODEPOINT

    for row in range(GRID_ROWS):
        for col in range(GRID_COLS):
            left = col * CELL_W
            top = row * CELL_H
            if cell_is_empty(img, left, top, CELL_W, CELL_H):
                cell_map[row][col] = 0x20
                continue
            slices = cell_to_slices(img, left, top, CELL_W, CELL_H)
            first_cp_for_cell = None
            for sidx, glyph in enumerate(slices):
                # pad/truncate glyph to GLYPH_HEIGHT
                glyph_rows = list(glyph[:GLYPH_HEIGHT]) + [0]*(GLYPH_HEIGHT - len(glyph))
                glyph_key = tuple(glyph_rows)
                # deduplicate: reuse existing packed glyph if identical
                if glyph_key in glyph_to_index:
                    packed_index = glyph_to_index[glyph_key]
                    assigned_cp = slice_codepoint[packed_index]
                else:
                    # new unique glyph: assign next preview codepoint and append to packed list
                    if codepoint >= 256:
                        print("Error: ran out of preview codepoints")
                        sys.exit(4)
                    assigned_cp = codepoint
                    codepoint += 1
                    packed_index = len(packed_glyphs)
                    glyph_to_index[glyph_key] = packed_index
                    packed_glyphs.append(glyph_rows)
                    slice_codepoint.append(assigned_cp)
                    preview[assigned_cp] = glyph_rows[:]  # place into preview array
                if first_cp_for_cell is None:
                    first_cp_for_cell = assigned_cp
            # If cell uses multiple slices, they must be consecutive codepoints for printing.
            # Dedup may cause identical slices to map to non-consecutive codepoints.
            # To ensure printing works by emitting consecutive chars we need to guarantee
            # that for a multi-slice cell the codepoints are consecutive. We'll handle this:
            if first_cp_for_cell is None:
                cell_map[row][col] = 0x20
            else:
                # Reconstruct the sequence of assigned codepoints for this cell's slices
                seq = []
                for sidx, glyph in enumerate(slices):
                    glyph_rows = list(glyph[:GLYPH_HEIGHT]) + [0]*(GLYPH_HEIGHT - len(glyph))
                    packed_index = glyph_to_index[tuple(glyph_rows)]
                    seq.append(slice_codepoint[packed_index])
                # If seq is already consecutive (start..start+N-1) we can store start.
                # Otherwise we must ensure printing on screen prints correct slices; easiest approach:
                # create or reuse a consecutive block in preview by allocating new codepoints
                # for the sequence if they are not consecutive.
                consec = True
                for i in range(1, len(seq)):
                    if seq[i] != seq[0] + i:
                        consec = False
                        break
                if consec:
                    cell_map[row][col] = seq[0]
                else:
                    # allocate consecutive preview slots and ensure preview contains corresponding glyphs
                    start_cp = codepoint
                    for grows in [list(g[:GLYPH_HEIGHT]) + [0]*(GLYPH_HEIGHT - len(g)) for g in slices]:
                        if codepoint >= 256:
                            print("Error: ran out of preview codepoints while making consecutive block")
                            sys.exit(5)
                        preview[codepoint] = grows[:]
                        packed_key = tuple(grows)
                        # If this glyph already exists in packed_glyphs, reuse the packed storage
                        if packed_key in glyph_to_index:
                            # reuse packed index, but still assign new preview codepoint for printing order
                            pass
                        else:
                            # new unique packed glyph (but we still append so font_data contains it)
                            packed_index = len(packed_glyphs)
                            glyph_to_index[packed_key] = packed_index
                            packed_glyphs.append(grows)
                            slice_codepoint.append(codepoint)
                        codepoint += 1
                    # store start of new consecutive block
                    cell_map[row][col] = start_cp

    # write preview.bin (256 * GLYPH_HEIGHT bytes)
    with open(PREVIEW_NAME, "wb") as f:
        for g in preview:
            f.write(bytes(g))

    # write fontdata.h with #defines and arrays
    with open(HFILE_NAME, "w", newline="\n") as f:
        f.write("// Generated by png_to_cfont_dedup.py\n")
        f.write("#ifndef FONTDATA_H\n#define FONTDATA_H\n\n")
        f.write("#include <stdint.h>\n\n")
        f.write(f"#define GLYPH_HEIGHT {GLYPH_HEIGHT}\n")
        f.write(f"#define GLYPH_COUNT {len(packed_glyphs)}\n\n")
        f.write(f"/* Packed unique glyphs: {len(packed_glyphs)} entries, each GLYPH_HEIGHT bytes */\n")
        f.write(f"static const uint8_t font_data[{len(packed_glyphs)*GLYPH_HEIGHT}] = {{\n")
        for g in packed_glyphs:
            f.write("  " + ", ".join(f"0x{b:02X}" for b in g) + ", \n")
        f.write("};\n\n")

        f.write("/* cell_map[row][col] : codepoint to print (0x20 = space). Row-major, left->right, up->down */\n")
        f.write(f"static const uint8_t cell_map[{GRID_ROWS}][{GRID_COLS}] = {{\n")
        for r in range(GRID_ROWS):
            rowvals = ", ".join(f"0x{cell_map[r][c]:02X}" for c in range(GRID_COLS))
            f.write("  { " + rowvals + " },\n")
        f.write("};\n\n")

        f.write("#endif // FONTDATA_H\n")

    print(f"Wrote {PREVIEW_NAME} and {HFILE_NAME}")
    print(f"Grid {GRID_COLS}x{GRID_ROWS}, unique glyphs {len(packed_glyphs)}, preview start CP 0x{START_CODEPOINT:02X}")

if __name__ == "__main__":
    main()

