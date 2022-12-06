//
//  sdlButton.m
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#import "sdlButton.h"

@implementation sdlButton

-(id) init
{
  NSLog(@"Use -initWithString:onRenderer:");
  return nil;
}

-(id) initWithString:(char *)s
          onRenderer:(SDL_Renderer *)r
{
  self = [super init];
  
  String = s;
  Selected = NO;
  SDL_Surface *Bitmap0 = IMG_Load("button0.png");
  SDL_Surface *Bitmap1 = IMG_Load("button1.png");
  TTF_Font *Font = TTF_OpenFont("Aller_Std_Rg.ttf", Bitmap0->h/3);
  SDL_Color Color = {0, 0, 0, 255};
  SDL_Surface *Text = TTF_RenderText_Blended(Font, String, Color);

  SDL_Rect TextBox;
  TTF_SizeText(Font, String, &TextBox.w, &TextBox.h);
  TextBox.x = Bitmap0->w/2 - TextBox.w/2;
  TextBox.y = Bitmap0->h/2 - TextBox.h/2;
  
  SDL_BlitSurface(Text, NULL, Bitmap0, &TextBox);
  SDL_BlitSurface(Text, NULL, Bitmap1, &TextBox);
  
  TextureOff = SDL_CreateTextureFromSurface(r, Bitmap0);
  TextureOn = SDL_CreateTextureFromSurface(r, Bitmap1);
  
  Box.x = Box.y = 0;
  Box.w = Bitmap0->w;
  Box.h = Bitmap0->h;
  //(u32)((r64)Bitmap0->h / ((r64)Bitmap0->w/(r64)Box.w));
  
  TTF_CloseFont(Font);
  SDL_FreeSurface(Bitmap0);
  SDL_FreeSurface(Bitmap1);
  SDL_FreeSurface(Text);
  
  return self;
}

-(void) setX:(s64)x
{
  Box.x = (s32)x;
}

-(void) setY:(s64)y
{
  Box.y = (s32)y;
}

-(s32) getX
{
  return Box.x;
}

-(s32) getY
{
  return Box.y;
}

-(s32) getWidth
{
  return Box.w;
}

-(s32) getHeight
{
  return Box.h;
}

-(void) setState:(BOOL)s
{
  Selected = s;
}

-(void) show:(SDL_Renderer *)r
{
  if (!Selected)
  {
    SDL_RenderCopy(r, TextureOff, NULL, &Box);
  } else {
    SDL_RenderCopy(r, TextureOn, NULL, &Box);
  }
}

-(BOOL) getState
{
  return Selected;
}

-(void) dealloc
{
  SDL_DestroyTexture(TextureOff);
  SDL_DestroyTexture(TextureOn);
  [super dealloc];
}

@end
