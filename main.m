//
//  main.m
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

// TODO Version 1.1:
// Add a custom title to the custom preset. SDL has SDL_StartTextInput() to use a
// keyboard on iOS. Also comment sdlController's -Create...Texture methods.

#import <Foundation/Foundation.h>

#import "types.h"
#import "sdlController.h"

int main(int ArgCount, char *Args[])
{
  // These are the main variables for the sliders. They get passed around everywhere:
  r64 Tone, Amount;
  // And a enum for the state of the program. This gets passed a lot also:
  enum { EXIT, INTRO1, INTRO2, APP, MENU } AppState;
  
  // First create the path to the save state file. Which saves the state
  // of the sliders when the program terminates.
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths objectAtIndex:0];
  NSString *SaveStatePath = [documentsDirectory stringByAppendingPathComponent:@"trippr.data"];
  
  // Load file (if any) into a NSData object.
  NSData *LoadDataFromFile = [NSData dataWithContentsOfFile:SaveStatePath];
  if (LoadDataFromFile == nil)
  {
    // When there's no file found use these hard-coded values:
    Tone = 0.3f;
    Amount = 0.5f;
  } else {
    r64 LoadedData[2];
    [LoadDataFromFile getBytes:LoadedData length:2*sizeof(r64)];
    Tone = LoadedData[0];
    Amount = LoadedData[1];
    [LoadDataFromFile release];
  }
  // Some extra checking for when file got corrupted somehow.
  if (Tone < 0.0f || Tone > 1.0f) Tone = 0.3f;
  if (Amount < 0.0f || Amount > 1.0f) Amount = 0.5f;
  
  // Startup SDL, when failed to initialize straightup drop out of program.
  sdlController *SDL = [[sdlController alloc] init];
  if (SDL == nil)
  {
    exit(EXIT_FAILURE);
    return 1;
  }
  
  // Start the main loop.
  AppState = INTRO1;
  BOOL Running = YES;
  
  while (Running)
  {
    // Update the variables to the users input.
    [SDL HandleInput:&AppState withTone:&Tone andAmount:&Amount];
    // Update the audio buffer (if necessary) to the variables.
    [SDL RenderTone:Tone withAmount:Amount];
    // Update the frame buffer to the variables. And render to screen.
    [SDL RenderImage:AppState withTone:Tone andAmount:Amount];
    // Calculate passed time last frame and wait if necessary for 60fps.
    [SDL HandleFrameRateAndForce:YES];
    
    // Exit program if state was set to 0 in HandleInput.
    if (AppState == EXIT)
    {
      Running = NO;
    }
    
    // End of main loop.
  }
  
  // Create a small array with the slider values.
  r64 SaveData[2];
  SaveData[0] = Tone;
  SaveData[1] = Amount;
  // Write these to a NSData object then to the save-state file path.
  NSData *SaveToFile = [NSData dataWithBytes:SaveData length:2*sizeof(r64)];
  [SaveToFile writeToFile:SaveStatePath atomically:YES];
  [SaveToFile release];
  
  // Shut down SDL then the program.
  [SDL dealloc];
  exit(EXIT_SUCCESS);
  return 0;
}
