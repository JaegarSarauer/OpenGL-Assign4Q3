//
//  Box2DWrapper.cpp
//  OpenGL-Assign4Question3
//
//  Created by Jaegar Sarauer on 2017-04-02.
//  Copyright © 2017 Jaegar Sarauer. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "Box2DWrapper.h"
#import <OpenGLES/ES2/glext.h>

@interface Box2DWrapper() {
    b2World* world;
    b2Body *ball;
    b2Body *paddle;
    
    b2Body *bricks[20];
    int score;
}

@end

@implementation Box2DWrapper

- (id)init
{
    //self = [super init];
    //if (self) {
    //}
    return self;
}


-(void) awakeFromNib {
    //world setup
    world = new b2World( b2Vec2(0,0));
    CContactListener *contactListener = new CContactListener();
    world->SetContactListener(contactListener);
    
    //ball setup
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.position.Set(0, 0);
    ball = world->CreateBody(&ballBodyDef);
    ball->SetUserData((__bridge void *)self);
    ball->SetAwake(false);
    b2CircleShape circle;
    circle.m_p.Set(0, 0);
    circle.m_radius = 1;
    b2FixtureDef circleFixtureDef;
    circleFixtureDef.shape = &circle;
    circleFixtureDef.density = 1.0f;
    circleFixtureDef.friction = 0.0f;
    circleFixtureDef.restitution = 1.0f;
    ball->CreateFixture(&circleFixtureDef);
    ball->SetActive(true);
    
    
    //bricks setup
    for (int i = 0; i < BRICK_COUNT; i++) {
        b2BodyDef brickBody;
        brickBody.type = b2_staticBody;
        brickBody.position.Set(-10 + ((i % 12) * 2), 20 - ((int)(i / 12) * 2));
        
        b2PolygonShape brickShape;
        
        b2FixtureDef brickFix;
        brickFix.shape = &brickShape;
        brickFix.density = 1;
        
        bricks[i] = world->CreateBody(&brickBody);
        brickShape.SetAsBox( 1, 1, b2Vec2(0, 0), 0);//paddle
        bricks[i]->CreateFixture(&brickFix);
        bricks[i]->SetActive(true);
        bricks[i]->SetUserData((void *)BRICK_ID);
    }
    
    
    //paddle setup
    b2BodyDef paddleBody;
    paddleBody.type = b2_staticBody;
    paddleBody.position.Set(0, -18);
    
    b2PolygonShape paddleShape;
    
    b2FixtureDef paddleFix;
    paddleFix.shape = &paddleShape;
    paddleFix.density = 1;
    
    paddle = world->CreateBody(&paddleBody);
    paddleShape.SetAsBox( 2, 1, b2Vec2(0, 0), 0);//paddle
    paddle->CreateFixture(&paddleFix);
    
    
    
    //walls setup
    b2BodyDef myBodyDef;
    b2PolygonShape polygonShape;
    
    b2FixtureDef myFixtureDef;
    myFixtureDef.shape = &polygonShape;
    myFixtureDef.density = 1;
    
    myBodyDef.type = b2_staticBody;
    myBodyDef.position.Set(0, 0);
    b2Body* staticBody = world->CreateBody(&myBodyDef);
    polygonShape.SetAsBox( 1, 60, b2Vec2(-15.5, 0), 0);//left
    staticBody->CreateFixture(&myFixtureDef);
    polygonShape.SetAsBox( 1, 60, b2Vec2(15.5, 0), 0);//right
    staticBody->CreateFixture(&myFixtureDef);
    polygonShape.SetAsBox( 40, 1, b2Vec2(0, 27), 0);//ceiling
    staticBody->CreateFixture(&myFixtureDef);
    
    
    ball->SetLinearVelocity(b2Vec2(10, 20));
}

-(GLKMatrix4)getBrick:(int)i {
    if (![self canDrawBrick:i])
        return GLKMatrix4Identity;
    GLKMatrix4 res = GLKMatrix4MakeTranslation(-10 + ((i % 12) * 2), 20 - ((int)(i / 12) * 2), 0.0);
    return res;
}

-(BOOL) canDrawBrick:(int)i {
    return bricks[i]->IsActive();
}

-(void) drawFrame {
    world->Step(1/60.0f, 8, 3);
    for (int i = 0; i < BRICK_COUNT; i++) {
        if ((int)bricks[i]->GetUserData() == BRICK_HIT_ID) {
            bricks[i]->SetActive(false);
            bricks[i]->SetUserData((void *)BRICK_ID);
            score += 10;
        }
    }
}

-(GLKMatrix4) updateBall:(GLKMatrix4)bM {
    GLKMatrix4 newBall = bM;
    const b2Vec2 pos = ball->GetPosition();
    newBall = GLKMatrix4Translate(newBall, pos.x, pos.y, 0.0);
    return newBall;
}

-(GLKMatrix4) resetBall:(GLKMatrix4)bM {
    ball->SetTransform(b2Vec2(0,0), 0);
    return [self updateBall:bM];
}


-(GLKMatrix4) movePlayer:(GLKMatrix4)bM xPos:(float)x {
    b2Vec2 pos = paddle->GetPosition();
    float restX = x;
    if (restX > 12)
        restX = 12;
    if (restX < -12)
        restX = -12;
    b2Vec2 newPos = b2Vec2(restX, pos.y);
    paddle->SetTransform(newPos, 0);
    
    GLKMatrix4 newPaddle = bM;
    newPaddle = GLKMatrix4Translate(GLKMatrix4Identity, newPos.x, newPos.y, 0.0);
    return newPaddle;
}


-(int)getScore {
    return score;
}



-(void) viewDidUnload {
    delete world;
}

class CContactListener : public b2ContactListener {
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState)
        {
            // Use contact->GetFixtureA()->GetBody() to get the body
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            if ((int)bodyA->GetUserData() == BRICK_ID) {
                bodyA->SetUserData((void *)BRICK_HIT_ID);
            }
        }
    }
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
};

@end
