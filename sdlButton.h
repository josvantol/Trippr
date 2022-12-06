//
//  sdlButton.h
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

@interface sdlButton : NSObject
{
  char *String;
  SDL_Texture *TextureOff;
  SDL_Texture *TextureOn;
  SDL_Rect Box;
  BOOL Selected;
}

-(id) init;
-(id) initWithString:(char *)s
          onRenderer:(SDL_Renderer *)r;
-(void) setX:(s64)x;
-(void) setY:(s64)y;
-(s32) getX;
-(s32) getY;
-(s32) getWidth;
-(s32) getHeight;
-(void) setState:(BOOL)s;
-(BOOL) getState;
-(void) show:(SDL_Renderer *)r;
-(void) dealloc;

@end
