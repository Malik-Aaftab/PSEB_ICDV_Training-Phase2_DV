# AXI-Lite Register File

SystemVerilog implementation of an AXI-Lite slave register file with directed testbench and coverage analysis.

Developed as part of the Digital Verification training under the NECOP program (GIKI consortium / PSEB Inspire initiative).

---

## Overview

This project implements a 32-entry, 32-bit register file accessible through a standard AXI-Lite interface. The design supports full write strobe (WSTRB) merging, independent address/data channel ordering, and response back-pressure.

A structured directed testbench exercises protocol corner cases and collects line, condition, and toggle coverage.

---

## Features Implemented

**DUT**
- AXI-Lite write address / write data / write response channels
- AXI-Lite read address / read data channels
- Byte-enable write merging using WSTRB
- Single-cycle ready generation
- Clean separation between protocol logic and register file

**Testbench**
- Reusable `axi_write` and `axi_read` tasks
- AWVALID-before-WVALID and WVALID-before-AWVALID ordering tests
- Write and read response back-pressure
- Idle channel cycles
- All 16 WSTRB combinations with expected-value checking
- Expanded register address coverage (including indices ≥ 16)
- Explicit signal toggle stimulus
- Additional reset pulse for reset coverage

---

## Directory Structure

```
axi_lite_src/
├── axi_lite_if.sv                  # AXI-Lite interface definition
├── my_axi_lite_regfile.sv          # DUT (axi_lite_regfile + reg_file)
├── my_axi_lite_regfile_tb.sv       # Testbench with write/read tasks
├── axi_lite_coverage_tasks.svh     # Directed coverage test suite
├── top.sv                          # Top-level integration
├── report/                         # Coverage report (URG output)
│   ├── dashboard.html
│   ├── hierarchy.html
│   ├── modlist.html
│   ├── tests.html
│   ├── session.xml
│   └── mod*.html                   # Per-module coverage details
└── README.md
```

---

## How to Run

Compile and simulate with any IEEE-1800 compliant simulator (example using VCS-style flow):

```bash
# Compile
vcs -sverilog \
    axi_lite_if.sv \
    my_axi_lite_regfile.sv \
    my_axi_lite_regfile_tb.sv \
    top.sv \
    -o simv

# Run simulation with coverage
./simv -cm line+cond+tgl

# Generate coverage report (URG)
urg -dir simv.vdb -report report/
```

A pre-generated coverage report is already included in the `report/` folder.  
Open `report/dashboard.html` to view the results.

---

## Coverage Results

| Metric     | Coverage |
|------------|----------|
| Overall    | 91.10%   |
| Line       | 94.25%   |
| Condition  | 84.85%   |
| Toggle     | 94.20%   |

### Key Observations

- **Line** coverage is high. Remaining holes are mostly error-path statements (non-OKAY responses) that are intentionally not exercised.
- **Condition** gaps come mainly from multi-input AND expressions in the write-handshake logic. Only the all-true case occurs under normal AXI-Lite protocol.
- **Toggle** gaps appear on:
  - Address bits [1:0] (always word-aligned)
  - Response codes (always OKAY)
  - A few address MSB 1→0 transitions

These gaps are understood and can be closed with additional directed or constrained-random tests if 100% is required.

---

## Concepts Applied

The following SystemVerilog constructs taught in the course were used:

- Tasks and functions for reusable stimulus
- Interfaces with modports for clean DUT/TB connection
- Hierarchical test organization via included task files
- Coverage-driven verification mindset (line / condition / toggle)

Object-oriented features (classes, inheritance, polymorphism, access control) were studied in parallel and will be applied in subsequent verification environments.

---

## Next Steps

- Close remaining condition bins with carefully crafted handshake sequences
- Improve toggle coverage on address low bits and response codes
- Introduce constrained-random stimulus and functional coverage groups
- Explore UVM-style structure in later modules

---

*Training program: NECOP – GIKI Consortium – PSEB Inspire*
