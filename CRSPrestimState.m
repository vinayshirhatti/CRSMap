//
//  CRSPrestimState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSPrestimState.h"

@implementation CRSPrestimState

- (void)stateAction;
{
	[stimuli setCueSpot:NO location:trial.attendLoc];
	[[task dataDoc] putEvent:@"preStimuli"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:CRSInterstimMSKey]];
}

- (NSString *)name {

    return @"CRSPrestim";
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
		return stateSystem->stimulate;
	}
	return nil;
}

@end
