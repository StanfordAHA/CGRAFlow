#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include "halide_image.h"
#include "halide_image_io.h"

using namespace Halide::Tools;

int main(int argc, char **argv) {
    if (argc != 5) {
      std::cout << "Usage: gen_testimage <width> <height> <pattern> <filename>" << std::endl
                << "   example: gen_testimage 10 10 a input_ones.pgm" << std::endl
                << "   patterns: a - all ones" << std::endl
                << "             b - increasing pixel values" << std::endl;

      return -1;
    }

    uint16_t input_width = atoi(argv[1]);
    uint16_t input_height = atoi(argv[2]);
    const char* type = argv[3];
    bool success = true;

    Image<uint8_t> in(input_width, input_height, 1);


    if (strcmp("a", type) == 0) {
      for (int y = 0; y < in.height(); y++) {
        for (int x = 0; x < in.width(); x++) {
          for (int c = 0; c < in.channels(); c++) {
            in(x,y,c) = 1;
          }
        }    
      } 

    } else if (strcmp("b", type) == 0) {
      int l = 1;
      for (int y = 0; y < in.height(); y++) {
        for (int x = 0; x < in.width(); x++) {
          for (int c = 0; c < in.channels(); c++) {
            in(x,y,c) = l;
            l++;
          }
        }    
      } 
    } else {
      success = false;
    }

    save_image(in, argv[4]);

    printf("finished generating image\n");

    if (success) {
        printf("Successed!\n");
        return 0;
    } else {
        printf("Failed!\n");
        return 1;
    }

}
