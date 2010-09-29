//
//  CCGestureRecognizer.m
//  cocos
//
//  Created by Joe Allen on 7/11/10.
//  Copyright 2010 Glaiveware LLC. All rights reserved.
//

#import "CCGestureRecognizer.h"
#import "CCDirector.h"
#import "ccMacros.h"
#import "CGPointExtension.h"

@implementation CCGestureRecognizer

-(void)dealloc
{
  CCLOGINFO( @"cocos2d: deallocing %@", self); 
  [m_gestureRecognizer release];
  [super dealloc];
}

- (UIGestureRecognizer*)gestureRecognizer
{
  return m_gestureRecognizer;
}

- (CCNode*)node
{
  return m_node;
}

- (void)setNode:(CCNode*)node
{
  m_node = node;
}

- (id<UIGestureRecognizerDelegate>)delegate
{
  return m_delegate;
}

- (void) setDelegate:(id<UIGestureRecognizerDelegate>)delegate
{
  m_delegate = delegate;
}

- (id)target
{
  return m_target;
}

- (void)setTarget:(id)target
{
  m_target = target;
}

- (SEL)callback
{
  return m_callback;
}

- (void)setCallback:(SEL)callback
{
  m_callback = callback;
}

- (id)initWithRecognizerTargetAction:(UIGestureRecognizer*)gestureRecognizer target:(id)target action:(SEL)action
{
  if( (self=[super init]) )
  {
    assert(gestureRecognizer != NULL && "gesture recognizer must not be null");
    m_gestureRecognizer = gestureRecognizer;
    [m_gestureRecognizer retain];
    [m_gestureRecognizer addTarget:self action:@selector(callback:)];
    
    // setup our new delegate
    m_delegate = m_gestureRecognizer.delegate;
    m_gestureRecognizer.delegate = self;
    
    m_target = target; // weak ref
    m_callback = action;
  }
  return self;
}

+ (id)CCRecognizerWithRecognizerTargetAction:(UIGestureRecognizer*)gestureRecognizer target:(id)target action:(SEL)action
{
  return [[[self alloc] initWithRecognizerTargetAction:gestureRecognizer target:target action:action] autorelease];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  assert( m_node != NULL && "gesture recognizer must have a node" );
    
  CGPoint pt = [[CCDirector sharedDirector] convertToGL:[touch locationInView: [touch view]]];
  /* do a rotation opposite of the node to see if the point is in it
     it should make it easier to check against an aligned object */
  
  BOOL rslt = [m_node isPointInArea:pt];
  // TODO: we might want to think about adding this first check back in.
 
  // leaving this out lets a node and its children share a touch if the
  // touch are overlaps. two nodes overlapping on a scene though would
  // not both get the touch.
  
  
  if( rslt )
  {
    /*  ok we know this node was touched, but now we need to make sure
        no other node above this one was touched -- this check only includes
        nodes that receive touches */
    
    // first is to check children
    CCNode* node;
    /*CCARRAY_FOREACH(m_node.children, node)
    {
      if( [node isNodeInTreeTouched:pt] )
      {
        rslt = NO;
        break;
      }
    }*/
    
    // ok, still ok, now check children of parents after this node
    node = m_node;
    CCNode* parent = m_node.parent;
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
  
  if( rslt && m_delegate )
    rslt = [m_delegate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
  
  return rslt;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
  if( !m_delegate )
    return YES;
  return [m_delegate gestureRecognizer:gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:otherGestureRecognizer];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  if( !m_delegate )
    return YES;
  return [m_delegate gestureRecognizerShouldBegin:gestureRecognizer];
}

- (void)callback:(UIGestureRecognizer*)recognizer
{
  if( m_target )
    [m_target performSelector:m_callback withObject:recognizer withObject:m_node];
}

- (void)encodeWithCoder:(NSCoder *)coder 
{
  [coder encodeObject:m_gestureRecognizer forKey:@"gestureRecognizer"];
  [coder encodeObject:m_node forKey:@"node"];
  [coder encodeObject:m_delegate forKey:@"delegate"];
  [coder encodeObject:m_target forKey:@"target"];
  // TODO: m_callback
  [coder encodeBytes:(uint8_t*)&m_callback length:sizeof(m_callback) forKey:@"callback"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
  self=[self init];
  if (self) 
  {
    // don't retain node, it will retain this
    m_node = [decoder decodeObjectForKey:@"node"];          // weak ref
    m_delegate = [decoder decodeObjectForKey:@"delegate"];  // weak ref
    m_target = [decoder decodeObjectForKey:@"target"];      // weak ref
    // TODO: m_callback
    NSUInteger len;
    const uint8_t * buffer = [decoder decodeBytesForKey:@"callback" returnedLength:&len];
    // sanity check to make sure our length is correct
    if( len == sizeof(m_callback) )
      memcpy(&m_callback, buffer, len);
   
    m_gestureRecognizer = [decoder decodeObjectForKey:@"gestureRecognizer"];
    [m_gestureRecognizer addTarget:self action:@selector(callback:)];
    
    m_gestureRecognizer.delegate = self;
    [m_gestureRecognizer retain];
  }
  return self;
}

- (NSString*) description
{
	return [NSString stringWithFormat:@"<%@ = %08X | %@ | Node = %@ >", [self class], self, [m_gestureRecognizer class], m_node];
}

@end
#pragma mark NSCoding of built in recognizers

@implementation UIRotationGestureRecognizer(NSCoder)
- (void)encodeWithCoder:(NSCoder *)coder 
{}

- (id)initWithCoder:(NSCoder *)decoder 
{
  self=[self init];
  if (self) 
  {}
  return self;
}
@end

@implementation UITapGestureRecognizer(NSCoder)
- (void)encodeWithCoder:(NSCoder *)coder 
{
  [coder encodeInt:self.numberOfTapsRequired forKey:@"numberofTapsRequired"];
  [coder encodeInt:self.numberOfTouchesRequired forKey:@"numberOfTouchesRequired"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
  self=[self init];
  if (self) 
  {
    self.numberOfTapsRequired = [decoder decodeIntForKey:@"numberOfTapsRequired"];
    self.numberOfTouchesRequired = [decoder decodeIntForKey:@"numberOfTouchesRequired"];
  }
  return self;
}
@end

@implementation UIPanGestureRecognizer(NSCoder)
- (void)encodeWithCoder:(NSCoder *)coder 
{
  [coder encodeInt:self.minimumNumberOfTouches forKey:@"minimumNumberOfTouches"];
  [coder encodeInt:self.maximumNumberOfTouches forKey:@"maximumNumberOfTouches"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
  self=[self init];
  if (self) 
  {
    self.minimumNumberOfTouches = [decoder decodeIntForKey:@"minimumNumberOfTouches"];
    self.maximumNumberOfTouches = [decoder decodeIntForKey:@"maximumNumberOfTouches"];
  }
  return self;
}
@end

@implementation UILongPressGestureRecognizer(NSCoder)
- (void)encodeWithCoder:(NSCoder *)coder 
{
  [coder encodeInt:self.numberOfTapsRequired forKey:@"numberOfTapsRequired"];
  [coder encodeInt:self.numberOfTouchesRequired forKey:@"numberOfTouchesRequired"];
  [coder encodeDouble:self.minimumPressDuration forKey:@"minimumPressDuration"];
  [coder encodeFloat:self.allowableMovement forKey:@"allowableMovement"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
  self=[self init];
  if (self) 
  {
    self.numberOfTapsRequired = [decoder decodeIntForKey:@"numberOfTapsRequired"];
    self.numberOfTouchesRequired = [decoder decodeIntForKey:@"numberOfTouchesRequired"];
    self.minimumPressDuration = [decoder decodeDoubleForKey:@"minimumPressDuration"];
    self.allowableMovement = [decoder decodeFloatForKey:@"allowableMovement"];
  }
  return self;
}
@end

@implementation UISwipeGestureRecognizer(NSCoder)
- (void)encodeWithCoder:(NSCoder *)coder 
{
  [coder encodeInt:self.numberOfTouchesRequired forKey:@"numberOfTouchesRequired"];
  [coder encodeInt:self.direction forKey:@"direction"];
}

- (id)initWithCoder:(NSCoder *)decoder 
{
  self=[self init];
  if (self) 
  {
    self.numberOfTouchesRequired = [decoder decodeIntForKey:@"numberOfTouchesRequired"];
    self.direction = (UISwipeGestureRecognizerDirection)[decoder decodeIntForKey:@"direction"];
  }
  return self;
}
@end

@implementation UIPinchGestureRecognizer(NSCoder)
- (void)encodeWithCoder:(NSCoder *)coder 
{
}

- (id)initWithCoder:(NSCoder *)decoder 
{
  self=[self init];
  if (self) 
  {
  }
  return self;
}
@end
