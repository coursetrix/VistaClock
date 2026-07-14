//
//  MZVistaClockAppDelegate.h
//  VistaClock
//
//  Created by Paul Wong on 9/5/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MZStatusItemView.h"
#import "MZClockItem.h"
#import "MZCalendarControl.h"
#import "MZVistaClockPreferences.h"
#import <ServiceManagement/ServiceManagement.h>
#import <EventKit/EKEventStore.h>
#import "VCSettings.h"
#import "MZDateCalc.h"
#import "MZTextField.h"
#import "MZAboutBox.h"
#import "NSDate+Tools.h"


#define DATE_FORMAT_DAY_FULL            @"eeee"
#define DATE_FORMAT_TIMEZONE_DAY        @"z ccc"
#define TIME_FORMAT_NORMAL              @"h:mm a"
#define TIME_FORMAT_NORMAL_FULL         @"h:mm:ss a"
#define TIME_FORMAT_MILITARY            @"HH:mm"
#define TIME_FORMAT_MILITARY_FULL       @"HH:mm:ss"

// window sizes
#define WINDOW_WIDTH_CALENDAR           306
#define WINDOW_HEIGHT                   266
#define WINDOW_HEIGHT_TOOLBAR           284
#define CLOCK_WIDTH                     146
#define CLOCK_HEIGHT                    214
#define CALENDAR_WIDTH                  290
#define CALENDAR_HEIGTH                 214


@interface MZVistaClockAppDelegate : NSObject <NSApplicationDelegate>
{
    // status item controls
    NSStatusItem* statusItem;
    MZStatusItemView* statusItemView;
    IBOutlet NSMenu* statusMenu;
    NSString* statusItemFormat;
    
    // clocks
    IBOutlet NSCollectionView *clockCollectionView;
	IBOutlet NSArrayController *clockArrayController;
	NSMutableArray* clockCollectionArray;
    
    // calendar
    IBOutlet MZCalendarControl* mainCalendar;
    IBOutlet NSScrollView* clockScrollView;
    IBOutlet NSDatePicker* altcal;
    
    // timer
    NSTimer* timer;
    
    // settings
    VCSettings* settings;

    // toolbar
    BOOL showToolbar;
    BOOL toolBarChanged;
    IBOutlet NSTextField* titleLabel;
    IBOutlet MZTextField* gotoDateField;
    IBOutlet NSTextField* dayDetailLabel;
    IBOutlet NSMenuItem* autoHideMenuItem;

    // MISC
    NSInteger lastWeek;
    NSString* lastCal;
    NSDate* lastDate;
    bool darkMenu;
    EKEventStore* store;
    NSString* systemVersion;
    NSImage* dockClockImage;
}

@property (assign) IBOutlet NSWindow *vistaClockWindow;
@property (strong) MZVistaClockPreferences* prefsWindow;
@property (assign) IBOutlet NSMenuItem* timeNow;
@property (strong) MZAboutBox* abox;


// methods
-(void) fireTimer: NSTimer;
-(void) updateTime;
-(NSString*) getFuzzyTime:(NSDate*) now;
-(int) addClock;
-(void) removeClock;
-(void) resizeWindow;
-(CGFloat) titleBarHeight:(NSWindow*) window;
-(CGFloat) toolBarHeight:(NSWindow*) window;
-(NSString*) buildStatusItemDateFormatString;
-(void) createStatusItem;

-(IBAction) toggleVistaClockWindow:(id)sender;
-(IBAction) launchAboutBoxPanel:(id)sender;
-(IBAction) launchHelpPanel:(id)sender;
-(IBAction) launchDateTimePreferencePanel:(id)sender;
-(IBAction) openPreferences:(id)sender;
-(IBAction) toggleAutoHide:(id)sender;
-(void) setAutoHideMenutItem;


-(void) configureToolbar;
-(void) resetToolbar;


-(IBAction) gotoDate:(id)sender;
-(IBAction) goToday:(id)sender;


-(void) getCalendarAccess;
-(IBAction)launchCalendar:(id)sender;
-(IBAction)launchReminders:(id)sender;

-(NSString*) getCurrentCalendar;
-(bool) isCalendarChanged;
-(bool) isDarkMenu;

@end

// -----------------------------------------------------------------------------
// for hidden api
@interface NSStatusBar (NSStatusBar_Private)
-(id) _statusItemWithLength:(float)l withPriority:(int)p;
-(id) _insertStatusItem:(NSStatusItem*)i withPriority:(int)p;
@end
