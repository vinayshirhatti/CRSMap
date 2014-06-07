//
//  CRSStateSystem.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSStateSystem.h"
#import "UtilityFunctions.h"
#import "CRSMap.h"

#import "CRSBlockedState.h"
#import "CRSEndtrialState.h"
#import "CRSFixGraceState.h"
#import "CRSFixonState.h"
#import "CRSIdleState.h"
#import "CRSIntertrialState.h"
#import "CRSFixateState.h"
#import "CRSReactState.h"
#import "CRSSaccadeState.h"
#import "CRSStarttrialState.h"
#import "CRSStimulate.h"
#import "CRSStopState.h"
#import "CRSTooFastState.h"

long 				eotCode;			// End Of Trial code
BOOL 				fixated;
LLEyeWindow			*fixWindow;
LLEyeWindow			*respWindow;
CRSStateSystem		*stateSystem;
TrialDesc			trial;

@implementation CRSStateSystem

- (void)dealloc {

    [fixWindow release];
	[respWindow release];
    [super dealloc];
}

- (id)init;
{
    if ((self = [super init]) != nil) {

// create & initialize the state system's states

		[self addState:[[[CRSBlockedState alloc] init] autorelease]];
		[self addState:[[[CRSEndtrialState alloc] init] autorelease]];
		[self addState:[[[CRSFixonState alloc] init] autorelease]];
		[self addState:[[[CRSFixGraceState alloc] init] autorelease]];
		[self addState:[[[CRSIdleState alloc] init] autorelease]];
		[self addState:[[[CRSIntertrialState alloc] init] autorelease]];
		[self addState:[[[CRSStimulate alloc] init] autorelease]];
		[self addState:[[[CRSFixateState alloc] init] autorelease]];
		[self addState:[[[CRSTooFastState alloc] init] autorelease]];
		[self addState:[[[CRSReactState alloc] init] autorelease]];
		[self addState:[[[CRSSaccadeState alloc] init] autorelease]];
		[self addState:[[[CRSStarttrialState alloc] init] autorelease]];
		[self addState:[[[CRSStopState alloc] init] autorelease]];
		[self setStartState:[self stateNamed:@"CRSIdle"] andStopState:[self stateNamed:@"CRSStop"]];

		[controller setLogging:YES];
	
		fixWindow = [[LLEyeWindow alloc] init];
		[fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:CRSFixWindowWidthDegKey]];
			
		respWindow = [[LLEyeWindow alloc] init];
		[respWindow setWidthAndHeightDeg:[[task defaults] floatForKey:CRSRespWindowWidthDegKey]];
    }
    return self;
}

- (BOOL) running {

    return [controller running];
}

- (BOOL) startWithCheckIntervalMS:(double)checkMS {			// start the system running

    return [controller startWithCheckIntervalMS:checkMS];
}

- (void) stop {										// stop the system

    [controller stop];
}

// Methods related to data events follow:

// Make a block status object that contains the number of blocks to do and how many 
// trials of each type have been done (initialized to zero).

- (void) reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long index;
	
	updateBlockStatus();
	blockStatus.blocksDone = blockStatus.sidesDone = blockStatus.instructDone = 0;
	for (index = 0; index < blockStatus.changes; index++) {
		blockStatus.validRepsDone[index] = blockStatus.invalidRepsDone[index] = 0;
	}
	[[(CRSMap *)task mapStimTable0] reset];
	[[(CRSMap *)task mapStimTable1] reset];
	mappingBlockStatus = [[(CRSMap *)task mapStimTable0] mappingBlockStatus];
    trialCounter = 0;
}

#define kMaxRate        100.0
#define kSpontRate      1.0

// Adjust based only on stim 0

- (void)stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	float firingRateHz;
	StimDesc *pSD = (StimDesc *)[eventData bytes];
	
    if (pSD->gaborIndex != kMapGabor1) {
        return;                                                     // do nothing with the task stimuli
    }
	firingRateHz = kMaxRate;
	firingRateHz *= (fabs(pSD->directionDeg - 90.0) < 45.0) ? 1.0 : 0.5;
	firingRateHz *= (fabs(fabs(pSD->azimuthDeg) - 5.0) < 2.5) ? 1.0 : 0.5;
	firingRateHz *= (fabs(fabs(pSD->elevationDeg) - 5.0) < 2.5) ? 1.0 : 0.5;
	firingRateHz *= (fabs(pSD->spatialFreqCPD - 1.0) < 0.5) ? 1.0 : 0.5;
	firingRateHz *= (fabs(pSD->sigmaDeg - 0.5) < 0.25) ? 1.0 : 0.5;
    [[task synthDataDevice] setSpikeRateHz:firingRateHz atTime:[LLSystemUtil getTimeS]];
}

- (void) stimulusOff:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    [[task synthDataDevice] setSpikeRateHz:kSpontRate atTime:[LLSystemUtil getTimeS]];
}

- (void) tries:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long tries;
	
	[eventData getBytes:&tries];
}

@end
