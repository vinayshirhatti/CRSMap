//
//  CRSSaccadeState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSSaccadeState.h"
#import "CRSDigitalOut.h"

@implementation CRSSaccadeState

- (void)stateAction {

	[[task dataDoc] putEvent:@"saccade"];
    [digitalOut outputEventName:@"saccade" withData:0x0000];
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
		if ([respWindow inWindowDeg:[task currentEyeDeg]])  {
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
		if ([respWindow inWindowDeg:[task currentEyeDeg]])  {
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
