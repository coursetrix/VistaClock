//
//  Settings.h
//  VistaClock
//
//  Created by Paul Wong on 9/12/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MZClockConfig.h"

@interface VCSettings : NSObject

// other settings
@property (nonatomic, assign) BOOL needsDisplay;
@property (nonatomic, assign) BOOL floatRight;

// general panel settings
@property (nonatomic, assign) BOOL useAutoLaunch;
@property (nonatomic, assign) BOOL useAutoHide;
@property (nonatomic, assign) BOOL useKeepTop;
@property (nonatomic, assign) BOOL useShadows;
@property (nonatomic, assign) BOOL useLargeFonts;
@property (nonatomic, assign) BOOL showDockIcon;

// menubar panel settings
@property (nonatomic, assign) BOOL showDateTime;
@property (nonatomic, assign) BOOL useBWIcon;
@property (nonatomic, assign) BOOL showWeekNumberIcon;
@property (nonatomic, assign) BOOL useBWWeekIcon;
@property (nonatomic, assign) BOOL useInverseTitle;
@property (nonatomic, assign) BOOL useFuzzyTime;

@property (nonatomic, assign) BOOL showDate;
@property (nonatomic, assign) BOOL showMonth;
@property (nonatomic, assign) BOOL showStatusFullMonth;
@property (nonatomic, assign) BOOL showStatusWeekDay;

@property (nonatomic, assign) BOOL showTime;
@property (nonatomic, assign) BOOL showStatusSeconds;
@property (nonatomic, assign) BOOL useStatusMilitary;
@property (nonatomic, assign) BOOL showStatusAMPM;
@property (nonatomic, assign) BOOL showStatusSecondaryTime;
@property (nonatomic, retain) NSString* statusSecondaryTimezone;

// clock settings
@property (nonatomic, assign) BOOL useMilitary;
@property (nonatomic, retain) NSString* clockFaceName;
@property (nonatomic, retain) NSMutableArray* clockConfigs;

// calendar settings
@property (nonatomic, assign) BOOL showCalendar;
@property (nonatomic, assign) BOOL showWeekNumbers;
@property (nonatomic, assign) BOOL showEvents;
@property (nonatomic, assign) BOOL showReminders;
@property (nonatomic, assign) BOOL showCalendarBoxes;
@property (nonatomic, assign) BOOL useHiliteColor;


+(VCSettings*) sharedSettings;
-(void) archive;
-(void) reset;

@end
