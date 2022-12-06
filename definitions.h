//
//  definitions.h
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#ifndef definitions_h
#define definitions_h

#define RECORD_DEBUG_AUDIO 0
#define SHOW_FRAME_RATE 0

#define SAMPLING_RATE 44100
#define BUFFER_SIZE PowU64(2, 12)
// Must be 2^11 or more @ 44.1 kHz, 60 FPS
// or 2^12 or more @ 44.1 kHz, 30FPS.
// Else there won't be enough time to
// calculate the new audio buffer.
// Larger buffer is saver, but results in lag.

#define MIN_TONE    80.0f
#define MAX_TONE    500.0f
#define MIN_AMOUNT  0.33f
#define MAX_AMOUNT  15.0f

#define NOISE_FILTER PowU64(2, 6)

#define BEATS_VOLUME 0.95f
#define NOISE_VOLUME (1.0f - BEATS_VOLUME)

#endif /* definitions_h */
