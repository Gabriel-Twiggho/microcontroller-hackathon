#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Analog Devices, Inc.
# ==============================================================================
# entrypoint.sh — Container entry point for the ADI MCU Hackathon Dev Container
# ==============================================================================
set -e

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; GRAY='\033[0;37m'; NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ADI MCU Hackathon Dev Container                  ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ---------------------------------------------------------------------------
# Tool inventory
# ---------------------------------------------------------------------------
print_tool() {
    local label="$1"; local cmd="$2"; local version_cmd="$3"
    local ver
    ver=$(eval "${version_cmd}" 2>/dev/null | head -1) || ver="not found"
    printf "  ${GREEN}%-18s${NC} %s\n" "${label}" "${ver}"
}

echo -e "${GREEN}Compiler toolchain:${NC}"
print_tool "clang"     clang     "clang --version"
print_tool "llc"       llc       "llc --version | head -1"
print_tool "opt"       opt       "opt --version | head -1"
print_tool "lld"       lld       "lld --version"

echo ""
echo -e "${GREEN}RTL / EDA:${NC}"
print_tool "iverilog"  iverilog  "iverilog -V 2>&1"
print_tool "verilator" verilator "verilator --version"
print_tool "yosys"     yosys     "yosys -V"
print_tool "gtkwave"   gtkwave   "gtkwave --version 2>&1"

echo ""
echo -e "${GREEN}Synthesis / P&R:${NC}"
if command -v nextpnr-ice40 &>/dev/null; then
    print_tool "nextpnr-ice40" nextpnr-ice40 "nextpnr-ice40 --version 2>&1"
fi
if command -v quartus_sh &>/dev/null; then
    print_tool "quartus_sh" quartus_sh "quartus_sh --version 2>/dev/null | head -1"
else
    printf "  ${YELLOW}%-18s${NC} %s\n" "quartus_sh" "not installed (optional — see install-quartus)"
fi

# ---------------------------------------------------------------------------
# Registered LLVM backends
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}LLVM registered backends:${NC}"
llc --version 2>/dev/null \
    | grep -E "^\s+(Registered|[A-Z])" \
    | sed 's/^/  /' \
    || echo "  (could not query llc)"

# ---------------------------------------------------------------------------
# Workspace contents
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}Workspace (/workspace):${NC}"
if [ -d /workspace ] && [ "$(ls -A /workspace 2>/dev/null)" ]; then
    ls /workspace | sed 's/^/  /'
else
    echo -e "  ${GRAY}(empty — mount your project with -v <path>:/workspace)${NC}"
fi

# ---------------------------------------------------------------------------
# Quick reference
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}Key commands (from resources/software/):${NC}"
echo "  python3 scripts/build_compiler.py <cfg.build-compiler.yml>   Integrate an LLVM backend"
echo "  python3 scripts/compile.py       <cfg.compile.yml>           C -> LLVM IR -> target asm"
echo "  python3 scripts/simulate.py      <cfg.simulate.yml>          Assemble + run in simulation"
echo "  python3 scripts/synthesize.py    <cfg.synthesize.yml>        Generate/run FPGA synthesis"
echo "  install-quartus <installer.run>                              Install Quartus Prime Lite"
echo ""
echo -e "${GRAY}LLVM source: ${LLVM_SRC:-<unset>}   Build tree: ${LLVM_BUILD:-<unset>}${NC}"
echo ""

exec "$@"
