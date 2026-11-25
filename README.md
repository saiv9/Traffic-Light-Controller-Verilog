# Traffic Light Controller

[![RTL simulation](https://github.com/saiv9/Traffic-Light-Controller-Verilog/actions/workflows/rtl-simulation.yml/badge.svg)](https://github.com/saiv9/Traffic-Light-Controller-Verilog/actions/workflows/rtl-simulation.yml)

A two-road traffic light controller implemented as a six-state Moore finite-state machine in Verilog HDL. North-south and east-west traffic take turns, with an all-red phase between directions.

## Design features

- Six Moore FSM states
- Separate north-south and east-west signal outputs
- Parameterized green, yellow, and all-red phase lengths
- Active-high red, yellow, and green outputs
- Active-low asynchronous reset
- Self-checking testbench for a complete traffic sequence

## State sequence

```text
NS Green
   |
NS Yellow
   |
All Red
   |
EW Green
   |
EW Yellow
   |
All Red
   |
NS Green (repeat)
```

## Architecture

![Traffic light controller architecture](docs/architecture.svg)

The controller advances through the six states using a cycle counter. Output signals depend only on the current state. The output bit order is `{red, yellow, green}`, with active-high logic.

## Interface

| Signal | Direction | Description |
|---|---|---|
| `clk` | Input | System clock |
| `rst_n` | Input | Asynchronous active-low reset |
| `ns_light[2:0]` | Output | North-south red, yellow, green |
| `ew_light[2:0]` | Output | East-west red, yellow, green |

### Parameters

| Parameter | RTL default | Description |
|---|---:|---|
| `GREEN_CYCLES` | 10 | Duration of each green phase in clock cycles |
| `YELLOW_CYCLES` | 3 | Duration of each yellow phase in clock cycles |
| `ALL_RED_CYCLES` | 1 | Duration of each all-red phase in clock cycles |

The testbench uses shorter phase lengths (4, 2, and 1 cycles respectively) to make the sequence quick to verify.

## Run the simulation

Install Icarus Verilog and Python with Matplotlib. From the repository root, run:

```bash
bash scripts/run_sim.sh
```

The testbench checks the reset outputs, the duration of all six phases, and return to north-south green. The current testbench reports 14 phase checks.

## Simulation output

![Traffic light waveform](docs/waveforms/traffic_light_controller.png)

[Open the VCD waveform](docs/waveforms/traffic_light_controller.vcd) · [View the simulation log](docs/waveforms/simulation.log)

GitHub Actions runs the same testbench and uploads the generated waveform and log.

## Scope

This is a fixed-sequence demonstration. It does not use vehicle sensors or pedestrian requests and has no emergency override or adaptive timing. Verification is simulation-based; no physical traffic controller or FPGA board test is claimed.

## License

MIT. See [LICENSE](LICENSE).
