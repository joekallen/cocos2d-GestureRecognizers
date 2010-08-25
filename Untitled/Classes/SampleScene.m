//
//  SampleScene.m
//  Untitled
//
//  Created by Joe Allen on 8/24/10.
//  Copyright Glaiveware LLC 2010. All rights reserved.
//

// Import the interfaces
#import "SampleScene.h"

// HelloWorld implementation
@implementation Sample

+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	Sample *layer = [Sample node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"squares.plist"];
		
    CCSprite* square;
    
    // magenta square
    square = [CCSprite spriteWithSpriteFrameName:@"magentasquare"];
    [self addRecognizers:square];
    [square setPosition:ccp(80,360)];
    [self addChild:square];                      
    
    // yellow square
    square = [CCSprite spriteWithSpriteFrameName:@"yellowsquare"];
    [self addRecognizers:square];
    [square setPosition:ccp(160,240)];
    [self addChild:square];
    
    // cyan square
    square = [CCSprite spriteWithSpriteFrameName:@"cyansquare"];
    [self addRecognizers:square];
    [square setPosition:ccp(240,120)];
    [self addChild:square];
	}
	return self;
}

- (void) addRecognizers:(CCNode*)node
{
  CCGestureRecognizer* recognizer;
  // add UIRotationGestureRecognizer
  recognizer = [CCGestureRecognizer CCRecognizerWithRecognizerTargetAction:[[[UIRotationGestureRecognizer alloc]init] autorelease] target:self action:@selector(rotate:node:)];
  [node addGestureRecognizer:recognizer];
  
  // add UITapGestureRecognizer
  recognizer = [CCGestureRecognizer CCRecognizerWithRecognizerTargetAction:[[[UITapGestureRecognizer alloc ]init] autorelease] target:self action:@selector(blink:node:)];
  [node addGestureRecognizer:recognizer];
  
  // add UIPanGestureRecognizer
  recognizer = [CCGestureRecognizer CCRecognizerWithRecognizerTargetAction:[[[UIPanGestureRecognizer alloc ]init] autorelease] target:self action:@selector(drag:node:)];
  [node addGestureRecognizer:recognizer];
  
  // add UIPinchGestureRecognizer
  recognizer = [CCGestureRecognizer CCRecognizerWithRecognizerTargetAction:[[[UIPinchGestureRecognizer alloc ]init] autorelease] target:self action:@selector(scale:node:)];
  [node addGestureRecognizer:recognizer];
  
  node.isTouchEnabled = YES;
}

- (void) rotate:(UIGestureRecognizer*)recognizer node:(CCNode*)node
{
  UIRotationGestureRecognizer* rotate = (UIRotationGestureRecognizer*)recognizer;
  float r = node.rotation;
  node.rotation += CC_RADIANS_TO_DEGREES(rotate.rotation) -r;
}

- (void) blink:(UIGestureRecognizer*)recognizer node:(CCNode*)node
{
  CCAction* action = [CCBlink actionWithDuration:1 blinks:3];
  [node runAction:action];
}

- (void) scale:(UIGestureRecognizer*)recognizer node:(CCNode*)node
{
  UIPinchGestureRecognizer* pinch = (UIPinchGestureRecognizer*)recognizer;
  node.scale *= pinch.scale;
  pinch.scale = 1.0f; // we just reset the scaling so we only wory about the delta
}

- (void) drag:(UIGestureRecognizer*)recognizer node:(CCNode*)node
{
  UIPanGestureRecognizer* pan = (UIPanGestureRecognizer*)recognizer;
  // this will center the node on the touch
  CCDirector* director = [CCDirector sharedDirector];
  CGPoint pt = [director convertToGL:[recognizer locationInView:recognizer.view.superview]];
  pt = [node convertToNodeSpace:pt];  
  if([recognizer state] == UIGestureRecognizerStateBegan ||
     [recognizer state] == UIGestureRecognizerStateChanged )
  {
    CGPoint delta = [pan translationInView:pan.view.superview];
    // y is switched
    delta.y = -delta.y;
    [node setPosition:ccpAdd(node.position, delta)];
    [pan setTranslation:CGPointZero inView:pan.view.superview];
  }
  // no change needed for finished
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
