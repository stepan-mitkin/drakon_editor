//
//  DRAKONEditorAppDelegate.h
//  DRAKONEditor
//
//  Created by Stepan Mitkin on 10/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DRAKONEditorAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)goToTclPage:(id)sender;

@end
