//
//  CRSTooFastState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSTooFastState.h"
#import "UtilityFunctions.h"

#define alpha		2.5
#define kBeta		2.0

@implementation CRSTooFastState

- (void)stateAction;
{
	float prob100;
	int tooFastMS;
	LLGabor *gabor;
	
	[[task dataDoc] putEvent:@"tooFast"];
	tooFastMS =  [[task defaults] integerForKey:CRSTooFastMSKey];
	expireTime = [LLSystemUtil timeFromNow:tooFastMS];
					
// Here we instruct the fake monkey to respond, using appropriate psychophysics.

	prob100 = 100.0 - 50.0 * exp(-exp(log(trial.orientationChangeDeg / alpha) * kBeta));
	if ((rand() % 100) < prob100) {
		gabor = [stimuli taskGabor];
		[[task synthDataDevice] setEyeTargetOn:NSMakePoint([gabor azimuthDeg], [gabor elevationDeg])];
	}
}

- (NSString *)name {

    return @"CRSTooFast";
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
		if (![fixWindow inWindowDeg:[task currentEyeDeg]]) {   // too fast reaction
			eotCode = kMyEOTBroke;
			return [[task stateSystem] stateNamed:@"CRSSaccade"];;
		}
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"CRSReact"];
	}
    return nil;
}

@end
