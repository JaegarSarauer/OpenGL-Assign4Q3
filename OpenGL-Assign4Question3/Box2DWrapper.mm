//
//  Box2DWrapper.cpp
//  OpenGL-Assign4Question3
//
//  Created by Jaegar Sarauer on 2017-04-02.
//  Copyright © 2017 Jaegar Sarauer. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "Box2DWrapper.h"

@implementation Box2DWrapper

b2World* m_world;

- (id)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

-(void) awakeFromNib {
    m_world = new b2World( b2Vec2(0,-10));
}

-(void) drawFrame {
    
}

-(void) viewDidUnload {
    delete m_world;
}

@end
