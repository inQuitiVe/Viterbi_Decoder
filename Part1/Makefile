# ============================================================
# Part 1 Simulation Makefile — Cadence Xcelium (xrun)
#
# Targets:
#   make sim     — compile and run the Part 1 testbench
#   make clean   — remove all generated files
# ============================================================

XRUN  := xrun
VDIR  := verilog
SDIR  := sim

# ── Source files ─────────────────────────────────────────────
SUBS  := $(VDIR)/encoder.sv        \
          $(VDIR)/mem_8x1024.sv     \
          $(VDIR)/bmc0.sv           \
          $(VDIR)/ACS.sv            \
          $(VDIR)/tbu.sv            \
          $(VDIR)/decoder.sv

CHANNEL := $(VDIR)/viterbi_tx_rx_2a1.sv   # clean channel (no errors)

TB    := $(SDIR)/viterbi_tx_rx_tb.sv

SRCS  := $(SUBS) $(CHANNEL) $(TB)

# ── xrun flags ───────────────────────────────────────────────
# -sv               : enable SystemVerilog
# -timescale 1ns/1ps: set default timescale to match testbench delays
# -access +rwc      : read/write/connect access (needed for vtr.* hierarchy probing)
# -exit             : exit simulator when $stop or $finish is reached
# -log sim.log      : write transcript to sim.log
XFLAGS := -sv                  \
           -timescale 1ns/1ps  \
           -access +rwc        \
           -exit               \
           -log sim.log

# ── Targets ──────────────────────────────────────────────────
.PHONY: sim clean

sim: $(SRCS)
	$(XRUN) $(XFLAGS) $(SRCS)
	@echo ""
	@echo "=== Simulation complete. Transcript: sim.log ==="

clean:
	rm -rf xcelium.d INCA_libs .simvision xrun.log sim.log *.key
