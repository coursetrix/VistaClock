//
//  MZAboutBox.m
//  NCal
//
//  Created by Paul Wong on 4/10/16.
//  Copyright © 2026 Mazookie, LLC. All rights reserved.
//

#import "MZAboutBox.h"

@implementation MZAboutBox

-(void) windowDidLoad
{
    [super windowDidLoad];

    // first time
    isHelpVisible = true;
    [self toggleHelp:nil];

    // Load variables
    NSDictionary *bundleDict = [[NSBundle mainBundle] infoDictionary];
    [self->appTitle setStringValue:[bundleDict objectForKey:@"CFBundleName"]];
    [self->appVersion setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Version %@ (Build %@)"
        , @"Version %@ (Build %@), displayed in the about window")
        , [bundleDict objectForKey:@"CFBundleShortVersionString"], [bundleDict objectForKey:@"CFBundleVersion"]]];
    [self->appCopyright setStringValue:[bundleDict objectForKey:@"NSHumanReadableCopyright"]];
    [self->appIcon setImage:[NSApp applicationIconImage]];

    // set help
    NSURL* fileURL = [[NSBundle mainBundle] URLForResource:@"help" withExtension:@"rtfd"];
    [[self->helpTextView textStorage] appendAttributedString:[
        [NSAttributedString alloc]
            initWithURL: fileURL
            options: @{ NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType }
            documentAttributes: nil
            error: nil
    ]];

    // Set acknowledgements
    fileURL = [[NSBundle mainBundle] URLForResource:@"acknowledgments" withExtension:@"txt"];
    [self->acknowledgmentsTextView setString:[
        [NSString alloc]initWithContentsOfFile:fileURL.path encoding:NSUTF8StringEncoding error:nil]
    ];
} // end of windowDidLoad

-(IBAction) visitWebsite:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.mazookie.com/"]];
} // end of visitWebsite


-(IBAction) toggleHelp:(id)sender
{
    if (self->isHelpVisible == true) {
        // show about
        self->isHelpVisible = false;
        [self->helpView setHidden:true];
        [self->aboutView setHidden:false];
        [self->helpButton setTitle:@"Help"];
    }
    else {
        // show help
        self->isHelpVisible = true;
        [self->helpView setHidden:false];
        [self->aboutView setHidden:true];
        [self->helpButton setTitle:@"About"];
    }
} // end of toggleHelp

-(void) forceHelp:(bool)force
{
    if (force == true) {
        self->isHelpVisible = false;
    }
    else {
        self->isHelpVisible = true;
    }
    [self toggleHelp:nil];
} // end of forceHelp

@end
