//
//  MZVistaClockAppDelegate.m
//  VistaClock
//
//  Created by Paul Wong on 9/5/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

#import "MZVistaClockAppDelegate.h"


// Removed MZStatusBarButton subclass since no longer needed for right-click handling.


@implementation MZVistaClockAppDelegate

@synthesize prefsWindow, abox;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    // Validate MainMenu.xib outlet connections (non-fatal warnings)
    #define LOG_OUTLET_WARNING(name) if (!(name)) { NSLog(@"[MainMenu] WARNING: Outlet '%s' is not connected in MainMenu.xib", #name); }
    LOG_OUTLET_WARNING(_vistaClockWindow);
    LOG_OUTLET_WARNING(statusMenu);
    LOG_OUTLET_WARNING(clockCollectionView);
    LOG_OUTLET_WARNING(clockArrayController);
    LOG_OUTLET_WARNING(mainCalendar);
    LOG_OUTLET_WARNING(clockScrollView);
    LOG_OUTLET_WARNING(altcal);
    LOG_OUTLET_WARNING(titleLabel);
    LOG_OUTLET_WARNING(gotoDateField);
    LOG_OUTLET_WARNING(dayDetailLabel);
    LOG_OUTLET_WARNING(toolBarMenuItem);
    LOG_OUTLET_WARNING(autoHideMenuItem);
    LOG_OUTLET_WARNING(_timeNow);
    
    // Ensure these views use frames, not Auto Layout constraints
    [clockScrollView setTranslatesAutoresizingMaskIntoConstraints:YES];
    [mainCalendar setTranslatesAutoresizingMaskIntoConstraints:YES];
    [clockCollectionView setTranslatesAutoresizingMaskIntoConstraints:YES];
    [altcal setTranslatesAutoresizingMaskIntoConstraints:YES];
    [titleLabel setTranslatesAutoresizingMaskIntoConstraints:YES];
    [gotoDateField setTranslatesAutoresizingMaskIntoConstraints:YES];
    [dayDetailLabel setTranslatesAutoresizingMaskIntoConstraints:YES];
    
    // get settings first thing
    settings = [VCSettings sharedSettings];
    
    // process the command line
    [self processCommandLine];

    // show dock icon
    if (settings.showDockIcon) {
        ProcessSerialNumber psn = { 0, kCurrentProcess };
        TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    }

    // init eventArray
	clockCollectionArray = [[NSMutableArray alloc] init];
    
    // default start
    [_vistaClockWindow setCollectionBehavior: NSWindowCollectionBehaviorMoveToActiveSpace];

    // ask for calendar access
    [self getCalendarAccess];

    // only for 10.10 and beyond
    _vistaClockWindow.titleVisibility = NSWindowTitleHidden;

    // setup toolbar
    showToolbar = FALSE;
    if (showToolbar)
    {
        [self configureToolbar: TRUE];
    }
    else
    {
        [self configureToolbar: FALSE];
    }

    // set the date box place holder to locale date
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    dateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
    [dateFormat setDateStyle:NSDateFormatterShortStyle];

    // set the format field for the date box
    [gotoDateField setPlaceholderString:[dateFormat dateFormat]];

    // should be yes, but make sure
    settings.needsDisplay = YES;
 
    // status item init
    // set status item to the right.
    [self createStatusItem];
    
    // Use NSStatusBarButton directly instead of custom statusItemView
    NSStatusBarButton *button = statusItem.button;
    button.target = self;
    button.action = @selector(statusItemButtonClicked:);
    // Add right-click (secondary click) handling to the button:
    [button sendActionOn:NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp];
    // Do NOT assign statusItem.button.menu to allow manual right-click handling

    // get the date
    lastDate = [[NSDate getDateNSDate:[NSDate date]] copy];

    // dark menu, init
    darkMenu = FALSE;
    
    // add clock info for the Princess Kendellyn
    NSMutableDictionary* addDict = [NSMutableDictionary new];
    [addDict setObject:settings.clockFaceName forKey:@"clock_face_name"];

    // launch the timer last
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fireTimer:)
        userInfo:nil repeats:YES];
        
    // keeps timer moving, even when menu has control
    [[NSRunLoop currentRunLoop] addTimer:timer 
        forMode:NSEventTrackingRunLoopMode];
    
} // end of applicationDidFinishLaunching


// called by the timer
-(void) fireTimer:(NSTimer*)timer 
{
    [self updateTime];
} // end of fireTimer


// Set current date time things.
-(void) updateTime
{
    // need to update the display?
    if (settings.needsDisplay == YES)
    {
        [self configureWindow];
        [NSApp activateIgnoringOtherApps:true];
    }

    // use dark menus, and then force to update
    if ([self isDarkMenu] != darkMenu)
    {
        lastWeek = -1; // force redraw
        darkMenu = [self isDarkMenu];
        // NSStatusBarButton does not support dark theme natively, so skip setDarkTheme calls
    }

    NSDate* now = [NSDate date];
    
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];

    // Date formats
    [dateFormatter setDateFormat:statusItemFormat];
    NSString* statusItemDate = [dateFormatter stringFromDate:now];
    
    [dateFormatter setDateStyle:NSDateFormatterFullStyle];
    NSString* fullDate = [dateFormatter stringFromDate:now];
    
    [dateFormatter setTimeStyle:NSDateFormatterLongStyle];
    NSString* fullDateTime = [dateFormatter stringFromDate:now];
    
    [dateFormatter setTimeStyle:NSDateFormatterNoStyle]; // clear
        
    //[dateFormatter setDateStyle:NSDateFormatterLongStyle];
    //NSString* longDate = [dateFormatter stringFromDate:now];
        
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString* mediumDate = [dateFormatter stringFromDate:now];
        
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    NSString* shortDate = [dateFormatter stringFromDate:now];

    [dateFormatter setDateStyle:NSDateFormatterNoStyle]; // clear
    
    // Time formats
    //[dateFormatter setDateFormat:TIME_FORMAT_NORMAL];
    //NSString* normalTime = [dateFormatter stringFromDate:now];
 
    [dateFormatter setDateFormat:TIME_FORMAT_NORMAL_FULL];
    NSString* normalFullTime = [dateFormatter stringFromDate:now];
    
    //[dateFormatter setDateFormat:TIME_FORMAT_MILITARY];
    //NSString* militaryTime = [dateFormatter stringFromDate:now];
 
    //[dateFormatter setDateFormat:TIME_FORMAT_MILITARY_FULL];
    //NSString* militaryFullTime = [dateFormatter stringFromDate:now];

    // NSStatusBarButton does not support inverse title, so skip setUseInverseTitle

    // update status item
    NSStatusBarButton *button = statusItem.button;
    if (settings.showWeekNumberIcon == YES)
    {
        NSInteger thisWeek;
        NSString* weekString;
        if ([[self getCurrentCalendar] compare:@"iso8601"] == NSOrderedSame)
        {
            weekString = [now getIsoWeekNumberString];
            thisWeek = [now getIsoWeekNumber];
        }
        else
        {
            weekString = [now getWeekNumberString];
            thisWeek = [now getWeekNumber];
        }
        if (lastWeek != thisWeek)
        {
            // create and set the image
            NSImage* weekImage;
            if (settings.useBWWeekIcon == TRUE)
            {
                weekImage = [[NSImage imageNamed:@"bw_calendar"] copy];
            }
            else
            {
                weekImage = [[NSImage imageNamed:@"c_calendar"] copy];
            }
                
            int x;
            if (thisWeek < 10)
            {
                x = 8;
            }
            else
            {
                x = 4;
            }
            NSPoint p = {x, 1};
            [weekImage lockFocus];
            
            // switch font color for dark menus?
            if ([self isDarkMenu] && settings.useBWWeekIcon == TRUE)
            {
                NSDictionary* attributes = [NSDictionary
                    dictionaryWithObject:[NSColor whiteColor]
                    forKey:NSForegroundColorAttributeName];
                [weekString drawAtPoint:p withAttributes:attributes];
            }
            else
            {
                [weekString drawAtPoint:p withAttributes:nil];
            }
            [weekImage unlockFocus];
            
            // update image on status item button
            button.image = weekImage;
            lastWeek = thisWeek;
        }
    }
    else
    {
        if (settings.showDateTime && (settings.showTime || settings.showDate)) // show time
        {
            // show nothing
            button.image = nil;
        }
        else
        {
            if (settings.useBWIcon) // use black and white
            {
                if ([self isDarkMenu])
                {
                    button.image = [[NSImage imageNamed:@"bw_w_mazookie"] copy];
                }
                else
                {
                    button.image = [[NSImage imageNamed:@"bw_b_mazookie"] copy];
                }
            }
            else
            {
                if ([self isDarkMenu])
                {
                    button.image = [[NSImage imageNamed:@"c_w_mazookie"] copy];
                }
                else
                {
                    button.image = [[NSImage imageNamed:@"c_b_mazookie"] copy];
                }
            }
        }
    }

    if (settings.showDateTime) // show time
    {
        if (settings.useFuzzyTime && settings.showTime)
        {
            button.title = [self getFuzzyTime:now];
        }
        else if (settings.showStatusSecondaryTime && settings.showTime)
        {
            NSDateFormatter* title1DateFormat = [[NSDateFormatter alloc] init];
            title1DateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
            [title1DateFormat setDateFormat:DATE_FORMAT_TIMEZONE_DAY];
            [title1DateFormat setTimeZone:[NSTimeZone timeZoneWithName:settings.statusSecondaryTimezone]];
            NSString* title1 = [title1DateFormat stringFromDate:now];
            NSDateFormatter* title2DateFormat = [[NSDateFormatter alloc] init];
            title2DateFormat.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
            if (settings.useStatusMilitary)
            {
                [title2DateFormat setDateFormat:TIME_FORMAT_MILITARY];
            }
            else
            {
                [title2DateFormat setDateFormat:TIME_FORMAT_NORMAL];
            }
            [title2DateFormat setTimeZone:[NSTimeZone timeZoneWithName:settings.statusSecondaryTimezone]];
            NSString* title2 = [title2DateFormat stringFromDate:now];
            
            // draw the secondary time zone as two small stacked lines to the
            // right of the main title, like the old custom status item view
            button.attributedTitle = [self statusTitleWithMain:statusItemDate top:title1 bottom:title2];
        }
        else
        {
            button.title = statusItemDate;
        }
    }
    else
    {
        button.title = @"";
    }
    
    // only update panel when the window is visiable
    //if ([_vistaClockWindow isVisible])
    {
        // set menu item
        [_timeNow setTitle:fullDateTime];
    
        // set window items
        // check size of window to see if title will fit
        if (clockCollectionArray.count<1)
        {
            if (showToolbar == TRUE)
            {
                [_vistaClockWindow setTitle:normalFullTime];
            }
            else
            {
                [_vistaClockWindow setTitle:@""];
            }
            [titleLabel setStringValue:normalFullTime];
        }
        else
        {
            if (showToolbar == TRUE)
            {
                [_vistaClockWindow setTitle:fullDate];
            }
            else
            {
                [_vistaClockWindow setTitle:@""];
            }
            int windowSize = _vistaClockWindow.frame.size.width;
            if (windowSize > 288)
            {
                [titleLabel setStringValue:fullDate];
            }
            else if (windowSize > 150)
            {
                [titleLabel setStringValue:mediumDate];
            }
            else
            {
                [titleLabel setStringValue:shortDate];
            }
        }

        // update clocks
        MZClockItem* item;
        for (long i=0; i<clockCollectionArray.count; i++)
        {
            item = (MZClockItem*)[clockCollectionView itemAtIndex:i];
            [item update:now];
            if (i == 0 && settings.showDockIcon) {
                [NSApp setApplicationIconImage: [item getImage]];
            }
        }
        
        // update calendar
        if ([self isCalendarChanged] == TRUE && (settings.showCalendar == TRUE || [settings.clockConfigs count] < 1))
        {
            if ([lastCal compare:@"gregorian"] == NSOrderedSame || [lastCal compare:@"iso8601"] == NSOrderedSame)
            {
                [mainCalendar setHidden:false];
                [altcal setHidden:true];
                [mainCalendar setDate:[mainCalendar getDate]];
                [toolBarMenuItem setEnabled:YES];
            }
            else
            {
                [altcal setHidden:false];
                [mainCalendar setHidden:true];
                [altcal setDateValue:now];
                // toolbar is only enabled if gregorian calendar is showing
                if (showToolbar == TRUE)
                {
                    [self toggleToolbar:self];
                }
                [toolBarMenuItem setEnabled:NO];
            }
        }

        // move to current date if changed
        if ([lastDate compare:[NSDate getDateNSDate:now]]
            != NSOrderedSame)
        {
            lastDate = [[NSDate getDateNSDate:now] copy];
            [mainCalendar setDate:lastDate];
        }
    }
    
    // update day details
    if ([_vistaClockWindow isVisible] && showToolbar)
    {
        NSDate* selectedDate = [mainCalendar getDate];
        NSTimeInterval secondsBetween = [selectedDate timeIntervalSinceDate:[NSDate getDateNSDate:now]];
        
        [dayDetailLabel setStringValue:[[NSString alloc] initWithFormat:@"%@ / %ld"
            , [selectedDate getDayOfYearString], (long)secondsBetween/86400]];
    }
} // end of updateTime


// Builds the status item title with the secondary time zone rendered as two
// small stacked lines (day/zone over time), matching the layout the legacy
// MZStatusItemView drew before the NSStatusBarButton migration.
-(NSAttributedString*) statusTitleWithMain:(NSString*)mainTitle top:(NSString*)topLine bottom:(NSString*)bottomLine
{
    NSFont* mainFont = [NSFont menuBarFontOfSize:0];
    NSFont* topFont = [NSFont fontWithName:@"Helvetica Neue" size:8];
    NSFont* bottomFont = [NSFont fontWithName:@"Helvetica Neue" size:10];
    if (topFont == nil) topFont = [NSFont systemFontOfSize:8];
    if (bottomFont == nil) bottomFont = [NSFont systemFontOfSize:10];
    NSDictionary* topAttributes = @{ NSFontAttributeName : topFont,
        NSForegroundColorAttributeName : [NSColor labelColor] };
    NSDictionary* bottomAttributes = @{ NSFontAttributeName : bottomFont,
        NSForegroundColorAttributeName : [NSColor labelColor] };

    NSSize topSize = [topLine sizeWithAttributes:topAttributes];
    NSSize bottomSize = [bottomLine sizeWithAttributes:bottomAttributes];
    CGFloat stackWidth = ceil(MAX(topSize.width, bottomSize.width));
    CGFloat stackHeight = ceil(topSize.height) + 10; // bottom line sits 10pt below the top one

    // the drawing handler runs at draw time, so labelColor resolves against
    // the menu bar's current light/dark appearance
    NSImage* stackImage = [NSImage imageWithSize:NSMakeSize(stackWidth, stackHeight)
        flipped:NO drawingHandler:^BOOL(NSRect dstRect)
    {
        [topLine drawAtPoint:NSMakePoint(0, 10) withAttributes:topAttributes];
        [bottomLine drawAtPoint:NSMakePoint(0, 0) withAttributes:bottomAttributes];
        return YES;
    }];

    NSTextAttachment* attachment = [[NSTextAttachment alloc] init];
    attachment.image = stackImage;
    // center the stack vertically against the main title's line
    CGFloat mainLineHeight = mainFont.ascender - mainFont.descender;
    CGFloat yOffset = mainFont.descender + (mainLineHeight - stackHeight) / 2.0;
    attachment.bounds = NSMakeRect(0, yOffset, stackWidth, stackHeight);

    NSMutableAttributedString* title = [[NSMutableAttributedString alloc]
        initWithString:[mainTitle stringByAppendingString:@" "]
        attributes:@{ NSFontAttributeName : mainFont,
            NSForegroundColorAttributeName : [NSColor labelColor] }];
    [title appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    return title;
} // end of statusTitleWithMain


-(NSString*) getFuzzyTime:(NSDate*) now
{
    int index = 0;

    NSString* HOUR_NAMES[] = {
        @"One",
        @"Two",
        @"Three",
        @"Four",
        @"Five",
        @"Six",
        @"Seven",
        @"Eight",
        @"Nine",
        @"Ten",
        @"Eleven",
        @"Twelve",
    };

    NSString* FUZZY_MSG[] = {
        @"%@ o'clock",
        @"Five past %@",
        @"Ten past %@",
        @"Quarter past %@",
        @"Twenty past %@",
        @"Twenty Five past %@",
        @"Half past %@",
        @"Twenty Five to %@",
        @"Twenty to %@",
        @"Quarter to %@",
        @"Ten to %@",
        @"Five to %@",
    };

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:now];
    NSInteger hours = [components hour];
    NSInteger minutes = [components minute];
    
    if (minutes > 2) {
        index = (int)((minutes - 3) / 5) + 1;
    }
    if (hours < 1) {
        hours = 12;
    }
    if (minutes > 32) {
        hours++;
    }

    //NSLog(@"%@", HOUR_NAMES[(hours - 1) % 12]);
    NSString* word_time = [NSString stringWithFormat:FUZZY_MSG[index % 12], HOUR_NAMES[(hours - 1) % 12]];

    return word_time;
} // end of getFuzzyTime


// process command line arguments
-(void) processCommandLine
{
    NSArray *arguments = [[NSProcessInfo processInfo] arguments];
    // reset takes takes priority
    for (int i=0; i<arguments.count; i++)
    {
    	if ([[arguments objectAtIndex:i] isEqualToString:@"-R"])
        {
        	[settings reset];
            [settings archive];
        }
    }
    // now handle the rest
    for (int i=0; i<arguments.count; i++)
    {
        if ([[arguments objectAtIndex:i] isEqualToString:@"-F:1"])
        {
            settings.floatRight = TRUE;
            [settings archive];
        }
        else if ([[arguments objectAtIndex:i] isEqualToString:@"-F:0"])
        {
            settings.floatRight = FALSE;
            [settings archive];
        }
    }
} // end of processCommandLine


// create the status item and move it to the right
-(void) createStatusItem
{
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    int priority = 0;
    
    // floatRight or not
    if (settings.floatRight == TRUE)
    {
        priority = INT32_MAX;
    }
    
    // Create the item with 0 length and then change it.
    if (!statusItem) 
    {
        statusItem = [bar _statusItemWithLength:0 withPriority:priority];
        [statusItem setLength:NSVariableStatusItemLength];
    }
    
} // end of createStatusItem

// Handle left and right clicks for the status item button
-(void) statusItemButtonClicked:(id)sender {
    NSEvent *event = [NSApp currentEvent];
    NSStatusBarButton *button = statusItem.button;
    if (event.type == NSEventTypeRightMouseUp) {
        [statusMenu popUpMenuPositioningItem:nil atLocation:NSMakePoint(0, button.bounds.size.height) inView:button];
    } else if (event.type == NSEventTypeLeftMouseUp) {
        [self toggleVistaClockWindow:sender];
    }
} // end of statusItemButtonClicked


// This method is called when opening the panel
-(IBAction) toggleVistaClockWindow:(id)sender
{
    if ([_vistaClockWindow isVisible] && [NSApp isActive])
    {
        [_vistaClockWindow orderOut:self];
        [NSApp activateIgnoringOtherApps:false];
    }
    else
    {
        [_vistaClockWindow makeKeyAndOrderFront:sender];
        [NSApp activateIgnoringOtherApps:true];
    }
    [_vistaClockWindow setCollectionBehavior: NSWindowCollectionBehaviorMoveToActiveSpace];
} // end of toggleVistaClockWindow


- (void)cancelOperation:(id)sender
{
    [self toggleVistaClockWindow:self];
} // end of cancelOperation


-(IBAction) launchAboutBoxPanel:(id)sender
{
    // hide main window
    //[_vistaClockWindow orderOut:sender];
    // launch about box
    //[[NSApplication sharedApplication] orderFrontStandardAboutPanel:sender];
    //[NSApp arrangeInFront:self];
    if (abox == nil) {
        abox = [[MZAboutBox alloc] initWithWindowNibName:@"MZAboutBox"];
        [abox setMacId:@"id466690161"];
    }
    [abox.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [abox showWindow:self];
    [abox forceHelp:FALSE];
} // end of launchAboutBox


-(IBAction) launchHelpPanel:(id)sender
{
    if (abox == nil) {
        abox = [[MZAboutBox alloc] initWithWindowNibName:@"MZAboutBox"];
        [abox setMacId:@"id466690161"];
    }
    [abox.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [abox showWindow:self];
    [abox forceHelp:TRUE];
} // end of launchHelpPanel


// launch the date & time preference panel
-(IBAction) launchDateTimePreferencePanel:(id)sender
{
    NSURL *prefPaneURL = [NSURL fileURLWithPath:@"/System/Library/PreferencePanes/DateAndTime.prefPane"];
    [[NSWorkspace sharedWorkspace] openURL:prefPaneURL];
} // end of launchDateTimePreferencePanel


-(int) addClock
{
	NSUInteger index = [[clockArrayController arrangedObjects] count];

	[clockArrayController insertObject:
        [NSDictionary dictionaryWithObjectsAndKeys:@"Name", @"Name", nil]
        atArrangedObjectIndex:index];
    
    //[self resizeWindow];
    return (int)index;
} // end of addClock


-(void) removeClock
{
 	NSUInteger index = [[clockArrayController arrangedObjects] count];
	if ( index > 0) {
		index--;
		[clockArrayController removeObjectAtArrangedObjectIndex:index];
	}
    
    //[self resizeWindow];
} // end of removeClock


-(void) removeAllClocks
{
 	NSUInteger cnt = [[clockArrayController arrangedObjects] count];
    for (long i=cnt; i>0; i--)
    {
        [clockArrayController removeObjectAtArrangedObjectIndex:i-1];
	}
    
    //[self resizeWindow];
} // end of removeAllClocks


-(void) configureWindow
{
    // remove all clocks
    [self removeAllClocks];
    
    // reset last week to redraw
    lastWeek = -1;
    
    // configure status item
    statusItemFormat = [self buildStatusItemDateFormatString];
    
    // set keep on top
    if (settings.useKeepTop == YES)
    {
        [_vistaClockWindow setLevel:1];
    }
    else
    {
        [_vistaClockWindow setLevel:NSNormalWindowLevel];
    }
    
    // turn on auto hide
    [_vistaClockWindow setHidesOnDeactivate:settings.useAutoHide];
    [self setAutoHideMenutItem];
    
    // show week numbers on calendar
    [mainCalendar setShowWeekNumbers:settings.showWeekNumbers];
    
    // show boxes on calendar
    [mainCalendar setShowBoxes:settings.showCalendarBoxes];

    // use red to highlight dates?
    if (settings.useHiliteColor)
    {
        [mainCalendar setHiliteColor:[NSColor redColor]];
    }
    else
    {
        if (@available(macOS 10.14, *)) {
            [mainCalendar setHiliteColor:[NSColor controlAccentColor]];
        } else {
            // Fallback on earlier versions
            [mainCalendar setHiliteColor:[NSColor highlightColor]];
        }
    }
    
    // show calendar event indicator
    [mainCalendar setShowEventIndicators:settings.showEvents];
    
    // show calendar reminder indicator
    [mainCalendar setShowReminderIndicators:settings.showReminders];
    
    // set theme elements
    // Font Shadow this code should move into calendar at some point
    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize( 1, 1 )];
    [shadow setShadowBlurRadius:1.5];
    [mainCalendar setUseShadow:settings.useShadows];

    if (settings.useLargeFonts)
    {
        [mainCalendar setFontSize:[NSFont systemFontSize]+2];
    }
    else
    {
        [mainCalendar setFontSize:[NSFont systemFontSize]];
    }

    // toolbar is only enabled if calendar is showing
    if (settings.showCalendar == YES || [settings.clockConfigs count] < 1)
    {
        [self resizeWindow];
        [toolBarMenuItem setEnabled:YES];
    }
    else
    {
        showToolbar = TRUE;
        [self toggleToolbar:self];
        [toolBarMenuItem setEnabled:NO];
    }

    // add clocks from config last
    int cnt = (int)[settings clockConfigs].count;
    for (int i=0; i<cnt; i++)
    {
        MZClockConfig* config = [[settings clockConfigs] objectAtIndex:i];
        MZClockItem* item = (MZClockItem*)[clockCollectionView itemAtIndex:[self addClock]];
        if (config.timezoneName != nil && config.title != nil)
        {
            [item configureClockItem:config.title
                zone:[NSTimeZone timeZoneWithName:config.timezoneName]
                clockFace:settings.clockFaceName
                useShadow:settings.useShadows
                largeFonts:settings.useLargeFonts
                seconds:config.useSeconds
                militaryTime:settings.useMilitary];
        }
    }
    [clockScrollView setNeedsDisplay:YES];

    // done painting
    settings.needsDisplay = NO;
} // end of configureWindow


-(void) resizeWindow
{
    NSRect screenRect = [[NSScreen mainScreen] visibleFrame];
    NSRect frame = [_vistaClockWindow frame];
    
    int clockWidth = 0;
    NSPoint clockOrigin;
    int maxSize = screenRect.size.width;

    int windowWidth = 0;

    // is toolbar showing?
    if (showToolbar)
    {
        //frame.size.height = WINDOW_HEIGHT_TOOLBAR;
        [_vistaClockWindow setTitleVisibility:NSWindowTitleVisible];
    }
    else
    {
        // adjust for wierd shift
        if (toolBarChanged)
        {
            toolBarChanged = FALSE;
            //frame.origin.y -= 2;
        }

        //frame.size.height = WINDOW_HEIGHT;
        [_vistaClockWindow setTitleVisibility:NSWindowTitleHidden];
    }

    // clocks only
    if (!settings.showCalendar && [settings.clockConfigs count] > 0)
    {
        [mainCalendar setHidden:TRUE];
        [altcal setHidden:TRUE];
        clockOrigin = NSMakePoint(8, 8);
        windowWidth = 16;
    }
    else // clock and calendar
    {
        if ([lastCal compare:@"gregorian"] == NSOrderedSame || [lastCal compare:@"iso8601"] == NSOrderedSame)
        {
            [mainCalendar setHidden:FALSE];
            [altcal setHidden:TRUE];
        }
        else
        {
            [mainCalendar setHidden:TRUE];
            [altcal setHidden:FALSE];
        }

        clockOrigin = NSMakePoint(CALENDAR_WIDTH + 8, 8);
        windowWidth = CALENDAR_WIDTH + 16;
    }
    
    for (long i=0; i<[settings.clockConfigs count]; i++)
    {
        if (clockWidth + CLOCK_WIDTH + windowWidth > maxSize)
            break;
        clockWidth += CLOCK_WIDTH;
    }

    windowWidth += clockWidth;
    frame.size.width = windowWidth;

    [_vistaClockWindow setFrame:frame display:YES animate:YES];

    [clockScrollView setFrameOrigin:clockOrigin];
    [clockScrollView setFrameSize:NSMakeSize(clockWidth, CLOCK_HEIGHT)];
    [mainCalendar setFrameOrigin:NSMakePoint(8,8)];

    //NSLog(@"Window Frame:   (%4.0f,%4.0f)(%4.0f,%4.0f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
} // end of resizeWindow


-(CGFloat) titleBarHeight:(NSWindow*) window
{
    CGFloat titleBarHeight = 0.0;
    NSRect frame = [window frame];

    NSRect contentRect;
    contentRect = [NSWindow contentRectForFrameRect: frame styleMask: window.styleMask];

    titleBarHeight = frame.size.height - contentRect.size.height;
    return titleBarHeight;
} // titleBarHeight


-(CGFloat) toolBarHeight:(NSWindow*) window
{
    NSToolbar *toolbar = [window toolbar];
    CGFloat toolBarHeight = 0.0;
    NSRect windowFrame;

    if (toolbar && [toolbar isVisible]) {
        windowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
        toolBarHeight = NSHeight(windowFrame) - NSHeight([[window contentView] frame]);
    }
    return toolBarHeight;
} // end toolbarHeight


// build StatusItem DateFormat String
-(NSString*) buildStatusItemDateFormatString
{
    //@"MMM d  h:mm a"
    NSString* buildString = [[NSString alloc] init];
    
    buildString = [buildString stringByAppendingString:@""];

    if (settings.showStatusWeekDay && settings.showDate)
    {
        buildString = [buildString stringByAppendingString:@"EEE"];
    }
    if (settings.showDate)
    {
    	NSDateFormatter *format = [[NSDateFormatter alloc] init];
        format.locale = [[NSLocale alloc] initWithLocaleIdentifier:[[NSLocale preferredLanguages] firstObject]];
        [format setDateStyle:NSDateFormatterLongStyle];
        NSString *dateFormat = [format dateFormat];
        dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"y" withString:@""];
        dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"," withString:@""];
        if (!settings.showMonth)
        {
            dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"MMMM"
                withString:@""];
        }
        else if (!settings.showStatusFullMonth)
        {
            dateFormat = [dateFormat stringByReplacingOccurrencesOfString:@"MMMM"
                withString:@"MMM"];
        }

        buildString = [buildString stringByAppendingString:@" "];
        buildString = [buildString stringByAppendingString:dateFormat];
    }
    if (settings.showTime)
    {
        if (settings.useStatusMilitary)
        {
            if (settings.showStatusSeconds)
            {
                buildString = [buildString stringByAppendingString:@" HH:mm:ss"];
            }
            else
            {
                buildString = [buildString stringByAppendingString:@" HH:mm"];
            }
        }
        else
        {
            if (settings.showStatusAMPM)
            {
                if (settings.showStatusSeconds)
                {
                    buildString = [buildString stringByAppendingString:@" h:mm:ss a"];
                }
                else
                {
                    buildString = [buildString stringByAppendingString:@" h:mm a"];
                }
            }
            else
            {
                if (settings.showStatusSeconds)
                {
                    buildString = [buildString stringByAppendingString:@" h:mm:ss"];
                }
                else
                {
                    buildString = [buildString stringByAppendingString:@" h:mm"];
                }
            }
        }
    }
    NSString *trimmedString = [buildString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    return trimmedString;
} // end of buildStatusItemDateFormatString


// get the current calendar
-(NSString*) getCurrentCalendar
{
    NSCalendar *usersCalendar = [[NSLocale currentLocale]
    	objectForKey:NSLocaleCalendar];
    return [usersCalendar calendarIdentifier];
} // end of getCurrentCalendar


// check for a change in calendar
-(bool) isCalendarChanged
{
    bool retval = false;
    NSString* currentCal = [self getCurrentCalendar];
    if ([currentCal compare:lastCal] != NSOrderedSame)
    {
        lastCal = [currentCal copy];
        retval = true;
    }
    return retval;
} // end of isCalendarChanged


-(IBAction) openPreferences:(id)sender
{
    if (prefsWindow == nil)
        prefsWindow = [[MZVistaClockPreferences alloc] initWithWindowNibName:@"MZVistaClockPreferences"];
    [prefsWindow showWindow:self];
    [prefsWindow.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [prefsWindow.window setCanHide:NO];
} // end of openPreferences



-(void) configureToolbar:(bool) full
{
    // reset toolbar;
    [self resetToolbar];

    if (full)
    {
        // Insert DateBoxID
        [_vistaClockWindow.toolbar insertItemWithItemIdentifier:@"DateBoxID" atIndex:0];
        NSToolbarItem *dateBoxItem = [_vistaClockWindow.toolbar items][0];
        if (dateBoxItem.view) {
            // Modern: Let system measure toolbar item view using constraints.
            dateBoxItem.view.translatesAutoresizingMaskIntoConstraints = NO;
            // Add constraints to let the toolbar size the item properly
            [dateBoxItem.view.widthAnchor constraintEqualToConstant:120].active = YES;
            [dateBoxItem.view.heightAnchor constraintEqualToConstant:24].active = YES;
        }

        // Insert GotoTodayID
        [_vistaClockWindow.toolbar insertItemWithItemIdentifier:@"GotoTodayID" atIndex:1];
        NSToolbarItem *gotoTodayItem = [_vistaClockWindow.toolbar items][1];
        if (gotoTodayItem.view) {
            // Modern: Let system measure toolbar item view using constraints.
            gotoTodayItem.view.translatesAutoresizingMaskIntoConstraints = NO;
            // Add constraints as appropriate; example fixed size:
            [gotoTodayItem.view.widthAnchor constraintEqualToConstant:80].active = YES;
            [gotoTodayItem.view.heightAnchor constraintEqualToConstant:24].active = YES;
        }

        // Insert DateDetailsID
        [_vistaClockWindow.toolbar insertItemWithItemIdentifier:@"DateDetailsID" atIndex:2];
        NSToolbarItem *dateDetailsItem = [_vistaClockWindow.toolbar items][2];
        if (dateDetailsItem.view) {
            // Modern: Let system measure toolbar item view using constraints.
            dateDetailsItem.view.translatesAutoresizingMaskIntoConstraints = NO;
            // Add constraints as appropriate; example fixed size:
            [dateDetailsItem.view.widthAnchor constraintEqualToConstant:100].active = YES;
            [dateDetailsItem.view.heightAnchor constraintEqualToConstant:24].active = YES;
        }

        [_vistaClockWindow makeFirstResponder:gotoDateField];
    }
    else
    {
        [_vistaClockWindow.toolbar insertItemWithItemIdentifier:@"TitleID" atIndex:0];
        NSToolbarItem *titleItem = [_vistaClockWindow.toolbar items][0];
        if (titleItem.view) {
            // Modern: Let system measure toolbar item view using constraints.
            titleItem.view.translatesAutoresizingMaskIntoConstraints = NO;
            // Add constraints as appropriate; example fixed size:
            [titleItem.view.widthAnchor constraintEqualToConstant:200].active = YES;
            [titleItem.view.heightAnchor constraintEqualToConstant:24].active = YES;
        }
        [_vistaClockWindow makeFirstResponder:clockCollectionView];
    }

    // redraw
    [self resizeWindow];
} // configureToolbar


-(void) resetToolbar
{
    while (_vistaClockWindow.toolbar.items.count > 0)
    {
        [_vistaClockWindow.toolbar removeItemAtIndex:0];
    }
    [_vistaClockWindow.toolbar insertItemWithItemIdentifier:NSToolbarFlexibleSpaceItemIdentifier atIndex:0];
    [_vistaClockWindow.toolbar insertItemWithItemIdentifier:@"SettingsID" atIndex:1];

    // Note: No longer setting minSize or maxSize on toolbar items.
    // Modern Auto Layout and intrinsicContentSize will determine toolbar item sizes.
} // resetToolbar


-(IBAction) toggleAutoHide:(id)sender
{
    settings.useAutoHide = !settings.useAutoHide;
    [_vistaClockWindow setHidesOnDeactivate:settings.useAutoHide];
    [self setAutoHideMenutItem];
} // toggleAutoHide


-(void) setAutoHideMenutItem
{
    if (settings.useAutoHide)
    {
        [autoHideMenuItem setTitle:@"Pin to Desktop"];
    }
    else
    {
        [autoHideMenuItem setTitle:@"Unpin from Desktop"];
    }
    [prefsWindow updateWindowControls];
} // setAutoHideMenutItem


-(IBAction) toggleToolbar:(id)sender
{
    showToolbar = !showToolbar;
    toolBarChanged = TRUE;
    if (showToolbar)
    {
        [toolBarMenuItem setTitle:@"Hide Toolbar"];
    }
    else
    {
        [toolBarMenuItem setTitle:@"Show Toolbar"];
    }
    [self configureToolbar: showToolbar];
} // toggleToolbar


-(IBAction) gotoDate:(id)sender
{
    MZDateCalc* calc = [MZDateCalc alloc];
    [calc setCalendar:mainCalendar];
    
    NSArray* strings = [[gotoDateField stringValue] componentsSeparatedByString:@","];

    // try to parse the date and set current date to it.
    if ([strings count] > 1)
    {
        if ([calc parseDate:strings[0]])
        {
            // got a date
            if (strings[1] != nil)
            {
                [calc moveDate:strings[1] useToday: NO];
            }
        }
        else
        {
            [calc moveDate:strings[1] useToday: NO];
        }
    }
    else
    {
        if (![calc parseDate:strings[0]])
        {
            [calc moveDate:strings[0] useToday: YES];
        }
    }
} // end of gotoDate


-(IBAction) goToday:(id)sender
{
    [gotoDateField setStringValue:@""];
    [mainCalendar setDate:[NSDate getDateNSDate:[NSDate date]]];
} // end of goToday


-(void) getCalendarAccess
{
    // get calendar access do in main init.
    store = [[EKEventStore alloc] init]; 
        
    BOOL needsToRequestAccessToEventStore = NO;
    EKAuthorizationStatus eventStatus = EKAuthorizationStatusNotDetermined;
    EKAuthorizationStatus reminderStatus = EKAuthorizationStatusNotDetermined;
    if ([[EKEventStore class] respondsToSelector:@selector(authorizationStatusForEntityType:)])
    {
        eventStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
        reminderStatus = [EKEventStore authorizationStatusForEntityType:EKEntityTypeReminder];
        needsToRequestAccessToEventStore = (eventStatus == EKAuthorizationStatusNotDetermined || reminderStatus == EKAuthorizationStatusNotDetermined);
    }

    BOOL hasEventAccess = (eventStatus == EKAuthorizationStatusFullAccess || eventStatus == EKAuthorizationStatusWriteOnly);
    BOOL hasReminderAccess = (reminderStatus == EKAuthorizationStatusFullAccess || reminderStatus == EKAuthorizationStatusWriteOnly);

    if (needsToRequestAccessToEventStore)
    {
        if (@available(macOS 14.0, *)) {
            // Request full access to events
            [store requestFullAccessToEventsWithCompletion:^(BOOL granted, NSError *error) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // You can use the event store now
                    });
                }
            }];
            // Request full access to reminders
            [store requestFullAccessToRemindersWithCompletion:^(BOOL granted, NSError *error) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // You can use the event store now
                    });
                }
            }];
        } else {
            // Fallback on earlier versions (macOS < 14.0)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            [store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // You can use the event store now
                    });
                }
            }];
            [store requestAccessToEntityType:EKEntityTypeReminder completion:^(BOOL granted, NSError *error) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // You can use the event store now
                    });
                }
            }];
#pragma clang diagnostic pop
        }
    }
    else if (!hasEventAccess || !hasReminderAccess)
    {
        // Access denied
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Access to calendar or reminder data has been denied!\n"
            "Please enable access in System Preferences and restart VistaClock."];
        [alert runModal];
        // quit
        [NSApp terminate:self];
        
    }
} // end of getCalendarAccess

-(IBAction)launchCalendar:(id)sender
{
    NSURL *calendarURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.apple.iCal"];
    if (calendarURL) {
        NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
        [[NSWorkspace sharedWorkspace] openApplicationAtURL:calendarURL configuration:config completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Failed to launch Calendar: %@", error);
            }
        }];
    } else {
        NSLog(@"Calendar app not found");
    }
} // end of launchCalendar


-(IBAction)launchReminders:(id)sender
{
    NSURL *remindersURL = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"com.apple.reminders"];
    if (remindersURL) {
        NSWorkspaceOpenConfiguration *config = [NSWorkspaceOpenConfiguration configuration];
        [[NSWorkspace sharedWorkspace] openApplicationAtURL:remindersURL configuration:config completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Failed to launch Reminders: %@", error);
            }
        }];
    } else {
        NSLog(@"Reminders app not found");
    }
} // end of launchReminders


-(bool) isDarkMenu
{
    bool retval = FALSE;
    
    // get the key
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    
    // if got a key
    if (value && [value compare:@"Dark"] == NSOrderedSame)
    {
        retval = TRUE;
    }
    
    return retval;
} // end of isDarkMenu

@end
