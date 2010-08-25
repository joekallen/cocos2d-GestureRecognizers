
#import "CCGestureRecognizer.h"
#import "CCNode.h"
#import "CCDirector.h"
#import "ccMacros.h"
#import "CGPointExtension.h"

@implementation CCGestureRecognizer

-(void)dealloc
{
  [delegate_ release];
  [super dealloc];
}

- (UIGestureRecognizer*)gestureRecognizer
{
  return gestureRecognizer_;
}

- (CCNode*)node
{
  return node_;
}

- (void)setNode:(CCNode*)node
{
  // we can't retain the node, otherwise a node will never get destroyed since it contains a
  // ref to this.  if node gets unrefed it will destroy this so all should be good
  node_ = node;
}

- (id<UIGestureRecognizerDelegate>)delegate
{
  return delegate_;
}

- (void) setDelegate:(id<UIGestureRecognizerDelegate>)delegate
{
  [delegate_ release];
  delegate_ = delegate;
  [delegate_ retain];
}

- (id)target
{
  return target_;
}

- (void)setTarget:(id)target
{
  [target_ release];
  target_ = target;
  [target_ retain];
}

- (SEL)callback
{
  return callback_;
}

- (void)setCallback:(SEL)callback
{
  callback_ = callback;
}

- (id)initWithRecognizerTargetAction:(UIGestureRecognizer*)gestureRecognizer target:(id)target action:(SEL)action
{
  if( (self=[super init]) )
  {
    gestureRecognizer_ = gestureRecognizer;
    [gestureRecognizer_ retain];
    [gestureRecognizer_ addTarget:self action:@selector(callback:)];
    
    // setup our new delegate
    delegate_ = gestureRecognizer_.delegate;
    gestureRecognizer_.delegate = self;
    
    target_ = target;
    [target_ retain];
    callback_ = action;
  }
  return self;
}

+ (id)CCRecognizerWithRecognizerTargetAction:(UIGestureRecognizer*)gestureRecognizer target:(id)target action:(SEL)action
{
  return [[[self alloc] initWithRecognizerTargetAction:gestureRecognizer target:target action:action] autorelease];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  CGPoint pt = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];
  /* do a rotation opposite of the node to see if the point is in it
     it should make it easier to check against an aligned object */
  
  BOOL rslt = [node_ isPointInArea:pt];
  if( rslt )
  {
    /*  ok we know this node was touched, but now we need to make sure
        no other node above this one was touched */
    CCNode* node = node_;
    CCNode* parent = node_.parent;
    while( node != nil && rslt)
    {
      CCNode* child;
      BOOL nodeFound = NO;
      CCARRAY_FOREACH(parent.children, child)
      {
        if( !nodeFound )
        {
          if( !nodeFound && node == child )
            nodeFound = YES;  // we need to keep track of until we hit our node, any past it have a higher z value
          continue;
        }
        
        if( [child isNodeInTreeTouched:pt] )
        {
          rslt = NO;
          break;
        }
      }
      
      node = parent;
      parent = node.parent;
    }    
  }
  
  if( rslt && delegate_ )
    rslt = [delegate_ gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
  
  return rslt;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  if( !delegate_ )
    return YES;
  return [delegate_ gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  if( !delegate_ )
    return YES;
  return [delegate_ gestureRecognizerShouldBegin:gestureRecognizer];
}

- (void)callback:(UIGestureRecognizer*)recognizer
{
  if( target_ )
    [target_ performSelector:callback_ withObject:recognizer withObject:node_];
}
@end
