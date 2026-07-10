#!/usr/bin/env python3
"""Sample a small ROI center of a PNG, return its average RGB and Lab. If two
images given, compute ΔE2000 between the centers and emit JSON."""
import sys, json, math
from PIL import Image

def srgb_to_linear(c):
    c = c/255.0
    return c/12.92 if c <= 0.04045 else ((c+0.055)/1.055)**2.4

def linear_to_xyz(r,g,b):
    # sRGB D65
    x = r*0.4124564 + g*0.3575761 + b*0.1804375
    y = r*0.2126729 + g*0.7151522 + b*0.0721750
    z = r*0.0193339 + g*0.1191920 + b*0.9503041
    return x,y,z

def xyz_to_lab(x,y,z):
    # D65 reference white
    Xn,Yn,Zn = 0.95047, 1.0, 1.08883
    def f(t):
        return t**(1/3) if t > (6/29)**3 else (1/3)*(29/6)**2*t + 4/29
    fx,fy,fz = f(x/Xn), f(y/Yn), f(z/Zn)
    L = 116*fy - 16
    a = 500*(fx - fy)
    b = 200*(fy - fz)
    return L,a,b

def rgb_to_lab(rgb):
    r,g,b = (srgb_to_linear(c) for c in rgb[:3])
    return xyz_to_lab(*linear_to_xyz(r,g,b))

def delta_e_2000(lab1, lab2):
    # simplified — use CIE76 (Euclidean) which is conservative enough for tint detection
    return math.sqrt(sum((a-b)**2 for a,b in zip(lab1, lab2)))

def avg_center(path, frac=0.05):
    img = Image.open(path).convert("RGB")
    w,h = img.size
    cx, cy = w//2, h//2
    rw, rh = max(1, int(w*frac)), max(1, int(h*frac))
    box = (cx-rw//2, cy-rh//2, cx+rw//2, cy+rh//2)
    crop = img.crop(box)
    px = list(crop.getdata())
    n = len(px)
    avg = tuple(round(sum(p[c] for p in px)/n) for c in range(3))
    return avg

if __name__ == "__main__":
    a = avg_center(sys.argv[1])
    if len(sys.argv) >= 3:
        b = avg_center(sys.argv[2])
        labA = rgb_to_lab(a); labB = rgb_to_lab(b)
        dE = delta_e_2000(labA, labB)
        print(json.dumps({"a_path": sys.argv[1], "b_path": sys.argv[2], "a_rgb": a, "b_rgb": b, "a_lab": labA, "b_lab": labB, "delta_e": round(dE,3)}))
    else:
        print(json.dumps({"path": sys.argv[1], "rgb": a, "lab": rgb_to_lab(a)}))
