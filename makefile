# .SECONDARY means don't remove any intermediate files
.SECONDARY:


CONVERT = CGRAGenerator/verilator/generator_z_tb/io/myconvert.csh

########################################################################
# For 8x8 CGRA grid, change CGRA_SIZE from "4x4" to "8x8"
# E.g. "make CGRA_SIZE=8x8"

# For now, default is "4x4"
DELAY := 0,0           # How long to wait before first output / last output
$(warning DELAY = $(DELAY))

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

# Image being used
IMAGE := default
CGRA_SIZE := 16x16

ifneq ($(SILENT), TRUE)
  $(warning PNR = $(PNR))
  $(warning OUTPUT = "$(OUTPUT)")
  $(warning CGRA_SIZE = $(CGRA_SIZE))
endif

########################################################################

# No longer used
# all: start_testing \
#      build/pointwise.correct.txt \
#      build/cascade_mapped.json

test_all:
	make start_testing
	  @echo 'Core tests'    >> build/test_summary.txt
	  make core_tests || (echo oops SMT failed | tee -a build/test_summary.txt)
	  @echo ''              >> build/test_summary.txt
	  @echo 'Serpent tests' >> build/test_summary.txt
	  make serpent_tests || (echo oops serpent failed | tee -a build/test_summary.txt)
	  @echo 'cgra_pnr tests' >> build/test_summary.txt
	  make cgra_pnr_tests || (echo oops cgra_pnr failed | tee -a build/test_summary.txt)
	  grep oops build/test_summary.txt && exit 13 || exit 0
	make end_testing

core_only:
        # make start_testing
	echo 'Core tests'    >> build/test_summary.txt
	make core_tests || (echo oops SMT failed | tee -a build/test_summary.txt)
	grep oops build/test_summary.txt && exit 13 || exit 0
        # make end_testing

serpent_only:
        # make start_testing
	echo 'Serpent tests' >> build/test_summary.txt
	make serpent_tests || (echo oops serpent failed | tee -a build/test_summary.txt)
	grep oops build/test_summary.txt && exit 13 || exit 0
        # make end_testing

cgra_pnr_only:
	echo 'cgra_pnr tests' >> build/test_summary.txt
	make cgra_pnr_tests || (echo oops cgra_pnr failed | tee -a build/test_summary.txt)
	grep oops build/test_summary.txt && exit 13 || exit 0

BSB  := CGRAGenerator/bitstream/bsbuilder
J2D  := CGRAGenerator/testdir/graphcompare/json2dot.py
VTOP := CGRAGenerator/verilator/generator_z_tb
# (note cgra_info_16x16.txt builds cgra_info.txt as a side effect)
# FIXME should make side effect explicit :(
test_onebit_bool_serpent:  build/onebit_bool_mapped.json build/cgra_info_16x16.txt
	echo 'Serpent onebit_bool test' >> build/test_summary.txt

        # Bad things will happen if no sram hack
	ls -l \
	  CGRAGenerator/hardware/generator_z/top/genesis_verif/sram_512w_16b.v \
	  CGRAGenerator/verilator/generator_z_tb/sram_stub.v

	diff \
	  CGRAGenerator/hardware/generator_z/top/genesis_verif/sram_512w_16b.v \
	  CGRAGenerator/verilator/generator_z_tb/sram_stub.v

	cmp \
	  CGRAGenerator/hardware/generator_z/top/genesis_verif/sram_512w_16b.v \
	  CGRAGenerator/verilator/generator_z_tb/sram_stub.v \
	  || exit 13

        ################################################################
        # BUILD
        # CGRAGenerator/bitstream/bsbuilder/testdir/make_bitstreams.csh build onebit_bool
        # json => dot
	$(J2D) < build/onebit_bool_mapped.json > build/onebit_bool_mapped.dot
        # dot => bsb
	$(BSB)/serpent.py build/onebit_bool_mapped.dot -o build/onebit_bool.bsb > build/onebit_bool.log.serpent
        # bsb => bsa
	$(BSB)/bsbuilder.py < build/onebit_bool.bsb > build/onebit_bool.bsa

        ################################################################
        # SIM
        # CGRAGenerator/bitstream/bsbuilder/testdir/test_bitstreams.csh build onebit_bool\
        # | tee -a build/compare_summary.txt;
        #
        # ./run.csh $buildswitch $tswitch -config $bsa -input $input -output $out $out1sw -delay $delay
        # FIXME below should instead maybe do 'build=`pwd`/build; cd $(VTOP)...'
        # --verilator_debug
	cd $(VTOP); \
	  build=../../../build; \
	  ./run.csh -gen \
	  -config    $${build}/onebit_bool.bsa \
	  -input     $${build}/onebit_bool_input.raw \
	  -output    $${build}/onebit_bool_CGRA_out16.raw \
	  -out1 s1t0 $${build}/onebit_bool_CGRA_out1.raw \
	  -delay 0,0 || exit 13

        ################################################################
        # TEST
	$(BSB)/testdir/compare_images.csh onebit_bool \
	  build/onebit_bool_halide_out.raw \
	  build/onebit_bool_CGRA_out1.raw \
	  | tee -a build/booltest_summary.txt || exit 13

	@(grep PASSED build/booltest_summary.txt > /dev/null) \
		&& echo ' ' `date +%H:%M:%S` TEST RESULT onebit_bool PASSED >> build/test_summary.txt \
		|| echo ' ' `date +%H:%M:%S` TEST RESULT onebit_bool FAILED >> build/test_summary.txt


core_tests:
	make clean_pnr
#       # For verbose output add "SILENT=FALSE" to command line(s) below
	make build/pointwise.correct.txt DELAY=0,0   GOLD=ignore
	make build/conv_1_2.correct.txt  DELAY=1,0   GOLD=ignore
	make build/conv_2_1.correct.txt  DELAY=10,0  GOLD=ignore
	make build/conv_3_1.correct.txt  DELAY=20,0  GOLD=ignore
	make build/conv_bw.correct.txt   DELAY=130,0 GOLD=ignore

serpent_tests:
	make clean_pnr
#       # For verbose output add "SILENT=FALSE" to command line(s) below
	make build/onebit_bool.correct.txt DELAY=0,0 GOLD=ignore PNR=serpent ONEBIT=TRUE
	make build/pointwise.correct.txt   DELAY=0,0 GOLD=ignore PNR=serpent
	make build/conv_1_2.correct.txt    DELAY=1,0 GOLD=ignore PNR=serpent
	make build/conv_2_1.correct.txt   DELAY=10,0 GOLD=ignore PNR=serpent
	make build/conv_3_1.correct.txt   DELAY=20,0 GOLD=ignore PNR=serpent
	make build/conv_bw.correct.txt   DELAY=130,0 GOLD=ignore PNR=serpent

cgra_pnr_tests:
	make clean_pnr
#       # For verbose output add "SILENT=FALSE" to command line(s) below
	make build/onebit_bool.correct.txt DELAY=0,0 GOLD=ignore PNR=cgra_pnr ONEBIT=TRUE
	make build/pointwise.correct.txt   DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_1_2.correct.txt    DELAY=1,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_2_1.correct.txt   DELAY=10,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_3_1.correct.txt   DELAY=20,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_bw.correct.txt   DELAY=130,0 GOLD=ignore PNR=cgra_pnr

clean_pnr:
#       # Remove pnr intermediates for e.g. retesting w/serpent
	ls build/*correct.txt    && rm build/*correct.txt    || echo "Nothing to clean"
	ls build/*CGRA_out.raw   && rm build/*CGRA_out.raw   || echo "Nothing to clean"
	ls build/*_pnr_bitstream && rm build/*_pnr_bitstream || echo "Nothing to clean"


start_testing:
# Build a test summary for the travis log.
	@if `test -e build/test_summary.txt`; then rm build/test_summary.txt; fi
	@echo "TEST SUMMARY BEGIN `date +%H:%M:%S`" > build/test_summary.txt
	@cat build/test_summary.txt

#	gold compare of intermediates; "ignore" still prints setup info
	@if `test -e build/compare_summary.txt`; then rm build/compare_summary.txt; fi
	@echo "GOLD-COMPARE SUMMARY BEGIN `date +%H:%M:%S`" > build/compare_summary.txt
ifeq ($(GOLD), ignore)
	@echo "Skipping gold test because GOLD=ignore..."
	@echo "To initialize gold tests:" >> build/compare_summary.txt
else
	@cat build/compare_summary.txt
endif

ifeq ($(GOLD), ignore)
	@echo "Skipping gold test because GOLD=ignore..."
else
	if `test -e test/compare_summary.txt`; then rm test/compare_summary.txt; fi
	@echo -n "GOLD-COMPARE SUMMARY " > test/compare_summary.txt
	@echo    "BEGIN `date +%H:%M:%S`"         >> test/compare_summary.txt
endif



end_testing:
ifeq ($(GOLD), ignore)
	@echo "Skipping gold test because GOLD=ignore..."
else
	@echo -n "GOLD-COMPARE SUMMARY " >> test/compare_summary.txt
	@echo    "END `date +%H:%M:%S`"            >> test/compare_summary.txt
	@echo ''
	cat test/compare_summary.txt
endif
	@echo ''
	cat build/test_summary.txt



%_input_image:
        # copy image to halide branch if not using "default"
	if [ $(IMAGE) != default ]; then\
		$(MAKE) -C $(TESTIMAGE_PATH) $(IMAGE);\
		cp tools/gen_testimage/input.png Halide_CoreIR/apps/coreir_examples/$*/input.png;\
	fi

build/%_design_top.json: %_input_image Halide_CoreIR/apps/coreir_examples/%
	@echo "Halide FLOW"

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

	@if [ $(SILENT) != "TRUE" ]; then ls -la build; fi

	@echo "CONVERT PNG IMAGES TO RAW for visual inspection"
        # Could not get "stream" command to work, so using my (steveri) hacky convert script instead...
        #cd ${TRAVIS_BUILD_DIR}

	@$(CONVERT) build/$*_input.png      build/$*_input.raw
	@$(CONVERT) build/$*_halide_out.png build/$*_halide_out.raw

	@echo "VISUALLY CONFIRM APP IN/OUT"
	od -t u1 build/$*_input.raw      | head
	od -t u1 build/$*_halide_out.raw | head

	@cat build/$*_design_top.json $(OUTPUT)

ifeq ($(GOLD), ignore)
	@echo "Skipping gold test because GOLD=ignore..."
	@echo "  " $@ "No gold test b/c GOLD=ignore..." >> test/compare_summary.txt
else
	@echo GOLD-COMPARE $(PNR) "--------------------------------------------------" \
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

	@echo "MAPPER"
	@echo; echo Making $@ because of $?
	./CGRAMapper/bin/cgra-mapper build/$*_design_top.json build/$*_mapped.json $(OUTPUT)
	cat build/$*_mapped.json $(OUTPUT)

        # Yeah, this doesn't always work (straight diff) (SD)
        #test/compare.csh build/$*_mapped.json diff \
        #  $(filter %.txt, $?) 2>&1 | tee -a build/compare_summary.txt
        # UPDATE: Ross says this will work now (above).
        # TODO in next rev: maybe do SD first, then topo compare if/when SD fails?

ifeq ($(GOLD), ignore)
	@echo "Skipping gold test because GOLD=ignore..."
	@echo "  " $@ "No gold test b/c GOLD=ignore..." >> test/compare_summary.txt
else
	test/compare.csh build/$*_mapped.json graphcompare \
	  $(filter %.txt, $?) 2>&1 | head -n 40 | tee -a test/compare_summary.txt
endif

build/cgra_info_16x16.txt:
	@echo; echo Making $@ because of $?
	@echo "CGRA generate (generates 16x16 CGRA + connection matrix for pnr)"
	CGRAGenerator/bin/generate.csh $(QVSWITCH) -$(CGRA_SIZE)|| exit 13
	cp CGRAGenerator/hardware/generator_z/top/cgra_info.txt build/cgra_info_16x16.txt
	cp CGRAGenerator/hardware/generator_z/top/board_info.json build/board_info.json
	CGRAGenerator/bin/cgra_info_analyzer.csh build/cgra_info_16x16.txt



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

ifeq ($(PNR), serpent)

	@echo Using deterministic PNR
	@echo serpent.csh\
		$(filter %.json,$?)                   \
		$(filter %.txt, $?)                   \
		-o build/$*_annotated
	CGRAGenerator/bitstream/bsbuilder/serpent.csh\
		$(filter %.json,$?)                   \
		-cgra_info $(filter %.txt, $?)                   \
		-o build/$*_annotated

	cp build/$*_annotated build/$*_pnr_bitstream

else ifeq ($(PNR), cgra_pnr)
	@echo Using cgra_pnr
	@echo cgra_pnr/scripts/pnr_flow.sh \
		$(filter %.txt , $?)     \ # config file   e.g. "build/cgra_info_4x4.txt"
		$(filter %.json, $?)     \ # program graph e.g. "build/pointwise_mapped.json"
	cgra_pnr/scripts/pnr_flow.sh \
		$(filter %.txt , $?)     \
		$(filter %.json, $?)     \

else
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
		--io-collateral build/$*.io.json      \
		--solver Boolector                    \
		--debug                               \
		--print --coreir-libs cgralib
endif



        # Note: having the annotated bitstream embedded as cleartext in the log
        # file (below) is incredibly useful...let's please keep it if we can.
	cat build/$*_annotated

        # bsa_verify compares PNR bitstream intent (encoded as annotations to
        # the bitstream) versus a separately-decoded version of the bitstream,
        # to make  sure they match
	@echo; echo Checking $*_annotated against separately-decoded $*_annotated...
	@echo "% bsa_verify.csh" $(QVSWITCH) build/$*_annotated -cgra $(filter %.txt, $?)
	@echo NOPE Temporarily NOT doing the bsa_verify check
# 	@CGRAGenerator/testdir/bsa_verify.csh $(QVSWITCH) \
# 		build/$*_annotated \
# 		-cgra $(filter %.txt, $?)

ifeq ($(GOLD), ignore)
	@echo "Skipping gold test because GOLD=ignore..."
	@echo "  " $@ "No gold test b/c GOLD=ignore..." >> test/compare_summary.txt
else
        # Compare to golden model.
        # Note: Pointwise is run in both 4x4 and 8x8 modes, each of which
        # will generate different intermediates but with the same names.
        # What to do? Gotta hack it :(
        #
	@echo "GOLD-COMPARE --------------------------------------------------" \
	  | tee -a build/compare_summary.txt
	if `test "$(CGRA_SIZE)" = "4x4"` ; then \
	  cp build/$*_annotated build/$*_annotated_4x4;\
	  test/compare.csh build/$*_annotated_4x4 graphcompare \
	    $(filter %.txt, $?) 2>&1 | head -n 40 | tee -a build/compare_summary.txt;\
	else\
	  test/compare.csh build/$*_annotated graphcompare \
	    $(filter %.txt, $?) 2>&1 | head -n 40 | tee -a build/compare_summary.txt;\
	fi
endif

BUILD := ../../../build
VERILATOR_TOP := CGRAGenerator/verilator/generator_z_tb
RTL_DIR=CGRAGenerator/hardware/generator_z/top/genesis_verif
build/%_CGRA_out.raw: build/%_pnr_bitstream
        # cgra program and run (caleb bitstream)
        # IN:  pnr_bitstream (Bitstream for programming CGRA)
        #      input.png     (Input image)
        # OUT: CGRA_out.raw  (Output image)

	@echo; echo Making $@ because of $?
	@echo "CGRA program and run (run.csh, uses output of pnr)"
	@echo "run.csh -config $*_pnr_bitstream"

ifeq ($(PNR), serpent)
	@cd $(VERILATOR_TOP);   \
	build=../../../build;   \
	./run.csh top_tb.cpp    \
		$(QVSWITCH)     \
		-gen            \
		-config $${build}/$*_pnr_bitstream \
		-input  $${build}/$*_input.png     \
		-output $${build}/$*_CGRA_out.raw  \
		-out1 s1t0 $${build}/1bit_out.raw  \
		-delay $(DELAY)                    \
		-nclocks 5M

    ifeq ($(ONEBIT), TRUE)
	mv $${build}/1bit_out.raw $${build}/$*_CGRA_out.raw
    endif

else
	cp $(VERILATOR_TOP)/sram_stub.v $(RTL_DIR)/sram_512w_16b.v  # SRAM hack

	python TestBenchGenerator/generate_harness.py \
		--pnr-io-collateral build/$*.io.json      \
		--bitstream build/$*_pnr_bitstream        \
		--max-clock-cycles 5000000                \
		--quiet                                   \
		--output-file-name harness.cpp

	# Verilator wrapper that only builds if the output object is not present
	# (override with --force-rebuild)
	python TestBenchGenerator/verilate.py \
		--harness harness.cpp             \
		--verilog-directory $(RTL_DIR)    \
		--output-directory build          \
		--top-module-name top

	make --silent -C build -j -f Vtop.mk Vtop

	# HACK: Input file name to inpurt port file name, also pre-processing input
	# file for DELAY
	cd build; python ../TestBenchGenerator/process_input.py $*.io.json $*_input.raw $(DELAY)

	cd build; ./Vtop

	# HACK: Output port file name to output file name, also post-processing
	# output file for DELAY
	cd build; python ../TestBenchGenerator/process_output.py $*.io.json $*_CGRA_out.raw $* $(DELAY)
endif

build/%.correct.txt: build/%_CGRA_out.raw
        # check to see that output is correct.

	@echo; echo Making $@ because of $?

#	For debugging
#	ls -l build/$*_*_out.raw
#	od -t u1 build/$*_halide_out.raw | head -2
#	od -t u1 build/$*_CGRA_out.raw   | head -2

	@echo "VISUAL COMPARE OF CGRA VS. HALIDE OUTPUT BYTES (should be null)"
	@od -t u1 -w1 -v -A none build/$*_halide_out.raw > build/$*_halide_out.od
	@od -t u1 -w1 -v -A none build/$*_CGRA_out.raw   > build/$*_CGRA_out.od
	diff build/$*_halide_out.od build/$*_CGRA_out.od | head -50
	@echo
	@echo "BYTE-BY-BYTE COMPARE OF CGRA VS. HALIDE OUTPUT IMAGES (should be null)"
	@echo cmp build/$*_halide_out.raw build/$*_CGRA_out.raw
	@cmp build/$*_halide_out.raw build/$*_CGRA_out.raw \
		&& echo ' ' `date +%H:%M:%S` TEST RESULT $* PASSED >> build/test_summary.txt \
		|| echo ' ' `date +%H:%M:%S` TEST RESULT $* FAILED >> build/test_summary.txt

#	Print the final result already; fail if didn't pass
#	Okay to print FAIL twice, but not PASS.  Get it?
	@echo ">"; echo ">"; echo ">"
	@tail -n 1 build/test_summary.txt
	@tail -n 1 build/test_summary.txt | grep FAILED  || exit 0 && exit 1
	@echo "************************************************************************"
	@echo "************************************************************************"
	@echo "************************************************************************"

        # Build target file if all went well
	@cmp build/$*_halide_out.raw build/$*_CGRA_out.raw && touch build/$*.correct.txt

#	(OLD)
#	# Build target file if all went well i.e.
#	# test -s => file exists and has size > 0
#	@diff build/$*_halide_out.od build/$*_CGRA_out.od > build/$*.diff
#	@test ! -s build/$*.diff && touch build/$*.correct.txt

clean:
	rm build/*
