include Makefile.inc

.PHONY: all
all: help input_ones.pgm input_unique.pgm

gen_testimage: gen_testimage.cpp
	$(CXX) $(CXXFLAGS) -O1 -DNDEBUG -g -Wall -Werror $^ $(LDFLAGS) -o $@ $(PNGFLAGS)
help: gen_testimage
	./gen_testimage; test $$? -eq 255

unique unique_10_10 input_unique.pgm: gen_testimage
	./gen_testimage 10 10 b input_unique.pgm
	./gen_testimage 10 10 b input.png
unique_9_9: gen_testimage
	./gen_testimage 9 9 b input.pgm
	./gen_testimage 9 9 b input.png

ones ones_10_10 input_ones.pgm: gen_testimage
	./gen_testimage 10 10 a input_ones.pgm
	./gen_testimage 10 10 a input.png
ones_9_9: gen_testimage
	./gen_testimage 9 9 a input.pgm
	./gen_testimage 9 9 a input.png



clean:
	rm -f gen_testimage
	rm -f input.png input_unique.pgm input_ones.pgm


