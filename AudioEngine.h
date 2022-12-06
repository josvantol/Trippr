//
//  AudioEngine.h
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "types.h"
#import "definitions.h"
#import "math.h"

#import "RIFF.h"

@interface AudioEngine : NSObject
{
  @public
  s16 *Buffer;
  BOOL WasWrittenToDevice;
  BOOL FadeIn, FadeOut;
  
  @protected
  r64 Phase1, Phase2;
  r64 Fader;
  
#if RECORD_DEBUG_AUDIO
  NSMutableData *DebugAudioData;
  u64 DebugSampleCount;
#endif
}

-(id) init;
-(void) dealloc;
-(void) WriteAudio:(r64)Tone :(r64)Amount;

@end
