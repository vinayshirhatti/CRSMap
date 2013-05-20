//
//  CRSFixonState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSFixonState.h"
#import "CRSDigitalOut.h"

@implementation CRSFixonState

- (void)stateAction {

    [stimuli setFixSpot:YES];
	[[task dataDoc] putEvent:@"fixOn"];
    [digitalOut outputEventName:@"fixOn" withData:0x0000];
    [[task synthDataDevice] setEyeTargetOn:NSMakePoint(0, 0)];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:CRSAcquireMSKey]];
	if ([[task defaults] boolForKey:CRSDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name {

    return @"CRSFixon";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if (![[task defaults] boolForKey:CRSFixateKey]) { 
		return [[task stateSystem] stateNamed:@"CRSFixate"];
    }
	else if ([fixWindow inWindowDeg:[task currentEyeDeg]])  {
		return [[task stateSystem] stateNamed:@"CRSFixGrace"];
    }
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kMyEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	else {
		return nil;
    }
}

@end
