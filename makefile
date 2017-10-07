CONVERT = CGRAGenerator/verilator/generator_z_tb/io/myconvert.csh

########################################################################
# For 8x8 CGRA grid, change CGRA_SIZE from "4x4" to "8x8"
# E.g. "make CGRA_SIZE=8x8"

# For now, default is "4x4"
DELAY := 0,0           # How long to wait before first output / last output
$(warning DELAY = $(DELAY))

# EGREGIOUS_CONV21_HACK := FALSE
# EGREGIOUS_CONV21_HACK_SWITCH :=
# ifeq ($(EGREGIOUS_CONV21_HACK), TRUE)
# 	EGREGIOUS_CONV21_HACK_SWITCH := -egregious_conv21_hack
# endif

SILENT := TRUE
ifeq ($(SILENT), TRUE)
	OUTPUT           :=  > /dev/null
	SILENT_FILTER_HF :=  | egrep -i 'compiling|flattening|run|json|start|finish|success'
	QVSWITCH         :=  -q
else
	OUTPUT           :=
	SILENT_FILTER_HF :=
	QVSWITCH         :=  -v
endif
$(warning OUTPUT = "$(OUTPUT)")

# Image being used
IMAGE := default

CGRA_SIZE := 8x8
ifeq ($(CGRA_SIZE), 4x4)
	MEM_SWITCH := -oldmem -4x4
endif

MEM_SWITCH := -oldmem  # Don't really need this...riiight?
ifeq ($(CGRA_SIZE), 8x8)
	MEM_SWITCH := -newmem -8x8
endif

$(warning CGRA_SIZE = $(CGRA_SIZE))
$(warning MEM_SWITCH = $(MEM_SWITCH))

# $(warning EGREGIOUS_CONV21_HACK = $(EGREGIOUS_CONV21_HACK))
# $(warning EGREGIOUS_CONV21_HACK_SWITCH = $(EGREGIOUS_CONV21_HACK_SWITCH))

########################################################################

# No longer used
# all: start_testing \
#      build/pointwise.correct.txt \
#      build/cascade_mapped.json

start_testing:
        # Build a test summary for the travis log.
	if `test -e build/test_summary.txt`; then rm build/test_summary.txt; fi
	echo TEST SUMMARY > build/test_summary.txt
	echo BEGIN `date` >> build/test_summary.txt

ifeq ($(GOLD), ignore)
	echo "Skipping gold test because GOLD=ignore..."
else
	if `test -e test/compare_summary.txt`; then rm test/compare_summary.txt; fi
	echo -n "GOLD-COMPARE SUMMARY " > test/compare_summary.txt
	echo    "BEGIN `date`"         >> test/compare_summary.txt
endif



end_testing:
ifeq ($(GOLD), ignore)
	echo "Skipping gold test because GOLD=ignore..."
else
	echo -n "GOLD-COMPARE SUMMARY " >> test/compare_summary.txt
	echo    "END `date`"            >> test/compare_summary.txt
	cat test/compare_summary.txt
endif
	cat build/test_summary.txt


%_input_image:
	# copy image to halide branch if not using "default"
	if [ $(IMAGE) != default ]; then\
		$(MAKE) -C $(TESTIMAGE_PATH) $(IMAGE);\
		cp tools/gen_testimage/input.png Halide_CoreIR/apps/coreir_examples/$*/input.png;\
	fi

build/%_design_top.json: %_input_image Halide_CoreIR/apps/coreir_examples/%
	echo "Halide FLOW"

        # Halide files needed are already in the repo
        # This is where Halide actually compiles our app and runs
        # it to build our comparison output parrot "halide_out.png"
        # as well as the DAG "design_top.json" for the mapper.
        #

        # remake the json and cpu output image for our test app
	@echo; echo Making $@ because of $?
        # E.g. '$*' = "pointwise" when building "build/pointwise/correct.txt"
	make -C Halide_CoreIR/apps/coreir_examples/$*/ clean design_top.json out.png $(SILENT_FILTER_HF)

        # copy over all pertinent files
	cp Halide_CoreIR/apps/coreir_examples/$*/design_top.json build/$*_design_top.json
	cp Halide_CoreIR/apps/coreir_examples/$*/input.png       build/$*_input.png
	cp Halide_CoreIR/apps/coreir_examples/$*/out.png         build/$*_halide_out.png
	cd ..

	if [ $(SILENT) != "TRUE" ]; then ls -la build; fi

	echo "CONVERT PNG IMAGES TO RAW for visual inspection"
        # Could not get "stream" command to work, so using my (steveri) hacky convert script instead...
        #cd ${TRAVIS_BUILD_DIR}

	$(CONVERT) build/$*_input.png      build/$*_input.raw
	$(CONVERT) build/$*_halide_out.png build/$*_halide_out.raw

	echo "VISUALLY CONFIRM APP IN/OUT"
	od -t u1 build/$*_input.raw      | head
	od -t u1 build/$*_halide_out.raw | head

	cat build/$*_design_top.json $(OUTPUT)

ifeq ($(GOLD), ignore)
	echo "Skipping gold test because GOLD=ignore..."
else
	echo "GOLD-COMPARE --------------------------------------------------" \
	  | tee -a test/compare_summary.txt
	test/compare.csh $@ diff 2>&1 | head -n 40 | tee -a test/compare_summary.txt
	test/compare.csh $@ graphcompare 2>&1 | head -n 40 | tee -a test/compare_summary.txt
endif

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
	./CGRAMapper/bin/mapper build/$*_design_top.json build/$*_mapped.json $(OUTPUT)
	cat build/$*_mapped.json $(OUTPUT)

        # Yeah, this doesn't always work (straight diff) (SD)
        #test/compare.csh build/$*_mapped.json diff \
        #  $(filter %.txt, $?) 2>&1 | tee -a test/compare_summary.txt
        # UPDATE: Ross says this will work now (above).
        # TODO in next rev: maybe do SD first, then topo compare if/when SD fails?

ifeq ($(GOLD), ignore)
	echo "Skipping gold test because GOLD=ignore..."
else
	test/compare.csh build/$*_mapped.json graphcompare \
	  $(filter %.txt, $?) 2>&1 | head -n 40 | tee -a test/compare_summary.txt
endif

build/cgra_info_4x4.txt:
	@echo; echo Making $@ because of $?
	@echo "CGRA generate (generates 4x4 CGRA + connection matrix for pnr)"
	cd CGRAGenerator; ./bin/generate.csh $(QVSWITCH) || exit -1
	cp CGRAGenerator/hardware/generator_z/top/cgra_info.txt build/cgra_info_4x4.txt

build/cgra_info_8x8.txt:
	@echo; echo Making $@ because of $?
	@echo "CGRA generate (generates 8x8 CGRA + connection matrix for pnr)"
	cd CGRAGenerator; export CGRA_GEN_USE_MEM=1; ./bin/generate.csh $(QVSWITCH) || exit -1
	cp CGRAGenerator/hardware/generator_z/top/cgra_info.txt build/cgra_info_8x8.txt
	CGRAGenerator/bin/cgra_info_analyzer.csh build/cgra_info_8x8.txt

# build/%_pnr_bitstream: build/%_mapped.json build/cgra_info_4x4.txt
build/%_pnr_bitstream: build/%_mapped.json build/cgra_info_$(CGRA_SIZE).txt
        #
        # pnr
        # IN:  mapped.json      # Output from mapper
        #      cgra_info.txt    # Fully-populated connection matrix from CGRA generator
        #
        # OUT: pnr_bitstream    # bitstream file
        #      annotated        # annotated bitstream file
        #- cd ${TRAVIS_BUILD_DIR}/smt-pnr/src/

	@echo; echo Making $@ because of $?
# 	ls -l CGRAGenerator/hardware/generator_z/top/cgra_info.txt $(filter %.txt, $?)
# 	diff CGRAGenerator/hardware/generator_z/top/cgra_info.txt $(filter %.txt, $?)


# 	smt-pnr/src/test.py  build/$*_mapped.json CGRAGenerator/hardware/generator_z/top/cgra_info.txt --bitstream build/$*_pnr_bitstream --annotate build/$*_annotated --print  --coreir-libs stdlib cgralib

        # $(filter %.json, $?) => program graph e.g. "build/pointwise_mapped.json"
        # $(filter %.txt,  $?) => config file   e.g. "build/cgra_info_4x4.txt"
        # (Could also maybe use $(word 1, $?) and $(word 2, $?)
        # Note json file must come before config file on command line!!!
	smt-pnr/run_pnr.py                        \
		$(filter %.json,$?)                   \
		$(filter %.txt, $?)                   \
		--bitstream build/$*_pnr_bitstream    \
		--annotate build/$*_annotated         \
		--print --coreir-libs cgralib

        # Note: having the annotated bitstream embedded as cleartext in the log 
        # file (below) is incredibly useful...let's please keep it if we can.
	cat build/$*_annotated

        # hackdiff compares PNR bitstream intent (encoded as annotations to the bitstream)
        # versus a separately-decoded version of the bitstream, to make sure they match
	@echo; echo Checking $*_annotated against decoded $*_pnr_bitstream...
	@echo bitstream/decoder/hackdiff.csh $*_pnr_bitstream $*_annotated
	@CGRAGenerator/bitstream/decoder/hackdiff.csh $(QVSWITCH) \
		build/$*_pnr_bitstream \
		build/$*_annotated \
		-cgra $(filter %.txt, $?)

ifeq ($(GOLD), ignore)
	echo "Skipping gold test because GOLD=ignore..."
else
        # Compare to golden model.
        # Note: Pointwise is run in both 4x4 and 8x8 modes, each of which
        # will generate different intermediates but with the same names.
        # What to do? Gotta hack it :(
        # 
	if `test "$(CGRA_SIZE)" = "4x4"` ; then \
	  cp build/$*_annotated build/$*_annotated_4x4;\
	  test/compare.csh build/$*_annotated_4x4 graphcompare \
	    $(filter %.txt, $?) 2>&1 | head -n 40 | tee -a test/compare_summary.txt;\
	else\
	  test/compare.csh build/$*_annotated graphcompare \
	    $(filter %.txt, $?) 2>&1 | head -n 40 | tee -a test/compare_summary.txt;\
	fi
endif

BUILD := ../../../build
VERILATOR_TOP := CGRAGenerator/verilator/generator_z_tb
build/%_CGRA_out.raw: build/%_pnr_bitstream
        # cgra program and run (caleb bitstream)
        # IN:  pnr_bitstream (Bitstream for programming CGRA)
        #      input.png     (Input image)
        # OUT: CGRA_out.raw  (Output image)

	@echo; echo Making $@ because of $?
	echo "CGRA program and run (uses output of pnr)"

	cd $(VERILATOR_TOP);    \
	build=../../../build;   \
	./run.csh top_tb.cpp -hackmem           \
		$(QVSWITCH)              \
		$(MEM_SWITCH)                       \
		-config $${build}/$*_pnr_bitstream  \
		-input  $${build}/$*_input.png      \
		-output $${build}/$*_CGRA_out.raw   \
		-delay $(DELAY)                     \
		-nclocks 5M

build/%.correct.txt: build/%_CGRA_out.raw
        # check to see that output is correct.

	@echo; echo Making $@ because of $?

	ls -l build/$*_*_out.raw

	od -t u1 build/$*_halide_out.raw | head -2
	od -t u1 build/$*_CGRA_out.raw   | head -2

	echo "VISUAL COMPARE OF CGRA VS. HALIDE OUTPUT BYTES (should be null)"
	od -t u1 -w1 -v -A none build/$*_halide_out.raw > build/$*_halide_out.od
	od -t u1 -w1 -v -A none build/$*_CGRA_out.raw   > build/$*_CGRA_out.od
	diff build/$*_halide_out.od build/$*_CGRA_out.od | head -50
	diff build/$*_halide_out.od build/$*_CGRA_out.od > build/$*.diff

	od -t u1 build/$*_halide_out.raw | head -2
	od -t u1 build/$*_CGRA_out.raw   | head -2

	echo "BYTE-BY-BYTE COMPARE OF CGRA VS. HALIDE OUTPUT IMAGES"
	cmp build/$*_halide_out.raw build/$*_CGRA_out.raw \
		&& echo $* test PASSED  >> build/test_summary.txt \
		|| echo $* test FAILED  >> build/test_summary.txt
	cmp build/$*_halide_out.raw build/$*_CGRA_out.raw

        # test -s => file exists and has size > 0
	test ! -s build/$*.diff && touch build/$*.correct.txt
