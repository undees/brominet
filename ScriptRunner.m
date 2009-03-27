//
//  ScriptRunner.m
//  SelfTesting
//
//  Created by Matt Gallagher on 9/10/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//

#ifdef BROMINE_ENABLED

#import "ScriptRunner.h"
#import "XMLDescription.h"
#import "XPathQuery.h"
#import "TouchSynthesis.h"

const float SCRIPT_RUNNER_INTER_COMMAND_DELAY = 0.0;
const float MAX_WAIT_ATTEMPTS = 60;
const float WAIT_ATTEMPT_DELAY = 0.25;
const float BACKBUTTON_WAIT_DELAY = 0.75;

@implementation ScriptRunner



//
// init
//
// Init method for the object.
//
- (id)init
{
	self = [super init];
	if (self != nil)
	{
		[self retain];
		
		response = [NSString string];

		NSData *fileData =
		[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"TestScript" ofType:@"plist"]];
		
		if (fileData != nil)
		{
			scriptCommands =
			[[NSPropertyListSerialization
			  propertyListFromData:fileData
			  mutabilityOption:NSPropertyListMutableContainers
			  format:nil
			  errorDescription:nil]
			 retain];

			NSAssert([scriptCommands count] > 0, @"TestScript was not an array as expected.");

			[self performSelector:@selector(runCommand) withObject:nil afterDelay:1.0];
		}
		else
		{
			scriptCommands = [[NSMutableArray new] retain];
		}
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
	[scriptCommands release];
	[super dealloc];
}


//
// setResponse:(NSString*)input
//
//
- (void)setResponse:(NSString*)input
{
    [response autorelease];
    response = [input retain];
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
// performBumpInView:
//
// Synthesize a short rightward drag in the center of the specified view. Since there
// is no API to do this, it's a dirty hack of a job.
//
- (void)performDragInView:(UIView *)view
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
// Optional paramter:
//	outputPath (file path to save PropertyList description of hierarchy, if omitted print to stdout)
//	viewXPath (only output views matching this XPath)
//
- (void) outputView: (NSDictionary *) command  {
	NSString *path = [command objectForKey:@"outputPath"];
		
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	
	printf("=== outputView\n    outputPath:\n        %s\n    viewXPath:\n        %s\n",
		   [path cStringUsingEncoding:NSUTF8StringEncoding],
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding]);
	
	NSString *resultString;
	if (viewXPath)	{
		NSAssert1(0, @"not implemented yet",nil);
	}
	else {
		resultString = [[UIApplication sharedApplication] xmlDescription];
	}
	if (path == nil) {
		[self setResponse:resultString];
	}
	else {
		[resultString writeToFile:path atomically:YES encoding: NSUTF8StringEncoding error: nil];
	}
	
	
}

//
// waitForElement
//
// This command keeps running until the elements associated with
// the given XPath query are avaiable or gives a timeout.
//
// Required parameters:
//	viewXPath (search for views matching this XPath)
//
// Optional parameter:
//	count (wait for a specified number of elements matching viewXPath)
//
- (void) waitForElement: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'checkMatchCount' requires 'viewXPath' parameter.\n");
		[self setResponse:@"fail"];
		return;
	}
	
	NSNumber *requiredCount = [command objectForKey:@"count"];
	
	NSString *requiredCountMessage;
	if(requiredCount) {
		requiredCountMessage = [requiredCount stringValue];
	}
	else {
		requiredCountMessage = @"at least one";
	}
	
	NSNumber *numberOfAttempts = [command objectForKey:@"numberOfCalls"];
	if (numberOfAttempts == nil) {
		numberOfAttempts = [NSNumber numberWithInt:1];
		printf("=== waitForElement\n    viewXPath:\n        %s\n    count:\n        %s\n",
			   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding],
			   [requiredCountMessage cStringUsingEncoding:NSUTF8StringEncoding]
			   );
		
	}

	printf("attempt %d\n", [numberOfAttempts intValue]);

	NSArray *views = [self viewsForXPath:viewXPath];
	
	BOOL foundElements = NO;
	if(requiredCount) {
		foundElements = [views count] == [requiredCount integerValue];
	}
	else {
		foundElements = [views count] != 0;
	}
	
	if(foundElements) {
		[self setResponse:@"pass"];
	}
	else {
		if ([numberOfAttempts integerValue] == MAX_WAIT_ATTEMPTS) {
			if(requiredCount) {
				fprintf(
						stderr,
						"### TIMEOUT: couldn't find specified number of elements: %d\n with xpath '%s'\n found: %d\n",
						[requiredCount intValue],
						[viewXPath cStringUsingEncoding:NSUTF8StringEncoding],
						[views count]);
				
			}
			else {
				fprintf(
						stderr,
						"### TIMEOUT: couldn't find elements with xpath '%s'\n",
						[viewXPath cStringUsingEncoding:NSUTF8StringEncoding]);
			}
			[self setResponse:@"fail"];
		}
		else {
			NSMutableDictionary *newCommand = [NSMutableDictionary dictionaryWithDictionary:command];
			[newCommand setValue:[NSNumber numberWithInt:([numberOfAttempts intValue] + 1)] forKey:@"numberOfCalls"];
			[self performSelector:@selector(waitForElement:) withObject:(newCommand) afterDelay:(WAIT_ATTEMPT_DELAY)];
		}
	}
}

//
// checkMatchCount
//
// This command verifies that the specified number of nodes matching
// the given XPath query are found.
//
// Required parameter:
//	viewXPath (search for views matching this XPath)
//
// Optional parameter:
//	matchCount (number of nodes found must equal this number; -1 means 1 or more)
//
- (void) checkMatchCount: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'checkMatchCount' requires 'viewXPath' parameter.\n");
		[self setResponse:@"fail"];
		return;
	}
	
	NSNumber *matchCount = [command objectForKey:@"matchCount"];

	int expected = -1;
	if (matchCount != nil)
	{
		expected = [matchCount integerValue];
	}
	
	printf("=== checkMatchCount\n    viewXPath:\n        %s\n    matchCount: %ld\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding],
		   expected);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	int actual = [views count];

	if (actual == expected ||
		(actual > 0 && expected == -1))
	{
		[self setResponse:@"pass"];
	}
	else
	{
		fprintf(
				stderr,
				"### 'checkMatchCount' wanted a matching count of %ld but encountered %ld\n",
				[matchCount integerValue],
				[views count]);
		[self setResponse:@"fail"];
	}
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
		[self setResponse:@"fail"];
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
		[self setResponse:@"fail"];
		return;
	}
	
	UIView *view = [views objectAtIndex:0];
	
	[self performTouchInView:view];
	[self setResponse:@"pass"];
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
		[self setResponse:@"fail"];
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
		[self setResponse:@"fail"];
		return;
	}
	
	UIView *view = [views objectAtIndex:0];
	
	[self performDragInView:view];
	[self setResponse:@"pass"];
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
			[self setResponse:@"fail"];
		}
		else if([views count] > 1) {
			fprintf(
					stderr,
					"### command 'touchBackButton' found more then one back buttons\n");
			[self setResponse:@"fail"];
		}
		else {
			UIView *view = [views objectAtIndex:0];
			[self performTouchInView:view];
			[self setResponse:@"pass"];
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
		[self setResponse:@"fail"];
	}
	else if(![[views objectAtIndex:0] isKindOfClass:[UITableView class]]) {
		fprintf(
				stderr,
				"### 'viewXPath' for command 'scrollToRow' selected a node but it wasn't a UITableView as required.\n",
				[views count]);
		[self setResponse:@"fail"];
	}
	else {
		UITableView *view = [views objectAtIndex:0];
		[view
		 scrollToRowAtIndexPath:indexPath
		 atScrollPosition:UITableViewScrollPositionNone
		 animated:NO];

		[self setResponse:@"pass"];
	}
}

//
// assertText
//
// This command asserts if expected text matches the text of an UITextField or any component with text attribute
// found with the given XPath query.
//
// Required parameters:
//	viewXPath (search for views matching this XPath)
//	text (the expected text)
//
- (void) assertText: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'assertText' requires 'viewXPath' parameter.\n");
		[self setResponse:@"fail"];
		return;
	}
	
	NSString *text = [command objectForKey:@"text"];
	if (text == nil)
	{
		fprintf(stderr, "### Command 'assertText' requires 'text' parameter.\n");
		[self setResponse:@"fail"];
		return;
	}
	
	printf("=== assertText\n    viewXPath:\n        %s\n    text: %s\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding],
		   [text cStringUsingEncoding:NSUTF8StringEncoding]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1)
	{
		fprintf(
				stderr,
				"### 'viewXPath' for command 'assertText' selected %ld nodes, where exactly 1 is required.\n",
				[views count]);
		[self setResponse:@"fail"];
		return;
	}
	
	UIView *viewForText = (UIView *)[views objectAtIndex:0];
	if([viewForText respondsToSelector:@selector(text)]) {
		NSString *actualText = (NSString *)[viewForText performSelector:@selector(text)];
		if([text isEqualToString:actualText]) {
			[self setResponse:@"pass"];
		}
		else {
			fprintf(
					stderr,
					"### '%s' found, but '%s' was expected.\n",
					[actualText cStringUsingEncoding:NSUTF8StringEncoding],
					[text cStringUsingEncoding:NSUTF8StringEncoding],
					[views count]);
			[self setResponse:@"fail"];
		}
	}
	else {
		fprintf(
				stderr,
				"### %s doesn't suport 'text' method.\n",
				[viewForText.className cStringUsingEncoding:NSUTF8StringEncoding],
				[views count]);
		[self setResponse:@"fail"];
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
		[self setResponse:@"fail"];
		return;
	}
	
	NSString *text = [command objectForKey:@"text"];
	if (text == nil)
	{
		fprintf(stderr, "### Command 'setText' requires 'text' parameter.\n");
		[self setResponse:@"fail"];
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
		[self setResponse:@"fail"];
		return;
	}
	
	UIView *viewForText = (UIView *)[views objectAtIndex:0];
	if([viewForText respondsToSelector:@selector(setText:)]) {
		[viewForText performSelector:@selector(setText:) withObject:text];
		[self setResponse:@"pass"];
	}
	else {
		fprintf(
				stderr,
				"### %s doesn't suport 'setText' method.\n",
				[viewForText.className cStringUsingEncoding:NSUTF8StringEncoding],
				[views count]);
		[self setResponse:@"fail"];
	}
}

//
// getText
//
// This command gets the text of an UITextField or any component with text attribute
// found with the given XPath query.
//
// Required parameter:
//	viewXPath (search for views matching this XPath)
//
- (void) getText: (NSDictionary *) command  {
	NSString *viewXPath = [command objectForKey:@"viewXPath"];
	if (viewXPath == nil)
	{
		fprintf(stderr, "### Command 'getText' requires 'viewXPath' parameter.\n");
		[self setResponse:@""];
		return;
	}

	printf("=== getText\n    viewXPath:\n        %s\n",
		   [viewXPath cStringUsingEncoding:NSUTF8StringEncoding]);
	
	NSArray *views = [self viewsForXPath:viewXPath];
	if([views count] != 1)
	{
		fprintf(
				stderr,
				"### 'viewXPath' for command 'getText' selected %ld nodes, where exactly 1 is required.\n",
				[views count]);
		[self setResponse:@""];
		return;
	}
	
	UIView *viewForText = (UIView *)[views objectAtIndex:0];
	if([viewForText respondsToSelector:@selector(text)]) {
		[self setResponse:[viewForText performSelector:@selector(text)]];
	}
	else {
		fprintf(
				stderr,
				"### %s doesn't suport 'text' method.\n",
				[viewForText.className cStringUsingEncoding:NSUTF8StringEncoding],
				[views count]);
		[self setResponse:@""];
	}
}

//
// pause
//
// This command keeps does nothing except setting the minimum interval
// to the next command according to the 'seconds' parameter.
//
// It has not been adapted to be called as a standalone step,
// so it is wired to return a failure message (the regular
// runCommand script will ignore it).
//
// Required parameters:
//	seconds (interval between pause and the next command)
//
- (void) pause: (NSDictionary *) command  {
	NSNumber *seconds = [command objectForKey:@"seconds"];
	if (seconds == nil) {
		fprintf(stderr, "### Command 'pause' requires 'seconds' parameter.\n");
	}
	else {
		printf("=== pause\n    seconds:\n        %f\n",
			   [seconds floatValue]);
		scriptRunnerInterCommandDelay = [seconds floatValue];
	}
	
	[self setResponse:@"fail"];
}

#pragma mark -

//
// runCommand
//
// Runs the first command in the scriptCommands array and then removes it from
// the array.
//
- (void)runCommand
{
	NSDictionary *command = [scriptCommands objectAtIndex:0];
	NSString *commandName = [[command objectForKey:@"command"] stringByAppendingString:@":"];
	
	//reset default interval
	scriptRunnerInterCommandDelay = SCRIPT_RUNNER_INTER_COMMAND_DELAY;
	
	if([self respondsToSelector:NSSelectorFromString(commandName)])
		[self performSelector:NSSelectorFromString(commandName) withObject:command];
	else {
		fprintf(
				stderr,
				"### command '%s' doesn't exist. See ScriptRunner.m\n",
				[commandName UTF8String]);
	}
	//
	// Remove each command after execution
	//
	[scriptCommands removeObjectAtIndex:0];
	
	//
	// If further commands remain, queue the next one
	//
	if ([scriptCommands count] > 0)
	{
		[self
		 performSelector:@selector(runCommand)
		 withObject:nil
		 afterDelay:scriptRunnerInterCommandDelay];
	}
}

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

	[self setResponse:[NSString string]];
	
	if([self respondsToSelector:NSSelectorFromString(commandName)])
		[self performSelector:NSSelectorFromString(commandName) withObject:parsed];
}

//
// response
//
// Returns the response sent to the most recent command.
//
- (NSString*)response
{
	return response;
}

@end

#endif
