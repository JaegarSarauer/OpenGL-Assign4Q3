//
//  CText2D.h
//  GLESTextDemos
//
//  Created by Borna Noureddin on 2015-03-18.
//  Copyright (c) 2015 BCIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

typedef struct {
    int width, height;
} BMSize;

@interface CText3DLines : NSObject

@property (nonatomic) int pointSize;
@property (nonatomic) int dotsPerInch;

-(unsigned char *)BitmapFromText:(NSString*)str size:(BMSize *)sz pixelCount:(int *)pCnt;
-(unsigned char *)BitmapFromText:(NSString*)str size:(BMSize *)sz pixelCount:(int *)pCnt withColor:(GLKVector3)col;
-(int)Generate3DText:(char *)text toVertices:(GLfloat **)vertices
                toColors:(GLfloat **)colors
                toIndices:(GLuint **)indices
                withNumVertices:(int *)numVerts;

@end
