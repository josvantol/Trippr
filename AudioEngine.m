//
//  AudioEngine.m
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#import "AudioEngine.h"

@implementation AudioEngine

-(id) init
{
  self = [super init];
  Buffer = (s16 *)malloc(BUFFER_SIZE * sizeof(s16) * 2);
  if (Buffer == NULL)
  {
    NSLog(@"Error allocating memory for audio...");
    [self dealloc];
    return nil;
  } else {
#if RECORD_DEBUG_AUDIO
    DebugAudioData = [NSMutableData data];
#endif
    // Make sure buffer will be written at start of program.
    WasWrittenToDevice = YES;
    return self;
  }
}

-(void) dealloc
{
#if RECORD_DEBUG_AUDIO
  struct RiffWaveHeader FileHeader;
  u64 AudioByteSize = DebugSampleCount * sizeof(s16) * 2;
  u8 *AudioData = malloc(AudioByteSize);
  
  UpdateHeader(&FileHeader, SAMPLING_RATE, 2, 16, (s32)DebugSampleCount);
  NSMutableData *DebugFile = [NSMutableData dataWithBytes:&FileHeader length:sizeof(struct RiffWaveHeader)];
  [DebugAudioData getBytes:AudioData length:AudioByteSize];
  [DebugFile appendBytes:AudioData length:AudioByteSize];
  
  NSString *Path = @"/Users/jvt/Desktop/debug.wav";
  [DebugFile writeToFile:Path atomically:YES];
  NSLog(@"Debug audio written to: %@", Path);
  
  [DebugAudioData release];
  [DebugFile release];
#endif
  free(Buffer);
  [super dealloc];
}

-(void) WriteAudio:(r64)Tone :(r64)Amount
{
  s16 *Output = Buffer;
  u64 SamplesToWrite = BUFFER_SIZE;
  
  // -----
  // NOISE: Write a buffer with "filtered" interpolated noise.
  // -----
  
  u64 Smooth = NOISE_FILTER;
  r64 Random[SamplesToWrite / Smooth];
  s16 Noise[SamplesToWrite];
  
  // Set random points to interpolate between.
  // First and very last sample are set to zero
  // for clean looping of buffers. */
  
  Random[0] = 0.0f;
  Random[SamplesToWrite/Smooth] = 0.0f;
  for (u64 i = 1; i < SamplesToWrite/Smooth; i++)
  {
    Random[i] = (r64)rand()/(r64)RandMax * 2.0f - 1.0f;
  }
  
  // Write buffer with smooth interpolation between random points
  
  for (u64 i = 0; i < SamplesToWrite/Smooth; i++)
  {
    for (u64 j = 0; j < Smooth; j++)
    {
      Noise[i*Smooth + j] = (NOISE_VOLUME * PowU64(2,16-1)-1) * Smoothstep(Random[i], Random[i+1], Smooth, j);
    }
  }
  
  // -----
  // BINAURAL BEATS: Write binaural beats with clean looping
  // by saving the phase at end of last buffer.
  // -----
  
  /* GUI to values */
  
  r64 SmoothTone = Tone * Tone * Tone;
  r64 Frequency1 = ((MAX_TONE - MIN_TONE) * SmoothTone + MIN_TONE) - ((MAX_AMOUNT - MIN_AMOUNT) * Amount + MIN_AMOUNT) / 2.0f;
  r64 Frequency2 = ((MAX_TONE - MIN_TONE) * SmoothTone + MIN_TONE) + ((MAX_AMOUNT - MIN_AMOUNT) * Amount + MIN_AMOUNT) / 2.0f;
  
  /* Write samples */
  
  for (u64 SampleIndex = 0; SampleIndex < SamplesToWrite; SampleIndex++)
  {
    /* Calculate samples */
    
    s16 Amplitude = BEATS_VOLUME * PowU64(2,16-1)-1;
    // TODO(jvt): Are these sin() functions too expensive?
    // NOTE(jvt): sin() is almost always faster than sinf() on 64-bit machines.
    s16 Sample1 = Amplitude * sin(Tau64 * Frequency1 * (r64)SampleIndex / (r64)SAMPLING_RATE + Phase1 * Tau64);
    s16 Sample2 = Amplitude * sin(Tau64 * Frequency2 * (r64)SampleIndex / (r64)SAMPLING_RATE + Phase2 * Tau64);
    
    /* Mix noise with beats */
    
    Sample1 = 0.9f * ((Sample1) + Noise[SampleIndex]);
    Sample2 = 0.9f * ((Sample2) + Noise[SampleIndex]);
    
    /* Add fades if necessary */
    
    if (FadeIn && Fader < 1.0f)
    {
      Fader += 1.0f / (r64)(SAMPLING_RATE / 1);
    }
    
    if (FadeOut && Fader > 0.0f)
    {
      Fader -= 1.0f / (r64)(SAMPLING_RATE / 4);
    }
    
    /* Write out */
    
    s16 SampleLeft = Fader * Sample1;
    s16 SampleRight = Fader * Sample2;
    
#if RECORD_DEBUG_AUDIO
    [DebugAudioData appendBytes:&SampleLeft length:sizeof(s16)];
    [DebugAudioData appendBytes:&SampleRight length:sizeof(s16)];
    DebugSampleCount++;
#endif
    
    *Output++ = SampleLeft;
    *Output++ = SampleRight;
  }
  
  /* Calculate phase at end of buffer and save it for next call */
  
  r64 Period1 = SAMPLING_RATE / Frequency1;
  r64 Period2 = SAMPLING_RATE / Frequency2;
  Phase1 = ((r64)SamplesToWrite - Period1 * (u64)(SamplesToWrite/Period1)) / Period1 + Phase1;
  Phase2 = ((r64)SamplesToWrite - Period2 * (u64)(SamplesToWrite/Period2)) / Period2 + Phase2;
}

@end
