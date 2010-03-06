//
//  TouchSynthesis.m
//  SelfTesting
//
//  Created by Matt Gallagher on 23/11/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "TouchSynthesis.h"

@implementation UITouch (Synthesize)

//
// initInView
//
// Creats a UITouch, centered on the specified view, in the view's window.
//
- (id)initInView:(UIView *)view
{
	return [self initInView:view hitTest:YES];
}


//
// initInView:hitTest
//
// Creats a UITouch, centered on the specified view, in the view's window.
// Determines the target view by either performing a hit test, or just
// forcing the tap to land on the passed-in view.
//
- (id)initInView:(UIView *)view hitTest:(BOOL)hitTest
{
	self = [super init];
	if (self != nil)
	{
		CGRect frameInWindow;
		if ([view isKindOfClass:[UIWindow class]])
		{
			frameInWindow = view.frame;
		}
		else
		{
			frameInWindow =
				[view.window convertRect:view.frame fromView:view.superview];
		}
		 
		_tapCount = 1;
		_locationInWindow =
			CGPointMake(
				frameInWindow.origin.x + 0.5 * frameInWindow.size.width,
				frameInWindow.origin.y + 0.5 * frameInWindow.size.height);
		_previousLocationInWindow = _locationInWindow;

		UIView *target = hitTest ?
			[view.window hitTest:_locationInWindow withEvent:nil] :
			view;

		_window = [view.window retain];
		_view = [target retain];
		_phase = UITouchPhaseBegan;
		_touchFlags._firstTouchForView = 1;
		_touchFlags._isTap = 1;
		_timestamp = [NSDate timeIntervalSinceReferenceDate];
	}
	return self;
}

//
// setPhase:
//
// Setter to allow access to the _phase member.
//
- (void)setPhase:(UITouchPhase)phase
{
	_phase = phase;
	_timestamp = [NSDate timeIntervalSinceReferenceDate];
}

//
// setLocationInWindow:
//
// Setter to allow access to the _locationInWindow member.
//
- (void)setLocationInWindow:(CGPoint)location
{
	_previousLocationInWindow = _locationInWindow;
	_locationInWindow = location;
	_timestamp = [NSDate timeIntervalSinceReferenceDate];
}

//
// moveLocationInWindow:
//
// Adjusts location to the right
//
- (void)moveLocationInWindow
{
	CGPoint moveTo = CGPointMake(_locationInWindow.x + 200, _locationInWindow.y);
	[self setLocationInWindow:moveTo];
}


//
// moveLocationInWindowLeft:
//
// Adjusts location to the LEFT
//
- (void)moveLocationInWindowLeft
{
	CGPoint moveTo = CGPointMake(_locationInWindow.x - 200, _locationInWindow.y);
	[self setLocationInWindow:moveTo];
}



@end

//
// GSEvent is an undeclared object. We don't need to use it ourselves but some
// Apple APIs (UIScrollView in particular) require the x and y fields to be present.
//
@interface GSEventProxy : NSObject
{
@public
	unsigned int flags;
	unsigned int type;
	unsigned int ignored1;
	float x1;
	float y1;
	float x2;
	float y2;
	unsigned int ignored2[10];
	unsigned int ignored3[7];
	float sizeX;
	float sizeY;
	float x3;
	float y3;
	unsigned int ignored4[3];
}
@end
@implementation GSEventProxy
@end

//
// PublicEvent
//
// A dummy class used to gain access to UIEvent's private member variables.
// If UIEvent changes at all, this will break.
//
@interface PublicEvent : NSObject
{
@public
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 31000
    GSEventProxy           *_event;
#endif
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 30000
    NSTimeInterval          _timestamp;
#endif
    NSMutableSet           *_touches;
    CFMutableDictionaryRef  _keyedTouches;
}
@end

@implementation PublicEvent
@end

@interface UIEvent (Creation)

- (id)_initWithEvent:(GSEventProxy *)fp8 touches:(id)fp12;

@end

//
// UIEvent (Synthesize)
//
// A category to allow creation of a touch event.
//
@implementation UIEvent (Synthesize)

- (id)initWithTouch:(UITouch *)touch
{
	CGPoint location = [touch locationInView:touch.window];
	GSEventProxy *gsEventProxy = [[GSEventProxy alloc] init];
	gsEventProxy->x1 = location.x;
	gsEventProxy->y1 = location.y;
	gsEventProxy->x2 = location.x;
	gsEventProxy->y2 = location.y;
	gsEventProxy->x3 = location.x;
	gsEventProxy->y3 = location.y;
	gsEventProxy->sizeX = 1.0;
	gsEventProxy->sizeY = 1.0;
	gsEventProxy->flags = ([touch phase] == UITouchPhaseEnded) ? 0x1010180 : 0x3010180;
	gsEventProxy->type = 3001;	
	
	//
	// On SDK versions 3.0 and greater, we need to reallocate as a
	// UITouchesEvent.
	//
	Class touchesEventClass = objc_getClass("UITouchesEvent");
	if (touchesEventClass && ![[self class] isEqual:touchesEventClass])
	{
		[self release];
		self = [touchesEventClass alloc];
	}
	
	self = [self _initWithEvent:gsEventProxy touches:[NSSet setWithObject:touch]];

	return self;
}

- (void)moveLocation
{
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 30000
	PublicEvent *publicEvent = (PublicEvent *)self;
	publicEvent->_timestamp = [NSDate timeIntervalSinceReferenceDate];
	publicEvent->_event->x += 20;
#endif
}

@end

