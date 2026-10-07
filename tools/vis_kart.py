#!/usr/bin/env python3
"""
Tegner kartet ovenfra til en PNG, fra DATA-linjene til test/kart.test.lua.

    python3 tools/test_luau.py test/kart.test.lua --data /tmp/kart.json
    python3 tools/vis_kart.py /tmp/kart.json -o assets/previews/_kart.png
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from vis_bane import Lerret  # noqa: E402


def main():
    data = json.load(open(sys.argv[1]))
    ut = sys.argv[sys.argv.index('-o') + 1] if '-o' in sys.argv else 'kart.png'
    B = 1000
    c = Lerret(B, B, (150, 195, 235))
    x0, x1 = -230, 230
    s = B / (x1 - x0)

    def til(x, z):
        return (x - x0) * s, (z - x0) * s
    for d in data:
        if d['k'] == 'c':
            dyp = (d['t'] - d['b']) / 40
            f = (int(90 + 40 * dyp), int(170 - 30 * dyp), 70) if d['t'] <= 41 else (150, 150, 160)
            px, pz = til(d['x'] - 2, d['z'] - 2)
            for yy in range(int(pz), int(pz + 4 * s)):
                for xx in range(int(px), int(px + 4 * s)):
                    c.sett(xx, yy, f)
    for d in data:
        if d['k'] == 'bro':
            ax, az = til(d['ax'], d['az'])
            bx, bz = til(d['bx'], d['bz'])
            c.linje(ax, az, bx, bz, 3.5 * s / 2, (150, 100, 55))
    farger = {'s': (230, 230, 235), 'laas': (255, 60, 60), 'plate': (60, 220, 110), 'skilt': (140, 90, 50),
              'belte': (50, 50, 60)}
    for d in data:
        if d['k'] in farger:
            x, z = til(d['x'], d['z'])
            c.sirkel(x, z, (1.8 if d['k'] == 's' else 2.5) * s, farger[d['k']])
    c.lagre(ut)
    print('Skrev', ut)


if __name__ == '__main__':
    main()
