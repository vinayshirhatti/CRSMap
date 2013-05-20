//
//  CRSFixateState.m
//  CRSMap
//
//  CRSPreCueState.m
//	Created by John Maunsell on 2/25/06.
//	modified from CRSPreCueState.m by Incheol Kang on 12/8/06
//
//  Copyright 2006. All rights reserved.
//

#import "CRSFixateState.h"


@implementation CRSFixateState

- (void)stateAction {
	long fixDurBase, fixJitterMS;
	long fixateMS = [[task defaults] integerForKey:CRSFixateMSKey];
	long fixJitterPC = [[task defaults] integerForKey:CRSFixJitterPCKey];
		
	if ([[task defaults] boolForKey:CRSFixateKey]) {				// fixation required && fixated
		[[task dataDoc] putEvent:@"fixate"];
		[scheduler schedule:@selector(updateCalibration) toTarget:self withObject:nil
				delayMS:fixateMS * 0.8];
		if ([[task defaults] boolForKey:CRSDoSoundsKey]) {
			[[NSSound soundNamed:kFixateSound] play];
		}
	}
	
	if (fixJitterPC > 0){
		fixJitterMS = round((fixateMS * fixJitterPC) / 100.0);
		fixDurBase = fixateMS - fixJitterMS;
		fixateMS = fixDurBase + (rand() % (2 * fixJitterMS + 1));
	}
	
	expireTime = [LLSystemUtil timeFromNow:fixateMS];
}

- (NSString *)name {

    return @"CRSFixate";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([[task defaults] boolForKey:CRSFixateKey] && ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kMyEOTBroke;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"CRSStimulate"];
	}
	return nil;
}

- (void)updateCalibration;
{
	if ([fixWindow inWindowDeg:[task currentEyeDeg]]) {
		[[task eyeCalibrator] updateCalibration:[task currentEyeDeg]];
	}
}


@end
