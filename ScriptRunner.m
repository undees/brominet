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

const float SCRIPT_RUNNER_INTER_COMMAND_DELAY = 0.0;
const float MAX_WAIT_ATTEMPTS = 60;
const float WAIT_ATTEMPT_DELAY = 0.25;
const float BACKBUTTON_WAIT_DELAY = 0.75;

@implementation ScriptRunner

@synthesize response;

//
// init
//
// Init method for the object.
//
- (id)init
{
	if (self = [super init])
	{
		self.response = @"";
	}
	return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[response release];

	[super dealloc];
}


//
// performTouchInView:
//
// Synthesize a touch begin/end in the center of the specified view. Since there
// is no API to do this, it's a dirty hack of a job.
//
- (void)performTouchInView:(UIView *)view
{
	UITouch *touch = [[UITouch alloc] initInView:view];
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
// performSwipeInView:
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
- (void) outputView: (NSDictionary *) command  {
	printf("=== outputView\n");
	
	self.response = [[UIApplication sharedApplication] xmlDescription];
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
- (void) simulateTouch: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'simulateTouch' requires 'viewXPath' parameter.\n");
		self.response = @"fail";
		return;
	}
	
	printf("=== simulateTouch\n    viewXPath:\n        %s\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1)
	{
		fprintf(
				stderr,
				"### 'viewXPath' for command 'simulateTouch' selected %ld nodes, where exactly 1 is required.\n",
				[views count]);
		self.response = @"fail";
		return;
	}
	
	UIView *view = [views objectAtIndex:0];
	
	[self performTouchInView:view];
	self.response = @"pass";
}

//
// simulateDrag
//
// Performs a synthesized rightward drag in a single view selected
// by a given XPath query.
//
// Required parameters:
//	viewXPath (search for a view matching this XPath)
//
- (void) simulateDrag: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'simulateDrag' requires 'viewXPath' parameter.\n");
		self.response = @"fail";
		return;
	}
	
	printf("=== simulateTouch\n    viewXPath:\n        %s\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1)
	{
		fprintf(
				stderr,
				"### 'viewXPath' for command 'simulateDrag' selected %ld nodes, where exactly 1 is required.\n",
				[views count]);
		self.response = @"fail";
		return;
	}
	
	UIView *view = [views objectAtIndex:0];
	
	[self performSwipeInView:view];
	self.response = @"pass";
}

//
// touchBackButton
//
// Performs a synthesized touch down and touch up in the current back item
//
- (void)touchBackButton:(NSDictionary *)command  {
	// the touch won't work if the previous animation is not completed yet, so we wait a little just to make sure we are able to touch back button
	NSObject *waitedForEnoughTime = [command objectForKey:@"waitedForEnoughTime"];
	if(waitedForEnoughTime) {
		NSString *viewXPath = @"//UINavigationItemButtonView";
		
		printf("=== touchBackButton\n\n");
		
		NSArray *views = [self viewsForXPath:viewXPath];
		if([views count] == 0) {
			fprintf(
					stderr,
					"### command 'touchBackButton' couldn't find any back buttons\n");
			self.response = @"fail";
		}
		else if([views count] > 1) {
			fprintf(
					stderr,
					"### command 'touchBackButton' found more then one back buttons\n");
			self.response = @"fail";
		}
		else {
			UIView *view = [views objectAtIndex:0];
			[self performTouchInView:view];
			self.response = @"pass";
		}
	}
	else {
		NSMutableDictionary *newCommand = [NSMutableDictionary dictionaryWithDictionary:command];
		[newCommand setValue:@"YES" forKey:@"waitedForEnoughTime"];
		[self performSelector:@selector(touchBackButton:) withObject:(newCommand) afterDelay:(BACKBUTTON_WAIT_DELAY)];
	}
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

- (void) scrollToRow: (NSDictionary *) command  {
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
	
	printf("=== scrollToRow\n    viewXPath:\n        %s\n    indexPath: (section: %ld, row: %ld)\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding],
		   [indexPath section],
		   [indexPath row]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1) {
		fprintf(
				stderr,
				"### 'viewXPath' for command 'scrollToRow' selected %ld nodes, where exactly 1 is required.\n",
				[views count]);
		self.response = @"fail";
	}
	else if(![[views objectAtIndex:0] isKindOfClass:[UITableView class]]) {
		fprintf(
				stderr,
				"### 'viewXPath' for command 'scrollToRow' selected a node but it wasn't a UITableView as required.\n",
				[views count]);
		self.response = @"fail";
	}
	else {
		UITableView *view = [views objectAtIndex:0];
		[view
		 scrollToRowAtIndexPath:indexPath
		 atScrollPosition:UITableViewScrollPositionNone
		 animated:NO];

		self.response = @"pass";
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
- (void) setText: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'setText' requires 'viewXPath' parameter.\n");
		self.response = @"fail";
		return;
	}
	
	NSString *text = [command objectForKey:@"text"];
	if (text == nil)
	{
		fprintf(stderr, "### Command 'setText' requires 'text' parameter.\n");
		self.response = @"fail";
		return;
	}
	
	printf("=== setText\n    viewXPath:\n        %s\n    text: %s\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding],
		   [text cStringUsingEncoding:NSUTF8StringEncoding]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1)
	{
		fprintf(
				stderr,
				"### 'viewXPath' for command 'setText' selected %ld nodes, where exactly 1 is required.\n",
				[views count]);
		self.response = @"fail";
		return;
	}
	
	UIView *viewForText = (UIView *)[views objectAtIndex:0];
	if([viewForText respondsToSelector:@selector(setText:)]) {
		[viewForText performSelector:@selector(setText:) withObject:text];
		self.response = @"pass";
	}
	else {
		fprintf(
				stderr,
				"### %s doesn't suport 'setText' method.\n",
				[viewForText.className cStringUsingEncoding:NSUTF8StringEncoding],
				[views count]);
		self.response = @"fail";
	}
}

#pragma mark -

//
// runCommandStep
//
// Runs the specified command.
//
- (void)runCommandStep:(NSData*)command
{
	NSDictionary* parsed =
	[NSPropertyListSerialization
	 propertyListFromData:command
	 mutabilityOption:NSPropertyListMutableContainers
	 format:nil
	 errorDescription:nil];

	NSString *commandName = [[parsed objectForKey:@"command"] stringByAppendingString:@":"];
	NSLog(commandName);

	self.response = @"";
	
	id appDelegate = [[UIApplication sharedApplication] delegate];

	id performer =
		([self respondsToSelector:NSSelectorFromString(commandName)] ?
		 self :
	     ([appDelegate respondsToSelector:NSSelectorFromString(commandName)] ?
		  appDelegate :
		  nil));
	
	if (performer)
	{
		[performer performSelector:NSSelectorFromString(commandName) withObject:parsed];
	}
}

@end
