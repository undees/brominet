//
//  ScriptRunner.m
//  SelfTesting
//
//  Created by Matt Gallagher on 9/10/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//

#import "ScriptRunner.h"
#import "XMLDescription.h"
#import "XPathQuery.h"
#import "TouchSynthesis.h"
#import "NSObject+ClassName.h"
#import "Foundation/Foundation.h"

const float SCRIPT_RUNNER_INTER_COMMAND_DELAY = 0.0;
const float MAX_WAIT_ATTEMPTS = 60;
const float WAIT_ATTEMPT_DELAY = 0.25;
const float BACKBUTTON_WAIT_DELAY = 0.75;

@implementation ScriptRunner

//
// performTouchInView:
//
// Synthesize a touch begin/end in the center of the specified view. Since there
// is no API to do this, it's a dirty hack of a job.
//
- (void)performTouchInView:(UIView *)view hitTest:(BOOL)hitTest
{
	UITouch *touch = [[UITouch alloc] initInView:view hitTest:hitTest];
	UIEvent *event = [[UIEvent alloc] initWithTouch:touch];
	NSSet *touches = [[NSMutableSet alloc] initWithObjects:&touch count:1];

	[touch.view touchesBegan:touches withEvent:event];

	[touch setPhase:UITouchPhaseEnded];

	[touch.view touchesEnded:touches withEvent:event];
	
	[event release];
	[touches release];
	[touch release];
}

//
// performLeftSwipeInView:
//
// swipe to the LEFT
//
// Synthesize a short rightward drag in the center of the specified view. Since there
// is no API to do this, it's a dirty hack of a job.
//
- (void)performLeftSwipeInView:(UIView *)view
{
	UITouch *touch = [[UITouch alloc] initInView:view];
	UIEvent *event = [[UIEvent alloc] initWithTouch:touch];
	NSSet *touches = [[NSMutableSet alloc] initWithObjects:&touch count:1];
	
	[touch.view touchesBegan:touches withEvent:event];
	
	[touch setPhase:UITouchPhaseMoved];

  //swipe left

  [touch moveLocationInWindowLeft];

	[event moveLocation];
	[touch.view touchesMoved:touches withEvent:event];
	
	[touch setPhase:UITouchPhaseEnded];
	[touch.view touchesEnded:touches withEvent:event];
	
	[event release];
	[touches release];
	[touch release];
}

//
// performSwipeInView:
//
// swipe to the RIGHT
//
// Synthesize a short rightward drag in the center of the specified view. Since there
// is no API to do this, it's a dirty hack of a job.
//
- (void)performSwipeInView:(UIView *)view
{
	UITouch *touch = [[UITouch alloc] initInView:view];
	UIEvent *event = [[UIEvent alloc] initWithTouch:touch];
	NSSet *touches = [[NSMutableSet alloc] initWithObjects:&touch count:1];
	
	[touch.view touchesBegan:touches withEvent:event];
	
	[touch setPhase:UITouchPhaseMoved];

  // swipe right
	[touch moveLocationInWindow];

	[event moveLocation];
	[touch.view touchesMoved:touches withEvent:event];
	
	[touch setPhase:UITouchPhaseEnded];
	[touch.view touchesEnded:touches withEvent:event];
	
	[event release];
	[touches release];
	[touch release];
}


//
// highlightView
//
// shows a yellow rect over the provided view
//
- (void)highlightView:(UIView *)view {
	UIView *highlightView = [[UIView alloc] init];
	CGRect frame = view.frame;
	frame.origin.x = 0;
	frame.origin.y = 0;
	highlightView.frame = frame;
	highlightView.backgroundColor = [UIColor yellowColor];
	highlightView.alpha = 0.5;
	[view addSubview:highlightView];
	
	[UIView beginAnimations:@"highlight" context:nil]; 
	[UIView setAnimationDuration:1.5f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	highlightView.alpha = 0;
	[UIView commitAnimations];
	[highlightView release];
}

//
// viewsForXPath:
//
// Generates an XML document from the current view tree and runs the specified
// XPath query on the document. If the resulting nodes contain "address" values
// then these values are interrogated to determine if they are UIViews. All
// UIViews found in this way are returned in the array.
//
- (NSArray *)viewsForXPath:(NSString *)xpath
{
	//printf("XML \n%s\n\n", [[[[UIApplication sharedApplication] keyWindow] xmlDescription] cStringUsingEncoding:NSUTF8StringEncoding]);
	NSData *resultData =
	[[[UIApplication sharedApplication] xmlDescription] dataUsingEncoding: NSUTF8StringEncoding];
	
	NSArray *queryResults = PerformXMLXPathQuery(resultData, xpath);
	//printf("%s", [queryResults.description UTF8String]);
	NSMutableArray *views =
	[NSMutableArray arrayWithCapacity:[queryResults count]];
	for (NSDictionary *result in queryResults)
	{
		int i;
		int count = [[result objectForKey:@"nodeChildArray"] count];
		for (i = 0; i < count; i++)
		{
			NSDictionary *childNode = [[result objectForKey:@"nodeChildArray"] objectAtIndex:i];
			if ([[childNode objectForKey:@"nodeName"] isEqualToString:@"address"] )
			{
				UIView *view =
				(UIView *)[[childNode objectForKey:@"nodeContent"] integerValue];
				NSAssert([view isKindOfClass:[UIView class]],
						 @"XPath selected memory address did not contain a UIView");
				[views addObject:view];
				
				[self highlightView:view];
				break;
			}
		}
	}
	return views;
}

#pragma mark -
#pragma mark Available test commands

//
// outputView
//
// This command outputs the current view hierarchy, starting with the
// keyWindow, to a file or stdout.
//
// Required parameter:
//
- (NSString*) outputView: (NSDictionary *) command  {
	printf("=== outputView\n");
	
	return [[UIApplication sharedApplication] xmlDescription];
}

//
// simulateTouch
//
// Performs a synthesized touch down and touch up in a single view selected
// by a given XPath query.
//
// Required parameters:
//	viewXPath (search for a view matching this XPath)
//
// Optional parameters:
//	hitTest (use hit-testing to find the target view; default 1)
//
- (NSString*) simulateTouch: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'simulateTouch' requires 'viewXPath' parameter.\n");
		return @"fail";
	}

	NSNumber *sectionIndex = [command objectForKey:@"hitTest"];
	BOOL hitTest = sectionIndex ? [sectionIndex boolValue] : YES;
	
	printf("=== simulateTouch\n    viewXPath:\n        %s\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1)
	{
		fprintf(
				stderr,
				"### 'viewXPath' for command 'simulateTouch' selected %d nodes, where exactly 1 is required.\n",
				[views count]);
		return @"fail";
	}
	
	UIView *view = [views objectAtIndex:0];
	
	[self performTouchInView:view hitTest:hitTest];
	return @"pass";
}

//
// simulateLeftSwipe
//
// swipe to the LEFT
//
- (NSString*) simulateLeftSwipe: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'simulateSwipe' requires 'viewXPath' parameter.\n");
		return @"fail";
	}
	
	printf("=== simulateSwipe\n    viewXPath:\n        %s\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1)
	{
		fprintf(
				stderr,
				"### 'viewXPath' for command 'simulateSwipe' selected %d nodes, where exactly 1 is required.\n",
				[views count]);
		return @"fail";
	}
	
	UIView *view = [views objectAtIndex:0];
	
	[self performLeftSwipeInView:view];
	return @"pass";
}


//
// simulateSwipe
//
// swipe to the RIGHT
//
// Performs a synthesized rightward swipe in a single view selected
// by a given XPath query.
//
// Required parameters:
//	viewXPath (search for a view matching this XPath)
//
- (NSString*) simulateSwipe: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'simulateSwipe' requires 'viewXPath' parameter.\n");
		return @"fail";
	}
	
	printf("=== simulateSwipe\n    viewXPath:\n        %s\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1)
	{
		fprintf(
				stderr,
				"### 'viewXPath' for command 'simulateSwipe' selected %d nodes, where exactly 1 is required.\n",
				[views count]);
		return @"fail";
	}
	
	UIView *view = [views objectAtIndex:0];
	
	[self performSwipeInView:view];
	return @"pass";
}

//
// scrollToRow
//
// Scrolls a UITableView selected by an XPath query to the specified
// rowIndex (and optionally sectionIndex).
//
// Required parameters:
//	viewXPath (search for a table view matching this XPath)
//	rowIndex (scroll the table view to this row)
//
// Optional parameter:
//	sectionIndex (scroll the table view to the rowIndex in this section)
//

- (NSString*) scrollToRow: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	NSAssert(viewXPath != nil, @"Command 'scrollToRow' requires 'viewXPath' parameter");
	NSNumber *rowIndex = [command objectForKey:@"rowIndex"];
	NSAssert(viewXPath != nil, @"Command 'scrollToRow' requires 'rowIndex' parameter");
	NSNumber *sectionIndex = [command objectForKey:@"sectionIndex"];
	// sectionIndex is allowed to be nil -- will select section 0
	
	NSIndexPath *indexPath =
	[NSIndexPath
	 indexPathForRow:[rowIndex integerValue]
	 inSection:[sectionIndex integerValue]];
	
	printf("=== scrollToRow\n    viewXPath:\n        %s\n    indexPath: (section: %d, row: %d)\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding],
		   [indexPath section],
		   [indexPath row]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1) {
		fprintf(
				stderr,
				"### 'viewXPath' for command 'scrollToRow' selected %d nodes, where exactly 1 is required.\n",
				[views count]);
		return @"fail";
	}
	else if(![[views objectAtIndex:0] isKindOfClass:[UITableView class]]) {
		fprintf(
				stderr,
				"### 'viewXPath' for command 'scrollToRow' selected a node but it wasn't a UITableView as required.\n",
				[views count]);
		return @"fail";
	}
	else {
		UITableView *view = [views objectAtIndex:0];
		[view
		 scrollToRowAtIndexPath:indexPath
		 atScrollPosition:UITableViewScrollPositionNone
		 animated:NO];

		return @"pass";
	}
}

//
// setText
//
// This command sets the text of an UITextField or any component with text attribute
// found with the given XPath query.
//
// Required parameters:
//	viewXPath (search for views matching this XPath)
//	text (the text to be set)
//
- (NSString*) setText: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'setText' requires 'viewXPath' parameter.\n");
		return @"fail";
	}
	
	NSString *text = [command objectForKey:@"text"];
	if (text == nil)
	{
		fprintf(stderr, "### Command 'setText' requires 'text' parameter.\n");
		return @"fail";
	}
	
	printf("=== setText\n    viewXPath:\n        %s\n    text: %s\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding],
		   [text cStringUsingEncoding:NSUTF8StringEncoding]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1)
	{
		fprintf(
				stderr,
				"### 'viewXPath' for command 'setText' selected %d nodes, where exactly 1 is required.\n",
				[views count]);
		return @"fail";
	}
	
	UIView *viewForText = (UIView *)[views objectAtIndex:0];
	if([viewForText respondsToSelector:@selector(setText:)]) {
		[viewForText performSelector:@selector(setText:) withObject:text];
		return @"pass";
	}
	else {
		fprintf(
				stderr,
				"### %s doesn't suport 'setText' method.\n",
				[viewForText.className cStringUsingEncoding:NSUTF8StringEncoding],
				[views count]);
		return @"fail";
	}
}

#pragma mark -

//
// runCommandStep
//
// Runs the specified command.
//
- (NSString*)runCommandStep:(NSData*)command
{
	NSDictionary* parsed =
	[NSPropertyListSerialization
	 propertyListFromData:command
	 mutabilityOption:NSPropertyListMutableContainers
	 format:nil
	 errorDescription:nil];

	NSString *commandName = [[parsed objectForKey:@"command"] stringByAppendingString:@":"];
	NSLog(commandName);

	id appDelegate = [[UIApplication sharedApplication] delegate];
	SEL selector = NSSelectorFromString(commandName);
	id performer = ([self respondsToSelector:selector] ?
					self :
					([appDelegate respondsToSelector:selector] ?
					 appDelegate :
					 nil));
	
	if (!performer)
		return @"";

	return [performer performSelector:selector withObject:parsed];
}

@end
