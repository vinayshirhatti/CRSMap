/*
 *  CRS.h
 *  CRSMap
 *
 *  Copyright (c) 2006. All rights reserved.
 *
 */

@class CRSDigitalOut;

#define kPI          		(atan(1) * 4)
#define k2PI         		(atan(1) * 4 * 2)
#define kRadiansPerDeg      (kPI / 180.0)
#define kDegPerRadian		(180.0 / kPI)

// The following should be changed to be unique for each application

enum {kTaskGabor = 0, kMapGabor0, kMapGabor1, kMapGabor2, kGabors}; // [Vinay] - kMapGabor2 for the centre gabor. So enum integer value for kGabors becomes equal to 4. Note this!
enum {kAttend0 = 0, kAttend1, kLocations};
enum {kLinear = 0, kLogarithmic};
enum {kUniform = 0, kExponential};
enum {kAuto = 0, kManual};
enum {kRewardFixed = 0, kRewardVariable};
enum {kNullStim = 0, kValidStim, kTargetStim, kFrontPadding, kBackPadding};
enum {kMyEOTCorrect = 0, kMyEOTMissed, kMyEOTEarlyToValid, kMyEOTEarlyToInvalid, kMyEOTBroke, 
				kMyEOTIgnored, kMyEOTQuit, kMyEOTTypes};

#define	kMaxOriChanges	12
#define kMaxMapValues   6
#define kMaxMapValuesFixed 1 // [Vinay] - added this variable to represent fixed quantities/variables in the stimulus mapping list 

typedef struct {
	long	levels;				// number of active stimulus levels
	float   maxValue;			// maximum stimulus value (i.e., direction change in degree)
	float   minValue;			// minimum stimulus value
} StimParams;

typedef struct StimDesc {
	long	gaborIndex;
	long	sequenceIndex;
	long	stimOnFrame;
	long	stimOffFrame;
	short	stimType;
	float	orientationChangeDeg;   // [Vinay] - This is perhaps related to the change in the orientation of the task gabor that has to be detected
	float	contrastPC;
	float	azimuthDeg;
	float	elevationDeg;
	float	sigmaDeg;
	float	radiusDeg;
	float	spatialFreqCPD;
	float	directionDeg;           // [Vinay] - And this may be related to the actual orientation of the gabor
    float   temporalFreqHz;
    float   spatialPhaseDeg;               // [Vinay] - Added a parameter for the phase of gabor
	long	azimuthIndex;
	long	elevationIndex;
	long	sigmaIndex;
	long	spatialFreqIndex;
	long	directionIndex;
	long	contrastIndex;
    long    temporalFreqIndex;
    long    temporalModulation;
    long    radiusIndex;        // [Vinay] - This parameter added to keep count of the different radius values
    long    spatialPhaseIndex;         // [Vinay] - This parameter added to keep count of the different phase values
} StimDesc;

typedef struct TrialDesc {
	BOOL	instructTrial;
	BOOL	catchTrial;
	long	numStim;
	long	targetIndex;				// index (count) of target in stimulus sequence
	long	targetOnTimeMS;				// time from first stimulus (start of stimlist) to the target
	long	orientationChangeIndex;     // [Vinay] - To keep record of the amount of change that happened in the task gabor on a particular trial?
	float	orientationChangeDeg;
} TrialDesc;

typedef struct BlockStatus {
	long	changes;
	float	orientationChangeDeg[kMaxOriChanges];
	float	validReps[kMaxOriChanges];
	long	validRepsDone[kMaxOriChanges];
	float	invalidReps[kMaxOriChanges];
	long	invalidRepsDone[kMaxOriChanges];
	long	instructDone;			// number of instruction trials done
	long	instructTrials;			// number of instruction trials to be done
	long	sidesDone;				// number of sides (out of kLocations) done
	long	blockLimit;				// number of blocks before stopping
	long	blocksDone;				// number of blocks completed
} BlockStatus;

typedef struct MappingBlockStatus {
	long	stimDone;				// number of stim done in this block
	long	stimLimit;				// number of stim in block
	long	blocksDone;				// number of blocks completed
	long	blockLimit;				// number of blocks before stopping
} MappingBlockStatus;

typedef struct  MapParams {
    long    n;                      // number of different conditions
    float   minValue;               // smallest value tested
    float   maxValue;               // largest value tested
} MapParams;

typedef struct  MapSettings {
    MapParams    azimuthDeg;        // [Vinay] - Actually not required in CRS because it can be a fixed value for every session
    MapParams    elevationDeg;      // [Vinay] - Actually not required in CRS because it can be a fixed value for every session
    MapParams    directionDeg;
    MapParams    spatialFreqCPD;
    MapParams    sigmaDeg;          // [Vinay] - Actually not required in CRS because it can be a fixed value for every session
    MapParams    contrastPC;
    MapParams    temporalFreqHz;    // [Vinay] - Actually not required in CRS because it can be a fixed value for every session, 0 Hz for static gratings
    MapParams    radiusDeg;         // [Vinay] - Added to include variations in radius of the gabor
    MapParams    spatialPhaseDeg;          // [Vinay] - Added to include variations in phase of the gabor
} MapSettings;

// put parameters set in the behavior controller

typedef struct BehaviorSetting {
	long	blocks;
	long	intertrialMS;
	long	acquireMS;
	long	fixGraceMS;
	long	fixateMS;
	long	fixateJitterPC;
	long	responseTimeMS;
	long	tooFastMS;
	long	minSaccadeDurMS;
	long	breakPunishMS;
	long	rewardSchedule;
	long	rewardMS;
	float	fixWinWidthDeg;
	float	respWinWidthDeg;
} BehaviorSetting;

// put parameters set in the Stimulus controller

typedef struct StimSetting {
	long	stimDurationMS;
	long	stimDurJitterPC;
	long	interStimMS;
	long	interStimJitterPC;
	long	stimLeadMS;
	float	stimSpeedHz;
	long	stimDistribution;
	long	minTargetOnTimeMS;
	long	meanTargetOnTimeMS;
	long	maxTargetOnTimeMS;
	float	eccentricityDeg;
	float	polarAngleDeg;
	float	driftDirectionDeg;
	float	contrastPC;
	short	numberOfSurrounds;
	long	changeScale;
	long	orientationChanges;
	float	maxChangeDeg;
	float	minChangeDeg;
	long	changeRemains;
} StimSetting;


#ifndef	NoGlobals

// Behavior settings dialog

extern NSString *CRSAcquireMSKey;
extern NSString *CRSBlockLimitKey;
extern NSString *CRSBreakPunishMSKey;
extern NSString *CRSCatchTrialPCKey;
extern NSString *CRSCatchTrialMaxPCKey;
//extern NSString *CRSCueMSKey;
extern NSString *CRSChangeScaleKey;
extern NSString *CRSDoSoundsKey;
extern NSString *CRSFixateKey;
extern NSString *CRSFixateMSKey;
extern NSString *CRSFixateOnlyKey;
extern NSString *CRSFixGraceMSKey;
extern NSString *CRSFixJitterPCKey;
extern NSString *CRSFixWindowWidthDegKey;
extern NSString *CRSIntertrialMSKey;
extern NSString *CRSInstructionTrialsKey;
extern NSString *CRSInvalidRewardFactorKey;
extern NSString *CRSMaxTargetMSKey;
extern NSString *CRSMinTargetMSKey;
extern NSString *CRSMeanTargetMSKey;
//extern NSString *CRSNontargetContrastPCKey;
//extern NSString *CRSRespSpotSizeDegKey;
extern NSString *CRSRespTimeMSKey;
extern NSString *CRSRespWindowWidthDegKey;
extern NSString *CRSRewardMSKey;
extern NSString *CRSMinRewardMSKey;
extern NSString *CRSRewardScheduleKey;
extern NSString *CRSSaccadeTimeMSKey;
extern NSString *CRSStimDistributionKey;
extern NSString *CRSStimRepsPerBlockKey;
extern NSString *CRSTaskStatus;
extern NSString *CRSTooFastMSKey;

// Stimulus settings dialog

extern NSString *CRSInterstimMSKey;
extern NSString *CRSMapInterstimDurationMSKey;
extern NSString *CRSInterstimJitterPCKey;
extern NSString *CRSStimDurationMSKey;
extern NSString *CRSMapStimDurationMSKey;
extern NSString *CRSMappingBlocksKey;
extern NSString *CRSStimJitterPCKey;
//extern NSString *CRSChangeScaleKey; - already defined above
extern NSString *CRSOrientationChangesKey;
extern NSString *CRSMaxDirChangeDegKey;
extern NSString *CRSMinDirChangeDegKey;
extern NSString *CRSChangeRemainKey;
extern NSString *CRSChangeArrayKey;

//extern NSString *CRSMapStimContrastPCKey;
extern NSString *CRSMapStimRadiusSigmaRatioKey;

extern NSString *CRSKdlPhiDegKey;
extern NSString *CRSKdlThetaDegKey;
extern NSString *CRSRadiusDegKey;
extern NSString *CRSSeparationDegKey;
extern NSString *CRSSpatialFreqCPDKey;
extern NSString *CRSSpatialPhaseDegKey;
extern NSString *CRSTemporalFreqHzKey;

extern NSString *CRSChangeKey;
extern NSString *CRSInvalidRepsKey;
extern NSString *CRSValidRepsKey;

// [Vinay] - Have replace Left anf Right gabor Keys with Centre, Ring, Surround gabor keys
//extern NSString *CRSHideLeftKey;
//extern NSString *CRSHideRightKey;
//extern NSString *CRSHideLeftDigitalKey;
//extern NSString *CRSHideRightDigitalKey;

extern NSString *CRSHideCentreKey;
extern NSString *CRSHideRingKey;
extern NSString *CRSHideSurroundKey;
extern NSString *CRSHideCentreDigitalKey;
extern NSString *CRSHideRingDigitalKey;
extern NSString *CRSHideSurroundDigitalKey;

// [Vinay] - till here

extern NSString *CRSConvertToGratingKey;

extern NSString *CRSHideTaskGaborKey;
extern NSString *CRSIncludeCatchTrialsinDoneListKey;
extern NSString *CRSMapTemporalModulationKey;

// [Vinay] - have added the following keys

extern NSString *CRSMatchCentreSurroundKey;
/*
extern NSString *CRSRingProtocolKey;
extern NSString *CRSContrastRingProtocolKey;
extern NSString *CRSDualContrastProtocolKey;
extern NSString *CRSDualOrientationProtocolKey;
extern NSString *CRSDualPhaseProtocolKey;
*/ // [Vinay] - Later commented these
// [Vinay] - for selecting protocol from a pop down menu
extern NSString *CRSProtocolNumberKey;

// added these later
extern NSString *CRSMatchCentreRingKey;
extern NSString *CRSMatchRingSurroundKey;

// [Vinay] - to show just an image at the fixation spot
extern NSString *CRSFixImageKey;

// [Vinay] - till here


long		argRand;

#import "CRSStimuli.h"

BlockStatus						blockStatus;
BehaviorSetting					behaviorSetting;
BOOL							brokeDuringStim;
MappingBlockStatus				mappingBlockStatus;
BOOL							resetFlag;
LLScheduleController			*scheduler;
CRSStimuli						*stimuli;
CRSDigitalOut					*digitalOut;

#endif

LLTaskPlugIn					*task;


