//
//  math.h
//  Trippr
//
//  Created by Jos van Tol on November 11, 2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#ifndef math_h
#define math_h

long PowU64(unsigned long long Base, unsigned long long Exp);
double Smoothstep(double A, double B, unsigned long long N, unsigned long long i);
double Smootherstep(double A, double B, unsigned long long N, unsigned long long i);

#endif /* math_h */
