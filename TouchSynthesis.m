//
//  TouchSynthesis.m
//  SelfTesting
//
//  Created by Matt Gallagher on 23/11/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//

#ifdef BROMINE_ENABLED

#import "TouchSynthesis.h"

@implementation UITouch (Synthesize)

//
// initInView:phase:
//
// Creats a UITouch, centered on the specified view, in the view's window.
// Sets the phase as specified.
//
- (id)initInView:(UIView *)view
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

		UIView *target = [view.window hitTest:_locationInWindow withEvent:nil];

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
// setPhase:
//
// Setter to allow access to the _locationInWindow member.
//
- (void)setLocationInWindow:(CGPoint)location
{
	_previousLocationInWindow = _locationInWindow;
	_locationInWindow = location;
	_timestamp = [NSDate timeIntervalSinceReferenceDate];
}

@end

//
// GSEvent is an undeclared object. We don't need to use it ourselves but some
// Apple APIs (UIScrollView in particular) require the x and y fields to be present.
//
@interface GSEventProxy : NSObject
{
@public
	int ignored1[5];
	float x;
	float y;
	int ignored2[24];
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
    GSEventProxy           *_event;
    NSTimeInterval          _timestamp;
    NSMutableSet           *_touches;
    CFMutableDictionaryRef  _keyedTouches;
}
@end

@implementation PublicEvent
@end

//
// UIEvent (Synthesize)
//
// A category to allow creation of a touch event.
//
@implementation UIEvent (Synthesize)

- (id)initWithTouch:(UITouch *)touch
{
	self = [super init];
	if (self != nil)
	{
		PublicEvent *publicEvent = (PublicEvent *)self;
		publicEvent->_touches = [[NSMutableSet alloc] initWithObjects:&touch count:1];
		publicEvent->_timestamp = [NSDate timeIntervalSinceReferenceDate];
		
		CGPoint location = [touch locationInView:touch.window];
		
		publicEvent->_event = [[GSEventProxy alloc] init];
		publicEvent->_event->x = location.x;
		publicEvent->_event->y = location.y;

		CFMutableDictionaryRef dict =
			CFDictionaryCreateMutable(
				kCFAllocatorDefault,
				0,
				&kCFTypeDictionaryKeyCallBacks,
				&kCFTypeDictionaryValueCallBacks);
		
		CFDictionaryAddValue(dict, touch.view, publicEvent->_touches);
		CFDictionaryAddValue(dict, touch.window, publicEvent->_touches);
		
		publicEvent->_keyedTouches = dict;
	}
	return self;
}

@end

#endif // BROMINE_ENABLED

