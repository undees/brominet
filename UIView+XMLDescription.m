//
//  UIView+XMLDescription.m
//  SelfTesting
//
//  Created by Matt Gallagher on 9/10/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//

#import "UIView+XMLDescription.h"

@implementation UIView (XMLDescription)

- (NSString *) xmlDescription {
	NSMutableString *resultingXML = [NSMutableString stringWithFormat:@"\n<%@>", [self className]];
	[resultingXML appendFormat:@"\n\t<address>%d</address>", (NSInteger)self];
	[resultingXML appendFormat:@"\n\t<tag>%d</tag>", [self tag]];
	if ([self respondsToSelector:@selector(text)])
	{
		[resultingXML appendFormat:@"\n\t<text><![CDATA[%@]]></text>", [self performSelector:@selector(text)]];
	}
	if ([self respondsToSelector:@selector(title)])
	{
		[resultingXML appendFormat:@"\n\t<title><![CDATA[%@]]></title>", [self performSelector:@selector(title)]];
	}
	if ([self respondsToSelector:@selector(currentTitle)])
	{
		[resultingXML appendFormat:@"\n\t<currentTitle><![CDATA[%@]]></currentTitle>", [self performSelector:@selector(currentTitle)]];
	}
	if ([self respondsToSelector:@selector(isKeyWindow)])
	{
		if([self performSelector:@selector(isKeyWindow)]) {
			[resultingXML appendString:@"\n\t<keyWindow>YES</keyWindow>"];			
		}
		else {
			[resultingXML appendString:@"\n\t<keyWindow>NO</keyWindow>"];			
		}
	}
	if ([self respondsToSelector:@selector(isOn)])
	{
		if(((UISwitch *)self).on) {
			[resultingXML appendString:@"\n\t<on>YES</on>"];			
		}
		else {
			[resultingXML appendString:@"\n\t<on>NO</on>"];			
		}
	}
	
	[resultingXML appendFormat:@"\n\t<frame>"];
	[resultingXML appendFormat:@"\n\t\t<x>%f</x>", self.frame.origin.x];
	[resultingXML appendFormat:@"\n\t\t<y>%f</y>", self.frame.origin.y];
	[resultingXML appendFormat:@"\n\t\t<width>%f</width>", self.frame.size.width];
	[resultingXML appendFormat:@"\n\t\t<height>%f</height>", self.frame.size.height];
	[resultingXML appendFormat:@"\n\t</frame>"];
	if(self.subviews.count > 0) {
		[resultingXML appendString:@"\n\t<subviews>"];
		for (UIView *subview in [self subviews]) {
			[resultingXML appendString:[subview xmlDescription]];
		}
		[resultingXML appendString:@"\n\t</subviews>"];
	}
	else {
		[resultingXML appendString:@"\n\t<subviews />"];
	}
	[resultingXML appendFormat:@"\n</%@>", [self className]];
	return resultingXML;
}


@end
