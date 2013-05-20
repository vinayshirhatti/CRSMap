//
//  CRSIntertrialState.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSStateSystem.h"

@interface CRSIntertrialState : LLState {

	NSTimeInterval	expireTime;
}

- (BOOL)selectTrial;

@end
