# ============================================================
# Part 2 Simulation Makefile — Cadence Xcelium (xrun)
#
# Targets:
#   make sim             — run a single test (default: 2a1)
#   make sim TEST=2a3    — run a specific test
#   make all_2a          — run all 8 deterministic tests (2a1..2a8)
#   make all_2b          — run all 8 random tests       (2b1..2b8)
#   make all             — run all_2a + all_2b
#   make transcripts     — run all 2a+2b, extract final section into transcripts/
#   make transcripts_2cde — parse sweep logs (2c/2d/2e) into transcripts/ (run after sweeps)
#   make sweep_2c        — sweep BURST_LEN=1..MAX_BURST for test 2c  (bit[0])
#   make sweep_2d        — same for test 2d (bit[1])
#   make sweep_2e        — same for test 2e (bit[0]+bit[1])
#   make sweep_summary   — print corrupted/good/bad table (run after sweeps)
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
          $(VDIR)/mem_1x1024.sv   \
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
TESTS_2CDE := 2c_b1 2c_b2 2c_b3 2c_b4 2c_b5 2c_b6 2c_b7 2c_b8 \
              2d_b1 2d_b2 2d_b3 2d_b4 2d_b5 2d_b6 2d_b7 2d_b8 \
              2e_b1 2e_b2 2e_b3 2e_b4 2e_b5 2e_b6 2e_b7 2e_b8

# ── Output directory for submission transcripts ──────────────
TRANS_DIR := transcripts

# ── Targets ──────────────────────────────────────────────────
.PHONY: sim all_2a all_2b all transcripts transcripts_2cde sweep_2c sweep_2d sweep_2e sweep_summary clean

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

# ── Run all 2a+2b and generate submission transcripts ─────────
# Extracts final section from "word_count" through "corrupted_bits" (incl. yaa!/boo! lines).
# Output: transcripts/2a1.txt .. 2a8.txt, 2b1.txt .. 2b8.txt, ALL.txt
transcripts: $(SUBS) $(TB)
	@mkdir -p $(TRANS_DIR)
	@echo "Running all 2a and 2b tests..."
	@for t in $(TESTS_2A) $(TESTS_2B); do \
	    echo "  Running $$t..."; \
	    $(XRUN) $(XFLAGS) -log $${t}.log \
	        $(SUBS) $(VDIR)/viterbi_tx_rx_$${t}.sv $(TB) 2>/dev/null || true; \
	    if grep -q "word_count" $${t}.log 2>/dev/null; then \
	        sed -n '/word_count/,$$p' $${t}.log > $(TRANS_DIR)/$${t}.txt; \
	    else \
	        echo "ERROR: no word_count (test may have failed)" > $(TRANS_DIR)/$${t}.txt; \
	    fi; \
	done
	@echo "" > $(TRANS_DIR)/ALL.txt
	@for t in $(TESTS_2A) $(TESTS_2B); do \
	    echo "=== $$t ===" >> $(TRANS_DIR)/ALL.txt; \
	    cat $(TRANS_DIR)/$${t}.txt >> $(TRANS_DIR)/ALL.txt; \
	    echo "" >> $(TRANS_DIR)/ALL.txt; \
	done
	@echo "=== transcripts complete ==="
	@echo "  Individual: $(TRANS_DIR)/2a1.txt .. $(TRANS_DIR)/2b8.txt"
	@echo "  Combined:   $(TRANS_DIR)/ALL.txt"

# ── Run all 2c/2d/2e sweeps and generate transcripts ─────────
# Same as transcripts: runs xrun for each test, then extracts word_count through corrupted_bits.
# Output: transcripts/2c_b1.txt .. 2e_b8.txt, ALL_2cde.txt
transcripts_2cde: $(SUBS) $(TB)
	@mkdir -p $(TRANS_DIR)
	@echo "Running all 2c, 2d, 2e sweep tests..."
	@for t in $(TESTS_2CDE); do \
	    prefix=$${t%_b*}; b=$${t#*_b}; \
	    echo "  Running $$t (BURST_LEN=$$b)..."; \
	    $(XRUN) $(XFLAGS) -log $${t}.log \
	        -defparam viterbi_tx_rx_tb.vtr.BURST_LEN=$$b \
	        $(SUBS) $(VDIR)/viterbi_tx_rx_$${prefix}.sv $(TB) 2>/dev/null || true; \
	    if grep -q "word_count" $${t}.log 2>/dev/null; then \
	        sed -n '/word_count/,$$p' $${t}.log > $(TRANS_DIR)/$${t}.txt; \
	    else \
	        echo "ERROR: no word_count ($${t}.log may have failed)" > $(TRANS_DIR)/$${t}.txt; \
	    fi; \
	done
	@echo "" > $(TRANS_DIR)/ALL_2cde.txt
	@for t in $(TESTS_2CDE); do \
	    echo "=== $$t ===" >> $(TRANS_DIR)/ALL_2cde.txt; \
	    cat $(TRANS_DIR)/$${t}.txt >> $(TRANS_DIR)/ALL_2cde.txt; \
	    echo "" >> $(TRANS_DIR)/ALL_2cde.txt; \
	done
	@echo "=== transcripts_2cde complete ==="
	@echo "  Individual: $(TRANS_DIR)/2c_b1.txt .. $(TRANS_DIR)/2e_b8.txt"
	@echo "  Combined:   $(TRANS_DIR)/ALL_2cde.txt"
	@$(MAKE) sweep_summary

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

# ── Print sweep summary (run after sweep_2c / sweep_2d / sweep_2e) ─────
# Finds first BURST_LEN where bad > 0 = threshold answer.
# Output saved to exp2cde_summary.txt
sweep_summary:
	@echo "=== 2c: consecutive bit[0] errors (threshold = first bad>0) ===" > exp2cde_summary.txt
	@for b in $(shell seq 1 $(MAX_BURST)); do \
	    if [ -f 2c_b$${b}.log ] && grep -q "corrupted_bits" 2c_b$${b}.log; then \
	        line=$$(grep "corrupted_bits" 2c_b$${b}.log | tail -1); \
	        printf "  BURST_LEN=%2d: %s\n" $$b "$$line"; \
	    fi; \
	done >> exp2cde_summary.txt
	@echo "" >> exp2cde_summary.txt
	@echo "=== 2d: consecutive bit[1] errors ===" >> exp2cde_summary.txt
	@for b in $(shell seq 1 $(MAX_BURST)); do \
	    if [ -f 2d_b$${b}.log ] && grep -q "corrupted_bits" 2d_b$${b}.log; then \
	        line=$$(grep "corrupted_bits" 2d_b$${b}.log | tail -1); \
	        printf "  BURST_LEN=%2d: %s\n" $$b "$$line"; \
	    fi; \
	done >> exp2cde_summary.txt
	@echo "" >> exp2cde_summary.txt
	@echo "=== 2e: consecutive bit[0]+bit[1] errors ===" >> exp2cde_summary.txt
	@for b in $(shell seq 1 $(MAX_BURST)); do \
	    if [ -f 2e_b$${b}.log ] && grep -q "corrupted_bits" 2e_b$${b}.log; then \
	        line=$$(grep "corrupted_bits" 2e_b$${b}.log | tail -1); \
	        printf "  BURST_LEN=%2d: %s\n" $$b "$$line"; \
	    fi; \
	done >> exp2cde_summary.txt
	@echo "Summary written to exp2cde_summary.txt"

# ── Clean ─────────────────────────────────────────────────────
clean:
	rm -rf xcelium.d INCA_libs .simvision xrun.log *.log *.key *.history
