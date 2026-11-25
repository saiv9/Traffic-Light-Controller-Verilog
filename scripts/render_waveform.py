#!/usr/bin/env python3
"""Make a readable PNG timing view from an Icarus Verilog VCD file."""

import argparse
import re
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


def read_vcd(path):
    scopes = []
    variables = {}
    changes = {}
    in_header = True
    tick_ns = 1.0
    current_time = 0

    with path.open("r", encoding="utf-8", errors="replace") as stream:
        for raw in stream:
            line = raw.strip()
            if not line:
                continue

            if in_header:
                if line.startswith("$timescale"):
                    scale = line.replace("$timescale", "").replace("$end", "").strip()
                    if not scale:
                        scale = next(stream).strip()
                    match = re.search(r"(\d+)\s*(s|ms|us|ns|ps|fs)", scale)
                    if match:
                        factor = {"s": 1e9, "ms": 1e6, "us": 1e3,
                                  "ns": 1, "ps": 1e-3, "fs": 1e-6}
                        tick_ns = int(match.group(1)) * factor[match.group(2)]
                elif line.startswith("$scope"):
                    scopes.append(line.split()[2])
                elif line.startswith("$upscope"):
                    if scopes:
                        scopes.pop()
                elif line.startswith("$var"):
                    parts = line.split()
                    width, code, name = int(parts[2]), parts[3], parts[4]
                    variables.setdefault(code, []).append(
                        (".".join(scopes + [name]), width)
                    )
                elif line.startswith("$enddefinitions"):
                    in_header = False
                continue

            if line.startswith("#"):
                current_time = int(line[1:])
            elif line[0] in "01xXzZ" and len(line) > 1:
                changes.setdefault(line[1:], []).append((current_time, line[0].lower()))
            elif line[0] in "bB" and " " in line:
                value, code = line[1:].split(None, 1)
                changes.setdefault(code.strip(), []).append((current_time, value.lower()))

    result = []
    for code, definitions in variables.items():
        for name, width in definitions:
            result.append({
                "name": name,
                "width": width,
                "values": changes.get(code, [])
            })
    return result, tick_ns


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("vcd", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("title")
    parser.add_argument("signals", help="Comma-separated VCD signal names")
    args = parser.parse_args()

    if not args.vcd.is_file():
        raise SystemExit(f"VCD file not found: {args.vcd}")

    available, tick_ns = read_vcd(args.vcd)
    wanted = [item.strip() for item in args.signals.split(",") if item.strip()]
    selected = []

    for name in wanted:
        matches = [sig for sig in available
                   if sig["name"] == name or sig["name"].endswith("." + name)]
        if matches:
            matches.sort(key=lambda sig: (".dut." in sig["name"], sig["name"].count(".")))
            selected.append(matches[0])
        else:
            print(f"Note: signal not found in VCD: {name}")

    if not selected:
        raise SystemExit("None of the requested signals were present in the VCD.")

    last_tick = max(
        (time for sig in selected for time, _ in sig["values"]),
        default=1
    )
    end_ns = max(last_tick * tick_ns, 1)
    palette = ["#315f91", "#527c65", "#a56d2a", "#7863a6",
               "#287d83", "#a24f50", "#52627b", "#8a713a"]

    height = max(4, 0.62 * len(selected) + 1.2)
    figure, axis = plt.subplots(figsize=(14, height), dpi=160)
    figure.patch.set_facecolor("#f4f7fb")
    axis.set_facecolor("#ffffff")

    for row, signal in enumerate(selected):
        base = len(selected) - row - 1
        values = signal["values"]
        if not values:
            continue

        color = palette[row % len(palette)]
        times = [0.0] + [time * tick_ns for time, _ in values]
        raw_values = ["x"] + [value for _, value in values]
        x_end = end_ns * 1.02

        if signal["width"] == 1:
            levels = [base + (0.18 if value in ("0", "x", "z") else 0.82)
                      for value in raw_values]
            axis.step(times + [x_end], levels + [levels[-1]],
                      where="post", color=color, linewidth=1.7)
        else:
            middle = base + 0.5
            axis.hlines(middle, 0, x_end, color=color, linewidth=1.5)
            for index, value in enumerate(raw_values):
                next_time = times[index + 1] if index + 1 < len(times) else x_end
                if next_time - times[index] < end_ns * 0.02:
                    continue
                if value and set(value) <= {"0", "1"}:
                    digits = max(1, (signal["width"] + 3) // 4)
                    label = f"0x{int(value, 2):0{digits}X}"
                else:
                    label = value.upper()
                axis.text((times[index] + next_time) / 2, middle + 0.08, label,
                          ha="center", va="bottom", fontsize=7.5, color=color)

    axis.set_yticks(range(len(selected)))
    axis.set_yticklabels(
        [signal["name"].split(".")[-1] for signal in selected][::-1],
        fontsize=9, color="#26364b"
    )
    axis.set_xlim(0, end_ns * 1.02)
    axis.set_ylim(-0.1, len(selected) + 0.1)
    axis.set_xlabel(f"Simulation time (ns), VCD tick = {tick_ns:g} ns",
                    fontsize=9, color="#526680")
    axis.set_title(args.title, loc="left", fontsize=15,
                   fontweight="bold", color="#1f2a3d", pad=16)
    axis.grid(axis="x", color="#dce4ee", linewidth=0.8)
    axis.tick_params(axis="x", labelsize=8, colors="#526680")
    axis.tick_params(axis="y", length=0)
    for side in axis.spines.values():
        side.set_visible(False)

    figure.text(0.01, 0.015, "Rendered from the simulation VCD file",
                fontsize=7.5, color="#667993")
    figure.tight_layout(rect=(0.02, 0.04, 0.995, 0.98))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    figure.savefig(args.output, bbox_inches="tight",
                   facecolor=figure.get_facecolor())
    plt.close(figure)
    print(f"Waveform image written: {args.output}")


if __name__ == "__main__":
    main()
