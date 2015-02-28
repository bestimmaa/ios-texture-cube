//
//  ViewController.m
//  texture-coordinates
//
//  Created by Christoph Halang on 28/02/15.
//  Copyright (c) 2015 Christoph Halang. All rights reserved.
//

#import "ViewController.h"
#import <OpenGLES/ES2/glext.h>
#import "Geometry.h"

@interface ViewController (){
    EAGLContext* _context;
    GLKBaseEffect* _effect;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;
    GLuint _vertexArray;
    BOOL _initialized;
}

@property GLKMatrix4 modelMatrix; // transformations of the model
@property GLKMatrix4 viewMatrix; // camera position and orientation
@property GLKMatrix4 projectionMatrix; // view frustum (near plane, far plane)
@property GLKTextureInfo* textureInfo;
@property float rotation;
@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!_context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *) self.view;
    view.context = _context;
    view.drawableMultisample = GLKViewDrawableMultisample4X;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    self.viewMatrix = GLKMatrix4MakeLookAt(0.0, 0.0, 26.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    self.projectionMatrix  = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), 4.0/3.0, 1, 51);
    
    [self initEffect];
    [self setupGL];
    
}

- (void)initEffect {
    _effect = [[GLKBaseEffect alloc] init];
    [self configureDefaultLight];
    _initialized = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Setup The Shader

- (void)prepareEffectWithModelMatrix:(GLKMatrix4)modelMatrix viewMatrix:(GLKMatrix4)viewMatrix projectionMatrix:(GLKMatrix4)projectionMatrix{
    _effect.transform.modelviewMatrix = GLKMatrix4Multiply(viewMatrix, modelMatrix);
    _effect.transform.projectionMatrix = projectionMatrix;
    [_effect prepareToDraw];
}

- (void)configureDefaultLight{
    //Lightning
    _effect.light0.enabled = GL_TRUE;
    _effect.light0.ambientColor = GLKVector4Make(1, 1, 1, 1.0);
    _effect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1.0);
    _effect.light0.position = GLKVector4Make(0, 0,-10,1.0);
}

- (void)configureDefaultMaterial {
    
    _effect.texture2d0.enabled = NO;
    
    
    _effect.material.ambientColor = GLKVector4Make(0.3,0.3,0.3,1.0);
    _effect.material.diffuseColor = GLKVector4Make(0.3,0.3,0.3,1.0);
    _effect.material.emissiveColor = GLKVector4Make(0.0,0.0,0.0,1.0);
    _effect.material.specularColor = GLKVector4Make(0.0,0.0,0.0,1.0);
    
    _effect.material.shininess = 0;
}

- (void)configureDefaultTexture{
    _effect.texture2d0.enabled = YES;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"texture_numbers" ofType:@"png"];
    
    NSError *error;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                        forKey:GLKTextureLoaderOriginBottomLeft];
    
    
    self.textureInfo = [GLKTextureLoader textureWithContentsOfFile:path
                                                           options:options error:&error];
    if (self.textureInfo == nil)
        NSLog(@"Error loading texture: %@", [error localizedDescription]);
    
    
    GLKEffectPropertyTexture *tex = [[GLKEffectPropertyTexture alloc] init];
    tex.enabled = YES;
    tex.envMode = GLKTextureEnvModeDecal;
    tex.name = self.textureInfo.name;
    
    _effect.texture2d0.name = tex.name;
    
}

#pragma mark - OpenGL Setup

- (void)setupGL {
    
    [EAGLContext setCurrentContext:_context];
    
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LEQUAL);
    
    // Enable Transparency
    glEnable (GL_BLEND);
    glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    
    // Create Vertex Array Buffer For Vertex Array Objects
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    
    // All of the following configuration for per vertex data is stored into the VAO
    
    // setup vertex buffer - what are my vertices?
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(VerticesCube), VerticesCube, GL_STATIC_DRAW);
    
    // setup index buffer - which vertices form a triangle?
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(IndicesTrianglesCube), IndicesTrianglesCube, GL_STATIC_DRAW);
    
    //Setup Vertex Atrributs
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    //SYNTAX -,number of elements per vertex, datatype, FALSE, size of element, offset in datastructure
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
    
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    
    //Textures
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord));
    
    //Normals
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Normal));
    
    
    
    
    glActiveTexture(GL_TEXTURE0);
    [self configureDefaultTexture];
    
    
    // were done so unbind the VAO
    glBindVertexArrayOES(0);
    
}

- (void)tearDownGL {
    
    [EAGLContext setCurrentContext:_context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    _effect = nil;
    
}

#pragma mark - OpenGL Drawing

- (void)update{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    self.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    self.rotation += self.timeSinceLastUpdate * 0.5f;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(3.0, 3.0, 3.0);
    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(0, 0, 0);
    GLKMatrix4 rotationMatrix = GLKMatrix4MakeRotation(self.rotation, 1.0, 1.0, 1.0);
    
    GLKMatrixStackRef matrixStack = GLKMatrixStackCreate(CFAllocatorGetDefault());
    
    GLKMatrixStackMultiplyMatrix4(matrixStack, translateMatrix);
    GLKMatrixStackMultiplyMatrix4(matrixStack, rotationMatrix);
    GLKMatrixStackMultiplyMatrix4(matrixStack, scaleMatrix);
    
    GLKMatrixStackPush(matrixStack);
    self.modelMatrix = GLKMatrixStackGetMatrix4(matrixStack);
    glBindVertexArrayOES(_vertexArray);
    [self prepareEffectWithModelMatrix:self.modelMatrix viewMatrix:self.viewMatrix projectionMatrix:self.projectionMatrix];
    glDrawElements(GL_TRIANGLES, sizeof(IndicesTrianglesCube) / sizeof(IndicesTrianglesCube[0]), GL_UNSIGNED_BYTE, 0);
    glBindVertexArrayOES(0);
    
    CFRelease(matrixStack);
    
}

@end
