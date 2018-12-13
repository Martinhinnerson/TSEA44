/*
 * jcdctmgr.c
 *
 * Copyright (C) 1994-1996, Thomas G. Lane.
 * This file is part of the Independent JPEG Group's software.
 * For conditions of distribution and use, see the accompanying README file.
 *
 * This file contains the forward-DCT management logic.
 * This code selects a particular DCT implementation to be used,
 * and it performs related housekeeping chores including coefficient
 * quantization.
 * 
 * Modified for the TSEA44 course
 */

#include <stdio.h>
#include <stdlib.h>

#include "my_encoder.h"
#include "jdct.h"
#include "perfctr.h"

/* Private subobject for this module */
static int row; // The row of the first pixel in the current MCU
static int col; // The column of the first pixel the current MCU
static unsigned int width; // Image width
static unsigned int height; // Image Height
static unsigned char  *theimage; // The raw image

/* Quantization matrix, Matlab notation
Q = [16 11 10 16 24 40 51 61;
     12 12 14 19 26 58 60 55; 
     14 13 16 24 40 57 69 56;
     14 17 22 29 51 87 80 62;
     18 22 37 56 68 109 103 77;
     24 35 55 64 81 104 113 92;
     49 64 78 87 103 121 120 101; 
     72 92 95 98 112 100 103 99];

reciprocals = round(2^15 ./ Q);
*/

static const int reciprocals[] = {2048, 2979, 3277, 2048, 1365, 819, 643, 537,
				  2731, 2731, 2341, 1725, 1260, 565, 546, 596,
				  2341, 2521, 2048, 1365,  819, 575, 475, 585,
				  2341, 1928, 1489, 1130,  643, 377, 410, 529,
				  1820, 1489,  886,  585,  482, 301, 318, 426,
				  1365,  936,  596,  512,  405, 315, 290, 356,
				  669,   512,  420,  377,  318, 271, 273, 324,
				  455,   356,  345,  334,  293, 328, 318, 331};


int workspace[DCTSIZE2];

void init_image(unsigned char *t,unsigned int image_width, unsigned int image_height)
{
   theimage = t;
   row = 0;
   col = 0;
   width = image_width;
   height = image_height;

#ifdef HW_DMA
   #ifdef HW_DCT
   REG32(0x96001800) = theimage;
   REG32(0x96001804) = width;
   REG32(0x96001808) = width/8 - 1;
   REG32(0x9600180c) = height/8 - 1;

   int tmp;
   tmp = REG32(0x96001800);
   printf("srcaddr: %#08x \n", tmp);
   tmp = REG32(0x96001804);
   printf("pitch: %d \n", tmp);
   tmp = REG32(0x96001808);
   printf("endblock_x: %d \n", tmp);
   tmp = REG32(0x9600180c);
   printf("endblock_y: %d \n", tmp);

   REG32(0x96001810) = 0x01;
   #endif
#endif

}


/*
 * forward DCT
 *
 * 1) Copy a block from theimage to workspace and subtract 128
 * 2) DCT
 * 3) Quantization
 *
 */
void forward_DCT (short coef_block[DCTSIZE2])
{
  int *pw = workspace;
  unsigned char *pb = theimage + row*width + col;
  int *pim = (int *) pb;
  int *pr=reciprocals;
  short *pc=coef_block;
  int y,x; // The current position within the MCU
  int temp, i,rval,j;
  unsigned int startcycle = gettimer();
  
#ifdef HW_DMA
  #ifdef HW_DCT
  // -1) Start DMA
  //if (!(REG32(0x96001810) & 1)) // Start DMA if not running
  //REG32(0x96001810) = 0x01;
  
  int addr_offset = 0;
  short block[8][8];
  int tmp;
  int result;
  int ctr = 0;
  //FILE* file = fopen("htdocs/output.txt", "a"); 
  // 0) Measure how long DMA takes
  // 1) Wait for DMA_DCT_Q to complete a block
  result = 0;
  while (!(result & 2)) {
    result = REG32(0x96001810);
    //fprintf(file, "ctr: %d \n", ctr++);
  }
  //fclose(file);
  //printf("result: %#08x \n", REG32(0x96001814));
  //printf("src: %#08x \n", theimage);
  //printf("srcaddr: %#08x \n", REG32(0x96001800));
  //printf("idle_ctr:                        %d \n", REG32(0x96001818));
  perf_copy += ((result & 0x003FF000) >> 12);
  perf_dctkernel += ((result & 0xFFC00000) >> 22);
  // 2) Read out data, transpose, convert from 16 to 32 bit
  addr_offset = 0;
  for (i=0; i < 8; i++) {
    for (j=0; j < 4; j++) {
      result = REG32(0x96000800 + addr_offset);
      addr_offset += 4;
      tmp = result;
      block[2*j][i] = (short) (result >> 16);
      block[2*j+1][i] = (short) (tmp & 0x0000ffff);
    }
  }

  for (i = 0; i < 8; i++) {
    for (j = 0; j < 8; j++) {
      *pc++ = block[i][j];
    }
  }
  // 3) Continue with the next block
  REG32(0x96001810) = 0x02;
  //printf("idle_ctr:                        %d \n", REG32(0x96001818));
  #endif
#else
  #ifdef HW_DCT

  // ===========================================================================
  // ADDED CODE HERE
  // ===========================================================================

  // 1) copy values from image to block RAM instead
  int addr_offset = 0;
  int result = 0;
  int pixels = 0;
  for (y = 0; y < DCTSIZE; y++, pim += (width - DCTSIZE)/4) {
    for (x = 0; x < 2; x++) {
      REG32(0x96000000 + addr_offset) = *pim++;
      addr_offset += 4;
    }
  }
  col += DCTSIZE;
  if (col >= width){
    col = 0;
    row += DCTSIZE;
  }
  perf_copy += gettimer() - startcycle;

  // 2) subtract 128 in SW (SKIP)
  // 3) start DCT_Q

  REG32(0x96001000) = 0x01000000;
  
  // 4) wait for it to finish
  while (!result){
    result = (REG32(0x96001000) & 0x80000000);
  }
  perf_dctkernel += gettimer() - startcycle;
  
  // 5) read out, transpose, convert from 16 to 32 bit 
  addr_offset = 0;
  short block[8][8];
  int tmp;
  for (i=0; i < 8; i++) {
    for (j=0; j < 4; j++) {
      result = REG32(0x96000800 + addr_offset);
      addr_offset += 4;
      tmp = result;
      block[2*j][i] = (short) (result >> 16);
      block[2*j+1][i] = (short) (tmp & 0x0000ffff);
    }
  }

  for (i = 0; i < 8; i++) {
    for (j = 0; j < 8; j++) {
      *pc++ = block[i][j];
    }
  }

  // ===========================================================================
  // 
  // ===========================================================================

  #else
  // 1) Load data into workspace, applying unsigned->signed conversion
  // 2) subtract 128 (JPEG)
  for (y = 0; y < DCTSIZE; y++, pb += (width - DCTSIZE)) {
    for (x = 0; x < DCTSIZE; x++) {
      *pw++ = (int) *pb++ - 128;
    }
  }
  col += DCTSIZE;
  if (col >= width){
    col = 0;
    row += DCTSIZE;
  }
  perf_copy += gettimer() - startcycle;

  // 3) Perform the DCT       
  jpeg_fdct_islow (workspace);

  // 4) Quantize/descale the coefficients, and store into coef_blocks[]
  int rnd,pos,bits;
  for (i=0, pw=workspace; i < DCTSIZE2; i++) {
    rval = *pr++;
    temp = *pw++;
      
    temp = temp*rval;
      
    rnd = (temp & 0x10000) != 0 ; 
    bits = (temp & 0xffff) != 0; 
    pos = (temp & 0x80000000) == 0; 
    temp = temp >> 17; 
    temp += rnd && (pos || bits); 

    *pc++ = (short) temp;
  }
  #endif
#endif
  perf_dct += gettimer() - startcycle;
}


/* This is the main encoding loop */ 

void encode_image(void)
{
   int i;
   int MCU_count = width * height / DCTSIZE2;
   short MCU_block[DCTSIZE2];
   
   for(i = 0; i < MCU_count; i++)
   {
      forward_DCT(MCU_block);
      encode_mcu_huff(MCU_block);
   }
}

/* Initialize the encoder */
void init_encoder(int width,int height,unsigned char *image, FILE *fp)
{
  init_huffman(fp,width,height);
  init_image(image, width, height);
}
