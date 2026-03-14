# Viterbi Decoder — ECE 260B Final Project

Rate-1/2, constraint-length-3 convolutional encoder + Viterbi decoder in SystemVerilog.
Requires **Cadence Xcelium (`xrun`)** — run `make` from a standard login shell where `xrun` is in PATH.

---

## Quick Start

```bash
# Part 1: error-free simulation
cd Part1 && make

# Part 2: run all error injection tests + generate transcripts
cd Part2 && make transcripts && make transcripts_2cde
```

---

## Directory Structure

```
Viterbi_Decoder/
├── Part1/
│   ├── verilog/
│   │   ├── decoder.sv            top-level decoder
│   │   ├── ACS.sv                Add-Compare-Select unit
│   │   ├── bmc0.sv               Branch Metric Computation (bmc + bmc_inv)
│   │   ├── tbu.sv                Trace Back Unit
│   │   ├── mem_8x1024.sv         8-bit x 1024 trellis memory
│   │   ├── mem_1x1024.sv         1-bit x 1024 display memory
│   │   ├── encoder.sv            convolutional encoder (not submitted)
│   │   └── viterbi_tx_rx_2a1.sv  clean channel wrapper (not submitted)
│   ├── sim/
│   │   └── viterbi_tx_rx_tb.sv   testbench
│   ├── report_source/
│   │   ├── transcripts.txt       simulation transcript
│   │   ├── waveform.png          waveform screenshot
│   │   └── waves.vcd             VCD waveform file
│   ├── delay.txt                 testbench capture delay value (default 410500)
│   └── Makefile
│
├── Part2/
│   ├── verilog/
│   │   ├── decoder.sv  ACS.sv  bmc0.sv  tbu.sv  mem_*.sv  encoder.sv
│   │   ├── viterbi_tx_rx_2a1.sv .. 2a8.sv   deterministic error injection
│   │   ├── viterbi_tx_rx_2b1.sv .. 2b8.sv   randomized error injection
│   │   ├── viterbi_tx_rx_2c.sv              burst threshold sweep, bit[0]
│   │   ├── viterbi_tx_rx_2d.sv              burst threshold sweep, bit[1]
│   │   └── viterbi_tx_rx_2e.sv              burst threshold sweep, bit[0]+bit[1]
│   ├── sim/
│   │   └── viterbi_tx_rx_tb.sv
│   ├── report_source/
│   │   ├── exp2ab_summary.txt    results table for 2a and 2b
│   │   ├── exp2cde_summary.txt   burst threshold results for 2c/2d/2e
│   │   ├── Part2_spreadsheet.xlsx
│   │   └── transcripts/          per-test transcripts + combined ALL.txt
│   └── Makefile
│
├── instruction/                  assignment reference files (read-only)
├── NOTES.md                      detailed implementation notes
├── .gitignore
└── README.md
```

---

## Part 1 Commands

| Priority | Command | Description |
|----------|---------|-------------|
| ★★★ | `make` | Compile + simulate (error-free). Pass/fail printed to terminal, transcript → `sim.log` |
| ★★☆ | `make waves` | Same simulation but also dumps `waves.vcd` for waveform viewing |
| ★☆☆ | `make clean` | Remove all generated files (`xcelium.d/`, `*.log`, `*.key`, etc.) |

```bash
cd Part1
make               # run simulation
make waves         # run simulation + generate waves.vcd
gtkwave waves.vcd  # open waveform (if GTKWave is available)
make clean
```

---

## Part 2 Commands

| Priority | Command | Description |
|----------|---------|-------------|
| ★★★ | `make transcripts` | Run all 2a1–2a8, 2b1–2b8; extract transcripts → `transcripts/` |
| ★★★ | `make transcripts_2cde` | Run burst sweeps 2c/2d/2e (BURST_LEN=1..8); extract transcripts + generate `exp2cde_summary.txt` |
| ★★☆ | `make sim TEST=2a1` | Run a single test (replace `2a1` with any test name) |
| ★★☆ | `make sweep_summary` | Re-generate `exp2cde_summary.txt` from existing logs (no re-simulation) |
| ★☆☆ | `make all_2a` | Run 2a1–2a8 only (no transcript extraction) |
| ★☆☆ | `make all_2b` | Run 2b1–2b8 only (no transcript extraction) |
| ★☆☆ | `make sweep_2c` | Run 2c sweep only (no transcript extraction) |
| ★☆☆ | `make clean` | Remove all generated files (transcripts are preserved) |

```bash
cd Part2

# Typical full run:
make transcripts          # 2a + 2b
make transcripts_2cde     # 2c + 2d + 2e (also writes exp2cde_summary.txt)

# Single test:
make sim TEST=2b4

# Adjust sweep range (default MAX_BURST=8):
make transcripts_2cde MAX_BURST=12

# Clean without removing transcripts:
make clean
```

---

## Submission Files (Part 1)

| File | Notes |
|------|-------|
| `bmc0.sv` | Contains both `bmc` and `bmc_inv` modules |
| `ACS.sv` | |
| `tbu.sv` | |
| `mem_8x1024.sv` | 8-bit trellis memory only |
| `mem_1x1024.sv` | 1-bit display memory |
| `decoder.sv` | Port names unchanged from starter |
| `delay.txt` | Contains `410500` |

Do **not** submit: `encoder.sv`, `viterbi_tx_rx*.sv`, `viterbi_tx_rx_tb.sv`
(autograder provides its own copies — submitting them causes compile errors).
