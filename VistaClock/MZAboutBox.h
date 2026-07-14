//
//  MZAboutBox.h
//  NCal
//
//  Created by Paul Wong on 4/10/16.
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MZAboutBox : NSWindowController
{
    IBOutlet NSImageView* appIcon;
    IBOutlet NSTextField* appTitle;
    IBOutlet NSTextField* appVersion;
    IBOutlet NSTextField* appCopyright;

    IBOutlet NSButton* visitWebsiteButton;
    IBOutlet NSButton* helpButton;

    IBOutlet NSTextView* acknowledgmentsTextView;
    IBOutlet NSTextView* helpTextView;

    IBOutlet NSView* aboutView;
    IBOutlet NSView* helpView;

    IBOutlet NSScrollView* helpScrollView;

    bool isHelpVisible;
}

-(IBAction) visitWebsite:(id)sender;
-(IBAction) toggleHelp:(id)sender;
-(void) forceHelp:(bool)force;

@end
