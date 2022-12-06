//
//  sdlController.h
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"
#import "SDL.h"
#import "SDL_ttf.h"
#import "SDL_image.h"
#pragma clang diagnostic pop

#import "types.h"
#import "definitions.h"
#import "math.h"

#import "sdlButton.h"
#import "AudioEngine.h"

@interface sdlController: NSObject
{
  // The SDL handles.
  SDL_Window *Window;
  SDL_Renderer *Renderer;
  SDL_DisplayMode DisplayMode;
  SDL_AudioDeviceID AudioDevice;
  SDL_Event Event;
  
  // For holding the screen/window size
  // the current frame.
  s32 WindowWidth, WindowHeight;
  
  // Memory for calculating and handeling
  // the frame rate.
  r64 TargetSecondsPerFrame;
  u64 ClockFrequency;
  u64 ClockLast;
  // This font will only get loaded when
  // asked for with SHOW_FRAME_RATE
  TTF_Font *FrameRateFont;
  // And the variable to hold it.
  r64 RealSecondsLastFrame;
  
  // Memory for rendering the frame.
  r64 HuePhase;
  r64 LFOPhase;
  
  // The binaural beats audio engine
  // gets loaded by this SDL controller.
  AudioEngine *Audio;
  
  // Memory for holding the backgrounds
  // for the extra screens.
  SDL_Texture *Intro1;
  SDL_Texture *Intro2;
  SDL_Texture *Menu;
  
  // The "info" menu button is hold in
  // memory for rendering every frame.
  SDL_Texture *Info;
  SDL_Rect InfoRect, InfoRenderRect;
  
  // Some variables for handeling the
  // buttons on the menu screen.
  sdlButton *Button[5];
  r64 Preset[5][2];
  SDL_Rect Arrow;
  // These are for handeling the path,
  // timer and effect of the custom preset.
  NSString *PresetPath;
  u64 ButtonTimer;
  BOOL CheckTimer;
  BOOL Flashing;
  u64 FlashClock;
}

-(id) init;
-(void) dealloc;

-(void) HandleInput:(u32 *)AppState
           withTone:(r64 *)Tone
          andAmount:(r64 *)Amount;

-(void) RenderTone:(r64)Tone
        withAmount:(r64)Amount;

-(void) RenderImage:(u64)AppState
           withTone:(r64)Tone
          andAmount:(r64)Amount;

-(void) HandleFrameRateAndForce:(BOOL)Delay;

@end
