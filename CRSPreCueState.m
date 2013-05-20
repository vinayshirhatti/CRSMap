//
//  CRSPreCueState.m
//  OrientationChange
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "CRSPreCueState.h"


@implementation CRSPreCueState

- (void)stateAction {

	long preCueMS = [[task defaults] integerForKey:CRSPrecueMSKey];
		
	if ([[task defaults] boolForKey:CRSFixateKey]) {				// fixation required && fixated
		[[task dataDoc] putEvent:@"fixate"];
		[scheduler schedule:@selector(updateCalibration) toTarget:self withObject:nil
				delayMS:preCueMS * 0.8];
		if ([[task defaults] boolForKey:CRSDoSoundsKey]) {
			[[NSSound soundNamed:kFixateSound] play];
		}
	}
	expireTime = [LLSystemUtil timeFromNow:preCueMS];
}

- (NSString *)name {

    return @"CRSPrecue";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return stateSystem->endtrial;
	}
	if ([[task defaults] boolForKey:CRSFixateKey] && ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		return stateSystem->endtrial;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return stateSystem->cue;
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
