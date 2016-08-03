//
//  CRSSaccadeState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSSaccadeState.h"
#import "CRSUtilities.h"
#import "CRSDigitalOut.h"

@implementation CRSSaccadeState

- (void)stateAction {

	bool useFewDigitalCodes;
    
    useFewDigitalCodes = [[task defaults] boolForKey:CRSUseFewDigitalCodesKey];
    
    [[task dataDoc] putEvent:@"saccade"];
//    [digitalOut outputEvent:kSaccadeDigitOutCode withData:(kSaccadeDigitOutCode+1)];
    if (useFewDigitalCodes)
        [digitalOut outputEvent:kSaccadeDigitOutCode sleepInMicrosec:kSleepInMicrosec];
    else
        [digitalOut outputEventName:@"saccade" withData:0.0];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:CRSSaccadeTimeMSKey]];
}

- (NSString *)name {

    return @"CRSSaccade";
}

- (LLState *)nextState;
{
	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if (eotCode == kMyEOTBroke) {				// got here by leaving fixWindow early (from stimulate)
		if ([CRSUtilities inWindow:respWindow])  {
			eotCode = kMyEOTEarlyToValid;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
		if ([LLSystemUtil timeIsPast:expireTime]) {
			eotCode = kMyEOTBroke;
			brokeDuringStim = YES;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
	}
	else {
		if ([CRSUtilities inWindow:respWindow])  {
			eotCode = kMyEOTCorrect;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
		if ([LLSystemUtil timeIsPast:expireTime]) {
			eotCode = kMyEOTMissed;
			return [[task stateSystem] stateNamed:@"Endtrial"];
		}
	}
    return nil;
}

@end
