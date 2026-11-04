#!/usr/bin/env python3
"""Redact and annotate screenshots for bug bounty reports.

Redaction uses opaque solid fills (never blur) and the output is re-saved from
raw pixel data so EXIF and other metadata are dropped.

Usage:
  redact.py grid   in.png out.png [--step 100]
  redact.py apply  in.png out.png --redact x,y,w,h [--redact ...] \
                   [--box x,y,w,h ...] [--label x,y,TEXT ...]

  grid    overlay a labelled coordinate grid so regions can be measured
  --redact  opaque black rectangle over x,y,w,h
  --box     red outline (no fill) to highlight the proof
  --label   red text at x,y
"""
import argparse
import sys

from PIL import Image, ImageDraw


def parse_rect(value):
    try:
        x, y, w, h = (int(p) for p in value.split(","))
    except ValueError:
        raise argparse.ArgumentTypeError(f"expected x,y,w,h integers, got {value!r}")
    if w <= 0 or h <= 0:
        raise argparse.ArgumentTypeError(f"width and height must be positive: {value!r}")
    return x, y, w, h


def parse_label(value):
    parts = value.split(",", 2)
    if len(parts) != 3:
        raise argparse.ArgumentTypeError(f"expected x,y,TEXT, got {value!r}")
    try:
        return int(parts[0]), int(parts[1]), parts[2]
    except ValueError:
        raise argparse.ArgumentTypeError(f"x and y must be integers: {value!r}")


def load(path):
    img = Image.open(path)
    img.load()
    return img.convert("RGB")


def save_clean(img, path):
    # Rebuild from raw pixels so no EXIF/ICC/text chunks carry over.
    clean = Image.new("RGB", img.size)
    clean.putdata(list(img.getdata()))
    clean.save(path)


def cmd_grid(args):
    img = load(args.input)
    d = ImageDraw.Draw(img)
    w, h = img.size
    for x in range(0, w, args.step):
        d.line([(x, 0), (x, h)], fill=(0, 160, 255), width=1)
        d.text((x + 2, 2), str(x), fill=(0, 100, 220))
    for y in range(0, h, args.step):
        d.line([(0, y), (w, y)], fill=(0, 160, 255), width=1)
        d.text((2, y + 2), str(y), fill=(0, 100, 220))
    save_clean(img, args.output)
    print(f"wrote {args.output} ({w}x{h}); grid is a measuring aid, do not attach it")


def cmd_apply(args):
    if not (args.redact or args.box or args.label):
        sys.exit("nothing to do: pass --redact, --box, or --label")
    img = load(args.input)
    d = ImageDraw.Draw(img)
    for x, y, w, h in args.box or []:
        d.rectangle([x, y, x + w, y + h], outline=(220, 0, 0), width=3)
    for x, y, text in args.label or []:
        d.text((x, y), text, fill=(220, 0, 0))
    # Redactions last so nothing drawn above can show through them.
    for x, y, w, h in args.redact or []:
        d.rectangle([x, y, x + w, y + h], fill=(0, 0, 0))
    save_clean(img, args.output)
    print(f"wrote {args.output}; verify redactions by viewing the output")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    g = sub.add_parser("grid")
    g.add_argument("input")
    g.add_argument("output")
    g.add_argument("--step", type=int, default=100)
    g.set_defaults(fn=cmd_grid)

    a = sub.add_parser("apply")
    a.add_argument("input")
    a.add_argument("output")
    a.add_argument("--redact", type=parse_rect, action="append")
    a.add_argument("--box", type=parse_rect, action="append")
    a.add_argument("--label", type=parse_label, action="append")
    a.set_defaults(fn=cmd_apply)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
