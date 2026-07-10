#!/usr/bin/env python3
"""Compare two PNGs at native threshold (0.5% pixels differ by > 3/255 per channel)."""
import sys
from PIL import Image

def diff(a_path, b_path):
    a = Image.open(a_path).convert("RGBA")
    b = Image.open(b_path).convert("RGBA")
    if a.size != b.size:
        return {"same_size": False, "a_size": a.size, "b_size": b.size, "pct_diff": None, "passed": False}
    pa = a.load(); pb = b.load()
    total = a.size[0]*a.size[1]
    bad = 0
    for y in range(a.size[1]):
        for x in range(a.size[0]):
            pa_ = pa[x,y]; pb_ = pb[x,y]
            for c in range(3):
                if abs(pa_[c]-pb_[c]) > 3:
                    bad += 1
                    break
    pct = (bad/total)*100.0
    return {"same_size": True, "a_size": a.size, "total_px": total, "diff_px": bad, "pct_diff": round(pct, 4), "threshold_pct": 0.5, "passed": pct <= 0.5}

if __name__ == "__main__":
    import json
    r = diff(sys.argv[1], sys.argv[2])
    print(json.dumps(r))
