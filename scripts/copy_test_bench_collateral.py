import os
import shutil

for test in ["pointwise", "conv_1_2", "conv_2_1", "conv_3_1", "conv_bw"]:
    os.mkdir(f"TestBenchGenerator/tests/{test}")
    for suffix in ["_pnr_bitstream", ".io.json", "_input.raw", "_halide_out.raw"]:
        shutil.copy(f"build/{test}{suffix}", f"TestBenchGenerator/tests/{test}")
