//
//  CRSBlockedState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSBlockedState.h"

@implementation CRSBlockedState

- (void)stateAction {

	[[task dataDoc] putEvent:@"blocked"];
//	schedule(&bNode, (PSCHED)&blockedTones, PRISYS - 1, 400, -1, NULL);
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:CRSAcquireMSKey]];
}

- (NSString *)name {

    return @"CRSBlocked";
}

- (LLState *)nextState {

	if (![[task defaults] boolForKey:CRSFixateKey] || ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		return [[task stateSystem] stateNamed:@"CRSFixon"];
    }
	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kMyEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
    return nil; 
}

@end
