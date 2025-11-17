# Successive Approximation Register Analog-to-Digial Convertor in SystemVerilog.

- A Successive Approximation Register ADC designed in SystemVerilog with a full testbench, for edge-condition testing and m

## Schematic of the Design.

![Block Diagram](https://github.com/tobywr/SAR_ADC/blob/main/images/schematic.jpeg "Schematic")

### Modules

- `main.sv`: Main SAR-ADC module, including VHold logic, comparator and FSM.
- `transaction_pkg.svh`: transaction package including transaction class for testbench. Generators random Vin analog values, utilizes constraint to keep it between 0-3.3v.
- `tb.sv`: Main testbench module, includes DUT, monitor, scoreboard, driver and generator. Utilizes mailboxes and tasks, and allows for a specific, pre-defined amount of conversions to occur, e.g : 10,000.

## Running simulation + Expected results.

### Running the sim:

1. Import all files from `/src` and `/sim` to your desired simulator (Tested in Vivado 2025.1). If using Vivado, set `transaction_pkg.svh` as a global include file.
2. Run simulation, in TCL console : `launch_simulation`, then `run all`.

### Expected Results:

```
............
............

[PASS] Vin_analog=1.242V -> Vin_digital=96, V_Out=96
[PASS] Vin_analog=0.738V -> Vin_digital=57, V_Out=57
[PASS] Vin_analog=2.485V -> Vin_digital=192, V_Out=192
[PASS] Vin_analog=1.307V -> Vin_digital=101, V_Out=101
[PASS] Vin_analog=1.656V -> Vin_digital=128, V_Out=128
[PASS] Vin_analog=2.860V -> Vin_digital=221, V_Out=221

***** Results *****
Pass Count: 10000
Fail Count: 0
********************

```