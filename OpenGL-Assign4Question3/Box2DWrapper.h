//
//  Box2DWrapper.hpp
//  OpenGL-Assign4Question3
//
//  Created by Jaegar Sarauer on 2017-04-02.
//  Copyright © 2017 Jaegar Sarauer. All rights reserved.
//

#ifndef BOX2DWRAPPER_H
#define BOX2DWRAPPER_H
#define BRICK_COUNT 20

#define BRICK_ID 4
#define BRICK_HIT_ID 5

#include <stdio.h>
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>


@interface Box2DWrapper : NSObject

-(id) init;
-(void) awakeFromNib;
-(void) drawFrame;
-(void) viewDidUnload;
-(GLKMatrix4) updateBall:(GLKMatrix4)bM;
-(GLKMatrix4) resetBall:(GLKMatrix4)bM;
-(GLKMatrix4) movePlayer:(GLKMatrix4)bM xPos:(float)x;
-(BOOL) canDrawBrick:(int)i;
-(GLKMatrix4)getBrick:(int)i;
-(int)getScore;

@end

#endif /* Box2DWrapper_hpp */
