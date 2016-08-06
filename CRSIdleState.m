//
//  CRSIdleState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSIdleState.h"

@implementation CRSIdleState

- (void)stateAction;
{
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
    [[task dataController] stopDevice];
	blockStatus.instructDone = 0;					// do new instructions trials on restart
}

- (NSString *)name {

    return @"CRSIdle";
}

- (LLState *)nextState {

	if ([task mode] == kTaskEnding) {
		return [[task stateSystem] stateNamed:@"CRSStop"];
    }
	if ([task mode] != kTaskIdle) {
		return [[task stateSystem] stateNamed:@"CRSIntertrial"];
    }
	else {
        return nil;
    }
}

@end
