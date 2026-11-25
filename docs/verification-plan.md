# Verification plan

The testbench uses short phase lengths so that a full cycle through the intersection finishes quickly.

| Check | Expected result |
| --- | --- |
| Reset | North-south green and east-west red |
| North-south green | Holds for four clock cycles |
| North-south yellow | Holds for two clock cycles |
| All red | Holds for one clock cycle before the next direction |
| East-west green | Holds for four clock cycles |
| East-west yellow | Holds for two clock cycles |
| Return to start | The sequence returns to north-south green |

The testbench checks the outputs on every phase cycle. Run `./scripts/run_sim.sh` to compile it, execute it, and save the VCD and timing view.

The testbench checks the programmed sequence. It does not cover pedestrian requests, sensor inputs, or emergency preemption.
