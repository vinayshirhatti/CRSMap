//
//  CRSMap.m
//  CRSMap
//
//  Copyright 2006. All rights reserved.
//

#import "CRS.h"
#import "CRSMap.h"
#import "CRSSummaryController.h"
#import "CRSBehaviorController.h"
#import "CRSSpikeController.h"
#import "CRSXTController.h"
#import "UtilityFunctions.h"
#import "CRSStimuli.h"
#import "CRSMapStimTable.h"

#define		kRewardBit				0x0001

// Behavioral parameters

NSString *CRSAcquireMSKey = @"CRSAcquireMS";
NSString *CRSAlphaTargetDetectionTaskKey = @"CRSAlphaTargetDetectionTask";
NSString *CRSBlockLimitKey = @"CRSBlockLimit";
NSString *CRSBreakPunishMSKey = @"CRSBreakPunishMS";
NSString *CRSChangeScaleKey = @"CRSChangeScale";
NSString *CRSCatchTrialPCKey = @"CRSCatchTrialPC";
NSString *CRSCatchTrialMaxPCKey = @"CRSCatchTrialMaxPC";
NSString *CRSCueMSKey = @"CRSCueMS";
NSString *CRSDoSoundsKey = @"CRSDoSounds";
NSString *CRSFixateKey = @"CRSFixate";
NSString *CRSFixateMSKey = @"CRSFixateMS";
NSString *CRSFixateOnlyKey = @"CRSFixateOnly";
NSString *CRSFixGraceMSKey = @"CRSFixGraceMS";
NSString *CRSFixJitterPCKey = @"CRSFixJitterPC";
NSString *CRSFixWindowWidthDegKey = @"CRSFixWindowWidthDeg";
NSString *CRSInstructionTrialsKey = @"CRSInstructionTrials";
NSString *CRSIntertrialMSKey = @"CRSIntertrialMS";
NSString *CRSInvalidRewardFactorKey = @"CRSInvalidRewardFactor";
NSString *CRSMinTargetMSKey = @"CRSMinTargetMS";
NSString *CRSMaxTargetMSKey = @"CRSMaxTargetMS";
NSString *CRSMeanTargetMSKey = @"CRSMeanTargetMS";
NSString *CRSNontargetContrastPCKey = @"CRSNontargetContrastPC";
NSString *CRSRespSpotSizeDegKey = @"CRSRespSpotSizeDeg";
NSString *CRSRespTimeMSKey = @"CRSRespTimeMS";
NSString *CRSRespWindowWidthDegKey = @"CRSRespWindowWidthDeg";
NSString *CRSRewardMSKey = @"CRSRewardMS";
NSString *CRSMinRewardMSKey = @"CRSMinRewardMS";
NSString *CRSRandTaskGaborDirectionKey = @"CRSRandTaskGaborDirection";
NSString *CRSRewardScheduleKey = @"CRSRewardSchedule";
NSString *CRSSaccadeTimeMSKey = @"CRSSaccadeTimeMS";
NSString *CRSStimRepsPerBlockKey = @"CRSStimRepsPerBlock";
NSString *CRSStimDistributionKey = @"CRSStimDistribution";
NSString *CRSTaskStatusKey = @"CRSTaskStatus";
NSString *CRSTooFastMSKey = @"CRSTooFastMS";

// Stimulus Parameters

NSString *CRSInterstimJitterPCKey = @"CRSInterstimJitterPC";
NSString *CRSInterstimMSKey = @"CRSInterstimMS";
NSString *CRSMapInterstimDurationMSKey = @"CRSMapInterstimDurationMS";
NSString *CRSMappingBlocksKey = @"CRSMappingBlocks";
NSString *CRSMapStimDurationMSKey = @"CRSMapStimDurationMS";
NSString *CRSStimDurationMSKey = @"CRSStimDurationMS";
NSString *CRSStimJitterPCKey = @"CRSStimJitterPC";
NSString *CRSOrientationChangesKey = @"CRSOrientationChanges";
NSString *CRSMaxDirChangeDegKey = @"CRSMaxDirChangeDeg";
NSString *CRSMinDirChangeDegKey = @"CRSMinDirChangeDeg";
NSString *CRSChangeRemainKey = @"CRSChangeRemain";
NSString *CRSChangeArrayKey = @"CRSChangeArray";
NSString *CRSStimTablesKey = @"CRSStimTables";
NSString *CRSStimTableCountsKey = @"CRSStimTableCounts";
NSString *CRSMapStimContrastPCKey = @"CRSMapStimContrastPC";
NSString *CRSMapStimRadiusSigmaRatioKey = @"CRSMapStimRadiusSigmaRatio";
NSString *CRSTargetAlphaKey = @"CRSTargetAlpha";
NSString *CRSTargetRadiusKey = @"CRSTargetRadius";

// [Vinay] - have replaced the L and R keys with C,R,S keys
//NSString *CRSHideLeftKey = @"CRSHideLeft";
//NSString *CRSHideRightKey = @"CRSHideRight";
//NSString *CRSHideLeftDigitalKey = @"CRSHideLeftDigital";
//NSString *CRSHideRightDigitalKey = @"CRSHideRightDigital";

NSString *CRSHideCentreKey = @"CRSHideCentre";
NSString *CRSHideRingKey = @"CRSHideRing";
NSString *CRSHideSurroundKey = @"CRSHideSurround";
NSString *CRSHideCentreDigitalKey = @"CRSHideCentreDigital";
NSString *CRSHideRingDigitalKey = @"CRSHideRingDigital";
NSString *CRSHideSurroundDigitalKey = @"CRSHideSurroundDigital";

// [Vinay] - till here

NSString *CRSConvertToGratingKey = @"CRSConvertToGrating";
NSString *CRSUseSingleITC18Key = @"CRSUseSingleITC18";

NSString *CRSHideTaskGaborKey = @"CRSHideTaskGabor";
NSString *CRSIncludeCatchTrialsinDoneListKey = @"CRSIncludeCatchTrialsinDoneList";
NSString *CRSMapTemporalModulationKey = @"CRSMapTemporalModulation";

// Visual Stimulus Parameters 

NSString *CRSSpatialPhaseDegKey = @"CRSSpatialPhaseDeg";            // [Vinay] - This was commented. I have uncommented it
NSString *CRSTemporalFreqHzKey = @"CRSTemporalFreqHz";              // [Vinay] - This was commented. I have uncommented it

// [Vinay] - added the following for protocol related keys

NSString *CRSMatchCentreSurroundKey = @"CRSMatchCentreSurround"; // [Vinay] - whenever one wants to match the centre and surround properties
/*
NSString *CRSRingProtocolKey = @"CRSRingProtocol";
NSString *CRSContrastRingProtocolKey = @"CRSContrastRingProtocol";
NSString *CRSDualContrastProtocolKey = @"CRSDualContrastProtocol";
NSString *CRSDualOrientationProtocolKey = @"CRSDualOrientationProtocol";
NSString *CRSDualPhaseProtocolKey = @"CRSDualPhaseProtocol";
*/ // [Vinay] - have commented these, since there aren't required
// [Vinay] - Exploring defining the protocol selection as a pop down menu, so that each is selected exclusively
NSString *CRSProtocolNumberKey = @"CRSProtocolNumber";

// [Vinay] Adding other matching options now
NSString *CRSMatchCentreRingKey = @"CRSMatchCentreRing";
NSString *CRSMatchRingSurroundKey = @"CRSMatchRingSurround";

// [Vinay] Adding an option of showing an image centrally
NSString *CRSFixImageKey = @"CRSFixImage";

// [Vinay] - to decide the mapping method for radius
NSString *CRSMapRadiusMappingCentreKey = @"CRSMapRadiusMappingCentre";
NSString *CRSMapRadiusMappingRingKey = @"CRSMapRadiusMappingRing";
NSString *CRSMapRadiusMappingSurroundKey = @"CRSMapRadiusMappingSurround";


// [Vinay] - to decide the mapping method for contrast
NSString *CRSMapContrastMappingCentreKey = @"CRSMapContrastMappingCentre";
NSString *CRSMapContrastMappingRingKey = @"CRSMapContrastMappingRing";
NSString *CRSMapContrastMappingSurroundKey = @"CRSMapContrastMappingSurround";

// [Vinay] - to decide the mapping method for SF
NSString *CRSMapSFMappingCentreKey = @"CRSMapSFMappingCentre";
NSString *CRSMapSFMappingRingKey = @"CRSMapSFMappingRing";
NSString *CRSMapSFMappingSurroundKey = @"CRSMapSFMappingSurround";

// [Vinay] - to decide the mapping method for TF
NSString *CRSMapTFMappingCentreKey = @"CRSMapTFMappingCentre";
NSString *CRSMapTFMappingRingKey = @"CRSMapTFMappingRing";
NSString *CRSMapTFMappingSurroundKey = @"CRSMapTFMappingSurround";


// [Vinay] - till here

// Keys for change array

NSString *CRSChangeKey = @"change";
NSString *CRSValidRepsKey = @"validReps";
NSString *CRSInvalidRepsKey = @"invalidReps";

NSString *keyPaths[] = {@"values.CRSBlockLimit", @"values.CRSRespTimeMS", 
					@"values.CRSStimTableCounts", @"values.CRSStimTables",
					@"values.CRSStimDurationMS", @"values.CRSMapStimDurationMS", @"values.CRSMapInterstimDurationMS", 
					@"values.CRSInterstimMS", @"values.CRSOrientationChanges", @"values.CRSMappingBlocks",
					@"values.CRSMinDirChangeDeg", @"values.CRSMaxDirChangeDeg", @"values.CRSStimRepsPerBlock",
					@"values.CRSMinTargetMS", @"values.CRSMaxTargetMS", @"values.CRSChangeArray",
					@"values.CRSChangeScale", @"values.CRSMeanTargetMS", @"values.CRSFixateMS",
					@"values.CRSMapStimRadiusSigmaRatio",@"values.CRSHideTaskGabor",@"values.CRSHideCentre",@"values.CRSHideRing",@"values.CRSHideSurround",
                    @"values.CRSMatchCentreSurround",@"values.CRSMatchCentreRing",@"values.CRSMatchRingSurround",@"values.CRSFixImage",
					nil}; // [Vinay] - have added the last 2 lines before nil - related to matching C and S and the protocol
// [Vinay] - Later removed. Added @"values.CRSMatchCentreRing",@"values.CRSMatchRingSurround",
//"values.CRSMatchCentreRing",@"values.CRSMatchRingSurround",@"values.CRSRingProtocol",@"values.CRSContrastRingProtocol",@"values.CRSDualContrastProtocol",@"values.CRSDualOrientationProtocol",@"values.CRSDualPhaseProtocol",
// and kept only @"values.CRSMatchCentreSurround"
// and replaced Left and right keys - @"values.CRSHideLeft",@"values.CRSHideRight" - with @"values.CRSHideCentre",@"values.CRSHideRing",@"values.CRSHideSurround",
// Added - @"values.CRSFixImage",

LLScheduleController	*scheduler = nil;
CRSStimuli				*stimuli = nil;
CRSDigitalOut			*digitalOut = nil;

LLDataDef gaborStructDef[] = kLLGaborEventDesc;
LLDataDef fixWindowStructDef[] = kLLEyeWindowEventDesc;

LLDataDef blockStatusDef[] = {
	{@"long",	@"changes", 1, offsetof(BlockStatus, changes)},
	{@"float",	@"orientationChangeDeg", kMaxOriChanges, offsetof(BlockStatus, orientationChangeDeg)},
	{@"long",	@"validReps", kMaxOriChanges, offsetof(BlockStatus, validReps)},
	{@"long",	@"validRepsDone", kMaxOriChanges, offsetof(BlockStatus, validRepsDone)},
	{@"long",	@"invalidReps", kMaxOriChanges, offsetof(BlockStatus, invalidReps)},
	{@"long",	@"invalidRepsDone", kMaxOriChanges, offsetof(BlockStatus, invalidRepsDone)},
	{@"long",	@"instructDone", 1, offsetof(BlockStatus, instructDone)},
	{@"long",	@"instructTrials", 1, offsetof(BlockStatus, instructTrials)},
	{@"long",	@"sidesDone", 1, offsetof(BlockStatus, sidesDone)},
	{@"long",	@"blockLimit", 1, offsetof(BlockStatus, blockLimit)},
	{@"long",	@"blocksDone", 1, offsetof(BlockStatus, blocksDone)},
	{nil}};

LLDataDef mappingBlockStatusDef[] = {
	{@"long",	@"stimDone", 1, offsetof(MappingBlockStatus, stimDone)},
	{@"long",	@"stimLimit", 1, offsetof(MappingBlockStatus, stimLimit)},
	{@"long",	@"blocksDone", 1, offsetof(MappingBlockStatus, blocksDone)},
	{@"long",	@"blockLimit", 1, offsetof(MappingBlockStatus, blockLimit)},
	{nil}};

LLDataDef stimDescDef[] = {
	{@"long",	@"gaborIndex", 1, offsetof(StimDesc, gaborIndex)},
	{@"long",	@"sequenceIndex", 1, offsetof(StimDesc, sequenceIndex)},
	{@"long",	@"stimOnFrame", 1, offsetof(StimDesc, stimOnFrame)},
	{@"long",	@"stimOffFrame", 1, offsetof(StimDesc, stimOffFrame)},
	{@"short",	@"stimType", 1, offsetof(StimDesc, stimType)},
	{@"float",	@"orientationChangeDeg", 1, offsetof(StimDesc, orientationChangeDeg)},
	{@"float",	@"contrastPC", 1, offsetof(StimDesc, contrastPC)},
	{@"float",	@"azimuthDeg", 1, offsetof(StimDesc, azimuthDeg)},
	{@"float",	@"elevationDeg", 1, offsetof(StimDesc, elevationDeg)},
	{@"float",	@"sigmaDeg", 1, offsetof(StimDesc, sigmaDeg)},
    {@"float",	@"radiusDeg", 1, offsetof(StimDesc, radiusDeg)},                          // [Vinay] - for the added parameter
	{@"float",	@"spatialFreqCPD", 1, offsetof(StimDesc, spatialFreqCPD)},
	{@"float",	@"directionDeg", 1, offsetof(StimDesc, directionDeg)},
    {@"float",	@"temporalFreqHz", 1, offsetof(StimDesc, temporalFreqHz)},
    {@"float",	@"spatialPhaseDeg", 1, offsetof(StimDesc, spatialPhaseDeg)},                          // [Vinay] - for the added parameter
	{@"long",	@"azimuthIndex", 1, offsetof(StimDesc, azimuthIndex)},
	{@"long",	@"elevationIndex", 1, offsetof(StimDesc, elevationIndex)},
	{@"long",	@"sigmaIndex", 1, offsetof(StimDesc, sigmaIndex)},
	{@"long",	@"spatialFreqIndex", 1, offsetof(StimDesc, spatialFreqIndex)},
	{@"long",	@"directionIndex", 1, offsetof(StimDesc, directionIndex)},
	{@"long",	@"contrastIndex", 1, offsetof(StimDesc, contrastIndex)},
	{@"long",	@"temporalFreqIndex", 1, offsetof(StimDesc, temporalFreqIndex)},
    {@"long",	@"temporalModulation", 1, offsetof(StimDesc, temporalModulation)},
    {@"long",	@"radiusIndex", 1, offsetof(StimDesc, radiusIndex)},                    // [Vinay] - for the added parameter
    {@"long",	@"spatialPhaseIndex", 1, offsetof(StimDesc, spatialPhaseIndex)},                      // [Vinay] - for the added parameter
    {nil}};

LLDataDef trialDescDef[] = {
	{@"boolean",@"instructTrial", 1, offsetof(TrialDesc, instructTrial)},
	{@"boolean",@"catchTrial", 1, offsetof(TrialDesc, catchTrial)},
	{@"long",	@"numStim", 1, offsetof(TrialDesc, numStim)},
	{@"long",	@"targetIndex", 1, offsetof(TrialDesc, targetIndex)},
	{@"long",	@"targetOnTimeMS", 1, offsetof(TrialDesc, targetOnTimeMS)},
	{@"long",	@"orientationChangeIndex", 1, offsetof(TrialDesc, orientationChangeIndex)},
	{@"float",	@"orientationChangeDeg", 1, offsetof(TrialDesc, orientationChangeDeg)},
	{nil}};

LLDataDef behaviorSettingDef[] = {
	{@"long",	@"blocks", 1, offsetof(BehaviorSetting, blocks)},
	{@"long",	@"intertrialMS", 1, offsetof(BehaviorSetting, intertrialMS)},
	{@"long",	@"acquireMS", 1, offsetof(BehaviorSetting, acquireMS)},
	{@"long",	@"fixGraceMS", 1, offsetof(BehaviorSetting, fixGraceMS)},
	{@"long",	@"fixateMS", 1, offsetof(BehaviorSetting, fixateMS)},
	{@"long",	@"fixateJitterPC", 1, offsetof(BehaviorSetting, fixateJitterPC)},
	{@"long",	@"responseTimeMS", 1, offsetof(BehaviorSetting, responseTimeMS)},
	{@"long",	@"tooFastMS", 1, offsetof(BehaviorSetting, tooFastMS)},
	{@"long",	@"minSaccadeDurMS", 1, offsetof(BehaviorSetting, minSaccadeDurMS)},
	{@"long",	@"breakPunishMS", 1, offsetof(BehaviorSetting, breakPunishMS)},
	{@"long",	@"rewardSchedule", 1, offsetof(BehaviorSetting, rewardSchedule)},
	{@"long",	@"rewardMS", 1, offsetof(BehaviorSetting, rewardMS)},
	{@"float",	@"fixWinWidthDeg", 1, offsetof(BehaviorSetting, fixWinWidthDeg)},
	{@"float",	@"respWinWidthDeg", 1, offsetof(BehaviorSetting, respWinWidthDeg)},
	{nil}};

LLDataDef stimSettingDef[] = {
	{@"long",	@"stimDurationMS", 1, offsetof(StimSetting, stimDurationMS)},
	{@"long",	@"stimDurJitterPC", 1, offsetof(StimSetting, stimDurJitterPC)},
	{@"long",	@"interStimMS", 1, offsetof(StimSetting, interStimMS)},
	{@"long",	@"interStimJitterPC", 1, offsetof(StimSetting, interStimJitterPC)},
	{@"long",	@"stimLeadMS", 1, offsetof(StimSetting, stimLeadMS)},
	{@"float",	@"stimSpeedHz", 1, offsetof(StimSetting, stimSpeedHz)},
	{@"long",	@"stimDistribution", 1, offsetof(StimSetting, stimDistribution)},
	{@"long",	@"minTargetOnTimeMS", 1, offsetof(StimSetting, minTargetOnTimeMS)},
	{@"long",	@"meanTargetOnTimeMS", 1, offsetof(StimSetting, meanTargetOnTimeMS)},
	{@"long",	@"maxTargetOnTimeMS", 1, offsetof(StimSetting, maxTargetOnTimeMS)},
	{@"float",	@"eccentricityDeg", 1, offsetof(StimSetting, eccentricityDeg)},
	{@"float",	@"polarAngleDeg", 1, offsetof(StimSetting, polarAngleDeg)},
	{@"float",	@"driftDirectionDeg", 1, offsetof(StimSetting, driftDirectionDeg)},
	{@"float",	@"contrastPC", 1, offsetof(StimSetting, contrastPC)},
	{@"short",	@"numberOfSurrounds", 1, offsetof(StimSetting, numberOfSurrounds)}, // [Vinay] - what's this?. check!
	{@"long",	@"changeScale", 1, offsetof(StimSetting, changeScale)},
	{@"long",	@"orientationChanges", 1, offsetof(StimSetting, orientationChanges)},
	{@"float",	@"maxChangeDeg", 1, offsetof(StimSetting, maxChangeDeg)},
	{@"float",	@"minChangeDeg", 1, offsetof(StimSetting, minChangeDeg)},
	{@"long",	@"changeRemains", 1, offsetof(StimSetting, changeRemains)},
	{nil}};

LLDataDef mapParamsDef[] = {
    {@"long",	@"n", 1, offsetof(MapParams, n)},
    {@"float",	@"minValue", 1, offsetof(MapParams, minValue)},
    {@"float",	@"maxValue", 1, offsetof(MapParams, maxValue)},
    {nil}};

LLDataDef mapSettingsDef[] = {
	{@"struct",	@"azimuthDeg", 1, offsetof(MapSettings, azimuthDeg), sizeof(MapParams), mapParamsDef},
	{@"struct",	@"elevationDeg", 1, offsetof(MapSettings, elevationDeg), sizeof(MapParams), mapParamsDef},
	{@"struct",	@"directionDeg", 1, offsetof(MapSettings, directionDeg), sizeof(MapParams), mapParamsDef},
	{@"struct",	@"spatialFreqCPD", 1, offsetof(MapSettings, spatialFreqCPD), sizeof(MapParams), mapParamsDef},
	{@"struct",	@"sigmaDeg", 1, offsetof(MapSettings, sigmaDeg), sizeof(MapParams), mapParamsDef},
	{@"struct",	@"contrastPC", 1, offsetof(MapSettings, contrastPC), sizeof(MapParams), mapParamsDef},
	{@"struct",	@"temporalFreqHz", 1, offsetof(MapSettings, temporalFreqHz), sizeof(MapParams), mapParamsDef},
    {@"struct",	@"radiusDeg", 1, offsetof(MapSettings, radiusDeg), sizeof(MapParams), mapParamsDef},            // [Vinay] - for the added parameter
    {@"struct",	@"spatialPhaseDeg", 1, offsetof(MapSettings, spatialPhaseDeg), sizeof(MapParams), mapParamsDef},              // [Vinay] - for the added parameter
    {nil}};
	
//DataAssignment eyeXDataAssignment = {@"eyeXData",	@"Synthetic", 0, 5.0};	
//DataAssignment eyeYDataAssignment = {@"eyeYData",	@"Synthetic", 1, 5.0};

DataAssignment eyeRXDataAssignment = {@"eyeRXData",     @"Synthetic", 2, 5.0};
DataAssignment eyeRYDataAssignment = {@"eyeRYData",     @"Synthetic", 3, 5.0};
DataAssignment eyeRPDataAssignment = {@"eyeRPData",     @"Synthetic", 4, 5.0};
DataAssignment eyeLXDataAssignment = {@"eyeLXData",     @"Synthetic", 5, 5.0};
DataAssignment eyeLYDataAssignment = {@"eyeLYData",     @"Synthetic", 6, 5.0};
DataAssignment eyeLPDataAssignment = {@"eyeLPData",     @"Synthetic", 7, 5.0};

DataAssignment spike0Assignment =   {@"spike0",     @"Synthetic", 2, 1};
DataAssignment spike1Assignment =   {@"spike1",     @"Synthetic", 3, 1};
DataAssignment VBLDataAssignment =  {@"VBLData",	@"Synthetic", 1, 1};

	
EventDefinition CRSEvents[] = {
    // recorded at start of file, these need to be announced using announceEvents() in UtilityFunctions.m
	{@"taskGabor",			sizeof(Gabor),			{@"struct", @"taskGabor", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"mappingGabor0",		sizeof(Gabor),			{@"struct", @"mappingGabor0", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"mappingGabor1",		sizeof(Gabor),			{@"struct", @"mappingGabor1", 1, 0, sizeof(Gabor), gaborStructDef}},
    {@"mappingGabor2",		sizeof(Gabor),			{@"struct", @"mappingGabor2", 1, 0, sizeof(Gabor), gaborStructDef}},                        // [Vinay] - for the centre gabor
	{@"behaviorSetting",	sizeof(BehaviorSetting),{@"struct", @"behaviorSetting", 1, 0, sizeof(BehaviorSetting), behaviorSettingDef}},
	{@"stimSetting",		sizeof(StimSetting),	{@"struct", @"stimSetting", 1, 0, sizeof(StimSetting), stimSettingDef}},
	{@"map0Settings",		sizeof(MapSettings),    {@"struct", @"mapSettings", 1, 0, sizeof(MapSettings), mapSettingsDef}},
	{@"map1Settings",		sizeof(MapSettings),    {@"struct", @"mapSettings", 1, 0, sizeof(MapSettings), mapSettingsDef}},
    {@"map2Settings",		sizeof(MapSettings),    {@"struct", @"mapSettings", 1, 0, sizeof(MapSettings), mapSettingsDef}},                    // [Vinay] - for the centre gabor
	{@"eccentricityDeg",	sizeof(float),			{@"float"}},
	{@"polarAngleDeg",		sizeof(float),			{@"float"}},

    // timing parameters
	{@"stimDurationMS",		sizeof(long),			{@"long"}},
	{@"interstimMS",		sizeof(long),			{@"long"}},
	{@"mapStimDurationMS",	sizeof(long),			{@"long"}},
	{@"mapInterstimDurationMS",		sizeof(long),	{@"long"}},
	{@"stimLeadMS",			sizeof(long),			{@"long"}},
	{@"responseTimeMS",		sizeof(long),			{@"long"}},
	{@"fixateMS",			sizeof(long),			{@"long"}},
	{@"tooFastTimeMS",		sizeof(long),			{@"long"}},
	{@"blockStatus",		sizeof(BlockStatus),	{@"struct", @"blockStatus", 1, 0, sizeof(BlockStatus), blockStatusDef}},
	{@"mappingBlockStatus",	sizeof(MappingBlockStatus),	{@"struct", @"mappingBlockStatus", 1, 0, sizeof(MappingBlockStatus), mappingBlockStatusDef}},
	{@"meanTargetTimeMS",	sizeof(long),			{@"long"}},
	{@"minTargetTimeMS",	sizeof(long),			{@"long"}},
	{@"maxTargetTimeMS",	sizeof(long),			{@"long"}},

    // declared at start of each trial	
	{@"trial",				sizeof(TrialDesc),		{@"struct", @"trial", 1, 0, sizeof(TrialDesc), trialDescDef}},
	{@"responseWindow",		sizeof(FixWindowData),	{@"struct", @"responseWindowData", 1, 0, sizeof(FixWindowData), fixWindowStructDef}},

    // marking the course of each trial
	{@"preStimuli",			0,						{@"no data"}},
	{@"stimulus",			sizeof(StimDesc),		{@"struct", @"stimDesc", 1, 0, sizeof(StimDesc), stimDescDef}},
    {@"stimulusOffTime",	0,						{@"no data"}},
	{@"stimulusOnTime",		0,						{@"no data"}},
	{@"postStimuli",		0,						{@"no data"}},
	{@"saccade",			0,						{@"no data"}},
	{@"tooFast",			0,						{@"no data"}},
	{@"react",				0,						{@"no data"}},
	{@"fixGrace",			0,						{@"no data"}},
	{@"myTrialEnd",			sizeof(long),			{@"long"}},

	{@"taskMode", 			sizeof(long),			{@"long"}},
	{@"reset", 				sizeof(long),			{@"long"}}, 
};

BlockStatus			blockStatus;
MappingBlockStatus	mappingBlockStatus;
BOOL				brokeDuringStim;
LLTaskPlugIn		*task = nil;
long                trialCounter;


@implementation CRSMap

+ (NSInteger)version;
{
	return kLLPluginVersion;
}

// Start the method that will collect data from the event buffer

- (void)activate;
{ 
	long longValue;
	NSMenu *mainMenu;
	
	if (active) {
		return;
	}

    // Insert Actions and Settings menus into menu bar
	 
	mainMenu = [NSApp mainMenu];
	[mainMenu insertItem:actionsMenuItem atIndex:([mainMenu indexOfItemWithTitle:@"Tasks"] + 1)];
	[mainMenu insertItem:settingsMenuItem atIndex:([mainMenu indexOfItemWithTitle:@"Tasks"] + 1)];
    
    // Make sure that the task status is in the right state
    
    [taskStatus setMode:kTaskIdle];
    [taskStatus setDataFileOpen:NO];
		
    // Erase the stimulus display

	[stimuli erase];
	
	mapStimTable0 = [[CRSMapStimTable alloc] init];
	mapStimTable1 = [[CRSMapStimTable alloc] init];
    mapStimTable2 = [[CRSMapStimTable alloc] init];         // [Vinay] - for centre gabor
	
// Create on-line display windows

	
	[[controlPanel window] orderFront:self];
  
	behaviorController = [[CRSBehaviorController alloc] init];
    [dataDoc addObserver:behaviorController];

	spikeController = [[CRSSpikeController alloc] init];
    [dataDoc addObserver:spikeController];

    eyeXYController = [[CRSEyeXYController alloc] init];
    [dataDoc addObserver:eyeXYController];

    summaryController = [[CRSSummaryController alloc] init];
    [dataDoc addObserver:summaryController];
 
	xtController = [[CRSXTController alloc] init];
    [dataDoc addObserver:xtController];

// Set up data events (after setting up windows to receive them)

	[dataDoc defineEvents:[LLStandardDataEvents eventsWithDataDefs] count:[LLStandardDataEvents countOfEventsWithDataDefs]];
	[dataDoc defineEvents:CRSEvents count:(sizeof(CRSEvents) / sizeof(EventDefinition))];
	announceEvents();
	longValue = 0;
	[[task dataDoc] putEvent:@"reset" withData:&longValue];
	

// Set up the data collector to handle our data types

    [dataController assignSampleData:eyeRXDataAssignment];
	[dataController assignSampleData:eyeRYDataAssignment];
	[dataController assignSampleData:eyeRPDataAssignment];
	[dataController assignSampleData:eyeLXDataAssignment];
	[dataController assignSampleData:eyeLYDataAssignment];
	[dataController assignSampleData:eyeLPDataAssignment];
    
	[dataController assignTimestampData:spike0Assignment];
	[dataController assignTimestampData:spike1Assignment];
	[dataController assignTimestampData:VBLDataAssignment];
	[dataController assignDigitalInputDevice:@"Synthetic"];
	[dataController assignDigitalOutputDevice:@"Synthetic"];
    
    
	collectorTimer = [NSTimer scheduledTimerWithTimeInterval:0.004 target:self
			selector:@selector(dataCollect:) userInfo:nil repeats:YES];
	[dataDoc addObserver:stateSystem];
    [stateSystem startWithCheckIntervalMS:5];				// Start the experiment state system
	
	active = YES;
}

// The following function is called after the nib has finished loading.  It is the correct
// place to initialize nib related components, such as menus.

- (void)awakeFromNib;
{
	if (actionsMenuItem == nil) {
		actionsMenuItem = [[NSMenuItem alloc] init]; 
		[actionsMenu setTitle:@"Actions"];
		[actionsMenuItem setSubmenu:actionsMenu];
		[actionsMenuItem setEnabled:YES];
	}
	if (settingsMenuItem == nil) {
		settingsMenuItem = [[NSMenuItem alloc] init]; 
		[settingsMenu setTitle:@"Settings"];
		[settingsMenuItem setSubmenu:settingsMenu];
		[settingsMenuItem setEnabled:YES];
	}
}

- (void)dataCollect:(NSTimer *)timer;
{
    long spikeIndex, spikes;
    short *spikePtr;
	NSData *data;
    TimestampData spikeData;

//	if ((data = [dataController dataOfType:@"eyeXData"]) != nil) {
//		[dataDoc putEvent:@"eyeXData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
//		currentEyeUnits.x = *(short *)([data bytes] + [data length] - sizeof(short));
//	}
//	if ((data = [dataController dataOfType:@"eyeYData"]) != nil) {
//		[dataDoc putEvent:@"eyeYData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
//		currentEyeUnits.y = *(short *)([data bytes] + [data length] - sizeof(short));
//		currentEyeDeg = [eyeCalibrator degPointFromUnitPoint:currentEyeUnits];
//	}
    
    if ((data = [dataController dataOfType:@"eyeLXData"]) != nil) {
		[dataDoc putEvent:@"eyeLXData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyesUnits[kLeftEye].x = *(short *)([data bytes] + [data length] - sizeof(short));
	}
    
	if ((data = [dataController dataOfType:@"eyeLYData"]) != nil) {
        [dataDoc putEvent:@"eyeLYData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyesUnits[kLeftEye].y = *(short *)([data bytes] + [data length] - sizeof(short));
        currentEyesDeg[kLeftEye] = [eyeCalibrator degPointFromUnitPoint: currentEyesUnits[kLeftEye] forEye:kLeftEye];
        }
	if ((data = [dataController dataOfType:@"eyeLPData"]) != nil) {
		[dataDoc putEvent:@"eyeLPData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
	}
	if ((data = [dataController dataOfType:@"eyeRXData"]) != nil) {
		[dataDoc putEvent:@"eyeRXData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyesUnits[kRightEye].x = *(short *)([data bytes] + [data length] - sizeof(short));
	}
	if ((data = [dataController dataOfType:@"eyeRYData"]) != nil) {
		[dataDoc putEvent:@"eyeRYData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyesUnits[kRightEye].y = *(short *)([data bytes] + [data length] - sizeof(short));
		currentEyesDeg[kRightEye] = [eyeCalibrator degPointFromUnitPoint: currentEyesUnits[kRightEye] forEye:kRightEye];	}
	if ((data = [dataController dataOfType:@"eyeRPData"]) != nil) {
		[dataDoc putEvent:@"eyeRPData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
	}

    
    
	if ((data = [dataController dataOfType:@"VBLData"]) != nil) {
		[dataDoc putEvent:@"VBLData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
	}
	if ((data = [dataController dataOfType:@"spike0"]) != nil) {
        spikeData.channel = 0;
        spikes = [data length] / sizeof(short);
        spikePtr = (short *)[data bytes];
        for (spikeIndex = 0; spikeIndex < spikes; spikeIndex++) {
            spikeData.time = *spikePtr++;
            [dataDoc putEvent:@"spike" withData:(Ptr)&spikeData];
        }
	}
	if ((data = [dataController dataOfType:@"spike1"]) != nil) {
        spikeData.channel = 1;
        spikes = [data length] / sizeof(short);
        spikePtr = (short *)[data bytes];
        for (spikeIndex = 0; spikeIndex < spikes; spikeIndex++) {
            spikeData.time = *spikePtr++;
            [dataDoc putEvent:@"spike" withData:(Ptr)&spikeData];
        }
	}
}
	
// Stop data collection and shut down the plug in

- (void)deactivate:(id)sender;
{
	if (!active) {
		return;
	}
    [dataController setDataEnabled:[NSNumber numberWithBool:NO]];
    [stateSystem stop];
	[collectorTimer invalidate];
    [dataDoc removeObserver:stateSystem];
    [dataDoc removeObserver:behaviorController];
    [dataDoc removeObserver:spikeController];
    [dataDoc removeObserver:eyeXYController];
    [dataDoc removeObserver:summaryController];
    [dataDoc removeObserver:xtController];
	[dataDoc clearEventDefinitions];

// Remove Actions and Settings menus from menu bar
	 
	[[NSApp mainMenu] removeItem:settingsMenuItem];
	[[NSApp mainMenu] removeItem:actionsMenuItem];

// Release all the display windows

    [behaviorController close];
    [behaviorController release];
    [spikeController close];
    [spikeController release];
    [eyeXYController deactivate];			// requires a special call
    [eyeXYController release];
    [summaryController close];
    [summaryController release];
    [xtController close];
    [xtController release];
	[[controlPanel window] close];
	
	active = NO;
}

- (void)dealloc;
{
	long index;
 
	while ([stateSystem running]) {};		// wait for state system to stop, then release it
	
	for (index = 0; keyPaths[index] != nil; index++) {
		[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:keyPaths[index]];
	}
	[[NSNotificationCenter defaultCenter] removeObserver:self]; 

    [[task dataDoc] removeObserver:stateSystem];
    [stateSystem release];
	
	[actionsMenuItem release];
	[settingsMenuItem release];
	[scheduler release];
	[stimuli release];
	[mapStimTable0 release];
	[mapStimTable1 release];
    [mapStimTable2 release];            // [Vinay] - for centre gabor
	[digitalOut release];
	[controlPanel release];
	[taskStatus release];
    [topLevelObjects release];
	[super dealloc];
}

- (void)doControls:(NSNotification *)notification;
{
	if ([[notification name] isEqualToString:LLTaskModeButtonKey]) {
		[self doRunStop:self];
	}
	else if ([[notification name] isEqualToString:LLJuiceButtonKey]) {
		[self doJuice:self];
	}
	if ([[notification name] isEqualToString:LLResetButtonKey]) {
		[self doReset:self];
	}
}

- (IBAction)doFixSettings:(id)sender;
{
	[stimuli doFixSettings];
}

- (IBAction)doJuice:(id)sender;
{
	long juiceMS, rewardSchedule;
	long minTargetMS, maxTargetMS;
	long minRewardMS, maxRewardMS;
	long targetOnTimeMS;
	float alpha, beta;
	BOOL useSingleITC18;
    
	NSSound *juiceSound;
	
	if ([sender respondsToSelector:@selector(juiceMS)]) {
		juiceMS = (long)[sender performSelector:@selector(juiceMS)];
	}
	else {
		juiceMS = [[task defaults] integerForKey:CRSRewardMSKey];
	}

	rewardSchedule = [[task defaults] integerForKey:CRSRewardScheduleKey];

	if (rewardSchedule == kRewardVariable) {
		minTargetMS = [[task defaults] integerForKey:CRSMinTargetMSKey];
		maxTargetMS = [[task defaults] integerForKey:CRSMaxTargetMSKey];
		
		minRewardMS = [[task defaults] integerForKey:CRSMinRewardMSKey];;
		maxRewardMS = juiceMS * 2 - minRewardMS;
		
		alpha = (float)(minRewardMS - maxRewardMS) / (float)(minTargetMS - maxTargetMS);
		beta = minRewardMS - alpha * minTargetMS;
		targetOnTimeMS = trial.targetOnTimeMS;
		juiceMS = alpha * targetOnTimeMS + beta;
		juiceMS = abs(juiceMS);
	}
    
    useSingleITC18 = [[task defaults] boolForKey:CRSUseSingleITC18Key];
    
    if (useSingleITC18) {
        [[task dataController] digitalOutputBits:(0xffff-kRewardBit)];      // Works as long as kRewardBit is either 0x0001 or 0x0000
    }
    else {
        [[task dataController] digitalOutputBitsOff:kRewardBit];
    }
	
    [scheduler schedule:@selector(doJuiceOff) toTarget:self withObject:nil delayMS:juiceMS];
	if ([[task defaults] boolForKey:CRSDoSoundsKey]) {
		juiceSound = [NSSound soundNamed:@"Correct"];
		if ([juiceSound isPlaying]) {   // won't play again if it's still playing
			[juiceSound stop];
		}
		[juiceSound play];			// play juice sound
	}
}

- (void)doJuiceOff;
{
    BOOL useSingleITC18;
    useSingleITC18 = [[task defaults] boolForKey:CRSUseSingleITC18Key];
    
    if (useSingleITC18) {
        [[task dataController] digitalOutputBits:(0xfffe | kRewardBit)];    // Works as long as kRewardBit is either 0x0001 or 0x0000
    }
    else {
        [[task dataController] digitalOutputBitsOn:kRewardBit];
    }
}

- (IBAction)doReset:(id)sender;
{
    requestReset();
}

- (IBAction)doRFMap:(id)sender;
{
	[host performSelector:@selector(switchToTaskWithName:) withObject:@"RFMap"];
}

- (IBAction)doRunStop:(id)sender;
{
	long newMode;
	
    // [Vinay] - adding lines to read the protocol name and then send it via digital code whenever one hits the 'Run' button and starts the experiment
    //int protocolNumber = [[task defaults] integerForKey:@"CRSProtocolNumber"]; // This variable reads the value of the protocol number
    // NSString *protocolName; // to store the name
    // [ Vinay] - till here
    
    
    switch ([taskStatus mode]) {
    case kTaskIdle:
		newMode = kTaskRunning;
        //[digitalOut outputEventName:@"protocolNumber" withData:(long)(protocolNumber)]; //[Vinay] - send the protocol name via digital code
        break;
    case kTaskRunning:
		newMode = kTaskStopping;
        break;
    case kTaskStopping:
    default:
		newMode = kTaskIdle;
        break;
    }
	[self setMode:newMode];
}

- (IBAction)doTaskGaborSettings:(id)sender;
{
	[stimuli doGabor0Settings];
}

// After our -init is called, the host will provide essential pointers such as
// defaults, stimWindow, eyeCalibrator, etc.  Only aMSer those are initialized, the
// following method will be called.  We therefore defer most of our initialization here

- (void)initializationDidFinish;
{
	long index;
	NSString *userDefaultsValuesPath;
    NSDictionary *userDefaultsValuesDict;
	
	extern long argRand;
	
	task = self;
	
// Register our default settings. This should be done first thing, before the
// nib is loaded, because items in the nib are linked to defaults

	userDefaultsValuesPath = [[NSBundle bundleForClass:[self class]] 
						pathForResource:@"UserDefaults" ofType:@"plist"];
	userDefaultsValuesDict = [NSDictionary dictionaryWithContentsOfFile:userDefaultsValuesPath];
	[[task defaults] registerDefaults:userDefaultsValuesDict];
	[NSValueTransformer 
			setValueTransformer:[[[LLFactorToOctaveStepTransformer alloc] init] autorelease]
			forName:@"FactorToOctaveStepTransformer"];

	[NSValueTransformer 
			setValueTransformer:[[[CRSRoundToStimCycle alloc] init] autorelease]
			forName:@"RoundToStimCycle"];


// Set up to respond to changes to the values

	for (index = 0; keyPaths[index] != nil; index++) {
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:keyPaths[index]
				options:NSKeyValueObservingOptionNew context:nil];
	}
		
// Set up the task mode object.  We need to do this before loading the nib,
// because some items in the nib are bound to the task mode. We also need
// to set the mode, because the value in defaults will be the last entry made
// which is typically kTaskEnding.

	taskStatus = [[LLTaskStatus alloc] init];
	stimuli = [[CRSStimuli alloc] init];
	digitalOut = [[CRSDigitalOut alloc] init];

// Load the items in the nib

	[[NSBundle bundleForClass:[self class]] loadNibNamed:@"CRSMap" owner:self topLevelObjects:&topLevelObjects];
	[topLevelObjects retain];
	
// Initialize other task objects

	scheduler = [[LLScheduleController alloc] init];
	stateSystem = [[CRSStateSystem alloc] init];

// Set up control panel and observer for control panel

	controlPanel = [[LLControlPanel alloc] init];
	[controlPanel setWindowFrameAutosaveName:@"CRSControlPanel"];
	[[controlPanel window] setFrameUsingName:@"CRSControlPanel"];
	[[controlPanel window] setTitle:@"CRSMap"];
	[[NSNotificationCenter defaultCenter] addObserver:self 
		selector:@selector(doControls:) name:nil object:controlPanel];
	
// initilize arg for randUnitInterval()
	srand(time(nil));
	argRand = -1 * abs(rand());
}

- (long)mode;
{
	return [taskStatus mode];
}

- (NSString *)name;
{
	return @"CRSMap";
}

// The release notes for 10.3 say that the options for addObserver are ignore
// (http://developer.apple.com/releasenotes/Cocoa/AppKit.html).   This means that the change dictionary
// will not contain the new values of the change.  For now it must be read directly from the model

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	static BOOL tested = NO;
	NSString *key;
	id newValue;
	long longValue;
    MapSettings settings;

	if (!tested) {
		newValue = [change objectForKey:NSKeyValueChangeNewKey];
		if (![[newValue className] isEqualTo:@"NSNull"]) {
			NSLog(@"NSKeyValueChangeNewKey is not NSNull, JHRM needs to change how values are accessed");
		}
		tested = YES;
	}
	key = [keyPath pathExtension];
	if ([key isEqualTo:CRSStimTablesKey] || [key isEqualTo:CRSStimTableCountsKey]) {
        /*
        [mapStimTable0 updateBlockParameters];
		settings = [mapStimTable0 mapSettings];
		[dataDoc putEvent:@"map0Settings" withData:&settings];
		[mapStimTable1 updateBlockParameters];
		settings = [mapStimTable1 mapSettings];
		[dataDoc putEvent:@"map1Settings" withData:&settings];
        //[Vinay] - For gabor2
        [mapStimTable2 updateBlockParameters];
		settings = [mapStimTable2 mapSettings];
		[dataDoc putEvent:@"map1Settings" withData:&settings];
        // [Vinay] - till here
		requestReset();
        */
		[mapStimTable0 updateBlockParameters:0]; // [Vinay] - added arguement '0'
		settings = [mapStimTable0 mapSettings];
		[dataDoc putEvent:@"map0Settings" withData:&settings];
		[mapStimTable1 updateBlockParameters:1]; // [Vinay] - added arguement '1'
		settings = [mapStimTable1 mapSettings];
		[dataDoc putEvent:@"map1Settings" withData:&settings];
        //----------------------------------------------------------- [Vinay] for centre gabor
        [mapStimTable2 updateBlockParameters:2]; // [Vinay] - added arguement '2'
		settings = [mapStimTable2 mapSettings];
		[dataDoc putEvent:@"map2Settings" withData:&settings];
        //-----------------------------------------------------
		requestReset();
	}
	else if ([key isEqualTo:CRSRespTimeMSKey]) {
		longValue = [defaults integerForKey:CRSRespTimeMSKey];
		[dataDoc putEvent:@"responseTimeMS" withData:&longValue];
	}
	else if ([key isEqualTo:CRSMapStimDurationMSKey]) {
		longValue = [defaults integerForKey:CRSMapStimDurationMSKey];
		[dataDoc putEvent:@"mapStimDurationMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:CRSMapInterstimDurationMSKey]) {
		longValue = [defaults integerForKey:CRSMapInterstimDurationMSKey];
		[dataDoc putEvent:@"mapInterstimDurationMS" withData:&longValue];
		requestReset();
	}
	else if ([key isEqualTo:CRSStimDurationMSKey]) {
		longValue = [defaults integerForKey:CRSStimDurationMSKey];
		[dataDoc putEvent:@"stimDurationMS" withData:&longValue];
		if ([[task defaults] integerForKey:CRSStimDistributionKey] == kExponential) {
			updateCatchTrialPC();
		}
		requestReset();
	}
	else if ([key isEqualTo:CRSMeanTargetMSKey]) {
		longValue = [defaults integerForKey:CRSMeanTargetMSKey];
		[dataDoc putEvent:@"meanTargetTimeMS" withData:&longValue];
		if ([[task defaults] integerForKey:CRSStimDistributionKey] == kExponential) {
			updateCatchTrialPC();
		}
//		requestReset();
	}
	else if ([key isEqualTo:CRSMaxTargetMSKey]) {
		longValue = [defaults integerForKey:CRSMaxTargetMSKey];
		[dataDoc putEvent:@"maxTargetTimeMS" withData:&longValue];
		if ([[task defaults] integerForKey:CRSStimDistributionKey] == kUniform) {
			longValue = [defaults integerForKey:CRSMinTargetMSKey] +
						([defaults integerForKey:CRSMaxTargetMSKey] - [defaults integerForKey:CRSMinTargetMSKey]) / 2.0;
//			[[task defaults] setInteger: longValue forKey: CRSMeanTargetMSKey];
		}
		else updateCatchTrialPC();
		requestReset();
	}
	else if ([key isEqualTo:CRSMinTargetMSKey]) {
		longValue = [defaults integerForKey:CRSMinTargetMSKey];
		[dataDoc putEvent:@"minTargetTimeMS" withData:&longValue];
		if ([[task defaults] integerForKey:CRSStimDistributionKey] == kUniform) {
			longValue = [defaults integerForKey:CRSMinTargetMSKey] +
						([defaults integerForKey:CRSMaxTargetMSKey] - [defaults integerForKey:CRSMinTargetMSKey]) / 2.0;
//			[[task defaults] setInteger: longValue forKey: CRSMeanTargetMSKey];
		}
		else updateCatchTrialPC();
		requestReset();
	}
	else if ([key isEqualTo:CRSInterstimMSKey]) {
		longValue = [defaults integerForKey:CRSInterstimMSKey];
		[dataDoc putEvent:@"interstimMS" withData:&longValue];
		if ([[task defaults] integerForKey:CRSStimDistributionKey] == kExponential) {
			updateCatchTrialPC();
		}
		requestReset();
	}
	else if ([key isEqualTo:CRSOrientationChangesKey] || [key isEqualTo:CRSMaxDirChangeDegKey] ||
				[key isEqualTo:CRSMinDirChangeDegKey] || [key isEqualTo:CRSChangeScaleKey]) {
		[self updateChangeTable];
	}
	else if ([key isEqualTo:CRSChangeArrayKey]) {
		updateBlockStatus();
		[[task dataDoc] putEvent:@"blockStatus" withData:&blockStatus];
	}
	else if ([key isEqualTo:CRSMappingBlocksKey]) {
		mappingBlockStatus.blockLimit = [[task defaults] integerForKey:CRSMappingBlocksKey];
		[[task dataDoc] putEvent:@"mappingBlockStatus" withData:&mappingBlockStatus];
	}
	else if ([key isEqualTo:CRSFixateMSKey]) {
		longValue = [defaults integerForKey:CRSFixateMSKey];
		[[task dataDoc] putEvent:@"fixateMS" withData:&longValue];
	}
	else if ([key isEqualTo:CRSStimRepsPerBlockKey]) {
		longValue = [defaults integerForKey:CRSOrientationChangesKey];
		[dataDoc putEvent:@"stimRepsPerBlock" withData:&longValue];
	}
    else if ([key isEqualTo:CRSMapStimContrastPCKey])	{
		[stimuli clearStimLists:&trial];
		//[stimuli makeStimLists:&trial];
	}
    else if ([key isEqualTo:CRSHideTaskGaborKey]) {
        [[task defaults] setBool:YES forKey:CRSIncludeCatchTrialsinDoneListKey];
        [[task defaults] setInteger:100 forKey:CRSCatchTrialPCKey];
    }
    /* // [Vinay] - commented and replaced the following loops
    else if ([key isEqualTo:CRSHideLeftKey]) {
        [[task defaults] setBool:YES forKey:CRSHideLeftDigitalKey];
    }
    else if ([key isEqualTo:CRSHideRightKey]) {
        [[task defaults] setBool:YES forKey:CRSHideRightDigitalKey];
    }
    */
	/*
    else if ([key isEqualTo:CRSMapStimContrastPCKey])	{
		[stimuli clearStimLists:&trial];
		//[stimuli makeStimLists:&trial];
	}*/
    
    // [Vinay] - Have replaced the Left and Right Digital code keys with C, R, S Digital code control keys
    else if ([key isEqualTo:CRSHideCentreKey]) {
        [[task defaults] setBool:YES forKey:CRSHideCentreDigitalKey];
    }
    else if ([key isEqualTo:CRSHideRingKey]) {
        [[task defaults] setBool:YES forKey:CRSHideRingDigitalKey];
    }
    else if ([key isEqualTo:CRSHideSurroundKey]) {
        [[task defaults] setBool:YES forKey:CRSHideSurroundDigitalKey];
    }
    
    // [Vinay] - have added the follow lines. And commented all later since they aren't required. In fact they cause an error -  NSLock error because whenever the key is set, you try to again set it thus leading to an uncontrolled runaway situation
    /*
    else if ([key isEqualTo:CRSMatchCentreSurroundKey]) {
        [[task defaults] setBool:YES forKey:CRSMatchCentreSurroundKey];
    }
    */
    /*
    else if ([key isEqualTo:CRSRingProtocolKey]) {
        [[task defaults] setBool:YES forKey:CRSRingProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSContrastRingProtocolKey]; // [Vinay] - Set one protocol and disable the others so that two aren't selected simultaneously
        //[[task defaults] setBool:NO forKey:CRSDualContrastProtocolKey]; // [Vinay] - Have commented all these becuase it was giving an NSLock error - *** -[NSLock lock]: deadlock (<NSLock: 0x676820> '(null)')
        //[[task defaults] setBool:NO forKey:CRSDualOrientationProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSDualPhaseProtocolKey];
        requestReset();
    }
    else if ([key isEqualTo:CRSContrastRingProtocolKey]) {
        [[task defaults] setBool:YES forKey:CRSContrastRingProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSRingProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSDualContrastProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSDualOrientationProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSDualPhaseProtocolKey];
        requestReset();
    }
    else if ([key isEqualTo:CRSDualContrastProtocolKey]) {
        [[task defaults] setBool:YES forKey:CRSDualContrastProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSRingProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSContrastRingProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSDualOrientationProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSDualPhaseProtocolKey];
        requestReset();
    }
    else if ([key isEqualTo:CRSDualOrientationProtocolKey]) {
        [[task defaults] setBool:YES forKey:CRSDualOrientationProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSRingProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSContrastRingProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSDualContrastProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSDualPhaseProtocolKey];
        requestReset();
    }
    else if ([key isEqualTo:CRSDualPhaseProtocolKey]) {
        [[task defaults] setBool:YES forKey:CRSDualPhaseProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSRingProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSContrastRingProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSDualContrastProtocolKey];
        //[[task defaults] setBool:NO forKey:CRSDualOrientationProtocolKey];
        requestReset();
    }
    */
    // [Vinay] - till here
}

- (DisplayModeParam)requestedDisplayMode;
{
	displayMode.widthPix = 1280; //1024;
	displayMode.heightPix = 720; //768;
	displayMode.pixelBits = 32;
	displayMode.frameRateHz = 100;
	return displayMode;
}

- (void)setMode:(long)newMode;
{
	[taskStatus setMode:newMode];
	[defaults setInteger:[taskStatus status] forKey:CRSTaskStatusKey];
	[controlPanel setTaskMode:[taskStatus mode]];
	[dataDoc putEvent:@"taskMode" withData:&newMode];
	switch ([taskStatus mode]) {
	case kTaskRunning:
	case kTaskStopping:
		[runStopMenuItem setKeyEquivalent:@"."];
		break;
	case kTaskIdle:
		[runStopMenuItem setKeyEquivalent:@"r"];
		break;
	default:
		break;
	}
}
// Respond to changes in the stimulus settings

- (void)setWritingDataFile:(BOOL)state;
{
	if ([taskStatus dataFileOpen] != state) {
		[taskStatus setDataFileOpen:state];
		[defaults setInteger:[taskStatus status] forKey:CRSTaskStatusKey];
		if ([taskStatus dataFileOpen]) {
			announceEvents();
			[controlPanel displayFileName:[[[dataDoc filePath] lastPathComponent] 
												stringByDeletingPathExtension]];
			[controlPanel setResetButtonEnabled:NO];
		}
		else {
			[controlPanel displayFileName:@""];
			[controlPanel setResetButtonEnabled:YES];
		}
	}
}

- (CRSStimuli *)stimuli;
{
	return stimuli;
}

- (CRSMapStimTable *)mapStimTable0
{
	return mapStimTable0;
}

- (CRSMapStimTable *)mapStimTable1
{
	return mapStimTable1;
}

// [Vinay] Add mapStimTable2 for centre gabor

- (CRSMapStimTable *)mapStimTable2
{
	return mapStimTable2;
}
//----------------------

// The change table (array) contains information about what changes will be tested and
// how often each change will be tested in the valid and invalid mode in each block

- (void)updateChangeTable;
{
	long index, changes, oldChanges;
	long changeScale;
	float minChange, maxChange;
	float logMinChange, logMaxChange;
	float newValue;
	NSMutableArray *changeArray;
	NSMutableDictionary *changeEntry;

	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver:self forKeyPath:@"values.CRSChangeArray"];
	changeArray = [NSMutableArray arrayWithArray:[defaults arrayForKey:CRSChangeArrayKey]];
	oldChanges = [changeArray count];
	changes = [defaults integerForKey:CRSOrientationChangesKey];

	if (oldChanges > changes) {
		[changeArray removeObjectsInRange:NSMakeRange(changes, oldChanges - changes)];
	}
	else if (changes > oldChanges) {
		changeEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithFloat:10.0], CRSChangeKey,
				[NSNumber numberWithLong:1], CRSValidRepsKey,
				[NSNumber numberWithLong:0], CRSInvalidRepsKey,
				nil];
		for (index = oldChanges; index < changes; index++) {
			[changeArray addObject:changeEntry];
		}
	}
	changeScale = [defaults integerForKey:CRSChangeScaleKey];
	minChange = [defaults floatForKey:CRSMinDirChangeDegKey];
	maxChange = [defaults floatForKey:CRSMaxDirChangeDegKey];
	logMinChange = log(minChange);
	logMaxChange = log(maxChange);
	for (index = 0; index < changes; index++) {
		if (changes <= 1) {
			newValue = minChange;
		}
		else if (changeScale == kLogarithmic) {
            newValue = exp(logMinChange + index * (logMaxChange - logMinChange) / (changes - 1));
        }
        else {
            newValue = minChange + index * (maxChange - minChange) / (changes - 1);
        }
		changeEntry = [NSMutableDictionary dictionaryWithCapacity:1];
		[changeEntry setDictionary:[changeArray objectAtIndex:index]];
		[changeEntry setObject:[NSNumber numberWithFloat:newValue] forKey:CRSChangeKey];
		[changeArray replaceObjectAtIndex:index withObject:changeEntry];
	}

	[defaults setObject:changeArray forKey:CRSChangeArrayKey];
	updateBlockStatus();
	[[task dataDoc] putEvent:@"blockStatus" withData:&blockStatus];
	requestReset();
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self forKeyPath:@"values.CRSChangeArray"
				options:NSKeyValueObservingOptionNew context:nil];

}

@end
