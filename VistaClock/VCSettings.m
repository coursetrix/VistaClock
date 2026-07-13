//
//  Settings.m
//  VistaClock
//
//  Created by Paul Wong on 9/12/14.
//  Copyright (c) 2026 Mazookie, LLC. All rights reserved.
//

#import "VCSettings.h"

#define insist(e) if(!(e)) [NSException raise: @"assertion failed." format: @"%@:%d (%s)", [[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lastPathComponent], __LINE__, #e]

static VCSettings* sharedSettings = nil;

@implementation VCSettings

// other shared things
@synthesize needsDisplay, floatRight, clockConfigs;

// general panel options
@synthesize useAutoLaunch, useAutoHide, useKeepTop, useShadows, showDockIcon
    , useLargeFonts;

// status item options
@synthesize useFuzzyTime, showWeekNumberIcon, useBWWeekIcon, showStatusSeconds
    , useStatusMilitary, showStatusAMPM, showStatusWeekDay, showDate
    , showStatusFullMonth, showStatusSecondaryTime, statusSecondaryTimezone, showTime
    , showDateTime, useBWIcon, useInverseTitle, showMonth;

// clock panel options
@synthesize useMilitary, clockFaceName;

// calendar options
@synthesize showCalendar, showWeekNumbers, showEvents, showReminders
    , showCalendarBoxes, useHiliteColor;


-(void) archive
{
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self requiringSecureCoding:NO error:&error];
    if (error) {
        NSLog(@"Failed to archive VCSettings: %@", error);
        return;
    }
    NSURL *url = [NSURL fileURLWithPath:[VCSettings archivePath]];
    BOOL success = [data writeToURL:url options:NSDataWritingAtomic error:&error];
    if (!success || error) {
        NSLog(@"Failed to write VCSettings to disk: %@", error);
    }
} // end archive


+(NSString*) archivePath
{
    NSArray*paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory
        , NSUserDomainMask, YES);
    insist(paths && [paths count]);
    NSString* programName = [NSString stringWithFormat:@"%@.cfg",
        [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleNameKey]
    ];
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:programName];
} // end archivePath


-(void) initTransient
{
    // set up new arrays
} // end initTransient


+(VCSettings*) sharedSettings
{
    if (sharedSettings == nil)
    {
        // get saved
        NSFileManager*fileManager = [NSFileManager defaultManager];
        insist(fileManager);
        
        if ([fileManager fileExistsAtPath:[VCSettings archivePath]])
        {
            NSData *data = [NSData dataWithContentsOfFile:[VCSettings archivePath]];
            NSError *unarchiveError = nil;
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:data error:&unarchiveError];
            if (unarchiver) {
                unarchiver.requiresSecureCoding = NO;
                sharedSettings = [unarchiver decodeObjectForKey:NSKeyedArchiveRootObjectKey];
                [unarchiver finishDecoding];
            }
            if (unarchiveError || sharedSettings == nil) {
                NSLog(@"Failed to unarchive VCSettings: %@", unarchiveError);
            } else {
                [sharedSettings initTransient];
                return sharedSettings;
            }
        }
        
        // alloc new one and init it
        sharedSettings = [[super allocWithZone:NULL] init];
    }
    
    return sharedSettings;
} // end sharedSettings


-(id)initWithCoder:(NSCoder*) decoder
{
    insist(decoder);
    self = [super init];
    insist(self);
    
    // decode
    // others
    floatRight = [decoder decodeBoolForKey:@"floatRight"];

    // clock panel options
    useAutoLaunch = [decoder decodeBoolForKey:@"useAutoLaunch"];
    useAutoHide = [decoder decodeBoolForKey:@"useAutoHide"];
    useKeepTop = [decoder decodeBoolForKey:@"useKeepTop"];
    useShadows = [decoder decodeBoolForKey:@"useShadows"];
    useLargeFonts = [decoder decodeBoolForKey:@"useLargeFonts"];
    showDockIcon = [decoder decodeBoolForKey:@"showDockIcon"];
    
    // status item options
    showDateTime = [decoder decodeBoolForKey:@"showDateTime"];
    useBWIcon = [decoder decodeBoolForKey:@"useBWIcon"];
    showWeekNumberIcon = [decoder decodeBoolForKey:@"showWeekNumberIcon"];
    useBWWeekIcon = [decoder decodeBoolForKey:@"useBWWeekIcon"];
    useInverseTitle = [decoder decodeBoolForKey:@"useInverseTitle"];
    useFuzzyTime = [decoder decodeBoolForKey:@"useFuzzyTime"];

    showDate = [decoder decodeBoolForKey:@"showDate"];
    showMonth = [decoder decodeBoolForKey:@"showMonth"];
    showStatusFullMonth = [decoder decodeBoolForKey:@"showStatusFullMonth"];
    showStatusWeekDay = [decoder decodeBoolForKey:@"showStatusWeekDay"];

    showTime = [decoder decodeBoolForKey:@"showTime"];
    showStatusSeconds = [decoder decodeBoolForKey:@"showStatusSeconds"];
    useStatusMilitary = [decoder decodeBoolForKey:@"useStatusMilitary"];
    showStatusAMPM = [decoder decodeBoolForKey:@"showStatusAMPM"];
    showStatusSecondaryTime = [decoder decodeBoolForKey:@"showStatusSecondaryTime"];
    statusSecondaryTimezone = [decoder decodeObjectForKey:@"statusSecondaryTimezone"];

    // clock panel options
    useMilitary = [decoder decodeBoolForKey:@"useMilitary"];
    clockFaceName = [decoder decodeObjectForKey:@"clockFace"];
    clockConfigs = [[decoder decodeObjectForKey:@"clockConfigs"] mutableCopy];
    
    // calendar options
    showCalendar = [decoder decodeBoolForKey:@"showCalendar"];
    showWeekNumbers = [decoder decodeBoolForKey:@"showWeekNumbers"];
    showEvents = [decoder decodeBoolForKey:@"showEvents"];
    showReminders = [decoder decodeBoolForKey:@"showReminders"];
    showCalendarBoxes = [decoder decodeBoolForKey:@"showCalendarBoxes"];
    useHiliteColor = [decoder decodeBoolForKey:@"useHiliteColor"];
    
    needsDisplay = YES;

    return self;
} // end initWithCoder


-(void) encodeWithCoder:(NSCoder*) encoder
{
    insist(encoder);
    
    // encode
    // others
    [encoder encodeBool:floatRight forKey:@"floatRight"];
    
    // clock configs array
    [encoder encodeObject:clockConfigs forKey:@"clockConfigs"];
    
    // general panel options
    [encoder encodeBool:useAutoLaunch forKey:@"useAutoLaunch"];
    [encoder encodeBool:useAutoHide forKey:@"useAutoHide"];
    [encoder encodeBool:useKeepTop forKey:@"useKeepTop"];
    [encoder encodeBool:useInverseTitle forKey:@"useInverseTitle"];

    [encoder encodeBool:useShadows forKey:@"useShadows"];
    [encoder encodeBool:useLargeFonts forKey:@"useLargeFonts"];
    [encoder encodeBool:showDockIcon forKey:@"showDockIcon"];

    
    // status item options
    [encoder encodeBool:showDateTime forKey:@"showDateTime"];
    [encoder encodeBool:useBWIcon forKey:@"useBWIcon"];
    [encoder encodeBool:showWeekNumberIcon forKey:@"showWeekNumberIcon"];
    [encoder encodeBool:useBWWeekIcon forKey:@"useBWWeekIcon"];
    [encoder encodeBool:useFuzzyTime forKey:@"useFuzzyTime"];

    [encoder encodeBool:showDate forKey:@"showDate"];
    [encoder encodeBool:showMonth forKey:@"showMonth"];
    [encoder encodeBool:showStatusFullMonth forKey:@"showStatusFullMonth"];
    [encoder encodeBool:showStatusWeekDay forKey:@"showStatusWeekDay"];


    [encoder encodeBool:showTime forKey:@"showTime"];
    [encoder encodeBool:showStatusSeconds forKey:@"showStatusSeconds"];
    [encoder encodeBool:useStatusMilitary forKey:@"useStatusMilitary"];
    [encoder encodeBool:showStatusAMPM forKey:@"showStatusAMPM"];
    [encoder encodeBool:showStatusSecondaryTime forKey:@"showStatusSecondaryTime"];
    [encoder encodeObject:statusSecondaryTimezone forKey:@"statusSecondaryTimezone"];


    // clock options
    [encoder encodeBool:useMilitary forKey:@"useMilitary"];
    [encoder encodeObject:clockFaceName forKey:@"clockFace"];

    // calendar options
    [encoder encodeBool:showCalendar forKey:@"showCalendar"];
    [encoder encodeBool:showWeekNumbers forKey:@"showWeekNumbers"];
    [encoder encodeBool:showEvents forKey:@"showEvents"];
    [encoder encodeBool:showReminders forKey:@"showReminders"];
    [encoder encodeBool:showCalendarBoxes forKey:@"showCalendarBoxes"];
    [encoder encodeBool:useHiliteColor forKey:@"useHiliteColor"];

} // end encodeWithCoder


-(void) reset
{
    // other shared things
    needsDisplay = YES;
    floatRight = NO;


    // clock panel options
    useAutoLaunch = NO;
    useAutoHide = YES;
    useKeepTop = NO;
    useShadows = YES;
    useLargeFonts = NO;
    showDockIcon = NO;
    useInverseTitle = NO;

    // status item options
    showDateTime = YES;
    useBWIcon = NO;
    showWeekNumberIcon = YES;
    useBWWeekIcon = NO;
    useFuzzyTime = NO;

    showDate = YES;
    showMonth = YES;
    showStatusFullMonth = NO;
    showStatusWeekDay = NO;

    showTime = YES;
    showStatusSeconds = NO;
    useStatusMilitary = NO;
    showStatusAMPM = YES;
    showStatusSecondaryTime = NO;
    statusSecondaryTimezone = @"GMT";
 
    // calendar options
    showCalendar = YES;
    showWeekNumbers = NO;
    showEvents = NO;
    showReminders = NO;
    showCalendarBoxes = NO;
    useHiliteColor = NO;

    // clock options
    useMilitary = NO;
    clockFaceName = @"VCB01.png";

    // clock configs
    MZClockConfig* config = [[MZClockConfig alloc] init];
    config.title = @"Portland, OR";
    config.timezoneName = @"America/Los_Angeles";
    config.useSeconds = YES;
    if (clockConfigs == nil)
    {
        clockConfigs = [[NSMutableArray alloc] initWithObjects:config, nil];
    }
    else
    {
        [clockConfigs removeAllObjects];
        [clockConfigs addObject:config];
    }
    
    needsDisplay = TRUE;
} // end reset


// call this only when no archived file exist
- (id) init
{
    self = [super init];
    insist(self);
    
    // build stuff that doesn't get archived
    [self initTransient];
    
    [self reset];

    return self;
} // end init


- (id) copyWithZone:(NSZone*)zone
{
    needsDisplay = TRUE;
    return self;
} // end copyWithZone


@end
