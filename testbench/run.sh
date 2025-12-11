#!/bin/bash
cd "$(dirname "$0")"

conda activate cocotb312

export LD_LIBRARY_PATH=/home/codes/miniconda3/envs/cocotb312/lib
export MODULE=tb_toplevel_wrapper
export TOPLEVEL=toplevel_wrapper
export TOPLEVEL_LANG=vhdl

VPI=$(python - <<'EOF'
import cocotb, os
print(os.path.join(cocotb.__path__[0], "libs", "libcocotbvpi_ghdl.so"))
EOF
)

ghdl -r --std=08 toplevel_wrapper --vpi="$VPI"
