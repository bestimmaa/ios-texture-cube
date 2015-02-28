//
//  Geometry.h
//  OpenGL Visible Surface Demo
//
//  Created by Christoph Halang on 28/02/15.
//  Copyright (c) 2015 Christoph Halang. All rights reserved.
//

#import "GLKit/GLKit.h"

#ifndef Geometry_h
#define Geometry_h

typedef struct {
    float Position[3];
    float Color[4];
    float TexCoord[2];
    float Normal[3];
} Vertex;

typedef struct{
    int x;
    int y;
    int z;
} Position;

extern const Vertex VerticesCube[24];

extern const GLubyte IndicesTrianglesCube[36];

#endif
