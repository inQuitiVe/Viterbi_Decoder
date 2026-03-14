# ============================================================
# Part 2 Simulation Makefile — Cadence Xcelium (xrun)
#
# Targets:
#   make sim             — run a single test (default: 2a1)
#   make sim TEST=2a3    — run a specific test
#   make all_2a          — run all 8 deterministic tests (2a1..2a8)
#   make all_2b          — run all 8 random tests       (2b1..2b8)
#   make all             — run all_2a + all_2b
#   make sweep_2c        — sweep BURST_LEN=1..MAX_BURST for test 2c  (bit[0])
#   make sweep_2d        — same for test 2d (bit[1])
#   make sweep_2e        — same for test 2e (bit[0]+bit[1])
#   make clean           — remove all generated files
#
# Examples:
#   make sim TEST=2b4              — random 2-burst bit[0]
#   make sweep_2c MAX_BURST=6      — sweep burst length 1..6
# ============================================================

XRUN  := xrun
VDIR  := verilog
SDIR  := sim

# ── Shared sub-modules ───────────────────────────────────────
SUBS  := $(VDIR)/encoder.sv      \
          $(VDIR)/mem_8x1024.sv   \
          $(VDIR)/bmc0.sv         \
          $(VDIR)/ACS.sv          \
          $(VDIR)/tbu.sv          \
          $(VDIR)/decoder.sv

TB    := $(SDIR)/viterbi_tx_rx_tb.sv

# ── xrun flags ───────────────────────────────────────────────
XFLAGS := -sv                  \
           -timescale 1ns/1ps  \
           -access +rwc        \
           -exit

# ── Test selection ───────────────────────────────────────────
# Override on command line:  make sim TEST=2a2
TEST      ?= 2a1
CHANNEL   := $(VDIR)/viterbi_tx_rx_$(TEST).sv

# Maximum burst length for sweep targets
MAX_BURST ?= 8

TESTS_2A := 2a1 2a2 2a3 2a4 2a5 2a6 2a7 2a8
TESTS_2B := 2b1 2b2 2b3 2b4 2b5 2b6 2b7 2b8

# ── Targets ──────────────────────────────────────────────────
.PHONY: sim all_2a all_2b all sweep_2c sweep_2d sweep_2e clean

# ── Single test ──────────────────────────────────────────────
sim: $(SUBS) $(CHANNEL) $(TB)
	$(XRUN) $(XFLAGS) -log $(TEST).log $(SUBS) $(CHANNEL) $(TB)
	@echo ""
	@echo "=== Test $(TEST) complete. Transcript: $(TEST).log ==="

# ── All deterministic tests (2.a) ────────────────────────────
all_2a: $(SUBS) $(TB)
	@for t in $(TESTS_2A); do \
	    echo ""; \
	    echo "========== Test $$t =========="; \
	    $(XRUN) $(XFLAGS) -log $${t}.log \
	        $(SUBS) $(VDIR)/viterbi_tx_rx_$${t}.sv $(TB) || true; \
	done
	@echo ""
	@echo "=== all_2a complete. Logs: 2a1.log .. 2a8.log ==="

# ── All random tests (2.b) ───────────────────────────────────
all_2b: $(SUBS) $(TB)
	@for t in $(TESTS_2B); do \
	    echo ""; \
	    echo "========== Test $$t =========="; \
	    $(XRUN) $(XFLAGS) -log $${t}.log \
	        $(SUBS) $(VDIR)/viterbi_tx_rx_$${t}.sv $(TB) || true; \
	done
	@echo ""
	@echo "=== all_2b complete. Logs: 2b1.log .. 2b8.log ==="

# ── Run everything ───────────────────────────────────────────
all: all_2a all_2b

# ── Threshold sweep: consecutive bit[0] errors (2c) ─────────
# Uses xrun -defparam to override BURST_LEN at elaboration time.
# Path: testbench top (viterbi_tx_rx_tb) -> instance vtr -> parameter BURST_LEN
sweep_2c: $(SUBS) $(TB)
	@for b in $(shell seq 1 $(MAX_BURST)); do \
	    echo ""; \
	    echo "========== 2c  BURST_LEN=$$b =========="; \
	    $(XRUN) $(XFLAGS) -log 2c_b$${b}.log \
	        -defparam viterbi_tx_rx_tb.vtr.BURST_LEN=$$b \
	        $(SUBS) $(VDIR)/viterbi_tx_rx_2c.sv $(TB) || true; \
	done
	@echo ""
	@echo "=== sweep_2c complete. Logs: 2c_b1.log .. 2c_b$(MAX_BURST).log ==="

# ── Threshold sweep: consecutive bit[1] errors (2d) ─────────
sweep_2d: $(SUBS) $(TB)
	@for b in $(shell seq 1 $(MAX_BURST)); do \
	    echo ""; \
	    echo "========== 2d  BURST_LEN=$$b =========="; \
	    $(XRUN) $(XFLAGS) -log 2d_b$${b}.log \
	        -defparam viterbi_tx_rx_tb.vtr.BURST_LEN=$$b \
	        $(SUBS) $(VDIR)/viterbi_tx_rx_2d.sv $(TB) || true; \
	done
	@echo ""
	@echo "=== sweep_2d complete. Logs: 2d_b1.log .. 2d_b$(MAX_BURST).log ==="

# ── Threshold sweep: consecutive both-bit errors (2e) ────────
sweep_2e: $(SUBS) $(TB)
	@for b in $(shell seq 1 $(MAX_BURST)); do \
	    echo ""; \
	    echo "========== 2e  BURST_LEN=$$b =========="; \
	    $(XRUN) $(XFLAGS) -log 2e_b$${b}.log \
	        -defparam viterbi_tx_rx_tb.vtr.BURST_LEN=$$b \
	        $(SUBS) $(VDIR)/viterbi_tx_rx_2e.sv $(TB) || true; \
	done
	@echo ""
	@echo "=== sweep_2e complete. Logs: 2e_b1.log .. 2e_b$(MAX_BURST).log ==="

# ── Clean ─────────────────────────────────────────────────────
clean:
	rm -rf xcelium.d INCA_libs .simvision xrun.log *.log *.key
