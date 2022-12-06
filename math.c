//
//  math.c
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#include "math.h"

long PowU64(unsigned long long Base, unsigned long long Exp)
{
  long Result = 1;
  for (long i = 0; i < Exp; i++)
  {
    Result *= Base;
  }
  return Result;
}

// Smoothstep functions from
// http://sol.gfxile.net/interpolation

double Smoothstep(double A, double B, unsigned long long N, unsigned long long i)
{
  double t = i/(double)N;
  t = t * t * (3 - 2*t);
  return (1.0f -t)*A + t*B;
}

double Smootherstep(double A, double B, unsigned long long N, unsigned long long i)
{
  double t = i/(double)N;
  t = t * t * t * (t * (t * 6 - 15) + 10);
  return (1.0f -t)*A + t*B;
}
