//
//  RIFF.h
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#ifndef RIFF_h
#define RIFF_h

struct RiffWaveHeader
{
  int RIFF;
  int FileSizeAfterThis;
  int WAVE;
  int FMT;
  int FMTChunkSize;
  short Format;
  short Channels;
  int SamplingRate;
  int BytesPerSecond;
  short BytesPerBlock; // (Block = BitDepth * Channels)
  short BitDepth;
  int DATA;
  int DATAChunkSize;
};

void UpdateHeader(struct RiffWaveHeader* Header,
                  int SamplingRate,
                  short Channels,
                  short BitDepth,
                  int AudioSize);

#endif /* RIFF_h */
