//
//  CRSCueState.m
//  OrientationChange
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "CRSCueState.h"

@implementation CRSCueState

- (void)stateAction;
{
	cueMS = [[task defaults] integerForKey:CRSCueMSKey];
	if (cueMS > 0) {
		[stimuli setCueSpot:YES location:trial.attendLoc];
		expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:CRSCueMSKey]];
		if ([[task defaults] boolForKey:CRSDoSoundsKey]) {
			[[NSSound soundNamed:kFixOnSound] play];
		}
		[[task dataDoc] putEvent:@"cueOn"];
	}
}

- (NSString *)name {

    return @"CRSCue";
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
	if (cueMS <= 0 || [LLSystemUtil timeIsPast:expireTime]) {
		return stateSystem->prestim;
	}
	else {
		return nil;
    }
}

@end
