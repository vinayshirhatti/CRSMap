//
//  CRSReactState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSReactState.h"
#import "UtilityFunctions.h"

#define kAlpha		2.5
#define kBeta		2.0

@implementation CRSReactState

- (void)stateAction;
{

	[[task dataDoc] putEvent:@"react"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:CRSRespTimeMSKey] -
                    [[task defaults] integerForKey:CRSTooFastMSKey]];
}

- (NSString *)name {

    return @"CRSReact";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {							// switched to idle
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if (![[task defaults] boolForKey:CRSFixateKey]) {
		eotCode = kMyEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	else {
		if (![fixWindow inWindowDeg:[task currentEyeDeg]]) {   // started a saccade
//			[[task dataDoc] putEvent:@"saccadeLaunched"]; 
			return [[task stateSystem] stateNamed:@"CRSSaccade"];
		}
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kMyEOTMissed;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
    return nil;
}

@end
