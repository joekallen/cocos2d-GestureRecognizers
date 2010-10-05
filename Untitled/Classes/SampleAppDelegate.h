//
//  SampleAppDelegate.h
//  Untitled
//
//  Created by Joe Allen on 8/24/10.
//  Copyright Glaiveware LLC 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;

@interface SampleAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
  RootViewController  *viewController;
}

@property (nonatomic, retain) UIWindow *window;

@end
