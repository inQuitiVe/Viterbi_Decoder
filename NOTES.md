# Viterbi Decoder — Implementation Notes

## Directory Structure

```
Viterbi_Decoder/
├── Part1/
│   ├── verilog/
│   │   ├── encoder.sv           ← Convolutional encoder (complete)
│   │   ├── mem_8x1024.sv        ← Trellis / Display memory (complete)
│   │   ├── bmc0.sv              ← Branch Metric Computation (complete)
│   │   ├── ACS.sv               ← Add-Compare-Select (complete)
│   │   ├── tbu.sv               ← Trace Back Unit (complete)
│   │   ├── decoder.sv           ← Top-level decoder (complete)
│   │   └── viterbi_tx_rx_2a1.sv ← Channel wrapper, no error injection (Part 1)
│   └── sim/
│       └── viterbi_tx_rx_tb.sv  ← Main testbench (do not modify)
│
├── Part2/
│   ├── verilog/
│   │   ├── encoder.sv           ← Same as Part 1
│   │   ├── mem_8x1024.sv        ← Same as Part 1
│   │   ├── bmc0.sv              ← Same as Part 1
│   │   ├── ACS.sv               ← Same as Part 1
│   │   ├── tbu.sv               ← Same as Part 1
│   │   ├── decoder.sv           ← Same as Part 1
│   │   └── viterbi_tx_rx_*.sv   ← One file per error injection test case
│   └── sim/
│       └── viterbi_tx_rx_tb.sv  ← Main testbench (do not modify)
│
└── instruction/                 ← Reference materials (do not modify)
```

---

## Part 1 — Implementation Details

### System Architecture

```
encoder_i → [encoder] → encoder_o → [channel: clean in Part 1, errors in Part 2]
                                               ↓ encoder_o_reg
                                          [decoder] → decoder_o
```

Decoder internal data flow:
```
d_in (2 bits/cycle)
    ↓
[8× BMC] ──→ branch metrics (2-bit Hamming distance)
    ↓
[8× ACS] ──→ selection[7:0], validity[7:0], path_cost[0..7]
    ↓
[4× Trellis Memory A/B/C/D, ping-pong, 8-bit × 1024 deep]
    ↓  (bank rotates every 1024 cycles)
[2× TBU traceback]
    ↓
[2× Display Memory, 1-bit × 1024 deep, ping-pong]
    ↓  (pipeline Q3 → Q4 → Q5)
d_out
```

---

### Encoder — `encoder.sv`

Implemented as a finite state machine with 8 states, producing a rate-1/2 convolutional code.

**State Transition Table:**

| cstate | d_in=0: nstate, d_out | d_in=1: nstate, d_out |
|--------|-----------------------|-----------------------|
| 0      | 0, 00                 | 4, 11                 |
| 1      | 4, 00                 | 0, 11                 |
| 2      | 5, 10                 | 1, 01                 |
| 3      | 1, 10                 | 5, 01                 |
| 4      | 2, 10                 | 6, 01                 |
| 5      | 6, 10                 | 2, 01                 |
| 6      | 7, 00                 | 3, 11                 |
| 7      | 3, 00                 | 7, 11                 |

`d_out` and `valid_o` are registered outputs (synchronous, 1-cycle latency).

---

### `mem_8x1024.sv` — Two Modules

| Module     | d_i / d_o width | Purpose                                   |
|------------|-----------------|-------------------------------------------|
| `mem`      | 8-bit           | Trellis memory — stores ACS selection vector |
| `mem_disp` | 1-bit           | Display memory — stores decoded output bit   |

Both use synchronous read/write (write then read at the same clock edge).

---

### `bmc0.sv` — Two Modules

Branch Metric Computation: calculates the Hamming distance between the received `rx_pair` and the expected encoder output.

**AND/XOR encoding principle:**
- `{a & b, a ^ b}` encodes the 2-bit Hamming distance between `(a, b)` and `(0, 0)`
- Example: rx=00 → metric=0; rx=01 or 10 → metric=1; rx=11 → metric=2

**Difference between the two modules:**

| Module    | Applicable states | tmp01       | Expected output (path_0 / path_1) |
|-----------|-------------------|-------------|-----------------------------------|
| `bmc`     | 0, 3, 4, 7        | rx_pair[1]  | 00 / 11                           |
| `bmc_inv` | 1, 2, 5, 6        | ~rx_pair[1] | 10 / 01                           |

---

### `ACS.sv` — Add-Compare-Select

Purely combinational logic.

```
path_cost_0 = path_0_pmc + {6'b0, path_0_bmc}
path_cost_1 = path_1_pmc + {6'b0, path_1_bmc}
```

**Selection logic:**

| path_0_valid | path_1_valid | selection                              |
|--------------|--------------|----------------------------------------|
| ?            | 0            | 0                                      |
| 0            | 1            | 1                                      |
| 1            | 1            | path_cost_0 > path_cost_1 ? 1 : 0     |

**valid_o** = path_0_valid | path_1_valid

**path_cost output** = valid_o ? (selection ? path_cost_1 : path_cost_0) : 8'b0

---

### `tbu.sv` — Trace Back Unit

Reads ACS selection data from the trellis memory and traces back the most likely path.

**Traceback State Transition Table:**

| pstate | d_bit=0 → nstate | d_bit=1 → nstate |
|--------|------------------|------------------|
| 0      | 0                | 1                |
| 1      | 3                | 2                |
| 2      | 4                | 5                |
| 3      | 7                | 6                |
| 4      | 1                | 0                |
| 5      | 2                | 3                |
| 6      | 5                | 4                |
| 7      | 6                | 7                |

`d_bit = selection ? d_in_1[pstate] : d_in_0[pstate]`

**Output logic:**
- `wr_en = selection` (only the active TBU drives output)
- `d_o = selection ? d_in_1[pstate] : 0` (decoded bit = ACS selection at the traced-back state)

**Kick-start exception:**
When `rst=1, enable=1, selection_buf=1, selection=0` (selection just fell to 0), `pstate` is still updated one more time.
Implementation: `if (enable && (selection || (selection_buf && !selection))) pstate <= nstate;`

---

### `decoder.sv` — Top-Level Glue

#### BMC Instantiation (8 instances)

```
bmc     bmc0_inst, bmc3_inst, bmc4_inst, bmc7_inst  ← no inversion
bmc_inv bmc1_inst, bmc2_inst, bmc5_inst, bmc6_inst  ← rx_pair[1] inverted
```

All BMC instances share the same `d_in[1:0]` input and each produces its own path_0/path_1 branch metrics.

#### ACS Interconnect (Butterfly Pattern)

Each ACS_i (destination state) receives its two predecessor states j (path_0) and k (path_1):

| ACS_i (nstate) | j (path_0 from) | k (path_1 from) | BMC   | Uses bmc_inv? |
|----------------|-----------------|-----------------|-------|---------------|
| 0              | 0               | 1               | bmc0  | No            |
| 1              | 3               | 2               | bmc1  | Yes           |
| 2              | 4               | 5               | bmc2  | Yes           |
| 3              | 7               | 6               | bmc3  | No            |
| 4              | 1               | 0               | bmc4  | No            |
| 5              | 2               | 3               | bmc5  | Yes           |
| 6              | 5               | 4               | bmc6  | Yes           |
| 7              | 6               | 7               | bmc7  | No            |

#### Path Cost Overflow Protection

When all 8 new path costs have their MSB set (all >= 128), mask off bit 7 to prevent saturation:
```systemverilog
else if (ACS0_pc[7] & ACS1_pc[7] & ... & ACS7_pc[7])
    path_cost[K] <= 8'h7F & ACSk_pc;
```

#### 4-Bank Ping-Pong Trellis Memory

`mem_bank` increments every 1024 cycles (0→1→2→3→0):

| mem_bank | Write | Idle/clear | Read (TBU)  |
|----------|-------|------------|-------------|
| 0        | A     | C          | B, D        |
| 1        | B     | D          | A, C        |
| 2        | C     | A          | B, D        |
| 3        | D     | B          | A, C        |

Write address = `wr_mem_counter` (0 → 1023, incrementing)
Read address  = `rd_mem_counter` (1023 → 0, decrementing, traceback direction)

#### Display Memory Ping-Pong

| Counter               | Initial value | Direction   |
|-----------------------|---------------|-------------|
| `wr_mem_counter_disp` | 2             | Decrementing |
| `rd_mem_counter_disp` | 1021          | Incrementing |

`mem_bank_Q3` (LSB of `mem_bank_Q2`, delayed 1 cycle) determines which display memory reads and which writes:
- `Q3=0`: disp_mem_0 reads (rd counter), disp_mem_1 writes (wr counter)
- `Q3=1`: disp_mem_0 writes (wr counter), disp_mem_1 reads (rd counter)

#### Pipeline Chain

```
mem_bank → (1 clk) → mem_bank_Q → (1 clk) → mem_bank_Q2   [2-bit, used for TBU mux]
mem_bank_Q2[0] → (1 clk) → mem_bank_Q3 → (1 clk) → mem_bank_Q4 → (1 clk) → mem_bank_Q5
d_out = mem_bank_Q5 ? d_o_disp_mem_1 : d_o_disp_mem_0    [registered]
```

Total pipeline delay from first valid input to first valid output: ~4096 + 9 cycles
(Testbench waits 410500 ns / 100 ns per cycle = 4105 cycles).

---

## Part 2 — Implementation (Complete)

### Test Architecture

Each Part 2 test case has its own `viterbi_tx_rx_*.sv` file under `Part2/verilog/`.
Every file defines the same `module viterbi_tx_rx` but replaces only the error injection logic.
All encoder/decoder sub-modules are shared across tests.

```
Part2/verilog/
├── encoder.sv              ← Same convolutional encoder as Part 1
├── mem_8x1024.sv           ← Same as Part 1
├── bmc0.sv                 ← Same as Part 1
├── ACS.sv                  ← Same as Part 1
├── tbu.sv                  ← Same as Part 1
├── decoder.sv              ← Same as Part 1
│
├── viterbi_tx_rx_2a1.sv    ← bit[0] every 8 samples
├── viterbi_tx_rx_2a2.sv    ← bit[1] every 8 samples
├── viterbi_tx_rx_2a3.sv    ← bit[0]+bit[1] every 16 samples
├── viterbi_tx_rx_2a4.sv    ← bit[0] ×2 every 16 samples
├── viterbi_tx_rx_2a5.sv    ← bit[1] ×2 every 16 samples
├── viterbi_tx_rx_2a6.sv    ← bit[0] ×4 every 32 samples
├── viterbi_tx_rx_2a7.sv    ← bit[1] ×4 every 32 samples
├── viterbi_tx_rx_2a8.sv    ← bit[0]+bit[1] ×2 every 32 samples
│
├── viterbi_tx_rx_2b1.sv    ← random bit[0], avg rate ~1/8
├── viterbi_tx_rx_2b2.sv    ← random bit[1], avg rate ~1/8
├── viterbi_tx_rx_2b3.sv    ← random bit[0]+bit[1], avg rate ~1/16
├── viterbi_tx_rx_2b4.sv    ← random 2-burst bit[0], avg 1 burst per 16
├── viterbi_tx_rx_2b5.sv    ← random 2-burst bit[1], avg 1 burst per 16
├── viterbi_tx_rx_2b6.sv    ← random 4-burst bit[0], avg 1 burst per 32
├── viterbi_tx_rx_2b7.sv    ← random 4-burst bit[1], avg 1 burst per 32
├── viterbi_tx_rx_2b8.sv    ← random 2-burst bit[0]+bit[1], avg 1 burst per 32
│
├── viterbi_tx_rx_2c.sv     ← Parameterized: consecutive bit[0] burst, find error threshold
├── viterbi_tx_rx_2d.sv     ← Parameterized: consecutive bit[1] burst
└── viterbi_tx_rx_2e.sv     ← Parameterized: consecutive bit[0]+bit[1] burst
```

### Error Injection Mechanism

```systemverilog
encoder_o_reg <= encoder_o ^ err_inj;   // XOR injection (1-cycle delayed)
```

- `err_inj = 2'b01`: invert bit[0]
- `err_inj = 2'b10`: invert bit[1]
- `err_inj = 2'b11`: invert both bit[0] and bit[1]

**1-cycle delay note**: `err_inj` is assigned at posedge T, but `encoder_o_reg` at the same
posedge uses the `err_inj` value from the previous cycle (T-1). The actual injection therefore
occurs one cycle after the trigger condition is met. All trigger windows are designed with this
offset in mind to ensure the injected positions match the specification.

### 2.a Test Cases

| File | Trigger condition          | err_inj | Actual injection        | BER  |
|------|----------------------------|---------|-------------------------|------|
| 2a1  | `word_ct[2:0]==7`          | 01      | 1 per 8 cycles          | 1/16 |
| 2a2  | `word_ct[2:0]==7`          | 10      | 1 per 8 cycles          | 1/16 |
| 2a3  | `word_ct[3:0]==F`          | 11      | 1 per 16 cycles         | 2/32 |
| 2a4  | `word_ct[3:0]>=E`          | 01      | 2 consecutive per 16    | 2/32 |
| 2a5  | `word_ct[3:0]>=E`          | 10      | 2 consecutive per 16    | 2/32 |
| 2a6  | `word_ct[4:0]` in [27, 30] | 01      | 4 consecutive per 32    | 4/64 |
| 2a7  | `word_ct[4:0]` in [27, 30] | 10      | 4 consecutive per 32    | 4/64 |
| 2a8  | `word_ct[4:0]` in [29, 30] | 11      | 2 consecutive per 32    | 4/64 |

### 2.b Random Versions

Uses the LSB(s) of `$random` as a probabilistic trigger:

| File | Trigger condition                        | Description                         |
|------|------------------------------------------|-------------------------------------|
| 2b1  | `$random[2:0]==0`                        | Independent random bit[0], prob 1/8 |
| 2b2  | `$random[2:0]==0`                        | Independent random bit[1], prob 1/8 |
| 2b3  | `$random[3:0]==0`                        | Independent random bit[0]+[1], prob 1/16 |
| 2b4  | `$random[3:0]==0` + `burst_active`       | Random 2-burst bit[0]               |
| 2b5  | `$random[3:0]==0` + `burst_active`       | Random 2-burst bit[1]               |
| 2b6  | `$random[4:0]==0` + `burst_cnt[2:0]`     | Random 4-burst bit[0]               |
| 2b7  | `$random[4:0]==0` + `burst_cnt[2:0]`     | Random 4-burst bit[1]               |
| 2b8  | `$random[4:0]==0` + `burst_active`       | Random 2-burst bit[0]+bit[1]        |

### 2.c / 2.d / 2.e — Consecutive Error Threshold Tests (Parameterized)

Each file exposes two parameters, `BURST_LEN` (default 1) and `GAP` (default 32):

```systemverilog
module viterbi_tx_rx #(
   parameter BURST_LEN = 1,   // sweep from 1 upward until bad > 0
   parameter GAP       = 32
) (...);
```

Injection timing: at the end of every `GAP` cycles, `BURST_LEN` consecutive samples are corrupted.

**Procedure to find the threshold:**
1. Set `BURST_LEN=1`, run simulation, check whether `bad > 0`
2. Increment `BURST_LEN` and repeat
3. The first `BURST_LEN` that produces `bad > 0` is the decoder's burst error tolerance threshold

For reference: a rate-1/2, K=3 Viterbi decoder with free distance d_free=5 can correct
isolated single-sample errors. Once the burst length exceeds the decoder's error-correction
capacity, output errors appear.

---

## Simulation Commands

### Part 1 (Cadence xrun — preferred)

```bash
cd Part1
make sim          # compile + run; transcript saved to sim.log
make clean        # remove xcelium.d, logs, etc.
```

### Part 2 (Cadence xrun — preferred)

```bash
cd Part2
make sim                    # run default test (2a1)
make sim TEST=2a4           # run a specific test
make all_2a                 # run all 8 deterministic tests (2a1..2a8)
make all_2b                 # run all 8 random tests       (2b1..2b8)
make all                    # all_2a + all_2b
make sweep_2c               # sweep BURST_LEN=1..8 for bit[0] threshold
make sweep_2d               # sweep for bit[1] threshold
make sweep_2e               # sweep for bit[0]+bit[1] threshold
make sweep_2c MAX_BURST=6   # limit sweep to BURST_LEN=1..6
make clean
```

---

### Alternative: Questa / ModelSim (manual)

**Part 1:**
```tcl
vlib work
vlog Part1/verilog/encoder.sv
vlog Part1/verilog/mem_8x1024.sv
vlog Part1/verilog/bmc0.sv
vlog Part1/verilog/ACS.sv
vlog Part1/verilog/tbu.sv
vlog Part1/verilog/decoder.sv
vlog Part1/verilog/viterbi_tx_rx_2a1.sv
vlog Part1/sim/viterbi_tx_rx_tb.sv
vsim viterbi_tx_rx_tb
run -all
```

Expected output: `corrupted_bits = 0, OUT: good = 256, bad = 0`

**Part 2:** replace `viterbi_tx_rx_2a1.sv` with the desired test file:
```
viterbi_tx_rx_2a1.sv   # bit[0] every 8
viterbi_tx_rx_2a2.sv   # bit[1] every 8
viterbi_tx_rx_2a3.sv   # both bits every 16
viterbi_tx_rx_2a4.sv   # bit[0] x2 every 16
viterbi_tx_rx_2a5.sv   # bit[1] x2 every 16
viterbi_tx_rx_2a6.sv   # bit[0] x4 every 32
viterbi_tx_rx_2a7.sv   # bit[1] x4 every 32
viterbi_tx_rx_2a8.sv   # both bits x2 every 32
```

**Simulation result format** (last line of testbench output):
```
corrupted_bits = X, OUT: good = Y, bad = Z
```
- `corrupted_bits`: number of cycles in which error injection was triggered
- `good`: correctly decoded output bits
- `bad`: incorrectly decoded bits (expect `bad=0` when Viterbi correction succeeds)

---

## Key Design Verification: Minimum Branch Metric = 0

When the channel is clean (`d_in == encoder_o`), the correct path always has branch metric 0.
Example — state 0, d_in=0, expected output `00`:
- rx_pair = 00
- tmp00=0, tmp01=0 → path_0_bmc = {0&0, 0^0} = {0, 0} = **0**

For any state, receiving the correct symbol pair produces metric 0; all incorrect paths
receive a positive metric, so the correct path is always selected.

---

## Removed Files

| File                          | Reason                                                              |
|-------------------------------|---------------------------------------------------------------------|
| `encoder2.sv` (Part1/Part2)   | HW7-style encoder incompatible with this decoder's trellis          |
| `encoder.sv` (empty starter)  | Superseded by the complete `encoder1.sv`                            |
| `encoder_tb.sv` (Part1/Part2) | Standalone encoder test; covered by the top-level testbench         |
| `pattern/encoder_soln.txt`    | Used only by `encoder_tb.sv`                                        |
