//
//  CRSStateSystem.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRS.h"

#define		kFixOnSound				@"6C"
#define		kFixateSound			@"7G"
#define		kStimOnSound			@"5C"
#define		kStimOffSound			@"5C"
#define 	kCorrectSound			@"Correct"
#define 	kNotCorrectSound		@"NotCorrect"

extern long					eotCode;			// End Of Trial code
extern LLEyeWindow			*fixWindow;
extern LLScheduleController *scheduler;
extern LLEyeWindow			*respWindow;
extern TrialDesc			trial;

@interface CRSStateSystem : LLStateSystem {

}

@end

