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
NSString *CRSBlockLimitKey = @"CRSBlockLimit";
NSString *CRSBreakPunishMSKey = @"CRSBreakPunishMS";
NSString *CRSChangeScaleKey = @"CRSChangeScale";
NSString *CRSCatchTrialPCKey = @"CRSCatchTrialPC";
NSString *CRSCatchTrialMaxPCKey = @"CRSCatchTrialMaxPC";
//NSString *CRSCueMSKey = @"CRSCueMS";
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
//NSString *CRSNontargetContrastPCKey = @"CRSNontargetContrastPC";
//NSString *CRSRespSpotSizeDegKey = @"CRSRespSpotSizeDeg";
NSString *CRSRespTimeMSKey = @"CRSRespTimeMS";
NSString *CRSRespWindowWidthDegKey = @"CRSRespWindowWidthDeg";
NSString *CRSRewardMSKey = @"CRSRewardMS";
NSString *CRSMinRewardMSKey = @"CRSMinRewardMS";
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
//NSString *CRSMapStimContrastPCKey = @"CRSMapStimContrastPC";
NSString *CRSMapStimRadiusSigmaRatioKey = @"CRSMapStimRadiusSigmaRatio";

NSString *CRSHideLeftKey = @"CRSHideLeft";
NSString *CRSHideRightKey = @"CRSHideRight";
NSString *CRSHideLeftDigitalKey = @"CRSHideLeftDigital";
NSString *CRSHideRightDigitalKey = @"CRSHideRightDigital";
NSString *CRSConvertToGratingKey = @"CRSConvertToGrating";

NSString *CRSHideTaskGaborKey = @"CRSHideTaskGabor";
NSString *CRSIncludeCatchTrialsinDoneListKey = @"CRSIncludeCatchTrialsinDoneList";
NSString *CRSMapTemporalModulationKey = @"CRSMapTemporalModulation";

// Visual Stimulus Parameters 

//NSString *CRSSpatialPhaseDegKey = @"CRSSpatialPhaseDeg";
//NSString *CRSTemporalFreqHzKey = @"CRSTemporalFreqHz";

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
					@"values.CRSMapStimRadiusSigmaRatio",@"values.CRSHideTaskGabor",@"values.CRSHideLeft",@"values.CRSHideRight",
					nil};

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
	{@"float",	@"spatialFreqCPD", 1, offsetof(StimDesc, spatialFreqCPD)},
	{@"float",	@"directionDeg", 1, offsetof(StimDesc, directionDeg)},
    {@"float",	@"temporalFreqHz", 1, offsetof(StimDesc, temporalFreqHz)},
	{@"long",	@"azimuthIndex", 1, offsetof(StimDesc, azimuthIndex)},
	{@"long",	@"elevationIndex", 1, offsetof(StimDesc, elevationIndex)},
	{@"long",	@"sigmaIndex", 1, offsetof(StimDesc, sigmaIndex)},
	{@"long",	@"spatialFreqIndex", 1, offsetof(StimDesc, spatialFreqIndex)},
	{@"long",	@"directionIndex", 1, offsetof(StimDesc, directionIndex)},
	{@"long",	@"contrastIndex", 1, offsetof(StimDesc, contrastIndex)},
	{@"long",	@"temporalFreqIndex", 1, offsetof(StimDesc, temporalFreqIndex)},
    {@"long",	@"temporalModulation", 1, offsetof(StimDesc, temporalModulation)},
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
	{@"short",	@"numberOfSurrounds", 1, offsetof(StimSetting, numberOfSurrounds)},
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
    {nil}};
	
DataAssignment eyeXDataAssignment = {@"eyeXData",	@"Synthetic", 0, 5.0};	
DataAssignment eyeYDataAssignment = {@"eyeYData",	@"Synthetic", 1, 5.0};	
DataAssignment spike0Assignment =   {@"spike0",     @"Synthetic", 2, 1};
DataAssignment spike1Assignment =   {@"spike1",     @"Synthetic", 3, 1};
DataAssignment VBLDataAssignment =  {@"VBLData",	@"Synthetic", 1, 1};
	
EventDefinition CRSEvents[] = {
    // recorded at start of file, these need to be announced using announceEvents() in UtilityFunctions.m
	{@"taskGabor",			sizeof(Gabor),			{@"struct", @"taskGabor", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"mappingGabor0",		sizeof(Gabor),			{@"struct", @"mappingGabor0", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"mappingGabor1",		sizeof(Gabor),			{@"struct", @"mappingGabor1", 1, 0, sizeof(Gabor), gaborStructDef}},
	{@"behaviorSetting",	sizeof(BehaviorSetting),{@"struct", @"behaviorSetting", 1, 0, sizeof(BehaviorSetting), behaviorSettingDef}},
	{@"stimSetting",		sizeof(StimSetting),	{@"struct", @"stimSetting", 1, 0, sizeof(StimSetting), stimSettingDef}},
	{@"map0Settings",		sizeof(MapSettings),    {@"struct", @"mapSettings", 1, 0, sizeof(MapSettings), mapSettingsDef}},
	{@"map1Settings",		sizeof(MapSettings),    {@"struct", @"mapSettings", 1, 0, sizeof(MapSettings), mapSettingsDef}},
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
	{@"trialSync",          sizeof(long),			{@"long"}},
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


@implementation CRSMap

+ (int)version;
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

	[dataController assignSampleData:eyeXDataAssignment];
	[dataController assignSampleData:eyeYDataAssignment];
	[dataController assignTimestampData:spike0Assignment];
	[dataController assignTimestampData:spike1Assignment];
	[dataController assignTimestampData:VBLDataAssignment];
	[dataController assignDigitalInputDevice:@"Synthetic"];
	[dataController assignDigitalOutputDevice:@"Synthetic"];
	collectorTimer = [NSTimer scheduledTimerWithTimeInterval:0.025 target:self 
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

	if ((data = [dataController dataOfType:@"eyeXData"]) != nil) {
		[dataDoc putEvent:@"eyeXData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyeUnits.x = *(short *)([data bytes] + [data length] - sizeof(short));
	}
	if ((data = [dataController dataOfType:@"eyeYData"]) != nil) {
		[dataDoc putEvent:@"eyeYData" withData:(Ptr)[data bytes] lengthBytes:[data length]];
		currentEyeUnits.y = *(short *)([data bytes] + [data length] - sizeof(short));
		currentEyeDeg = [eyeCalibrator degPointFromUnitPoint:currentEyeUnits];
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
	[digitalOut release];
	[controlPanel release];
	[taskStatus dealloc];
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
	[[task dataController] digitalOutputBitsOff:kRewardBit];
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
	[[task dataController] digitalOutputBitsOn:kRewardBit];
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
	
    switch ([taskStatus mode]) {
    case kTaskIdle:
		newMode = kTaskRunning;
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

	[NSBundle loadNibNamed:@"CRSMap" owner:self];
	
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
		[mapStimTable0 updateBlockParameters];
		settings = [mapStimTable0 mapSettings];
		[dataDoc putEvent:@"map0Settings" withData:&settings];
		[mapStimTable1 updateBlockParameters];
		settings = [mapStimTable1 mapSettings];
		[dataDoc putEvent:@"map1Settings" withData:&settings];
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
    else if ([key isEqualTo:CRSHideTaskGaborKey]) {
        [[task defaults] setBool:YES forKey:CRSIncludeCatchTrialsinDoneListKey];
        [[task defaults] setInteger:100 forKey:CRSCatchTrialPCKey];
    }
    else if ([key isEqualTo:CRSHideLeftKey]) {
        [[task defaults] setBool:YES forKey:CRSHideLeftDigitalKey];
    }
    else if ([key isEqualTo:CRSHideRightKey]) {
        [[task defaults] setBool:YES forKey:CRSHideRightDigitalKey];
    }
	/*
    else if ([key isEqualTo:CRSMapStimContrastPCKey])	{
		[stimuli clearStimLists:&trial];
		//[stimuli makeStimLists:&trial];
	}*/
}

- (DisplayModeParam)requestedDisplayMode;
{
	displayMode.widthPix = 1360; //1024;
	displayMode.heightPix = 768;
	displayMode.pixelBits = 32;
	displayMode.frameRateHz = 60; //100;
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
		changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithFloat:10.0], CRSChangeKey,
				[NSNumber numberWithLong:1], CRSValidRepsKey,
				[NSNumber numberWithLong:0], CRSInvalidRepsKey,
				nil];
		for (index = oldChanges; index < changes; index++) {
			[changeArray addObject:changeEntry];
		}
	}
/*
	changeSign = 0;
	minChange = [defaults floatForKey:CRSMinDirChangeDegKey];
	maxChange = [defaults floatForKey:CRSMaxDirChangeDegKey];
	
	changeScale = [defaults integerForKey:CRSChangeScaleKey];
	
	if ((minChange > 0) & (maxChange > 0)) {
		changeSign = 1;
		logMinChange = log(minChange);
		logMaxChange = log(maxChange);
		logGuessThreshold = log(guessThreshold);
	}
	else if ((minChange < 0) & (maxChange < 0)) {
		changeSign = -1;
		logMinChange = log((-1*minChange));
		logMaxChange = log((-1*maxChange));
		logGuessThreshold = log(-1*guessThreshold);
	} 

	switch (changes) {
		case 1:
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:maxChange], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:0 withObject:changeEntry];
			break;

		case 2:
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:minChange], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:0 withObject:changeEntry];
		
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:maxChange], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:1 withObject:changeEntry];
			break;
		
		case 3:
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:minChange], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:0 withObject:changeEntry];
		
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:guessThreshold], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:1 withObject:changeEntry];

			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:maxChange], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:2 withObject:changeEntry];
			break;

		case 4:
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:minChange], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:0 withObject:changeEntry];
		
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:guessThreshold], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:1 withObject:changeEntry];

			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:maxChange], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:2 withObject:changeEntry];

			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:maxChange * 1.5], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
			[changeArray replaceObjectAtIndex:3 withObject:changeEntry];
			break;

		default:
			netChanges = changes -1;
			halfIndex = changes / 2;
			for (index = 0; index < changes/2; index++) {
				if (changeScale == kLinear) {
					newValue = minChange + (index) * (guessThreshold - minChange) / (changes / 2 - 1);
				}
				else if (changeScale == kLogarithmic) {
				newValue = exp(logMinChange + (index) * (logGuessThreshold - logMinChange) / (changes / 2 - 1));
				newValue = changeSign * newValue;
				}
//				newValue = 0.1;
				changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:newValue], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
				[changeArray replaceObjectAtIndex:index withObject:changeEntry];
			}
			halfIndex = index;
			for (index = halfIndex; index < changes - 1; index++) {
				if (changeScale == kLinear) {
					newValue = guessThreshold + (index - halfIndex + 1) * 
								(maxChange - guessThreshold) / ((changes + 1) / 2 - 1);
				}
				else if (changeScale == kLogarithmic) {
				newValue = exp(logGuessThreshold + (index - halfIndex + 1) * 
								(logMaxChange - logGuessThreshold) / ((changes + 1) / 2 - 1));
				newValue = changeSign * newValue;
				}
//				newValue = 0.1;
				changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithFloat:newValue], CRSChangeKey,
					[NSNumber numberWithLong:1], CRSValidRepsKey,
					nil];
				[changeArray replaceObjectAtIndex:index withObject:changeEntry];
			}
			
			changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithFloat:maxChange*1.5], CRSChangeKey,
				[NSNumber numberWithLong:1], CRSValidRepsKey,
				nil];

			[changeArray replaceObjectAtIndex:changes-1 withObject:changeEntry];
			break;
	}



	changeEntry = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithFloat:1.0*changeSign], CRSChangeKey,
			[NSNumber numberWithLong:1], CRSValidRepsKey,
			nil];

	[changeArray replaceObjectAtIndex:0 withObject:changeEntry];
*/
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
