CONVERT = CGRAGenerator/verilator/generator_z_tb/io/myconvert.csh

# For 8x8 CGRA grid, change CGRA_SIZE from "4x4" to "8x8"
CGRA_SIZE := "4x4"
MEM_SWITCH = "-oldmem"
ifeq ($(CGRA_SIZE),"8x8")
  MEM_SWITCH = "-newmem"
endif

$(warning CGRA_SIZE = $(CGRA_SIZE))
$(warning MEM_SWITCH = $(MEM_SWITCH))


all: build/pointwise.correct.txt build/conv_bw_mapped.json build/cascade_mapped.json

build/%_design_top.json: Halide_CoreIR/apps/coreir_examples/%
	echo "Halide FLOW"

  # Halide files needed are already in the repo

  # This is where Halide actually compiles our app and runs
  # it to build our comparison output parrot "halide_out.png"
  # as well as the DAG "design_top.json" for the mapper.
  #

	@echo; echo Making $@ because of $?
        # I think e.g. '$*' == "pointwise" when building e.g. "build/pointwise/correct.txt"
        # remake the json and cpu output image for our test app
	make -C Halide_CoreIR/apps/coreir_examples/$*/ clean design_top.json out.png
        # copy over all pertinent files
	cp Halide_CoreIR/apps/coreir_examples/$*/design_top.json build/$*_design_top.json
	cp Halide_CoreIR/apps/coreir_examples/$*/input.png       build/$*_input.png
	cp Halide_CoreIR/apps/coreir_examples/$*/out.png         build/$*_halide_out.png
	cd ..

	ls -la build

	echo "CONVERT PNG IMAGES TO RAW for visual inspection"
        # Could not get "stream" command to work, so using my (steveri) hacky convert script instead...
        #cd ${TRAVIS_BUILD_DIR}

	$(CONVERT) build/$*_input.png      build/$*_input.raw
	$(CONVERT) build/$*_halide_out.png build/$*_halide_out.raw

	echo "VISUALLY CONFIRM THAT OUT = 2*IN"
	od -t u1 build/$*_input.raw      | head
	od -t u1 build/$*_halide_out.raw | head

	ls -la build

	cat build/$*_design_top.json
#  - xxd build/input.png
#  - xxd build/input.raw
#  - xxd build/halide_out.png
#  - xxd build/halide_out.raw

build/%_mapped.json: build/%_design_top.json
  # Mapper uses DAG output "design_top.json" from Halide compiler
  # to produce a mapped version "mapped.json" for the PNR folks.  Right?
  #

	@echo; echo Making $@ because of $?
	echo "MAPPER"
	./CGRAMapper/bin/map build/$*_design_top.json build/$*_mapped.json
	ls -la build
	cat build/$*_mapped.json

build/cgra_info_4x4.txt:
	@echo; echo Making $@ because of $?
	@echo "CGRA generate (generates 4x4 CGRA + connection matrix for pnr)"
	cd CGRAGenerator; ./bin/generate.csh || exit -1
	cp CGRAGenerator/hardware/generator_z/top/cgra_info.txt build/cgra_info_4x4.txt

build/cgra_info_8x8.txt:
	@echo; echo Making $@ because of $?
	@echo "CGRA generate (generates 8x8 CGRA + connection matrix for pnr)"
	cd CGRAGenerator; export CGRA_GEN_USE_MEM=1; ./bin/generate.csh || exit -1
	cp CGRAGenerator/hardware/generator_z/top/cgra_info.txt build/cgra_info_8x8.txt

build/%_pnr_bitstream: build/%_mapped.json build/cgra_info_4x4.txt
        # 
        # pnr
        # IN:  mapped.json      # Output from mapper
        #      cgra_info.txt    # Fully-populated connection matrix from CGRA generator
        #
        # OUT: pnr_bitstream    # bitstream file
        #      annotated        # annotated bitstream file
        #- cd ${TRAVIS_BUILD_DIR}/smt-pnr/src/
        # 

	smt-pnr/src/test.py  build/$*_mapped.json CGRAGenerator/hardware/generator_z/top/cgra_info.txt --bitstream build/$*_pnr_bitstream --annotate build/$*_annotated --print  --coreir-libs stdlib cgralib

	smt-pnr/src/test.py  \
	  build/$*_mapped.json \
	  CGRAGenerator/hardware/generator_z/top/cgra_info.txt \
	  --bitstream build/$*_pnr_bitstream \
	  --annotate build/$*_annotated      \
	  --print  --coreir-libs stdlib cgralib

	smt-pnr/src/test.py     \
	  build/$*_mapped.json   \
	  build/cgra_info_4x4.txt \
	  --bitstream build/$*_pnr_bitstream \
	  --annotate build/$*_annotated      \
	  --print  --coreir-libs stdlib cgralib

# 	build/$*_mapped.json 
# 	CGRAGenerator/hardware/generator_z/top/cgra_info.txt 
# 	--bitstream build/$*_pnr_bitstream 
# 	--annotate build/$*_annotated 
# 	--print  
# 	--coreir-libs stdlib cgralib

        # filter (below) auto-extracts cgra_info file from dependency list maybe
        # I think $(word 2,$?) will return second dependence thingy
	@echo; echo Making $@ because of $?
	\
	config=$(filter %.txt, $?); \
	graph=$(filter  %.json,$?); \
	echo smt-pnr/src/test.py  \
	    $(filter %.txt ,$?)   \
	    $(filter %.json,$?)   \
	    --bitstream build/$*_pnr_bitstream \
	    --annotate build/$*_annotated \
	    --print --coreir-libs stdlib cgralib

	\
	smt-pnr/src/test.py       \
	    $(filter %.txt ,$?)   \
	    $(filter %.json,$?)   \
	    --bitstream build/$*_pnr_bitstream \
	    --annotate build/$*_annotated \
	    --print --coreir-libs stdlib cgralib

	cat build/$*_annotated

# 	set config=build/cgra_info_4x4.txt; \
# 	set graph=build/pointwise_mapped.json; \
# 	smt-pnr/src/test.py  \
# 	    ${graph}  \
# 	    ${config} \
# 	    --bitstream build/pointwise_pnr_bitstream \
# 	    --annotate build/pointwise_annotated \
# 	    --print --coreir-libs stdlib cgralib

  ##############################################################################
  # Little temporary hack to get around instabilities above when/if needed.
  # - EXAMPLE3=${TRAVIS_BUILD_DIR}/CGRAGenerator/bitstream/example3;
  # - cp ${EXAMPLE3}/PNRguys_config.dat ${TRAVIS_BUILD_DIR}/build/config.dat;
  # - cp ${EXAMPLE3}/PNRguys_io.xml     ${TRAVIS_BUILD_DIR}/build/io.xml;
  ##############################################################################

VERILATOR_TOP := CGRAGenerator/verilator/generator_z_tb
build/%_CGRA_out.raw: build/%_pnr_bitstream
  # cgra program and run (caleb bitstream)
  # IN:  pnr_bitstream (Bitstream for programming CGRA)
  #      input.png     (Input image)
  # OUT: CGRA_out.raw  (Output image)

	@echo; echo Making $@ because of $?
	echo "CGRA program and run (uses output of pnr)"

# 	cd CGRAGenerator/verilator/generator_z_tb;  \
# 	./run.csh top_tb.cpp  
# -config ../../../build/$*_pnr_bitstream \
# 	    -input ../../../build/$*_input.png -output ../../../build/$*_CGRA_out.raw -nclocks 5M

	cd $(VERILATOR_TOP);    \
	build=../../../build;   \
	./run.csh top_tb.cpp                   \
	   -config $${build}/$*_pnr_bitstream  \
	   -input  $${build}/$*_input.png      \
	   -output $${build}/$*_CGRA_out.raw   \
	   -nclocks 5M

build/%.correct.txt: build/%_CGRA_out.raw
  # check to see that output is correct.

	@echo; echo Making $@ because of $?
	echo "BYTE-BY-BYTE COMPARE OF CGRA VS. HALIDE OUTPUT IMAGES"
	ls -l build/*.raw
	cmp   build/$*_halide_out.raw  build/$*_CGRA_out.raw

	echo "VISUAL COMPARE OF CGRA VS. HALIDE OUTPUT BYTES (should be null)"
	od -t u1 -w1 -v -A none build/$*_halide_out.raw > /tmp/$*_halide_out.od
	od -t u1 -w1 -v -A none build/$*_CGRA_out.raw   > /tmp/$*_CGRA_out.od
	diff /tmp/$*_halide_out.od /tmp/$*_CGRA_out.od | head -500
	diff /tmp/$*_halide_out.od /tmp/$*_CGRA_out.od > build/$*.diff
	test ! -s build/$*.diff && touch build/$*.correct.txt
