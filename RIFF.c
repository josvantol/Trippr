//
//  RIFF.c
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#include "RIFF.h"

/* This is based on Victor Lazzarini's tutorial
 from The Audio Programming Book page 746.*/

static char RIFF_ID[4] = {'R', 'I', 'F', 'F' };
static char WAVE_ID[4] = {'W', 'A', 'V', 'E' };
static char FMT_ID[4] = {'f', 'm', 't', ' ' };
static char DATA_ID[4] = {'d', 'a', 't', 'a' };

void UpdateHeader(struct RiffWaveHeader* Header,
                  int SamplingRate,
                  short Channels,
                  short BitDepth,
                  int AudioSize)
{
  Header->RIFF = *(int*)RIFF_ID;
  Header->FileSizeAfterThis = AudioSize + sizeof(struct RiffWaveHeader) - 8;
  Header->WAVE = *(int*)WAVE_ID;
  Header->FMT = *(int*)FMT_ID;
  Header->FMTChunkSize = 16;
  Header->Format = 1;
  Header->Channels = Channels;
  Header->SamplingRate = SamplingRate;
  Header->BytesPerSecond = Channels * (BitDepth / 8) * SamplingRate;
  Header->BytesPerBlock = Channels * (BitDepth / 8);
  Header->BitDepth = BitDepth;
  Header->DATA = *(int*)DATA_ID;
  Header->DATAChunkSize = Channels * (BitDepth / 8) * AudioSize;
  return;
}
