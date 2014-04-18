//
//  DRAKONEditorAppDelegate.m
//  DRAKONEditor
//
//  Created by Stepan Mitkin on 10/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DRAKONEditorAppDelegate.h"


@implementation DRAKONEditorAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app {
	return YES;
}

- (IBAction)goToTclPage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: @"http://www.activestate.com/activetcl/downloads"]];	
}

@end
