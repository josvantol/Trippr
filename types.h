//
//  Standard types header for projects by jvt
//
//  Created by Jos van Tol on 25/10/2018.
//  Copyright © 2018 Jos van Tol. All rights reserved.
//

#ifndef types_h
#define types_h

#import <stdint.h>

typedef int8_t    s8;
typedef int16_t   s16;
typedef int32_t   s32;
typedef int64_t   s64;

typedef uint8_t   u8;
typedef uint16_t  u16;
typedef uint32_t  u32;
typedef uint64_t  u64;

typedef float     r32;
typedef double    r64;
typedef r32       f32;
typedef r64       f64;

#define Pi64      3.141592653589793115997963468544185161590576171875f
#define Tau64     (2.0f * Pi64)

#define U8Max     ((u8)-1)
#define U16Max    ((u16)-1)
#define U32Max    ((u32)-1)
#define U64Max    ((u64)-1)

#define S8Min     ((s8)0x80)
#define S8Max     ((s8)0x7f)
#define S16Min    ((s16)0x8000)
#define S16Max    ((s16)0x7fff)
#define S32Min    ((s32)0x80000000)
#define S32Max    ((s32)0x7fffffff)
#define S64Min    ((s64)0x8000000000000000)
#define S64Max    ((s64)0x7fffffffffffffff)
#define R32Min    FLT_MIN
#define R32Max    FLT_MAX
#define R64Min    DBL_MIN
#define R64Max    DBL_MAX

#define RandMax   S32Max

typedef struct v2
{
  r32 x, y;
} v2;

typedef struct v3
{
  r32 x, y, z;
} v3;

typedef struct buffer
{
  u64 Count;
  u8 *Data;
} buffer;
typedef buffer string;

#define internal static
#define local_persist static
#define global static

#if DEBUG
#define Assert(Expression) //if(!(Expression)) {*(int *)0=0;}
#else
#define Assert(Expression)
#endif

#define Kilobytes(Value) ((Value)*1024LL)
#define Megabytes(Value) (Kilobytes(Value)*1024LL)
#define Gigabytes(Value) (Megabytes(Value)*1024LL)
#define Terabytes(Value) (Gigabytes(Value)*1024LL)

inline u32
SafeTruncateToU32(u64 Value)
{
  Assert(Value <= U32Max);
  u32 Result = (u32)Value;
  return(Result);
}

inline u16
SafeTruncateToU16(u32 Value)
{
  Assert(Value <= U16Max);
  u16 Result = (u16)Value;
  return(Result);
}

inline u32
StringLength(char *String)
{
  u32 Count = 0;
  if(String)
  {
    while(*String++)
    {
      ++Count;
    }
  }
  
  return(Count);
}

#endif /* types_h */
