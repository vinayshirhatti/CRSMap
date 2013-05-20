//
//  CRSFixGraceState.m
//  CRSMap
//
//  Copyright 2006. All rights reserved.
//

#import "CRSFixGraceState.h"


@implementation CRSFixGraceState

- (void)stateAction;
{
	[[task dataDoc] putEvent:@"fixGrace"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:CRSFixGraceMSKey]];
	if ([[task defaults] boolForKey:CRSDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name;
{
    return @"CRSFixGrace";
}

- (LLState *)nextState;
{
	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		if ([fixWindow inWindowDeg:[task currentEyeDeg]])  {
			return [[task stateSystem] stateNamed:@"CRSFixate"];
		}
		else {
			eotCode = kMyEOTIgnored;
			return [[task stateSystem] stateNamed:@"Endtrial"];;
		}
	}
	else {
		return nil;
    }
}

@end
