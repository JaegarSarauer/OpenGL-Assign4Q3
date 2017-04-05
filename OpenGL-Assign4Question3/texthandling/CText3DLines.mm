//
//  CText2D.m
//  GLESTextDemos
//
//  Created by Borna Noureddin on 2015-03-18.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#import "CText3DLines.h"

#include <ft2build.h>
#include FT_FREETYPE_H

@interface CText3DLines()
{
    UIImageView *textiv;
    FT_Face       face;
}

@end

@implementation CText3DLines

@synthesize pointSize;
@synthesize dotsPerInch;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self TextInit];
    }
    return self;
}

-(unsigned char *)BitmapFromText:(NSString*)str size:(BMSize *)sz pixelCount:(int *)pCnt
{
    return [self BitmapFromText:str size:sz pixelCount:pCnt withColor:GLKVector3Make(1, 1, 1)];
}

-(unsigned char *)BitmapFromText:(NSString*)str size:(BMSize *)sz pixelCount:(int *)pCnt withColor:(GLKVector3)col
{
    char *cstr = (char *)[str UTF8String];
    int nChars = strlen(cstr);
    
    FT_Error error = FT_Set_Char_Size(face, pointSize * 64, pointSize * 64, dotsPerInch, dotsPerInch);
    if (error)
    {
        NSLog(@"Could not set font size!\n");
        return NULL;
    }
    int r, c, x, y, offset;
    x = y = 0;
    int gTop, gLeft, yoff, maxTop = -1;
    unsigned char glyphPix;
    for (int n=0; n<nChars; n++)
    {
        FT_Set_Transform(face, NULL, NULL);
        error = FT_Load_Char(face, cstr[n], FT_LOAD_RENDER);
        if (error) continue;
        gTop = face->glyph->bitmap_top;
        if (maxTop < gTop)
            maxTop = gTop;
        x += face->glyph->advance.x >> 6;
        y += face->glyph->advance.y >> 6;
    }
    
    // Create new pixel data
    int w = pow(2, floor(log2(x + face->glyph->bitmap.width)) + 1);
    int h = pow(2, floor(log2(y + maxTop + face->glyph->bitmap.rows)) + 1);
    unsigned char *rawData = (unsigned char *)malloc(h * w * 4);
    memset(rawData, 0, h*w*4);
    
    x = y = 0;
    int pc = 0;
    for (int n=0; n<nChars; n++)
    {
        FT_Set_Transform(face, NULL, NULL);
        error = FT_Load_Char(face, cstr[n], FT_LOAD_RENDER);
        if (error) continue;
        gTop = face->glyph->bitmap_top;
        gLeft = face->glyph->bitmap_left;
        yoff = maxTop - gTop;
        for (r=0; r<face->glyph->bitmap.rows; r++)
            for (c=0; c<face->glyph->bitmap.width; c++)
            {
                glyphPix = face->glyph->bitmap.buffer[r * face->glyph->bitmap.width + c];
                if (glyphPix)
                {
                    offset = ((y + yoff + r) * w + (gLeft + x + c) ) * 4;
                    rawData[offset] = glyphPix * col.r;
                    rawData[offset+1] = glyphPix * col.g;
                    rawData[offset+2] = glyphPix * col.b;
                    rawData[offset+3] = glyphPix;
                    pc++;
                }
            }
        x += face->glyph->advance.x >> 6;
        y += face->glyph->advance.y >> 6;
    }
    
    sz->height = h;
    sz->width = w;
    *pCnt = pc;
    return rawData;
}


- (void)TextInit
{
    FT_Library ftLib;
    FT_Error error = FT_Init_FreeType(&ftLib);
    if (error)
    {
        NSLog(@"Could not initialize freetype library!\n");
        return;
    }

    NSString *fontFile = [[NSBundle mainBundle] pathForResource:@"times" ofType:@"ttf"];
    char *filename = (char *)[fontFile UTF8String];
    error = FT_New_Face(ftLib, filename, 0, &face);
    if (error)
    {
        NSLog(@"Could not find font file <%s>!\n", filename);
        return;
    }

    textiv = NULL;
}

-(int)Generate3DText:(char *)text toVertices:(GLfloat **)vertices
           toColors:(GLfloat **)colors
           toIndices:(GLuint **)indices withNumVertices:(int *)numVerts
{
    BMSize sz;
    int pc;
    unsigned char *txtBitmap = [self BitmapFromText:[NSString stringWithUTF8String:text] size:&sz pixelCount:&pc withColor:GLKVector3Make(1, 1, 0)];
    
    int numVertices = 2 * pc;
    
    GLfloat *vertPos = (GLfloat *)malloc(numVertices * sizeof(GLfloat) * 3);
    GLfloat *vertCols = (GLfloat *)malloc(numVertices * sizeof(GLfloat) * 3);
    int r, c, idx = 0;
    int offset;
    for (r=0; r<sz.height; r++)
        for (c=0; c<sz.width; c++)
        {
            offset = (r*sz.width+c)*4;
            if (txtBitmap[offset] || txtBitmap[offset+1] ||
                txtBitmap[offset+2] || txtBitmap[offset+3])
            {
                vertPos[idx] = c / (GLfloat)sz.width;
                vertPos[idx+1] = 1.0f - r / (GLfloat)sz.height;
                vertPos[idx+2] = .05f;
                vertPos[idx+3] = c / (GLfloat)sz.width;
                vertPos[idx+4] = 1.0f - r / (GLfloat)sz.height;
                vertPos[idx+5] = -.05f;
                vertCols[idx] = txtBitmap[offset];
                vertCols[idx+1] = txtBitmap[offset+1];
                vertCols[idx+2] = txtBitmap[offset+2];
                vertCols[idx+3] = txtBitmap[offset];
                vertCols[idx+4] = txtBitmap[offset+1];
                vertCols[idx+5] = txtBitmap[offset+2];
                idx += 6;
            }
        }
    if (idx != numVertices*3)
    {
        NSLog(@"Expected %d vertices, but tried to fill %d!\n", numVertices, idx/3);
    }
    
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = vertPos;
    } else
        free(vertPos);
    if ( colors != NULL )
    {
        *colors = vertCols;
    } else
        free(colors);
    if ( indices != NULL )
    {
        *indices = (GLuint *)malloc(numVertices*sizeof(GLuint));
        for (int i=0; i<numVertices; i++)
            (*indices)[i] = i;
    }

    if (numVerts != NULL)
        *numVerts = numVertices;
    
    return numVertices;
}

@end
