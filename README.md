# Traffic Light Controller

A six-state finite state machine for a two-road intersection. The north-south and east-west signals take turns moving through green, yellow, and an all-red interval.

The phase lengths are set in clock cycles with module parameters. This keeps the design easy to test with short simulation values and easy to adapt to a different clock rate.


![Traffic light controller architecture](docs/architecture.svg)

## Signals

| Signal | Direction | Meaning |
| --- | --- | --- |
| `clk` | Input | System clock |
| `rst_n` | Input | Active-low asynchronous reset |
| `ns_light[2:0]` | Output | North-south red, yellow, green |
| `ew_light[2:0]` | Output | East-west red, yellow, green |

The light encoding is active high: `100` red, `010` yellow, and `001` green.

## Run the simulation

Install Icarus Verilog and Python with Matplotlib, then run:

```bash
./scripts/run_sim.sh
```

The testbench checks each phase duration and the complete sequence. The script saves a VCD, a simulation log, and a PNG timing view in `docs/waveforms/`.

## Scope

This is a fixed two-road sequence. It does not include pedestrian requests, vehicle sensors, emergency override, or adaptive timing.

Sai Teja
