//
//  CRSStarttrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSStarttrialState.h"
#import "UtilityFunctions.h"
#import "CRSDigitalOut.h"
#import "CRS.h"
#import "CRSUtilities.h"

@implementation CRSStarttrialState

- (void)stateAction;
{
	long lValue;
	FixWindowData fixWindowData, respWindowData;
	
	eotCode = -1;
    trialCounter++;
	
// Prepare structures describing the fixation and response windows;
	
	fixWindowData.index = [[task eyeCalibrator] nextCalibrationPosition];
	[[task synthDataDevice] setOffsetDeg:[[task eyeCalibrator] calibrationOffsetPointDeg]];			// keep synth data on offset fixation

// fixWindow is not being updated

	fixWindowData.windowDeg = [fixWindow rectDeg];
    fixWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:fixWindowData.windowDeg];
    [fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:CRSFixWindowWidthDegKey]];

	[respWindow setAzimuthDeg:[[stimuli taskGabor] azimuthDeg] elevationDeg:[[stimuli taskGabor] elevationDeg]];
	[respWindow setWidthAndHeightDeg:[[task defaults] floatForKey:CRSRespWindowWidthDegKey]];
	respWindowData.index = 0;
	respWindowData.windowDeg = [respWindow rectDeg];
	respWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:respWindowData.windowDeg];

// Stop data collection before this block of events, and force all the data to be readcollectorTimer
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
	[[task dataController] readDataFromDevices];		// flush data buffers
	[[task collectorTimer] fire];
	[[task dataDoc] putEvent:@"trialStart" withData:&trialCounter];
//    [digitalOut outputEvent:kTrialStartDigitOutCode withData:trialCounter];
    [digitalOut outputEventName:@"trialStart" withData:trialCounter];
    [[task dataDoc] putEvent:@"trial" withData:&trial];
    [digitalOut outputEventName:@"instructTrial" withData:(long)trial.instructTrial];
	[digitalOut outputEventName:@"catchTrial" withData:(long)trial.catchTrial];
	lValue = 0;
	[[task dataDoc] putEvent:@"sampleZero" withData:&lValue];	// for now, it has no practical functions
	[[task dataDoc] putEvent:@"spikeZero" withData:&lValue];
	
// Restart data collection immediately after declaring the zerotimes

    [[task dataController] setDataEnabled:[NSNumber numberWithBool:YES]];
	//[[task dataDoc] putEvent:@"eyeCalibration" withData:[[task eyeCalibrator] calibrationData]];
    [[task dataDoc] putEvent:@"eyeLeftCalibration" withData:[[task eyeCalibrator] calibrationDataForEye:kLeftEye]];
	[[task dataDoc] putEvent:@"eyeRightCalibration" withData:[[task eyeCalibrator] calibrationDataForEye:kRightEye]];

	[[task dataDoc] putEvent:@"eyeWindow" withData:&fixWindowData];
	[[task dataDoc] putEvent:@"responseWindow" withData:&respWindowData];
    
    // [Vinay] - iff this is the first trial then send the protocolNumber as a digital code.
    // 'trialCounter' gets reset only at the beginning or whenever you press 'RESET'. So whenever a new protocol is run, it is mandatory to press RESET as well
    if (trialCounter == 1) { // first trial
        [digitalOut outputEventName:@"protocolNumber" withData:(long)[[task defaults] integerForKey:@"CRSProtocolNumber"]];
        //NSLog(@"trial number %ld , protocol number is %ld", trialCounter, [[task defaults] integerForKey:@"CRSProtocolNumber"]);
        int protocolNumber = [[task defaults] integerForKey:@"CRSProtocolNumber"]; // This variable reads the value of the protocol number
        [[task dataDoc] putEvent:@"protocolNumber" withData:&protocolNumber];
    }
}

- (NSString *)name {

    return @"CRSStarttrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return  [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([[task defaults] boolForKey:CRSFixateKey] && [CRSUtilities inWindow:fixWindow]) {
		return [[task stateSystem] stateNamed:@"CRSBlocked"];
	}
	else {
		return [[task stateSystem] stateNamed:@"CRSFixon"];
	} 
}

@end
