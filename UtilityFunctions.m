//
//  UtilityFunctions.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRS.h"
#import "CRSMap.h"
#import "UtilityFunctions.h"

//#define kC50Squared			0.0225
#define kC50Squared			0.09
#define kDrivenRate			100.0
#define kSpontRate			5.0


void announceEvents(void) {

    long lValue;
    MapSettings settings;
	char *idString = "CRSMap Version 1.0";
	
 	[[task dataDoc] putEvent:@"text" withData:idString lengthBytes:strlen(idString)];

	[[task dataDoc] putEvent:@"blockStatus" withData:&blockStatus];
	[[task dataDoc] putEvent:@"mappingBlockStatus" withData:&mappingBlockStatus];
	[[task dataDoc] putEvent:@"behaviorSetting" withData:(Ptr)getBehaviorSetting()];
	[[task dataDoc] putEvent:@"stimSetting" withData:(Ptr)getStimSetting()];
	[[task dataDoc] putEvent:@"taskGabor" withData:(Ptr)[[stimuli taskGabor] gaborData]];
	[[task dataDoc] putEvent:@"mappingGabor0" withData:(Ptr)[[stimuli mappingGabor0] gaborData]];
	[[task dataDoc] putEvent:@"mappingGabor1" withData:(Ptr)[[stimuli mappingGabor1] gaborData]];
    [[task dataDoc] putEvent:@"mappingGabor2" withData:(Ptr)[[stimuli mappingGabor2] gaborData]];   // [Vinay] - Added for the 3rd gabor - centre gabor
    [[(CRSMap *)task mapStimTable0] updateBlockParameters:0]; // [Vinay] - added arguement '0'
    settings = [[(CRSMap *)task mapStimTable0] mapSettings];
    [[task dataDoc] putEvent:@"map0Settings" withData:&settings];
    [[(CRSMap *)task mapStimTable1] updateBlockParameters:1]; // [Vinay] - added arguement '1'
    settings = [[(CRSMap *)task mapStimTable1] mapSettings];
    [[task dataDoc] putEvent:@"map1Settings" withData:&settings];
    [[(CRSMap *)task mapStimTable2] updateBlockParameters:2];         // [Vinay] - for centre gabor // [Vinay] - added arguement '2'
    settings = [[(CRSMap *)task mapStimTable2] mapSettings];
    [[task dataDoc] putEvent:@"map2Settings" withData:&settings];

    lValue = [[task defaults] integerForKey:CRSStimDurationMSKey];
	[[task dataDoc] putEvent:@"stimDurationMS" withData:&lValue];
    lValue = [[task defaults] integerForKey:CRSInterstimMSKey];
	[[task dataDoc] putEvent:@"interstimMS" withData:&lValue];
    lValue = [[task defaults] integerForKey:CRSMapStimDurationMSKey];
	[[task dataDoc] putEvent:@"mapStimDurationMS" withData:&lValue];
    lValue = [[task defaults] integerForKey:CRSMapInterstimDurationMSKey];
	[[task dataDoc] putEvent:@"mapInterstimDurationMS" withData:&lValue];
    lValue = [[task defaults] integerForKey:CRSRespTimeMSKey];
	[[task dataDoc] putEvent:@"responseTimeMS" withData:&lValue];
	lValue = [[task defaults] integerForKey:CRSMaxTargetMSKey];
	[[task dataDoc] putEvent:@"maxTargetTimeMS" withData:(void *)&lValue];
	lValue = [[task defaults] integerForKey:CRSMinTargetMSKey];
	[[task dataDoc] putEvent:@"minTargetTimeMS" withData:(void *)&lValue];
}

void requestReset(void) {

    if ([task mode] == kTaskIdle) {
        reset();
    }
    else {
        resetFlag = YES;
    }
}

void reset(void) {

    long resetType = 0;
    
	[[task dataDoc] putEvent:@"reset" withData:&resetType];
}

float spikeRateFromStimValue(float normalizedValue) {

	double vSquared;
	
	vSquared = normalizedValue * normalizedValue;
	return kDrivenRate *  vSquared / (vSquared + kC50Squared) + kSpontRate;
}

// Return the number of stimulus repetitions in a block (kLocations * repsPerBlock * contrasts)  

void updateCatchTrialPC(void) {

	float lambda, catchTrialMaxPC;
	float minTargetS, meanTargetS, maxTargetS, meanRateHz;
	long stimulusMS, interstimMS;

	stimulusMS = [[task defaults] integerForKey:CRSStimDurationMSKey]; 
	interstimMS = [[task defaults] integerForKey:CRSInterstimMSKey];
	meanRateHz = 1000.0 / (stimulusMS + interstimMS);
	minTargetS = [[task defaults] integerForKey:CRSMinTargetMSKey] / 1000.0;
	meanTargetS = [[task defaults] integerForKey:CRSMeanTargetMSKey] / 1000.0;

	lambda = log(2.0) / (meanTargetS - minTargetS + 0.5 / meanRateHz);
	maxTargetS = [[task defaults] integerForKey:CRSMaxTargetMSKey] / 1000.0 - minTargetS + 1.0 / meanRateHz;
	catchTrialMaxPC = exp(-lambda * maxTargetS) *100.0;
	
	[[task defaults] setFloat:catchTrialMaxPC forKey:CRSCatchTrialMaxPCKey];
	
	if ([[task defaults] floatForKey:CRSCatchTrialPCKey] > catchTrialMaxPC)
		[[task defaults] setFloat:catchTrialMaxPC forKey:CRSCatchTrialPCKey];
	
}

BehaviorSetting *getBehaviorSetting(void) {

	static BehaviorSetting behaviorSetting;
	
	behaviorSetting.blocks =  [[task defaults] integerForKey:CRSBlockLimitKey];
	behaviorSetting.intertrialMS =  [[task defaults] integerForKey:CRSIntertrialMSKey];
	behaviorSetting.acquireMS =  [[task defaults] integerForKey:CRSAcquireMSKey];
	behaviorSetting.fixGraceMS = [[task defaults] integerForKey:CRSFixGraceMSKey];
	behaviorSetting.fixateMS = [[task defaults] integerForKey:CRSFixateMSKey];
	behaviorSetting.fixateJitterPC = [[task defaults] integerForKey:CRSFixJitterPCKey];
	behaviorSetting.responseTimeMS = [[task defaults] integerForKey:CRSRespTimeMSKey];
	behaviorSetting.tooFastMS = [[task defaults] integerForKey:CRSTooFastMSKey];
	behaviorSetting.minSaccadeDurMS = [[task defaults] integerForKey:CRSSaccadeTimeMSKey];
	behaviorSetting.breakPunishMS = [[task defaults] integerForKey:CRSBreakPunishMSKey];
	behaviorSetting.rewardSchedule = [[task defaults] integerForKey:CRSRewardScheduleKey];
	behaviorSetting.rewardMS = [[task defaults] integerForKey:CRSRewardMSKey];
	behaviorSetting.fixWinWidthDeg = [[task defaults] floatForKey:CRSFixWindowWidthDegKey];
	behaviorSetting.respWinWidthDeg = [[task defaults] floatForKey:CRSRespWindowWidthDegKey];
	
	return &behaviorSetting;
}


StimSetting *getStimSetting(void) {

	static StimSetting stimSetting;
	
	stimSetting.stimDurationMS =  [[task defaults] integerForKey:CRSStimDurationMSKey];
	stimSetting.stimDurJitterPC =  [[task defaults] integerForKey:CRSStimJitterPCKey];
	stimSetting.interStimMS =  [[task defaults] integerForKey:CRSInterstimMSKey];
	stimSetting.interStimJitterPC = [[task defaults] integerForKey:CRSInterstimJitterPCKey];
	stimSetting.stimDistribution =  [[task defaults] integerForKey:CRSStimDistributionKey];
	stimSetting.minTargetOnTimeMS = [[task defaults] integerForKey:CRSMinTargetMSKey];
	stimSetting.meanTargetOnTimeMS = [[task defaults] integerForKey:CRSMeanTargetMSKey];
	stimSetting.maxTargetOnTimeMS = [[task defaults] integerForKey:CRSMaxTargetMSKey];
	stimSetting.changeScale =  [[task defaults] integerForKey:CRSChangeScaleKey];
	stimSetting.orientationChanges =  [[task defaults] integerForKey:CRSOrientationChangesKey];
	stimSetting.maxChangeDeg =  [[task defaults] floatForKey:CRSMaxDirChangeDegKey];
	stimSetting.minChangeDeg =  [[task defaults] floatForKey:CRSMinDirChangeDegKey];
	stimSetting.changeRemains =  [[task defaults] boolForKey:CRSChangeRemainKey];
	
	return &stimSetting;
}



// used in randUnitInterval()
#define kIA					16807
#define kIM					2147483647
#define kAM					(1.0 / kIM)
#define kIQ					127773
#define kIR					2836
#define kNTAB				32
#define kNDIV				(1 + (kIM - 1) / kNTAB)
#define kEPS				1.2e-7
#define kRNMX				(1.0 - kEPS)

float randUnitInterval(long *idum) {

	int j;
	long k;
	static long iy = 0;
	static long iv[kNTAB];
	float temp;	
	
	if (*idum <= 0 || !iy) {
		if (-(*idum) < 1)
			*idum = 1;
		else *idum = -(*idum);
		
		for (j = kNTAB + 7; j >= 0; j--) {
			k = (*idum) / kIQ;
			*idum = kIA * (*idum - k * kIQ) - kIR * k;
			if (*idum < 0)
				*idum += kIM;
			if (j < kNTAB)
				iv[j] = *idum;		
		}
		iy = iv[0];	
	}
	k = (*idum) / kIQ;
	*idum = kIA * (*idum - k * kIQ) - kIR *k;
	
	if (*idum < 0)
		*idum += kIM;	
	j = iy / kNDIV;
	iy = iv[j];
	iv[j] = *idum;
	
	temp = kAM * iy;

	if (temp > kRNMX)
		return kRNMX;
	else
		return temp;
}
	

// Get the parameters from user defaults that control what trials are displayed in a block, and put them
// into a structure.

void updateBlockStatus(void)
{
	long index;
	NSArray *changeArray;
	NSDictionary *entryDict;
	
	blockStatus.changes = [[task defaults] integerForKey:CRSOrientationChangesKey];
	blockStatus.instructTrials = [[task defaults] integerForKey:CRSInstructionTrialsKey];
	blockStatus.blockLimit = [[task defaults] integerForKey:CRSBlockLimitKey];
	changeArray = [[task defaults] arrayForKey:CRSChangeArrayKey];
	for (index = 0; index < blockStatus.changes; index++) {
		entryDict = [changeArray objectAtIndex:index];
		(blockStatus.orientationChangeDeg)[index] = [[entryDict valueForKey:CRSChangeKey] floatValue];
		blockStatus.validReps[index] = [[entryDict valueForKey:CRSValidRepsKey] longValue];
		blockStatus.invalidReps[index] = [[entryDict valueForKey:CRSInvalidRepsKey] longValue];
	}
}


