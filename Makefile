# .SECONDARY means don't remove any intermediate files
.SECONDARY:


CONVERT = CGRAGenerator/verilator/generator_z_tb/io/myconvert.csh
BUILD := $(CURDIR)/build

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

test_all:
	make start_testing
	  @echo 'Core tests'    >> build/test_summary.txt
	  make core_tests || (echo oops SMT failed | tee -a build/test_summary.txt)
	  @echo ''              >> build/test_summary.txt
	  @echo 'CGRA PnR' 		>> build/test_summary.txt
	  make cgra_pnr_tests || (echo oops cgra_pnr failed | tee -a build/test_summary.txt)
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
	# make start_testing
	@echo 'CGRA PnR' 		>> build/test_summary.txt
	make cgra_pnr_tests || (echo oops cgra_pnr failed | tee -a build/test_summary.txt)
	grep oops build/test_summary.txt && exit 13 || exit 0
	# make end_testing

BSB  := CGRAGenerator/bitstream/bsbuilder
J2D  := CGRAGenerator/testdir/graphcompare/json2dot.py
VTOP := CGRAGenerator/verilator/generator_z_tb
CMP  := CGRAGenerator/verilator/generator_z_tb/bin/keyi_compare.py
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
	make build/conv_3_3.correct.txt   DELAY=130,0 GOLD=ignore

serpent_tests:
	make clean_pnr
#       # For verbose output add "SILENT=FALSE" to command line(s) below
	make build/pointwise.correct.txt   DELAY=0,0 GOLD=ignore PNR=serpent
	make build/conv_1_2.correct.txt    DELAY=1,0 GOLD=ignore PNR=serpent
	make build/conv_2_1.correct.txt   DELAY=10,0 GOLD=ignore PNR=serpent
	make build/conv_3_1.correct.txt   DELAY=20,0 GOLD=ignore PNR=serpent
	make build/conv_3_3.correct.txt   DELAY=130,0 GOLD=ignore PNR=serpent
#make build/onebit_bool.correct.txt DELAY=0,0 GOLD=ignore PNR=serpent ONEBIT=TRUE

cgra_pnr_tests:
	make clean_pnr
#       # For verbose output add "SILENT=FALSE" to command line(s) below
# this test no longer exists
#make build/onebit_bool.correct.txt DELAY=0,0 GOLD=ignore PNR=cgra_pnr ONEBIT=TRUE
	make build/pointwise.correct.txt  DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_1_2.correct.txt   DELAY=1,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_2_1.correct.txt   DELAY=10,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_3_1.correct.txt   DELAY=20,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_3_3.correct.txt   DELAY=130,0 GOLD=ignore PNR=cgra_pnr
	make build/cascade.correct.txt    DELAY=260,0 GOLD=ignore PNR=cgra_pnr
	make build/harris.correct.txt     DELAY=390,0 GOLD=ignore PNR=cgra_pnr


cgra_pnr_fulltests:
	make clean_pnr
#       # For verbose output add "SILENT=FALSE" to command line(s) below
	make build/pointwise.correct.txt     DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_1_2.correct.txt      DELAY=1,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_2_1.correct.txt      DELAY=10,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_3_1.correct.txt      DELAY=20,0 GOLD=ignore PNR=cgra_pnr
	make build/conv_3_3.correct.txt      DELAY=130,0 GOLD=ignore PNR=cgra_pnr
	make build/cascade.correct.txt       DELAY=260,0 GOLD=ignore PNR=cgra_pnr
	make build/harris.correct.txt        DELAY=390,0 GOLD=ignore PNR=cgra_pnr
	make build/absolute.correct.txt      DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/arith.correct.txt         DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/bitwise.correct.txt       DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/boolean_ops.correct.txt   DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/scomp.correct.txt         DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/ucomp.correct.txt         DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/sminmax.correct.txt       DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/uminmax.correct.txt       DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/sshift.correct.txt        DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/ushift.correct.txt        DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/ternary.correct.txt       DELAY=0,0 GOLD=ignore PNR=cgra_pnr
	make build/equal.correct.txt         DELAY=0,0 GOLD=ignore PNR=cgra_pnr
#       # These are still failing:
#	make build/counter.correct.txt       DELAY=0,0 GOLD=ignore PNR=cgra_pnr
#	make build/inout_onebit.correct.txt  DELAY=0,0 GOLD=ignore PNR=cgra_pnr

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
	grep oops build/test_summary.txt && exit 13 || exit 0
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
		if [ -d Halide-to-Hardware/apps/hardware_benchmarks/apps/$* ]; then \
			cp tools/gen_testimage/input.png Halide-to-Hardware/apps/hardware_benchmarks/apps/$*/input.png;\
		else \
			cp tools/gen_testimage/input.png Halide-to-Hardware/apps/hardware_benchmarks/tests/$*/input.png;\
		fi \
	fi

build/%_design_top.json: %_input_image
	@echo "Halide FLOW"

        # Halide files needed are already in the repo
        # This is where Halide actually compiles our app and runs
        # it to build our comparison output parrot "halide_out.png"
        # as well as the DAG "design_top.json" for the mapper.
        #

        # remake the json and cpu output image for our test app
	@echo; echo Making $@ because of $?
        # E.g. '$*' = "pointwise" when building "build/pointwise/correct.txt"

	make -C Halide-to-Hardware bin/build/halide_config.make
	cp Halide-to-Hardware/bin/build/halide_config.make Halide-to-Hardware/distrib/halide_config.make
	if [ -d Halide-to-Hardware/apps/hardware_benchmarks/apps/$* ]; then \
		make -C Halide-to-Hardware/apps/hardware_benchmarks/apps/$*/ bin/design_top.json bin/output_cpu.png $(SILENT_FILTER_HF);\
		cp Halide-to-Hardware/apps/hardware_benchmarks/apps/$*/bin/design_top.json build/$*_design_top.json;\
		cp Halide-to-Hardware/apps/hardware_benchmarks/apps/$*/input.png           build/$*_input.png;\
		cp Halide-to-Hardware/apps/hardware_benchmarks/apps/$*/bin/output_cpu.png      build/$*_halide_out.png;\
	else \
		make -C Halide-to-Hardware/apps/hardware_benchmarks/tests/$*/ bin/design_top.json bin/output_cpu.png $(SILENT_FILTER_HF);\
		cp Halide-to-Hardware/apps/hardware_benchmarks/tests/$*/bin/design_top.json build/$*_design_top.json;\
		cp Halide-to-Hardware/apps/hardware_benchmarks/tests/$*/input.png           build/$*_input.png;      \
		cp Halide-to-Hardware/apps/hardware_benchmarks/tests/$*/bin/output_cpu.png      build/$*_halide_out.png; \
	fi
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
	@echo pnr_flow.sh\
		$(filter %.txt, $?)                 \
		$(filter %.json,$?)                 \
		build/$*_annotated.bsb
	# NOTE: currently the mapper has some bugs
	# will use custom fix script to fix some of them
	cgra_pnr/coreir_fix/fix_all.sh		    \
		$(filter %.json,$?)                 \
		$(filter %.json,$?)
	cgra_pnr/scripts/pnr_flow.sh            \
		$(filter %.txt, $?)                 \
		$(filter %.json,$?)                 \
		build/$*_annotated.bsb
	@echo "build bitstream using bsbuider"
	@echo $(BSB)/bsbuilder.py               \
		< build/$*_annotated.bsb            \
		> build/$*_pnr_bitstream
	$(BSB)/bsbuilder.py                     \
		< build/$*_annotated.bsb            \
		> build/$*_pnr_bitstream
	cp build/$*_pnr_bitstream build/$*_annotated
	cp build/$*_annotated.bsb.json build/$*_io.json
else
	$(error smt_pnr no longer supported)
endif

        # Note: having the annotated bitstream embedded as cleartext in the log
        # file (below) is incredibly useful...let's please keep it if we can.

ifeq ($(SILENT), FALSE)
	cat build/$*_annotated
endif

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
	./run_tbg.csh $(QVSWITCH) -gen \
		-config    $(BUILD)/$*_pnr_bitstream \
		-input     $(BUILD)/$*_input.png     \
		-output    $(BUILD)/$*_CGRA_out.raw  \
		-out1      $(BUILD)/1bit_out.raw     \
		-delay $(DELAY) \
		-nclocks 5M

    ifeq ($(ONEBIT), TRUE)
	mv $(BUILD)/1bit_out.raw $(BUILD)/$*_CGRA_out.raw
    endif

endif

ifeq ($(PNR), cgra_pnr)
	@cd $(VERILATOR_TOP);   \
	./run_tbg.csh $(QVSWITCH) -gen \
		-config    $(BUILD)/$*_pnr_bitstream \
		-io_config $(BUILD)/$*_io.json       \
		-input     $(BUILD)/$*_input.png     \
		-output    $(BUILD)/$*_CGRA_out.raw  \
		-out1      $(BUILD)/$*_CGRA_out1.raw \
		-delay $(DELAY) \
		-nclocks 5M

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
	@echo "BYTE-BY-BYTE COMPARE OF CGRA VS. HALIDE OUTPUT IMAGES (should be null)"
	@echo python $(CMP) build/$*_halide_out.raw build/$*_CGRA_out.raw
	@python $(CMP) build/$*_CGRA_out.raw build/$*_CGRA_out1.raw build/$*_halide_out.raw \
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
	@python $(CMP) build/$*_CGRA_out.raw build/$*_CGRA_out1.raw build/$*_halide_out.raw \
		&& touch build/$*.correct.txt

#	(OLD)
#	# Build target file if all went well i.e.
#	# test -s => file exists and has size > 0
#	@diff build/$*_halide_out.od build/$*_CGRA_out.od > build/$*.diff
#	@test ! -s build/$*.diff && touch build/$*.correct.txt

clean:
	rm build/*
