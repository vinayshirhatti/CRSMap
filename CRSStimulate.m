//
//  CRSStimulate.m
//  CRSMap
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSStimulate.h" 
#import "CRSUtilities.h"

@implementation CRSStimulate

- (void)stateAction;
{
	[stimuli startStimSequence];
}

- (NSString *)name {

    return @"CRSStimulate";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([stimuli targetPresented]) {
		if ([[task defaults] boolForKey: CRSFixateOnlyKey]) {
			eotCode = kMyEOTCorrect;
			return [[task stateSystem] stateNamed:@"Endtrial"];		
		}
		return [[task stateSystem] stateNamed:@"CRSTooFast"];
	}
	if ([[task defaults] boolForKey:CRSFixateKey] && ![CRSUtilities inWindow:fixWindow]) {
		eotCode = kMyEOTBroke;
		return [[task stateSystem] stateNamed:@"CRSSaccade"];;
	}
	if (![stimuli stimulusOn]) {
		eotCode = kMyEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
    return nil;
}


@end
