//
//  Box2DWrapper.hpp
//  OpenGL-Assign4Question3
//
//  Created by Jaegar Sarauer on 2017-04-02.
//  Copyright © 2017 Jaegar Sarauer. All rights reserved.
//

#ifndef BOX2DWRAPPER_H
#define BOX2DWRAPPER_H

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
-(GLKMatrix4) movePlayer:(GLKMatrix4)bM yPos:(float)y;
-(GLKMatrix4) moveAI:(GLKMatrix4)bM;

@end

#endif /* Box2DWrapper_hpp */
