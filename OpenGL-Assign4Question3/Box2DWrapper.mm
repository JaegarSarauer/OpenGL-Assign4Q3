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
#include "CText2D.h"

@interface Box2DWrapper() {
    b2World* world;
    b2Body *ball;
    b2Body *paddleLeft, *paddleRight;
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
    
    //paddle setup
    b2BodyDef leftBody;
    leftBody.type = b2_staticBody;
    leftBody.position.Set(-21, 0);
    
    b2BodyDef rightBody;
    rightBody.type = b2_staticBody;
    rightBody.position.Set(21, 0);
    
    b2PolygonShape paddleShape;
    
    b2FixtureDef paddleFix;
    paddleFix.shape = &paddleShape;
    paddleFix.density = 1;
    
    paddleLeft = world->CreateBody(&leftBody);
    paddleShape.SetAsBox( 1, 2, b2Vec2(0, 0), 0);//left paddle
    paddleLeft->CreateFixture(&paddleFix);
    
    paddleRight = world->CreateBody(&rightBody);
    paddleShape.SetAsBox( 1, 2, b2Vec2(0, 0), 0);//right paddle
    paddleRight->CreateFixture(&paddleFix);
    
    
    
    //walls setup
    b2BodyDef myBodyDef;
    b2PolygonShape polygonShape;
    
    b2FixtureDef myFixtureDef;
    myFixtureDef.shape = &polygonShape;
    myFixtureDef.density = 1;
    
    myBodyDef.type = b2_staticBody;
    myBodyDef.position.Set(0, 0);
    b2Body* staticBody = world->CreateBody(&myBodyDef);
    polygonShape.SetAsBox( 30, 1, b2Vec2(0, -14), 0);//ground
    staticBody->CreateFixture(&myFixtureDef);
    polygonShape.SetAsBox( 30, 1, b2Vec2(0, 14), 0);//ceiling
    staticBody->CreateFixture(&myFixtureDef);
    
    
    ball->SetLinearVelocity(b2Vec2(10, 20));
}

-(void) drawFrame {
    world->Step(1/60.0f, 8, 3);
    world->DrawDebugData();
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


-(GLKMatrix4) moveAI:(GLKMatrix4)bM {
    b2Vec2 pos = paddleLeft->GetPosition();
    float restY = pos.y;
    float ballY = ball->GetPosition().y;
    if (restY + 1 < ballY)
        restY += 0.25;
    if (restY - 1 > ballY)
        restY -= 0.25;
    if (restY > 14)
        restY = 14;
    if (restY < -14)
        restY = -14;
    b2Vec2 newPos = b2Vec2(pos.x, restY);
    paddleLeft->SetTransform(newPos, 0);
    
    GLKMatrix4 newPaddle = bM;
    newPaddle = GLKMatrix4Translate(GLKMatrix4Identity, newPos.x, newPos.y, 0.0);
    return newPaddle;
}

-(GLKMatrix4) movePlayer:(GLKMatrix4)bM yPos:(float)y {
    b2Vec2 pos = paddleRight->GetPosition();
    float restY = y;
    if (restY > 14)
        restY = 14;
    if (restY < -14)
        restY = -14;
    b2Vec2 newPos = b2Vec2(pos.x, restY);
    paddleRight->SetTransform(newPos, 0);
    
    GLKMatrix4 newPaddle = bM;
    newPaddle = GLKMatrix4Translate(GLKMatrix4Identity, newPos.x, newPos.y, 0.0);
    return newPaddle;
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
        }
    }
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
};

@end
