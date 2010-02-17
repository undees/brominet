//
//  UIApplication+XMLDescription.m
//  iPhoneRiskManager
//
//  Created by Felipe Barreto on 03/12/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "UIApplication+XMLDescription.h"
#import "UIView+XMLDescription.h"
#import "NSObject+ClassName.h"

@implementation UIApplication (XMLDescription)

#ifndef NAMEOF(obj)
#define NAMEOF(obj)     object_getClassName(obj)
#endif

- (NSString *) xmlDescription {
	NSMutableString *resultingXML = [NSMutableString stringWithFormat:@"\n<%s>", NAMEOF(self)];
	[resultingXML appendFormat:@"\n\t<address>%d</address>", (NSInteger)self];
	

	if(self.windows.count > 0) {
		[resultingXML appendString:@"\n\t<windows>"];
		for (UIWindow *window in self.windows) {
			[resultingXML appendString:[window xmlDescriptionWithStringPadding:@"\t"]];
		}
		[resultingXML appendString:@"\n\t</windows>"];
	}
	else {
		[resultingXML appendString:@"\n\t<windows />"];
	}
	[resultingXML appendFormat:@"\n</%s>", NAMEOF(self)];
	return resultingXML;
}


@end
