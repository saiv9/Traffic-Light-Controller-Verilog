#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build"
WAVE_DIR="$ROOT_DIR/docs/waveforms"
mkdir -p "$BUILD_DIR" "$WAVE_DIR"
command -v iverilog >/dev/null 2>&1 || { echo "Install Icarus Verilog first." >&2; exit 127; }
command -v vvp >/dev/null 2>&1 || { echo "Icarus Verilog runtime (vvp) is missing." >&2; exit 127; }
cd "$ROOT_DIR"
iverilog -g2012 -Wall -s tb_traffic_light_controller -o "$BUILD_DIR/traffic_sim" \
    rtl/traffic_light_controller.v tb/tb_traffic_light_controller.v
vvp "$BUILD_DIR/traffic_sim" 2>&1 | tee "$BUILD_DIR/simulation.log"
python3 scripts/render_waveform.py "$BUILD_DIR/traffic_light_controller.vcd" "$WAVE_DIR/traffic_light_controller.png" \
    "Traffic Light Controller, FSM phase timing" \
    "tb_traffic_light_controller.clk,tb_traffic_light_controller.rst_n,tb_traffic_light_controller.ns_light,tb_traffic_light_controller.ew_light,tb_traffic_light_controller.dut.state,tb_traffic_light_controller.dut.cycle_count"
cp "$BUILD_DIR/traffic_light_controller.vcd" "$WAVE_DIR/traffic_light_controller.vcd"
cp "$BUILD_DIR/simulation.log" "$WAVE_DIR/simulation.log"
echo "Waveform, VCD and log saved in docs/waveforms/."
