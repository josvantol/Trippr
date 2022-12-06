//
//  sdlController.m
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#import "sdlController.h"

void AudioCallback(void *Engine, u8 *Stream, s32 SizeInBytes)
{
  // Straight up copy buffer to audio device.
  AudioEngine *Audio = (AudioEngine *)Engine;
  memcpy(Stream, Audio->Buffer, SizeInBytes);
  Audio->WasWrittenToDevice = YES;
  return;
}

@implementation sdlController

-(id) init
{
  self = [super init];
  
  // Start audio engine. If failed shut down program.
  Audio = [[AudioEngine alloc] init];
  if (Audio == nil)
  {
    [self dealloc];
    return nil;
  }
  
  // Start SDL and SDL_ttf. If any returns non-zero shut down program.
  if (SDL_Init(SDL_INIT_VIDEO|SDL_INIT_AUDIO)
      + SDL_GetCurrentDisplayMode(0, &DisplayMode)
      + SDL_CreateWindowAndRenderer(DisplayMode.w, DisplayMode.h, 0, &Window, &Renderer)
      + TTF_Init())
  {
    [self dealloc];
    return nil;
  }
  
  // Start SDL_image. If it returns zero shut down program.
  if (IMG_Init(IMG_INIT_PNG) == 0)
  {
    [self dealloc];
    return nil;
  }
  
  // Some OpenGL settings that should help perfromance according to
  // the SDL documentation.
  SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 0);
  SDL_GL_SetAttribute(SDL_GL_RETAINED_BACKING, 0);
  SDL_SetRenderDrawBlendMode(Renderer, SDL_BLENDMODE_BLEND);
  
  // Get preferred frame rate for device. And save hardware clock
  // frequency. Maybe this helps performance? I don't know what
  // SDL_GetPerformanceCounter() does.
  TargetSecondsPerFrame = 1.0f / DisplayMode.refresh_rate;
  ClockFrequency = SDL_GetPerformanceFrequency();
  
  // Load SDL audio device with settings that work with our
  // own binbeats audio engine code.
  SDL_AudioSpec Desired, Obtained;
  Desired.freq = SAMPLING_RATE;
  Desired.format = AUDIO_S16;
  Desired.channels = 2;
  Desired.samples = BUFFER_SIZE;
  Desired.callback = AudioCallback;
  Desired.userdata = Audio;
  
  // Check if audio device was loaded. If not, shut down program. We expect the
  // obtained settings to be the same as the desired.
  AudioDevice = SDL_OpenAudioDevice(NULL, 0, &Desired, &Obtained, SDL_AUDIO_ALLOW_ANY_CHANGE);
  if (AudioDevice == 0)
  {
    [self dealloc];
    return nil;
  } else {
    // Pause audio device until needed.
    SDL_PauseAudioDevice(AudioDevice, 1);
  }
  
  // All systems are loaded now. Start getting our data now.
  // First, update window sizes before creating background
  // textures and other visual calculations.
  SDL_GetWindowSize(Window, &WindowWidth, &WindowHeight);
  
  // Menu button.
  InfoRect.w = InfoRect.h = 44;
  InfoRect.x = WindowWidth - InfoRect.w;
  InfoRect.y = WindowHeight - InfoRect.h;
  
  // Load info/menu button texture.
  SDL_Surface *InfoSurface = IMG_Load("info.png");
  if (InfoSurface)
  {
    // Calculate the dimensions and position of the button and texture.
    // The actual button is larger (44px) than the image (30px).
    InfoRenderRect.w = InfoSurface->w;
    InfoRenderRect.h = InfoSurface->h;
    InfoRenderRect.x = WindowWidth - InfoRenderRect.w - 10;
    InfoRenderRect.y = WindowHeight - InfoRenderRect.h - 10;
    // Create the texture.
    Info = SDL_CreateTextureFromSurface(Renderer, InfoSurface);
    // Then free the surface
    SDL_FreeSurface(InfoSurface);
  }
  
  // Create the path to the custom preset file.
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  PresetPath = [documentsDirectory stringByAppendingPathComponent:@"preset.data"];
  
  // Load file (if any) into a NSData object.
  NSData *FileHandle = [NSData dataWithContentsOfFile:PresetPath];
  if (FileHandle == nil)
  {
    // When there's no file present set Preset[4] to zero.
    Preset[4][0] = 0.0f;
    Preset[4][1] = 0.0f;
  } else {
    // Load the saved custom preset into the preset array at location 4.
    [FileHandle getBytes:Preset[4] length:2*sizeof(r64)];
    [FileHandle release];
  }
  
  // Setup all other preset data before creating the preset button textures.
  
  char *ButtonString[5];
  
  ButtonString[0] = "Happiness";
  Preset[0][0] = 0.13f;
  Preset[0][1] = 0.73f;
  ButtonString[1] = "Moon in June";
  Preset[1][0] = 0.17f;
  Preset[1][1] = 0.28f;
  ButtonString[2] = "Third eye";
  Preset[2][0] = 0.50f;
  Preset[2][1] = 0.66f;
  ButtonString[3] = "White light";
  Preset[3][0] = 0.80f;
  Preset[3][1] = 0.65f;
  ButtonString[4] = "Custom";
  
  // Use our own sdlButton class to create the preset buttons.
  for (u64 i = 0; i < 5; i++)
  {
    // Create texture.
    Button[i] = [[sdlButton alloc] initWithString:ButtonString[i] onRenderer:Renderer];
    // Calculate positions.
    [Button[i] setX:WindowWidth/2 - [Button[i] getWidth]/2];
    u64 ThisY = [Button[i] getHeight] * i * 1.2f;
    ThisY += WindowHeight/2 - 20;
    ThisY -= [Button[i] getHeight] * 2.5f * 1.2f;
    [Button[i] setY:ThisY];
  }
  
  // Create the large background texture for the extra screens.
  // This should happen _after_ we calculate the preset button rects because we need
  // these rects for other elements in the background.
  [self CreateMenuTexture];
  [self CreateIntroTexture1];
  [self CreateIntroTexture2];
  
#if SHOW_FRAME_RATE
  FrameRateFont = TTF_OpenFont("Aller_Std_Rg.ttf", 12);
#endif
  
  // Let's get rollin!
  
  return self;
}

-(void) dealloc
{
#if SHOW_FRAME_RATE
  if (FrameRateFont)
  {
    TTF_CloseFont(FrameRateFont);
  }
#endif
  // First get the audio to stop.
  SDL_PauseAudioDevice(AudioDevice, 1);
  // The close down our own audio engine.
  [Audio dealloc];
  // Now deallocate all textures and stuff
  // in the opposite direction of us allocating them.
  for (u64 i = 0; i < 5; i++)
  {
    [Button[i] dealloc];
  }
  [PresetPath release];
  SDL_DestroyTexture(Info);
  SDL_DestroyTexture(Intro1);
  SDL_DestroyTexture(Intro2);
  SDL_DestroyTexture(Menu);
  SDL_DestroyRenderer(Renderer);
  SDL_DestroyWindow(Window);
  
  // Shut down SDL.
  IMG_Quit();
  TTF_Quit();
  SDL_Quit();
  
  // And dealloc whatever is up there in NSObject.
  [super dealloc];
}

-(void) HandleInput:(u32 *)AppState
           withTone:(r64 *)Tone
          andAmount:(r64 *)Amount
{
  // This is the main user input function.
  // Since we didn't pass the enum, these are what the AppState value stands for:
  //  0 = EXIT
  //  1 = INTRO1
  //  2 = INTRO2
  //  3 = APP
  //  4 = MENU
  
  // Update our window/screen sizes if they would have changed last frame.
  // (Which could happen on iOS but is not very likely with this app)
  SDL_GetWindowSize(Window, &WindowWidth, &WindowHeight);

  // If we are checking time for the saving of the custom preset, do this.
  if (CheckTimer)
  {
    if ((r64)(SDL_GetPerformanceCounter() - ButtonTimer) / (r64)ClockFrequency > 2.0f)
    {
      // More than two seconds? Save preset in slot 4.
      Preset[4][0] = *Tone;
      Preset[4][1] = *Amount;
      
      // Save preset in custom preset file.
      NSData *FileHandle = [NSData dataWithBytes:Preset[4] length:2*sizeof(r64)];
      [FileHandle writeToFile:PresetPath atomically:YES];
      [FileHandle release];
      
      // Stop checking time and render a flashing button.
      Flashing = YES;
      CheckTimer = NO;
    }
  }

  // The standard SDL event checking.
  
  while (SDL_PollEvent(&Event))
  {
    switch (Event.type)
    {
      case SDL_QUIT:
      case SDL_APP_TERMINATING:
      case SDL_APP_LOWMEMORY:
      {
        // Exit program.
        *AppState = 0;
      } break;
        
      case SDL_MOUSEBUTTONDOWN:
      {
        // All buttons on touch screens work better on "mouse up" events. But do
        // start checking time when the custom preset button is pressed in this case.
        
        if (*AppState == 4)
        {
          if (Event.button.x > [Button[4] getX]
              && Event.button.x < [Button[4] getX] + [Button[4] getWidth]
              && Event.button.y > [Button[4] getY]
              && Event.button.y < [Button[4] getY] + [Button[4] getHeight])
          {
            ButtonTimer = SDL_GetPerformanceCounter();
            CheckTimer = YES;
          }
        }
      } break;
        
      case SDL_MOUSEBUTTONUP:
      {
        // Change states.
        // Intro 1 to Intro 2. (And start audio)
        // Intro 2 to App.
        // App to Menu (if on menu/info button)
        
        if (*AppState == 1)
        {
          *AppState = 2;
          [self StartAudio];
        } else if (*AppState == 2)
        {
          *AppState = 3;
        } else if (*AppState == 3)
        {
          if (Event.button.x > InfoRect.x && Event.button.y > InfoRect.y)
          {
            *AppState = 4;
          }
        } else if (*AppState == 4)
        {
          
          // Handle menu input.
          
          for (u64 i = 0; i < 5; i++)
          {
            // First make sure all buttons are turned off.
            [Button[i] setState:NO];
          }
          
          if (Event.button.x < Arrow.w + Arrow.x && Event.button.y < Arrow.h + Arrow.y)
          {
            // When on arrow button, go back to App.
            *AppState = 3;
          }
          
          if (Event.button.x > [Button[0] getX]
              && Event.button.x < [Button[0] getX] + [Button[0] getWidth])
          {
            for (u64 i = 0; i < 5; i++)
            {
              // If one of the buttons was pressed...
              if (Event.button.y > [Button[i] getY]
                  && Event.button.y < [Button[i] getY] + [Button[i] getHeight])
              {
                // ... load the according preset values.
                *Tone = Preset[i][0];
                *Amount = Preset[i][1];
              }
            }
          }
          
          if (CheckTimer)
          {
            // If we were checking time, stop doing that.
            // In this case we pushed down on the custom preset button
            // but released before two seconds were passed.
            CheckTimer = NO;
          }
        }
      } break;
        
      case SDL_MOUSEMOTION:
      {
        if (*AppState == 3 &&
            (Event.motion.x < InfoRect.x || Event.motion.y < InfoRect.y))
        {
          // The main functionality of the application.
          // Find out what slider was moved and set variables to right value.
          u64 ChooseSlider = (u64)(Event.button.x / (r64)WindowWidth * 2.0f);
          r64 CurrentValue = 1.0f - Event.button.y / (r64)WindowHeight;
          switch (ChooseSlider)
          {
            case 0:
            {
              *Tone = CurrentValue;
            } break;
              
            case 1:
            {
              *Amount = CurrentValue;
            } break;
          }
        }
        
        if (*AppState == 4)
        {
          if (Event.motion.x > [Button[0] getX]
              && Event.motion.x < [Button[0] getX] + [Button[0] getWidth])
          {
            for (u64 i = 0; i < 5; i++)
            {
              // The input is moving over the buttons.
              // First turn them all off...
              [Button[i] setState:NO];
              if (Event.motion.y > [Button[i] getY]
                  && Event.motion.y < [Button[i] getY] + [Button[i] getHeight])
              {
                // ... then turn on the one where the input is.
                [Button[i] setState:YES];
              }
              
              // This is all only visual. It has no effect on functionality,
              // this is handled in the mouse-down and -up cases.
            }
          }
          
          if (CheckTimer && (Event.button.x < [Button[4] getX]
              || Event.button.x > [Button[4] getX] + [Button[4] getWidth]
              || Event.button.y < [Button[4] getY]
              || Event.button.y > [Button[4] getY] + [Button[4] getHeight]))
          {
            // If the input finger was moved _off_ the custom preset button,
            // stop keeping time.
            CheckTimer = NO;
          }
        }
      } break;
    }
  }
}

-(void) RenderTone:(r64)Tone
        withAmount:(r64)Amount
{
  if (Audio->WasWrittenToDevice)
  {
    // Quick shortcut to our own audio engine.
    // If the audio was written to SDL's audio device in the last frame
    // fill up the audio buffer with new data.
    [Audio WriteAudio:Tone :Amount];
    Audio->WasWrittenToDevice = NO;
  }
}

-(void) RenderImage:(u64)AppState
           withTone:(r64)Tone
          andAmount:(r64)Amount
{
  // This is the main render function.
  // Since we didn't pass the enum, these are what the AppState value stands for:
  //  0 = EXIT
  //  1 = INTRO1
  //  2 = INTRO2
  //  3 = APP
  //  4 = MENU
  
  // The sliders that show the variable values.
  SDL_Rect ToneSlider = { 0, WindowHeight, WindowWidth/2, -WindowHeight * Tone };
  SDL_Rect AmountSlider = { WindowWidth/2, WindowHeight, WindowWidth/2, -WindowHeight * Amount };
  
  // Don't change colors when we're reading the intro text.
  if (AppState > 2)
  {
    // But if we do, update the phase for the visual pulsation.
    r64 LFOFrequency = (MAX_AMOUNT - MIN_AMOUNT) * Amount + MIN_AMOUNT;
    LFOPhase += 1.0f / (r64)(DisplayMode.refresh_rate / LFOFrequency);
    if (LFOPhase >= 1.0f)
    {
      // If the phase passes 1.0 loop around.
      LFOPhase -= (u64)LFOPhase;
    }
    
    // Update the phase going slowly around the hue scale. for the background color.
    HuePhase += 1.0f / (r64)DisplayMode.refresh_rate / 30.0f;
  }
  
  // Create a triangle wave from the phase we keep tracking for the visual pulses.
  r64 LFO = LFOPhase * 4.0f - 1.0f;
  if (LFO > 1.0f)
  {
    LFO *= -1.0f;
    LFO += 2.0f;
  }
  
  // When we're in the menu. Soften the pulsating effect by 4.
  if (AppState == 4)
  {
    LFO = LFO / 4.0;
  }
  
  // Connect the pulse value and the background color phase to HSB.
  r64 Hue = HuePhase + 0.12f;
  r64 Saturation = 0.2f + LFO * 0.1f;
  r64 Brightness = 0.2f + Tone * 0.6f + LFO * 0.08f;
  
  // Create a RGB color and render the background.
  SDL_Color RGB = [self HueToRGB:Hue :Saturation :Brightness];
  SDL_SetRenderDrawColor(Renderer, RGB.r, RGB.g, RGB.b, 255);
  SDL_RenderClear(Renderer);
  
  // Render the sliders.
  SDL_SetRenderDrawColor(Renderer, 255, 255, 255, 255/5);
  SDL_RenderFillRect(Renderer, &ToneSlider);
  SDL_RenderFillRect(Renderer, &AmountSlider);
  
  // Now show other functinality.
  // Like the intro screens:
  if (AppState == 1)
  {
    SDL_RenderCopy(Renderer, Intro1, NULL, NULL);
  } else if (AppState == 2)
  {
    SDL_RenderCopy(Renderer, Intro2, NULL, NULL);
  } else if (AppState == 3)
  {
    // The info button:
    if (Info)
    {
      SDL_RenderCopy(Renderer, Info, NULL, &InfoRenderRect);
    }
  } else if (AppState == 4)
  {
    // Or the menu screen background:
    SDL_RenderCopy(Renderer, Menu, NULL, NULL);
    
    // Did we save the custom preset? Flash the button a few times.
    if (Flashing)
    {
      FlashClock++;
      if ((FlashClock % 10) == 0)
      {
        // Every 10 frames switch color.
        if ([Button[4] getState])
        {
          [Button[4] setState:NO];
        } else {
          [Button[4] setState:YES];
        }
      }
      
      if (FlashClock == 60)
      {
        // After 60 frames: Stop flashing.
        [Button[4] setState:NO];
        Flashing = NO;
        FlashClock = 0;
      }
    }
    
    // And now show the buttons.
    [Button[0] show:Renderer];
    [Button[1] show:Renderer];
    [Button[2] show:Renderer];
    [Button[3] show:Renderer];
    [Button[4] show:Renderer];
  }
  
#if SHOW_FRAME_RATE
  if (FrameRateFont)
  {
    SDL_Color FrameRateColor = { 0, 0, 0, 255 };
    char TimeString[7];
    if (RealSecondsLastFrame < 1.0f)
    {
      sprintf(TimeString, "%.2f", RealSecondsLastFrame * 1000.0f);
    } else {
      sprintf(TimeString, "x.xx");
    }
    SDL_Surface *FrameRateSurface = TTF_RenderText_Solid(FrameRateFont, TimeString, FrameRateColor);
    SDL_Texture *FrameRateTexture = SDL_CreateTextureFromSurface(Renderer, FrameRateSurface);
    SDL_FreeSurface(FrameRateSurface);
    SDL_Rect FrameRateLocation = {};
    TTF_SizeText(FrameRateFont, TimeString, &FrameRateLocation.w, &FrameRateLocation.h);
    FrameRateLocation.y = WindowHeight - FrameRateLocation.h;
    SDL_RenderCopy(Renderer, FrameRateTexture, NULL, &FrameRateLocation);
    SDL_DestroyTexture(FrameRateTexture);
  }
#endif
  
  // Show our frame!
  
  SDL_RenderPresent(Renderer);
}

-(void) HandleFrameRateAndForce:(BOOL)Delay
{
  if (Delay) // Was there asked to force the delay time?
  {
    // Do we need to wait?
    if((r64)(SDL_GetPerformanceCounter() - ClockLast) / (r64)ClockFrequency < TargetSecondsPerFrame)
    {
      // How many milliseconds can we SDL_Delay()?
      u64 TimeToSleep = (u64)(1000.0f * ((r64)TargetSecondsPerFrame - (r64)(SDL_GetPerformanceCounter() - ClockLast) / (r64)ClockFrequency));
      if (TimeToSleep > 1)
      {
        SDL_Delay((u32)TimeToSleep - 1);
      }
      while ((r64)(SDL_GetPerformanceCounter() - ClockLast) / (r64)ClockFrequency < TargetSecondsPerFrame)
      {
        // Is there more time left that's less than 1 ms?
        ; // Waiting...
      }
    }
  }
  
#if SHOW_FRAME_RATE
  RealSecondsLastFrame = (r64)(SDL_GetPerformanceCounter() - ClockLast) / (r64)ClockFrequency;
#endif
  
  // Get the time saved for next time.
  ClockLast = SDL_GetPerformanceCounter();
}

-(void) StartAudio
{
  SDL_PauseAudioDevice(AudioDevice, 0);
  Audio->FadeIn = YES;
  Audio->FadeOut = NO;
}

-(void) PauseAudio
{
  Audio->FadeIn = NO;
  Audio->FadeOut = YES;
}

-(void) CreateIntroTexture1
{
  SDL_Surface *Surface = SDL_CreateRGBSurfaceWithFormat(0, WindowWidth, WindowHeight, 32, SDL_PIXELFORMAT_RGBA32);
  SDL_FillRect(Surface, NULL, SDL_MapRGBA(Surface->format, 0, 0, 0, 255*2/3));
  
  SDL_Color TextColor = {255, 255, 255, 255};
  TTF_Font *Font = TTF_OpenFont("Aller_Std_Rg.ttf", WindowHeight/30);
  if (Font)
  {
    const u64 Lines = 13;
    const char *Text[Lines];
    Text[0] = "Trippr is a psycho-acoustic";
    Text[1] = "experience created to";
    Text[2] = "stimulate brainwaves";
    Text[3] = "through stereophonic";
    Text[4] = "pulses (also known as";
    Text[5] = "\"binaural beats\"), discovered";
    Text[6] = "in 1839 by German physicist";
    Text[7] = "Heinrich Dove.";
    Text[8] = "";
    Text[9] = "This auditory illusion is";
    Text[10] = "created by presenting two";
    Text[11] = "different tones, one through";
    Text[12] = "each ear.";
    
    SDL_Rect Rect[Lines] = {};
    SDL_Surface *String[Lines];
    
    for (u64 i = 0; i < Lines; i++)
    {
      TTF_SizeText(Font, Text[i], &Rect[i].w, &Rect[i].h);
      Rect[i].x = WindowWidth/2 - Rect[i].w/2;
      Rect[i].y = (s32)(TTF_FontLineSkip(Font) * i) + (WindowHeight / 2) - ((TTF_FontLineSkip(Font)*Lines)/2);
      
      String[i] = TTF_RenderUTF8_Blended(Font, Text[i], TextColor);
      SDL_BlitSurface(String[i], NULL, Surface, &Rect[i]);
      SDL_FreeSurface(String[i]);
    }
    
    TTF_CloseFont(Font);
  }
  
  Intro1 = SDL_CreateTextureFromSurface(Renderer, Surface);
  SDL_FreeSurface(Surface);
}

-(void) CreateIntroTexture2
{
  SDL_Surface *Surface = SDL_CreateRGBSurfaceWithFormat(0, WindowWidth, WindowHeight, 32, SDL_PIXELFORMAT_RGBA32);
  SDL_FillRect(Surface, NULL, SDL_MapRGBA(Surface->format, 0, 0, 0, 255*2/3));
  
  SDL_Color TextColor = {255, 255, 255, 255};
  TTF_Font *Font = TTF_OpenFont("Aller_Std_Rg.ttf", WindowHeight/30);
  TTF_Font *SmallFont = TTF_OpenFont("Aller_Std_Rg.ttf", WindowHeight/40);
  SDL_Surface *Picture = IMG_Load("headphones.png");
  
  if (Font && SmallFont && Picture)
  {
    SDL_Rect PictureRect = {};
    PictureRect.w = Picture->w;
    PictureRect.h = Picture->h;
    // (u32)((r64)Picture->h / ((r64)Picture->w/(r64)PictureRect.w));
    
    const u64 Lines = 10;
    const char *Text[Lines];
    Text[0] = "Hear how the effect";
    Text[1] = "disappears when listening";
    Text[2] = "to only your left or right";
    Text[3] = "headphone.";
    Text[4] = "";
    Text[5] = "Use Trippr for your";
    Text[6] = "meditation or brain";
    Text[7] = "massages. Set the pitch and";
    Text[8] = "amount of pulsation with";
    Text[9] = "the sliders on screen.";
    
    SDL_Rect Rect[Lines] = {};
    SDL_Surface *String[Lines];
    
    for (u64 i = 0; i < Lines; i++)
    {
      TTF_SizeText(Font, Text[i], &Rect[i].w, &Rect[i].h);
      Rect[i].x = WindowWidth/2 - Rect[i].w/2;
      Rect[i].y = (s32)(TTF_FontLineSkip(Font) * i) + (WindowHeight / 2) - ((TTF_FontLineSkip(Font)*Lines)/2);
      Rect[i].y += PictureRect.h/2 + TTF_FontLineSkip(Font);
      String[i] = TTF_RenderUTF8_Blended(Font, Text[i], TextColor);
      SDL_BlitSurface(String[i], NULL, Surface, &Rect[i]);
      SDL_FreeSurface(String[i]);
    }
    
    PictureRect.y = Rect[0].y - PictureRect.h - TTF_FontLineSkip(Font)*2;
    PictureRect.x = (WindowWidth / 2) - (PictureRect.w / 2);
    SDL_BlitSurface(Picture, NULL, Surface, &PictureRect);
    
    const char *NoticeText = "Trippr only works with headphones!";
    SDL_Rect NoticeRect;
    TTF_SizeText(SmallFont, NoticeText, &NoticeRect.w, &NoticeRect.h);
    NoticeRect.x = WindowWidth/2 - NoticeRect.w/2;
    NoticeRect.y = Rect[0].y - 2 * TTF_FontLineSkip(Font);
    SDL_Surface *Notice = TTF_RenderUTF8_Blended(SmallFont, NoticeText, TextColor);
    SDL_BlitSurface(Notice, NULL, Surface, &NoticeRect);
    
    SDL_FreeSurface(Notice);
    SDL_FreeSurface(Picture);
    TTF_CloseFont(Font);
    TTF_CloseFont(SmallFont);
  }
  
  Intro2 = SDL_CreateTextureFromSurface(Renderer, Surface);
  SDL_FreeSurface(Surface);
}

-(void) CreateMenuTexture
{
  SDL_Surface *Surface = SDL_CreateRGBSurfaceWithFormat(0, WindowWidth, WindowHeight, 32, SDL_PIXELFORMAT_RGBA32);
  
  SDL_Color TextColor = {0, 0, 0, 255};
  u32 NumCredits = 3;
  TTF_Font *CreditsFont = TTF_OpenFont("Aller_Std_Rg.ttf", 12);
  if (CreditsFont)
  {
    const char *CreditsString[NumCredits];
    SDL_Surface *Credits[NumCredits];
    SDL_Rect CreditsRect[NumCredits];
    
    CreditsString[0] = "Trippr was created by";
    CreditsString[1] = "Jos van Tol, 2018";
    CreditsString[2] = "www.josvantol.com";
    
    for (int i = 0; i < NumCredits; i++)
    {
      Credits[i] = TTF_RenderText_Blended(CreditsFont, CreditsString[i], TextColor);
      TTF_SizeText(CreditsFont, CreditsString[i], &CreditsRect[i].w, &CreditsRect[i].h);
      CreditsRect[i].x = WindowWidth/2 - CreditsRect[i].w/2;
      CreditsRect[i].y = WindowHeight - (NumCredits-i+1)*TTF_FontLineSkip(CreditsFont);
      SDL_BlitSurface(Credits[i], NULL, Surface, &CreditsRect[i]);
    }
    
    for (int i = 0; i < NumCredits; i++)
    {
      SDL_FreeSurface(Credits[i]);
    }
    
    TTF_CloseFont(CreditsFont);
  }
  
  TTF_Font *SavingFont = TTF_OpenFont("Aller_Std_Rg.ttf", 15);
 
  if (SavingFont)
  {
    const char *SavingString1 = "Hold this button for 2 seconds to save";
    const char *SavingString2 = "the current tone as your custom preset.";
    SDL_Surface *SavingInfo1 = TTF_RenderText_Blended(SavingFont, SavingString1, TextColor);
    SDL_Surface *SavingInfo2 = TTF_RenderText_Blended(SavingFont, SavingString2, TextColor);
    SDL_Rect SavingInfoRect1;
    SDL_Rect SavingInfoRect2;
    TTF_SizeText(SavingFont, SavingString1, &SavingInfoRect1.w, &SavingInfoRect1.h);
    SavingInfoRect1.x = WindowWidth/2 - SavingInfoRect1.w/2;
    SavingInfoRect1.y = [Button[4] getY] + [Button[4] getHeight];
    TTF_SizeText(SavingFont, SavingString2, &SavingInfoRect2.w, &SavingInfoRect2.h);
    SavingInfoRect2.x = WindowWidth/2 - SavingInfoRect2.w/2;
    SavingInfoRect2.y = [Button[4] getY] + [Button[4] getHeight] + TTF_FontLineSkip(SavingFont);
    SDL_BlitSurface(SavingInfo1, NULL, Surface, &SavingInfoRect1);
    SDL_BlitSurface(SavingInfo2, NULL, Surface, &SavingInfoRect2);
    
    SDL_FreeSurface(SavingInfo1);
    SDL_FreeSurface(SavingInfo2);
    TTF_CloseFont(SavingFont);
  }
  
  SDL_Surface *Bitmap = IMG_Load("arrow.png");
  if (Bitmap)
  {
    Arrow.w = Bitmap->w;
    Arrow.h = Bitmap->h;
    Arrow.x = Arrow.y = 20;
    SDL_BlitSurface(Bitmap, NULL, Surface, &Arrow);
    SDL_FreeSurface(Bitmap);
  }
  
  Menu = SDL_CreateTextureFromSurface(Renderer, Surface);
  SDL_FreeSurface(Surface);
}

-(SDL_Color) HueToRGB:(r64)Hue
                     :(r64)Saturation
                     :(r64)Brightness
{
  // A utility to convert a HSB color to RGB.
  SDL_Color Result;
  
  if (Hue >= 1.0f)
  {
    Hue -= (u64)Hue;
  }
  
  Hue *= 6.0f;
  
  u64 Hex = (u64)Hue;
  r64 Deg = Hue - Hex;
  
  r64 Formula0 = Brightness;
  r64 Formula1 = Brightness * (1.0f - Saturation);
  r64 Formula2 = Brightness * (1.0f - (Saturation * Deg));
  r64 Formula3 = Brightness * (1.0f - (Saturation * (1.0f - Deg)));
  
  switch (Hex)
  {
    case 0:
    {
      Result.r = 255 * Formula0;
      Result.g = 255 * Formula3;
      Result.b = 255 * Formula1;
    } break;
      
    case 1:
    {
      Result.r = 255 * Formula2;
      Result.g = 255 * Formula0;
      Result.b = 255 * Formula1;
    } break;
      
    case 2:
    {
      Result.r = 255 * Formula1;
      Result.g = 255 * Formula0;
      Result.b = 255 * Formula3;
    } break;
      
    case 3:
    {
      Result.r = 255 * Formula1;
      Result.g = 255 * Formula2;
      Result.b = 255 * Formula0;
    } break;
      
    case 4:
    {
      Result.r = 255 * Formula3;
      Result.g = 255 * Formula1;
      Result.b = 255 * Formula0;
    } break;
      
    case 5:
    default:
    {
      Result.r = 255 * Formula0;
      Result.g = 255 * Formula1;
      Result.b = 255 * Formula2;
    } break;
  }
  return Result;
}

@end
