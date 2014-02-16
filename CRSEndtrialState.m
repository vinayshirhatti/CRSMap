//
//  CRSEndtrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//
#import "CRSMap.h"
#import "CRSEndtrialState.h"
#import "UtilityFunctions.h"
#import "CRSDigitalOut.h"

#define kMinRewardMS	10
#define kMinTrials		4

@implementation CRSEndtrialState

- (long)juiceMS;
{
	return [[task defaults] integerForKey:CRSRewardMSKey];
}

- (void)stateAction {

	long trialCertify;
	long longValue = 0;
	long codeTranslation[kMyEOTTypes] = {kEOTCorrect, kEOTFailed, kEOTWrong, kEOTWrong, kEOTBroke, 
					kEOTIgnored, kEOTQuit};
	
	[stimuli stopAllStimuli];
	[[task dataDoc] putEvent:@"stimulusOff" withData:&longValue];

// Put our trial end code, then tranlate it into something that everyone else will understand.

	[[task dataDoc] putEvent:@"myTrialEnd" withData:(void *)&eotCode];
	eotCode = codeTranslation[eotCode];
	
// The computer may have failed to create the display correctly.  We check that now
// If the computer failed, the monkey will still get rewarded for correct trial,
// but the trial will be done over.  Other computer checks can be added here.

	trialCertify = 0;
	if (![[stimuli monitor] success]) {
		trialCertify |= (0x1 << kCertifyVideoBit);
	}
	expireTime = [LLSystemUtil timeFromNow:0];					// no delay, except for breaks (below)
	switch (eotCode) {
	case kEOTFailed:
		if (trial.catchTrial == YES) {
			[task performSelector:@selector(doJuice:) withObject:self];
		}
		else {
			if ([[task defaults] boolForKey:CRSDoSoundsKey]) {
				[[NSSound soundNamed:kNotCorrectSound] play];
			}
            /* Do not update anything
			if (trialCertify == 0) {
				if (trial.instructTrial) {
					blockStatus.instructDone++;
				}
				else {
					blockStatus.validRepsDone[trial.orientationChangeIndex]++;
				}
			} */
		}
		break;
	case kEOTCorrect:
		[task performSelector:@selector(doJuice:) withObject:self];
		if (trial.instructTrial) {
			blockStatus.instructDone++;
		}
		else  {
            if ((!trial.catchTrial) || ([[task defaults] boolForKey:CRSIncludeCatchTrialsinDoneListKey])) { // update if it is not a catch trial or if CRSIncludeCatchTrialsinDoneList is set to YES
                blockStatus.validRepsDone[trial.orientationChangeIndex]++;
                [[(CRSMap *)task mapStimTable0] tallyStimList:nil upToFrame:[stimuli targetOnFrame]];
                [[(CRSMap *)task mapStimTable1] tallyStimList:nil upToFrame:[stimuli targetOnFrame]];
                [[(CRSMap *)task mapStimTable2] tallyStimList:nil upToFrame:[stimuli targetOnFrame]]; // Added by Vinay - for the centre gabor
                mappingBlockStatus =  [[(CRSMap *)task mapStimTable0] mappingBlockStatus];
            }
        }
		//mappingBlockStatus.trialsDone = [[(CRSMap *)task mapStimTable0] trialDoneInBlock];
		//mappingBlockStatus.blocksDone = [[(CRSMap *)task mapStimTable0] blocksDone];
		//NSLog(@"endTrial: mappingBlock trials done %d blocksDone %d blockLimit %d",
		//			mappingBlockStatus.trialsDone, mappingBlockStatus.blocksDone, mappingBlockStatus.blockLimit); 
		break;
	case kEOTBroke:
		if (brokeDuringStim) {
			expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:CRSBreakPunishMSKey]];
		}
		// Fall through
	case kEOTWrong:
	default:
		if ([[task defaults] boolForKey:CRSDoSoundsKey]) {
			[[NSSound soundNamed:kNotCorrectSound] play];
		}
		break;
	}	
	[[task dataDoc] putEvent:@"trialCertify" withData:(void *)&trialCertify];
    [digitalOut outputEventName:@"trialCertify" withData:(long)(trialCertify)];
	[[task dataDoc] putEvent:@"trialEnd" withData:(void *)&eotCode];
    [digitalOut outputEventName:@"trialEnd" withData:(long)(eotCode)];
	[[task synthDataDevice] setSpikeRateHz:spikeRateFromStimValue(0.0) atTime:[LLSystemUtil getTimeS]];
    [[task synthDataDevice] setEyeTargetOff];
    [[task synthDataDevice] doLeverUp];
	if (resetFlag) {
		reset();
        resetFlag = NO;
	}
    if ([task mode] == kTaskStopping) {						// Requested to stop
        [task setMode:kTaskIdle];
	}
}

- (NSString *)name;
{
    return @"Endtrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		return [[task stateSystem] stateNamed:@"CRSIdle"];
    }
	else if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"CRSIntertrial"];
	}
	else {
		return nil;
	}
}

@end
