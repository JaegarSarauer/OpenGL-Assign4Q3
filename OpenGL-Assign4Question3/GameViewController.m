//
//  GameViewController.m
//  OpenGL-Assign4Question3
//
//  Created by Jaegar Sarauer on 2017-04-02.
//  Copyright © 2017 Jaegar Sarauer. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>


@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    box2D = [[Box2DWrapper alloc] init];
    
    balls = 3;
    
    [self setupGL];
}

- (void)dealloc
{    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }

    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    [self loadShaders];
    
    self.effect = [[GLKBaseEffect alloc] init];
    self.effect.light0.enabled = GL_TRUE;
    self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
    
    glEnable(GL_DEPTH_TEST);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(0));
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 24, BUFFER_OFFSET(12));
    
    glBindVertexArrayOES(0);
    
    ballMatrix = GLKMatrix4Identity;
    paddleMatrix = GLKMatrix4MakeTranslation(0.0, -18.0, 0.0);
    
    for (int i = 0; i < BRICK_COUNT; i++) {
        brickMatrix[i] = GLKMatrix4Identity;
    }
    
    [box2D awakeFromNib];
    [box2D resetBall:ballMatrix];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    [box2D viewDidUnload];
    
    self.effect = nil;
    
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    _ScoreLabel.text = [NSString stringWithFormat:@"Score: %d", [box2D getScore]];
    [box2D drawFrame];
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;

    GLKMatrix4 cameraMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -40.0);
    
    GLKMatrix4 ballResultMatrix = [box2D updateBall:ballMatrix];
    ballResultMatrix = GLKMatrix4Multiply(ballResultMatrix, cameraMatrix);
    //ballResultMatrix = GLKMatrix4Translate(ballResultMatrix, 0.0, ballY, 0.0);
    _ballNormal = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(ballResultMatrix), NULL);
    _ballProjection = GLKMatrix4Multiply(projectionMatrix, ballResultMatrix);
    
    GLKMatrix4 paddleResultMatrix = GLKMatrix4Identity;
    paddleResultMatrix = GLKMatrix4Multiply(paddleMatrix, cameraMatrix);
    paddleResultMatrix = GLKMatrix4Scale(paddleResultMatrix, 4.0, 1.0, 1.0);
    _paddleNormal = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(paddleResultMatrix), NULL);
    _paddleProjection = GLKMatrix4Multiply(projectionMatrix, paddleResultMatrix);
    
    //calculate brick positions
    for (int i = 0; i < BRICK_COUNT; i++) {
        if ([box2D canDrawBrick:i]) {
            brickMatrix[i] = [box2D getBrick:i];
            brickMatrix[i] = GLKMatrix4Multiply(brickMatrix[i], cameraMatrix);
            brickMatrix[i] = GLKMatrix4Scale(brickMatrix[i], 2.0, 2.0, 1.0);
            _brickNormal[i] = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(brickMatrix[i]), NULL);
            _brickProjection[i] = GLKMatrix4Multiply(projectionMatrix, brickMatrix[i]);
        }
    }
    
    //test ball bounds
    GLKVector3 ballPos = GLKVector3Make(ballResultMatrix.m30, ballResultMatrix.m31, ballResultMatrix.m32);
    if (![self inScreen:projectionMatrix point:ballPos]) {
        [self loseBall];
        if (balls > 0)
            [box2D resetBall:ballMatrix];
    }
}

- (void)loseBall {
    if (balls > 0) {
        balls--;
        _BallsLabel.text = [NSString stringWithFormat:@"Balls: %d", balls];
    } else {
        _BallsLabel.text = [NSString stringWithFormat:@"Game Over!"];
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindVertexArrayOES(_vertexArray);
    
    // Render the object again with ES2
    glUseProgram(_program);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _ballProjection.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _ballNormal.m);
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _paddleProjection.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _paddleNormal.m);
    glDrawArrays(GL_TRIANGLES, 0, 36);
    
    for (int i = 0; i < BRICK_COUNT; i++) {
        if ([box2D canDrawBrick:i]) {
            glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _brickProjection[i].m);
            glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _brickNormal[i].m);
            glDrawArrays(GL_TRIANGLES, 0, 36);
        }
    }
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}
- (IBAction)OnScreenTouch:(UIPanGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:nil];
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    paddleMatrix = [box2D movePlayer:paddleMatrix xPos:((point.x - (width / 2)) / 12)];
}

- (BOOL) inScreen:(GLKMatrix4)M point:(GLKVector3)p {
    GLKVector4 Pclip = GLKMatrix4MultiplyVector4(M, GLKVector4Make(p.x, p.y, p.z, 1.0));
    BOOL res = fabsf(Pclip.x) < Pclip.w && fabsf(Pclip.y) < Pclip.w && 0 < Pclip.z && Pclip.z < Pclip.w;
    return res;
}



@end
