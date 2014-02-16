/*
CRSStimuli.m
Stimulus generation for CRSMap
March 29, 2003 JHRM
*/

#import "CRS.h"
#import "CRSMap.h"
#import "CRSStimuli.h"
#import "UtilityFunctions.h"

#define kDefaultDisplayIndex	1		// Index of stim display when more than one display
#define kMainDisplayIndex		0		// Index of main stimulus display
#define kPixelDepthBits			32		// Depth of pixels in stimulus window
#define	stimWindowSizePix		250		// Height and width of stim window on main display

#define kTargetBlue				0.0
#define kTargetGreen			1.0
#define kMidGray				0.5
#define kPI						(atan(1) * 4)
#define kTargetRed				1.0
#define kDegPerRad				57.295779513

#define kAdjusted(color, contrast)  (kMidGray + (color - kMidGray) / 100.0 * contrast)

NSString *stimulusMonitorID = @"CRSMap Stimulus";

@implementation CRSStimuli

- (void) dealloc;
{
	[[task monitorController] removeMonitorWithID:stimulusMonitorID];
	[taskStimList release];
	[mapStimList0 release];
	[mapStimList1 release];
    [mapStimList2 release];         // [Vinay] - for centre gabors
	[fixSpot release];
    [gabors release];

    [super dealloc];
}

- (void)doFixSettings;
{
	[fixSpot runSettingsDialog];
}

- (void)doGabor0Settings;
{
	[[self taskGabor] runSettingsDialog];
}

- (void)dumpStimList;
{
	StimDesc stimDesc;
	long index;
	
	NSLog(@"\ncIndex stim0Type stim1Type stimOnFrame stimOffFrame SF");
	for (index = 0; index < [taskStimList count]; index++) {
		[[taskStimList objectAtIndex:index] getValue:&stimDesc];
		NSLog(@"%4ld:\t%d\t %ld %ld %.2f", index, stimDesc.stimType, stimDesc.stimOnFrame, stimDesc.stimOffFrame, 
              stimDesc.spatialFreqCPD);
		NSLog(@"stim is %s", (stimDesc.stimType == kValidStim) ? "valid" : 
              ((stimDesc.stimType == kTargetStim) ? "target" : "other"));
	}
	NSLog(@"\n");
}

- (void)erase;
{
	[[task stimWindow] lock];
    glClearColor(kMidGray, kMidGray, kMidGray, 0);
    glClear(GL_COLOR_BUFFER_BIT);
	[[NSOpenGLContext currentContext] flushBuffer];
	[[task stimWindow] unlock];
}

- (id)init;
{
	float frameRateHz = [[task stimWindow] frameRateHz]; 
	
	if (!(self = [super init])) {
		return nil;
	}
	monitor = [[[LLIntervalMonitor alloc] initWithID:stimulusMonitorID 
					description:@"Stimulus frame intervals"] autorelease];
	[[task monitorController] addMonitor:monitor];
	[monitor setTargetIntervalMS:1000.0 / frameRateHz];
	taskStimList = [[NSMutableArray alloc] init];
	mapStimList0 = [[NSMutableArray alloc] init];
	mapStimList1 = [[NSMutableArray alloc] init];
    mapStimList2 = [[NSMutableArray alloc] init];           // [Vinay] - for centre gabor
	
// Create and initialize the visual stimuli

	gabors = [[NSArray arrayWithObjects:[self initGabor],
                            [self initGabor], [self initGabor], [self initGabor], nil] retain];         // [Vinay] - one extra [self initGabor] added here for centre gabor
	[[gabors objectAtIndex:kMapGabor0] setAchromatic:YES];
	[[gabors objectAtIndex:kMapGabor1] setAchromatic:YES];
    [[gabors objectAtIndex:kMapGabor2] setAchromatic:YES];                  // [Vinay] - for centre gabor
	fixSpot = [[LLFixTarget alloc] init];
	[fixSpot bindValuesToKeysWithPrefix:@"CRSFix"];

	return self;
}

- (LLGabor *)initGabor;
{
	static long counter = 0;
	LLGabor *gabor;
	
	gabor = [[LLGabor alloc] init];				// Create a gabor stimulus
	[gabor setDisplays:[[task stimWindow] displays] displayIndex:[[task stimWindow] displayIndex]];

    //[gabor removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborDirectionDegKey,
    //                LLGaborTemporalPhaseDegKey, LLGaborSpatialPhaseDegKey, nil]]; // [Vinay] - I have commented these just to check their effect

	[gabor bindValuesToKeysWithPrefix:[NSString stringWithFormat:@"CRS%ld", counter++]];
	return gabor;
}

/*

makeStimList()

Make stimulus lists for one trial.  Three lists are made: one for the task gabor, and one each for the
mapping gabors at the two locations.  Each list is constructed as an NSMutableArry of StimDesc or StimDesc
structures.

Task Stim List: The target in the specified targetIndex position (0 based counting). 

Mapping Stim List: The list is constructed so that each stimulus type appears n times before any appears (n+1).
Details of the construction, as well as monitoring how many stimuli and blocks have been completed are handled
by mapStimTable.

*/

- (void)makeStimLists:(TrialDesc *)pTrial;
{
	long targetIndex;
	long stim, nextStimOnFrame, lastStimOffFrame = 0;
	long stimDurFrames, interDurFrames, stimJitterPC, interJitterPC, stimJitterFrames, interJitterFrames;
	long stimDurBase, interDurBase;
	float frameRateHz;
	StimDesc stimDesc, copyStimDesc, copyStimDesc2; // [Vinay] added copyStimDesc and copyStimDesc2
	LLGabor *taskGabor = [self taskGabor];
    //matchSurroundCentre = 1; // [Vinay] - setting this 1 to check
	
	[taskStimList removeAllObjects];
	targetIndex = MIN(pTrial->targetIndex, pTrial->numStim);
	
// Now we make a second pass through the list adding the stimulus times.  We also insert 
// the target stimulus (if this isn't a catch trial) and set the invalid stimuli to kNull
// if this is an instruction trial.

	frameRateHz = [[task stimWindow] frameRateHz];
	stimJitterPC = [[task defaults] integerForKey:CRSStimJitterPCKey];
	interJitterPC = [[task defaults] integerForKey:CRSInterstimJitterPCKey];
	stimDurFrames = ceil([[task defaults] integerForKey:CRSStimDurationMSKey] / 1000.0 * frameRateHz);
	interDurFrames = ceil([[task defaults] integerForKey:CRSInterstimMSKey] / 1000.0 * frameRateHz);
	stimJitterFrames = round(stimDurFrames / 100.0 * stimJitterPC);
	interJitterFrames = round(interDurFrames / 100.0 * interJitterPC);
	stimDurBase = stimDurFrames - stimJitterFrames;
	interDurBase = interDurFrames - interJitterFrames;

	pTrial->targetOnTimeMS = 0;
 	for (stim = nextStimOnFrame = 0; stim < pTrial->numStim; stim++) {

// Set the default values
	
		stimDesc.gaborIndex = kTaskGabor;
		stimDesc.sequenceIndex = stim;
		stimDesc.stimType = kValidStim;
		stimDesc.contrastPC = 100.0*[taskGabor contrast];
        stimDesc.temporalFreqHz = [taskGabor temporalFreqHz];
		stimDesc.azimuthDeg = [taskGabor azimuthDeg];
		stimDesc.elevationDeg = [taskGabor elevationDeg];
		stimDesc.sigmaDeg = [taskGabor sigmaDeg];
		stimDesc.spatialFreqCPD = [taskGabor spatialFreqCPD];
		stimDesc.directionDeg = [taskGabor directionDeg];
		stimDesc.radiusDeg = [taskGabor radiusDeg];
        stimDesc.temporalModulation = [taskGabor temporalModulation];
        stimDesc.spatialPhaseDeg = [taskGabor spatialPhaseDeg];                 // [Vinay] - added for phase of gabor
	
// If it's not a catch trial and we're in a target spot, set the target 

		if (!pTrial->catchTrial) {
			if ((stimDesc.sequenceIndex == targetIndex) ||
							(stimDesc.sequenceIndex > targetIndex &&
							[[task defaults] boolForKey:CRSChangeRemainKey])) {
				stimDesc.stimType = kTargetStim;
				stimDesc.directionDeg += pTrial->orientationChangeDeg;
			}
		}

// Load the information about the on and off frames
	
		stimDesc.stimOnFrame = nextStimOnFrame;
		if (stimJitterFrames > 0) {
			stimDesc.stimOffFrame = stimDesc.stimOnFrame + 
					MAX(1, stimDurBase + (rand() % (2 * stimJitterFrames + 1)));
		}
		else {
			stimDesc.stimOffFrame = stimDesc.stimOnFrame +  MAX(1, stimDurFrames);
		}
		lastStimOffFrame = stimDesc.stimOffFrame;
		if (interJitterFrames > 0) {
			nextStimOnFrame = stimDesc.stimOffFrame + 
				MAX(1, interDurBase + (rand() % (2 * interJitterFrames + 1)));
		}
		else {
			nextStimOnFrame = stimDesc.stimOffFrame + MAX(0, interDurFrames);
		}

// Set to null if HideTaskGaborKey is set
        if ([[task defaults] boolForKey:CRSHideTaskGaborKey])
            stimDesc.stimType = kNullStim;
        
// Put the stimulus descriptor into the list

		[taskStimList addObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];

// Save the estimated target on time

		if (stimDesc.stimType == kTargetStim) {
			pTrial->targetOnTimeMS = stimDesc.stimOnFrame / frameRateHz * 1000.0;	// this is a theoretical value
		}
	}
//	[self dumpStimList];
	
// The task stim list is done, now we need to get the mapping stim lists

    [[(CRSMap*)task mapStimTable0] makeMapStimList:mapStimList0 index:0 lastFrame:lastStimOffFrame pTrial:pTrial];
	[[(CRSMap*)task mapStimTable1] makeMapStimList:mapStimList1 index:1 lastFrame:lastStimOffFrame pTrial:pTrial];
    [[(CRSMap*)task mapStimTable2] makeMapStimList:mapStimList2 index:2 lastFrame:lastStimOffFrame pTrial:pTrial];          // [Vinay] - for the centre gabor
    
    //===================^^^==========================
    // [Vinay] - the following lines have been added to change stimulus parameters mapping as per the specific protocol requirements
    
    BOOL matchCentreSurround = [[task defaults] boolForKey:CRSMatchCentreSurroundKey]; // To enable or disable matching of centre and surround properties
    
    BOOL matchCR = [[task defaults] boolForKey:CRSMatchCentreRingKey]; // [Vinay] Added later to match centre and ring
    BOOL matchRS = [[task defaults] boolForKey:CRSMatchRingSurroundKey]; // [Vinay] Added later to match ring and surround
    
    int protocolNumber = [[task defaults] integerForKey:@"CRSProtocolNumber"]; // This variable reads the value of the protocol number
    
    // ------------------------------------------------
    // protocolNumber indicates the following protocol:
    // protocolNumber = 0 - do nothing; 1 - ring protocol; 2 - contrast ring; 3 - dual contrast; 4 - dual ori; 5 - dual phase protocol; 6 - ori ring; 7 - phase ring
    // ------------------------------------------------
    
    // [Vinay] - Don't match centre and surround for the dual protocols since the surround is off in these cases anyway.
    // if (([[task defaults] boolForKey:CRSDualContrastProtocolKey]) || ([[task defaults] boolForKey:CRSDualOrientationProtocolKey]) || ([[task defaults] boolForKey:CRSDualPhaseProtocolKey])) { was removed and replaced as following
    if ((protocolNumber == 3) || (protocolNumber == 4) || (protocolNumber == 5)) {
        //[[task defaults] setBool:NO forKey:CRSMatchCentreSurroundKey]; // [Vinay] This line was commented and replaced as below
        matchCentreSurround = NO;
    }
    
    // [Vinay] - disable matchCR and matchRS when using any of the specific protocols
    if (protocolNumber != 0) {
        matchCR = NO;
        matchRS = NO;
    }
    
    // [Vinay] - Match them if it is one of the four ring protocols or if it is explicitly asked to match them.
    // [Vinay] - adding the following lines to copy some surround gabor properties to those of the centre gabor
    NSValue *val, *val2;
    
    // if (([[task defaults] boolForKey:CRSMatchCentreSurroundKey]) || ([[task defaults] boolForKey:CRSRingProtocolKey]) || ([[task defaults] boolForKey:CRSContrastRingProtocolKey])) -  was replaced as follows -
    if ((matchCentreSurround == YES) || (protocolNumber == 1) || (protocolNumber == 2) || (protocolNumber == 6) || (protocolNumber == 7)) {
        //long sfi,di,ci,tfi,spi;
        //float sf, d, c, tf, sp;
        for (stim = 0; stim < [mapStimList0 count]; stim++) {
            val = [mapStimList0 objectAtIndex:stim];
            [val getValue:&copyStimDesc];
            /*
            sfi = copyStimDesc->spatialFreqIndex;
            di = copyStimDesc->directionIndex;
            ci = copyStimDesc->contrastIndex;
            tfi = copyStimDesc->temporalFreqIndex;
            spi = copyStimDesc->spatialPhaseIndex;
            sf = copyStimDesc->spatialFreqCPD;
            d = copyStimDesc->directionDeg;
            c = copyStimDesc->contrastPC;
            tf = copyStimDesc->temporalFreqHz;
            sp = copyStimDesc->spatialPhaseDeg;
            */
            val2 = [mapStimList2 objectAtIndex:stim];
            [val2 getValue:&copyStimDesc2];
            copyStimDesc.radiusDeg = copyStimDesc2.radiusDeg;
            copyStimDesc.radiusIndex = copyStimDesc2.radiusIndex;
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex;
            copyStimDesc.sequenceIndex = copyStimDesc2.sequenceIndex;
            copyStimDesc.stimOnFrame = copyStimDesc2.stimOnFrame;
            copyStimDesc.stimOffFrame = copyStimDesc2.stimOffFrame;
            copyStimDesc.stimType = copyStimDesc2.stimType;
            
            copyStimDesc.azimuthIndex = copyStimDesc2.azimuthIndex;
            copyStimDesc.elevationIndex= copyStimDesc2.elevationIndex;
            copyStimDesc.sigmaIndex = copyStimDesc2.sigmaIndex;
            
            copyStimDesc.azimuthDeg = copyStimDesc2.azimuthDeg;
            copyStimDesc.elevationDeg = copyStimDesc2.elevationDeg;
            copyStimDesc.sigmaDeg = copyStimDesc2.sigmaDeg;
            
            copyStimDesc.temporalModulation = copyStimDesc2.temporalModulation;
            copyStimDesc.orientationChangeDeg = copyStimDesc2.orientationChangeDeg;
            
            
            // [Vinay] - Basically except the five parameters that have to be matched the rest have been restored to the value assigned originally to gabor2 by makeMapStimList
            
            /*
            copyStimDesc->spatialFreqIndex = sfi;
            copyStimDesc->directionIndex = di;
            copyStimDesc->contrastIndex = ci;
            copyStimDesc->temporalFreqIndex = tfi;
            copyStimDesc->spatialPhaseIndex = spi;
            copyStimDesc->spatialFreqCPD = sf;
            copyStimDesc->directionDeg = d;
            copyStimDesc->contrastPC = c;
            copyStimDesc->temporalFreqHz = tf;
            copyStimDesc->spatialPhaseDeg = sp;
             */
            
            [mapStimList2 replaceObjectAtIndex:stim withObject:[NSValue valueWithBytes:&copyStimDesc objCType:@encode(StimDesc)]];
        }
    }
    
    // [Vinay] - Match some parameters of ring gabor with the centre gabor for the contrast ring protocol. Except contrast and radius, the rest of the values are changed to be equal to those of the centre gabor. Trivially azimuth, elevation and sigma are also not changed. If required then they may be matched in the future. Changed this: if (([[task defaults] boolForKey:CRSContrastRingProtocolKey])) to read the value from pop up menu
    if (protocolNumber == 2) {
        for (stim = 0; stim < [mapStimList1 count]; stim++) {
            val = [mapStimList1 objectAtIndex:stim]; // ring gabor
            [val getValue:&copyStimDesc];
            
            val2 = [mapStimList2 objectAtIndex:stim]; // centre gabor
            [val2 getValue:&copyStimDesc2];
            
            //copyStimDesc.radiusDeg = copyStimDesc2.radiusDeg; // [Vinay] - this and next line commented because radius is maintained the same for ring gabor
            //copyStimDesc.radiusIndex = copyStimDesc2.radiusIndex;
            
            copyStimDesc.spatialFreqCPD = copyStimDesc2.spatialFreqCPD;
            copyStimDesc.spatialFreqIndex = copyStimDesc2.spatialFreqIndex;
            
            copyStimDesc.directionDeg = copyStimDesc2.directionDeg;
            copyStimDesc.directionIndex = copyStimDesc2.directionIndex;
            
            copyStimDesc.temporalFreqHz = copyStimDesc2.temporalFreqHz;
            copyStimDesc.temporalFreqIndex = copyStimDesc2.temporalFreqIndex;
            
            copyStimDesc.spatialPhaseDeg = copyStimDesc2.spatialPhaseDeg;
            copyStimDesc.spatialPhaseIndex = copyStimDesc2.spatialPhaseIndex;
            
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex;
            copyStimDesc.sequenceIndex = copyStimDesc2.sequenceIndex;
            copyStimDesc.stimOnFrame = copyStimDesc2.stimOnFrame;
            copyStimDesc.stimOffFrame = copyStimDesc2.stimOffFrame;
            copyStimDesc.stimType = copyStimDesc2.stimType;
            
            copyStimDesc.azimuthIndex = copyStimDesc2.azimuthIndex;
            copyStimDesc.elevationIndex= copyStimDesc2.elevationIndex;
            copyStimDesc.sigmaIndex = copyStimDesc2.sigmaIndex;
            
            copyStimDesc.azimuthDeg = copyStimDesc2.azimuthDeg;
            copyStimDesc.elevationDeg = copyStimDesc2.elevationDeg;
            copyStimDesc.sigmaDeg = copyStimDesc2.sigmaDeg;
            
            copyStimDesc.temporalModulation = copyStimDesc2.temporalModulation;
            copyStimDesc.orientationChangeDeg = copyStimDesc2.orientationChangeDeg;
            
            
            // [Vinay] - Basically except the five parameters that have to be matched the rest have been restored to the value assigned originally to gabor2 by makeMapStimList
            
            [mapStimList1 replaceObjectAtIndex:stim withObject:[NSValue valueWithBytes:&copyStimDesc objCType:@encode(StimDesc)]];
        }
    }
    
    
    // [Vinay] - for Dual Contrast protocol ring radius is maximum (set during mapping). Other than contrast rest of the parameters are matched to those of the centre.
    // if (([[task defaults] boolForKey:CRSDualContrastProtocolKey])) { -  changed this as follows
    if (protocolNumber == 3) {
        for (stim = 0; stim < [mapStimList1 count]; stim++) {
            val = [mapStimList1 objectAtIndex:stim]; // ring gabor
            [val getValue:&copyStimDesc];
            
            val2 = [mapStimList2 objectAtIndex:stim]; // centre gabor
            [val2 getValue:&copyStimDesc2];
            
            //copyStimDesc.radiusDeg = copyStimDesc2.radiusDeg; // [Vinay] - this and next line commented because radius is maintained the same for ring gabor
            //copyStimDesc.radiusIndex = copyStimDesc2.radiusIndex;
            
            copyStimDesc.spatialFreqCPD = copyStimDesc2.spatialFreqCPD;
            copyStimDesc.spatialFreqIndex = copyStimDesc2.spatialFreqIndex;
            
            copyStimDesc.directionDeg = copyStimDesc2.directionDeg;
            copyStimDesc.directionIndex = copyStimDesc2.directionIndex;
            
            copyStimDesc.temporalFreqHz = copyStimDesc2.temporalFreqHz;
            copyStimDesc.temporalFreqIndex = copyStimDesc2.temporalFreqIndex;
            
            copyStimDesc.spatialPhaseDeg = copyStimDesc2.spatialPhaseDeg;
            copyStimDesc.spatialPhaseIndex = copyStimDesc2.spatialPhaseIndex;
            
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex;
            copyStimDesc.sequenceIndex = copyStimDesc2.sequenceIndex;
            copyStimDesc.stimOnFrame = copyStimDesc2.stimOnFrame;
            copyStimDesc.stimOffFrame = copyStimDesc2.stimOffFrame;
            copyStimDesc.stimType = copyStimDesc2.stimType;
            
            copyStimDesc.azimuthIndex = copyStimDesc2.azimuthIndex;
            copyStimDesc.elevationIndex= copyStimDesc2.elevationIndex;
            copyStimDesc.sigmaIndex = copyStimDesc2.sigmaIndex;
            
            copyStimDesc.azimuthDeg = copyStimDesc2.azimuthDeg;
            copyStimDesc.elevationDeg = copyStimDesc2.elevationDeg;
            copyStimDesc.sigmaDeg = copyStimDesc2.sigmaDeg;
            
            copyStimDesc.temporalModulation = copyStimDesc2.temporalModulation;
            copyStimDesc.orientationChangeDeg = copyStimDesc2.orientationChangeDeg;
            
            
            // [Vinay] - Basically except the five parameters that have to be matched the rest have been restored to the value assigned originally to gabor2 by makeMapStimList
            
            [mapStimList1 replaceObjectAtIndex:stim withObject:[NSValue valueWithBytes:&copyStimDesc objCType:@encode(StimDesc)]];
        }
    }
    
    
    // [Vinay] - for Dual Orientation protocol ring radius is maximum (set during mapping). Other than orientation rest of the parameters are matched to those of the centre.
    // if (([[task defaults] boolForKey:CRSDualOrientationProtocolKey])) { - was changed as follows
    if (protocolNumber == 4) {
        for (stim = 0; stim < [mapStimList1 count]; stim++) {
            val = [mapStimList1 objectAtIndex:stim]; // ring gabor
            [val getValue:&copyStimDesc];
            
            val2 = [mapStimList2 objectAtIndex:stim]; // centre gabor
            [val2 getValue:&copyStimDesc2];
            
            //copyStimDesc.radiusDeg = copyStimDesc2.radiusDeg; // [Vinay] - this and next line commented because radius is maintained the same for ring gabor
            //copyStimDesc.radiusIndex = copyStimDesc2.radiusIndex;
            
            copyStimDesc.spatialFreqCPD = copyStimDesc2.spatialFreqCPD;
            copyStimDesc.spatialFreqIndex = copyStimDesc2.spatialFreqIndex;
            
            copyStimDesc.contrastPC = copyStimDesc2.contrastPC;
            copyStimDesc.contrastIndex = copyStimDesc2.contrastIndex;
            
            copyStimDesc.temporalFreqHz = copyStimDesc2.temporalFreqHz;
            copyStimDesc.temporalFreqIndex = copyStimDesc2.temporalFreqIndex;
            
            copyStimDesc.spatialPhaseDeg = copyStimDesc2.spatialPhaseDeg;
            copyStimDesc.spatialPhaseIndex = copyStimDesc2.spatialPhaseIndex;
            
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex;
            copyStimDesc.sequenceIndex = copyStimDesc2.sequenceIndex;
            copyStimDesc.stimOnFrame = copyStimDesc2.stimOnFrame;
            copyStimDesc.stimOffFrame = copyStimDesc2.stimOffFrame;
            copyStimDesc.stimType = copyStimDesc2.stimType;
            
            copyStimDesc.azimuthIndex = copyStimDesc2.azimuthIndex;
            copyStimDesc.elevationIndex= copyStimDesc2.elevationIndex;
            copyStimDesc.sigmaIndex = copyStimDesc2.sigmaIndex;
            
            copyStimDesc.azimuthDeg = copyStimDesc2.azimuthDeg;
            copyStimDesc.elevationDeg = copyStimDesc2.elevationDeg;
            copyStimDesc.sigmaDeg = copyStimDesc2.sigmaDeg;
            
            copyStimDesc.temporalModulation = copyStimDesc2.temporalModulation;
            copyStimDesc.orientationChangeDeg = copyStimDesc2.orientationChangeDeg;
            
            
            // [Vinay] - Basically except the five parameters that have to be matched the rest have been restored to the value assigned originally to gabor2 by makeMapStimList
            
            [mapStimList1 replaceObjectAtIndex:stim withObject:[NSValue valueWithBytes:&copyStimDesc objCType:@encode(StimDesc)]];
        }
    }
    
    
    // [Vinay] - for Dual Phase protocol ring radius is maximum (set during mapping). Other than phase rest of the parameters are matched to those of the centre.
    // if (([[task defaults] boolForKey:CRSDualPhaseProtocolKey])) { - was changed as follows
    if (protocolNumber == 5) {
        for (stim = 0; stim < [mapStimList1 count]; stim++) {
            val = [mapStimList1 objectAtIndex:stim]; // ring gabor
            [val getValue:&copyStimDesc];
            
            val2 = [mapStimList2 objectAtIndex:stim]; // centre gabor
            [val2 getValue:&copyStimDesc2];
            
            //copyStimDesc.radiusDeg = copyStimDesc2.radiusDeg; // [Vinay] - this and next line commented because radius is maintained the same for ring gabor
            //copyStimDesc.radiusIndex = copyStimDesc2.radiusIndex;
            
            copyStimDesc.spatialFreqCPD = copyStimDesc2.spatialFreqCPD;
            copyStimDesc.spatialFreqIndex = copyStimDesc2.spatialFreqIndex;
            
            copyStimDesc.directionDeg = copyStimDesc2.directionDeg;
            copyStimDesc.directionIndex = copyStimDesc2.directionIndex;
            
            copyStimDesc.temporalFreqHz = copyStimDesc2.temporalFreqHz;
            copyStimDesc.temporalFreqIndex = copyStimDesc2.temporalFreqIndex;
            
            copyStimDesc.contrastPC = copyStimDesc2.contrastPC;
            copyStimDesc.contrastIndex = copyStimDesc2.contrastIndex;
            
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex;
            copyStimDesc.sequenceIndex = copyStimDesc2.sequenceIndex;
            copyStimDesc.stimOnFrame = copyStimDesc2.stimOnFrame;
            copyStimDesc.stimOffFrame = copyStimDesc2.stimOffFrame;
            copyStimDesc.stimType = copyStimDesc2.stimType;
            
            copyStimDesc.azimuthIndex = copyStimDesc2.azimuthIndex;
            copyStimDesc.elevationIndex= copyStimDesc2.elevationIndex;
            copyStimDesc.sigmaIndex = copyStimDesc2.sigmaIndex;
            
            copyStimDesc.azimuthDeg = copyStimDesc2.azimuthDeg;
            copyStimDesc.elevationDeg = copyStimDesc2.elevationDeg;
            copyStimDesc.sigmaDeg = copyStimDesc2.sigmaDeg;
            
            copyStimDesc.temporalModulation = copyStimDesc2.temporalModulation;
            copyStimDesc.orientationChangeDeg = copyStimDesc2.orientationChangeDeg;
            
            
            // [Vinay] - Basically except the five parameters that have to be matched the rest have been restored to the value assigned originally to gabor2 by makeMapStimList
            
            [mapStimList1 replaceObjectAtIndex:stim withObject:[NSValue valueWithBytes:&copyStimDesc objCType:@encode(StimDesc)]];
        }
    }
    
    // [Vinay] - Match some parameters of ring gabor with the centre gabor for the orientation ring protocol. Except orientation and radius, the rest of the values are changed to be equal to those of the centre gabor. Trivially azimuth, elevation and sigma are also not changed. If required then they may be matched in the future. Changed this: if (([[task defaults] boolForKey:CRSContrastRingProtocolKey])) to read the value from pop up menu
    if (protocolNumber == 6) {
        for (stim = 0; stim < [mapStimList1 count]; stim++) {
            val = [mapStimList1 objectAtIndex:stim]; // ring gabor
            [val getValue:&copyStimDesc];
            
            val2 = [mapStimList2 objectAtIndex:stim]; // centre gabor
            [val2 getValue:&copyStimDesc2];
            
            //copyStimDesc.radiusDeg = copyStimDesc2.radiusDeg; // [Vinay] - this and next line commented because radius is maintained the same for ring gabor
            //copyStimDesc.radiusIndex = copyStimDesc2.radiusIndex;
            
            copyStimDesc.spatialFreqCPD = copyStimDesc2.spatialFreqCPD;
            copyStimDesc.spatialFreqIndex = copyStimDesc2.spatialFreqIndex;
            
            copyStimDesc.contrastPC = copyStimDesc2.contrastPC;
            copyStimDesc.contrastIndex = copyStimDesc2.contrastIndex;
            
            //copyStimDesc.directionDeg = copyStimDesc2.directionDeg; // [Vinay] - because orientation is maintained for the ring gabor here
            //copyStimDesc.directionIndex = copyStimDesc2.directionIndex;
            
            copyStimDesc.temporalFreqHz = copyStimDesc2.temporalFreqHz;
            copyStimDesc.temporalFreqIndex = copyStimDesc2.temporalFreqIndex;
            
            copyStimDesc.spatialPhaseDeg = copyStimDesc2.spatialPhaseDeg;
            copyStimDesc.spatialPhaseIndex = copyStimDesc2.spatialPhaseIndex;
            
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex;
            copyStimDesc.sequenceIndex = copyStimDesc2.sequenceIndex;
            copyStimDesc.stimOnFrame = copyStimDesc2.stimOnFrame;
            copyStimDesc.stimOffFrame = copyStimDesc2.stimOffFrame;
            copyStimDesc.stimType = copyStimDesc2.stimType;
            
            copyStimDesc.azimuthIndex = copyStimDesc2.azimuthIndex;
            copyStimDesc.elevationIndex= copyStimDesc2.elevationIndex;
            copyStimDesc.sigmaIndex = copyStimDesc2.sigmaIndex;
            
            copyStimDesc.azimuthDeg = copyStimDesc2.azimuthDeg;
            copyStimDesc.elevationDeg = copyStimDesc2.elevationDeg;
            copyStimDesc.sigmaDeg = copyStimDesc2.sigmaDeg;
            
            copyStimDesc.temporalModulation = copyStimDesc2.temporalModulation;
            copyStimDesc.orientationChangeDeg = copyStimDesc2.orientationChangeDeg;
            
            
            // [Vinay] - Basically except the five parameters that have to be matched the rest have been restored to the value assigned originally to gabor2 by makeMapStimList
            
            [mapStimList1 replaceObjectAtIndex:stim withObject:[NSValue valueWithBytes:&copyStimDesc objCType:@encode(StimDesc)]];
        }
    }
    
    
    // [Vinay] - Match some parameters of ring gabor with the centre gabor for the phase ring protocol. Except phase and radius, the rest of the values are changed to be equal to those of the centre gabor. Trivially azimuth, elevation and sigma are also not changed. If required then they may be matched in the future. Changed this: if (([[task defaults] boolForKey:CRSContrastRingProtocolKey])) to read the value from pop up menu
    if (protocolNumber == 7) {
        for (stim = 0; stim < [mapStimList1 count]; stim++) {
            val = [mapStimList1 objectAtIndex:stim]; // ring gabor
            [val getValue:&copyStimDesc];
            
            val2 = [mapStimList2 objectAtIndex:stim]; // centre gabor
            [val2 getValue:&copyStimDesc2];
            
            //copyStimDesc.radiusDeg = copyStimDesc2.radiusDeg; // [Vinay] - this and next line commented because radius is maintained the same for ring gabor
            //copyStimDesc.radiusIndex = copyStimDesc2.radiusIndex;
            
            copyStimDesc.spatialFreqCPD = copyStimDesc2.spatialFreqCPD;
            copyStimDesc.spatialFreqIndex = copyStimDesc2.spatialFreqIndex;
            
            copyStimDesc.contrastPC = copyStimDesc2.contrastPC;
            copyStimDesc.contrastIndex = copyStimDesc2.contrastIndex;
            
            copyStimDesc.directionDeg = copyStimDesc2.directionDeg;
            copyStimDesc.directionIndex = copyStimDesc2.directionIndex;
            
            copyStimDesc.temporalFreqHz = copyStimDesc2.temporalFreqHz;
            copyStimDesc.temporalFreqIndex = copyStimDesc2.temporalFreqIndex;
            
            //copyStimDesc.spatialPhaseDeg = copyStimDesc2.spatialPhaseDeg; // [Vinay] - because phase is maintained for the ring gabor here
            //copyStimDesc.spatialPhaseIndex = copyStimDesc2.spatialPhaseIndex;
            
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex;
            copyStimDesc.sequenceIndex = copyStimDesc2.sequenceIndex;
            copyStimDesc.stimOnFrame = copyStimDesc2.stimOnFrame;
            copyStimDesc.stimOffFrame = copyStimDesc2.stimOffFrame;
            copyStimDesc.stimType = copyStimDesc2.stimType;
            
            copyStimDesc.azimuthIndex = copyStimDesc2.azimuthIndex;
            copyStimDesc.elevationIndex= copyStimDesc2.elevationIndex;
            copyStimDesc.sigmaIndex = copyStimDesc2.sigmaIndex;
            
            copyStimDesc.azimuthDeg = copyStimDesc2.azimuthDeg;
            copyStimDesc.elevationDeg = copyStimDesc2.elevationDeg;
            copyStimDesc.sigmaDeg = copyStimDesc2.sigmaDeg;
            
            copyStimDesc.temporalModulation = copyStimDesc2.temporalModulation;
            copyStimDesc.orientationChangeDeg = copyStimDesc2.orientationChangeDeg;
            
            
            // [Vinay] - Basically except the five parameters that have to be matched the rest have been restored to the value assigned originally to gabor2 by makeMapStimList
            
            [mapStimList1 replaceObjectAtIndex:stim withObject:[NSValue valueWithBytes:&copyStimDesc objCType:@encode(StimDesc)]];
        }
    }
    
    /*
    // [Vinay] - To match centre and ring if required
    if ((matchCR == YES) && (protocolNumber == 0)) {
        //long sfi,di,ci,tfi,spi;
        //float sf, d, c, tf, sp;
        for (stim = 0; stim < [mapStimList2 count]; stim++) {
            val = [mapStimList2 objectAtIndex:stim]; // centre
            [val getValue:&copyStimDesc];
            
            val2 = [mapStimList1 objectAtIndex:stim]; // ring
            [val2 getValue:&copyStimDesc2];
            copyStimDesc.radiusDeg = copyStimDesc2.radiusDeg;
            copyStimDesc.radiusIndex = copyStimDesc2.radiusIndex;
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex;
            copyStimDesc.sequenceIndex = copyStimDesc2.sequenceIndex;
            copyStimDesc.stimOnFrame = copyStimDesc2.stimOnFrame;
            copyStimDesc.stimOffFrame = copyStimDesc2.stimOffFrame;
            copyStimDesc.stimType = copyStimDesc2.stimType;
            
            copyStimDesc.azimuthIndex = copyStimDesc2.azimuthIndex;
            copyStimDesc.elevationIndex= copyStimDesc2.elevationIndex;
            copyStimDesc.sigmaIndex = copyStimDesc2.sigmaIndex;
            
            copyStimDesc.azimuthDeg = copyStimDesc2.azimuthDeg;
            copyStimDesc.elevationDeg = copyStimDesc2.elevationDeg;
            copyStimDesc.sigmaDeg = copyStimDesc2.sigmaDeg;
            
            copyStimDesc.temporalModulation = copyStimDesc2.temporalModulation;
            copyStimDesc.orientationChangeDeg = copyStimDesc2.orientationChangeDeg;
            
            
            // [Vinay] - Basically except the five parameters that have to be matched the rest have been restored to the value assigned originally to gabor2 by makeMapStimList
            
            [mapStimList1 replaceObjectAtIndex:stim withObject:[NSValue valueWithBytes:&copyStimDesc objCType:@encode(StimDesc)]];
        }
    }
    
    
    // [Vinay] - To match ring and surround if required
    if ((matchRS == YES) && (protocolNumber == 0)) {
        //long sfi,di,ci,tfi,spi;
        //float sf, d, c, tf, sp;
        for (stim = 0; stim < [mapStimList0 count]; stim++) {
            val = [mapStimList0 objectAtIndex:stim]; // surround
            [val getValue:&copyStimDesc];
            
            val2 = [mapStimList1 objectAtIndex:stim]; // ring
            [val2 getValue:&copyStimDesc2];
            copyStimDesc.radiusDeg = copyStimDesc2.radiusDeg;
            copyStimDesc.radiusIndex = copyStimDesc2.radiusIndex;
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex;
            copyStimDesc.sequenceIndex = copyStimDesc2.sequenceIndex;
            copyStimDesc.stimOnFrame = copyStimDesc2.stimOnFrame;
            copyStimDesc.stimOffFrame = copyStimDesc2.stimOffFrame;
            copyStimDesc.stimType = copyStimDesc2.stimType;
            
            copyStimDesc.azimuthIndex = copyStimDesc2.azimuthIndex;
            copyStimDesc.elevationIndex= copyStimDesc2.elevationIndex;
            copyStimDesc.sigmaIndex = copyStimDesc2.sigmaIndex;
            
            copyStimDesc.azimuthDeg = copyStimDesc2.azimuthDeg;
            copyStimDesc.elevationDeg = copyStimDesc2.elevationDeg;
            copyStimDesc.sigmaDeg = copyStimDesc2.sigmaDeg;
            
            copyStimDesc.temporalModulation = copyStimDesc2.temporalModulation;
            copyStimDesc.orientationChangeDeg = copyStimDesc2.orientationChangeDeg;
            
            
            // [Vinay] - Basically except the five parameters that have to be matched the rest have been restored to the value assigned originally to gabor2 by makeMapStimList
            
            [mapStimList1 replaceObjectAtIndex:stim withObject:[NSValue valueWithBytes:&copyStimDesc objCType:@encode(StimDesc)]];
        }
    }
    */
    //==========================___============================== [Vinay] - till here

}
	
- (void)loadGabor:(LLGabor *)gabor withStimDesc:(StimDesc *)pSD;
{	
	if (pSD->spatialFreqCPD == 0) {					// Change made by Incheol and Kaushik to get gaussians
		[gabor directSetSpatialPhaseDeg:90.0];
	}
	[gabor directSetSigmaDeg:pSD->sigmaDeg];		// *** Should be directSetSigmaDeg
	[gabor directSetRadiusDeg:pSD->radiusDeg];
	[gabor directSetAzimuthDeg:pSD->azimuthDeg elevationDeg:pSD->elevationDeg];
	[gabor directSetSpatialFreqCPD:pSD->spatialFreqCPD];
	[gabor directSetDirectionDeg:pSD->directionDeg];
	[gabor directSetContrast:pSD->contrastPC / 100.0];
    [gabor directSetTemporalFreqHz:pSD->temporalFreqHz];
    [gabor setTemporalModulation:pSD->temporalModulation];
    [gabor directSetSpatialPhaseDeg:pSD->spatialPhaseDeg];          // [Vinay] - added for gabor phase
}

- (void)clearStimLists:(TrialDesc *)pTrial
{
	// tally stim lists first?
	[mapStimList0 removeAllObjects];
	[mapStimList1 removeAllObjects];
    [mapStimList2 removeAllObjects];            // [Vinay] - for centre gabor
}

- (LLGabor *)mappingGabor0;
{
	return [gabors objectAtIndex:kMapGabor0];
}

- (LLGabor *)mappingGabor1;
{
	return [gabors objectAtIndex:kMapGabor1];
}

// ------------------------------------------
// [Vinay] - Adding another gabor - the 'centre gabor'
- (LLGabor *)mappingGabor2;
{
	return [gabors objectAtIndex:kMapGabor2];
}
// ------------------------------------------

- (LLIntervalMonitor *)monitor;
{
	return monitor;
}

- (void)presentStimSequence;
{
    long index, trialFrame, taskGaborFrame;
	NSArray *stimLists;
	StimDesc stimDescs[kGabors], *pSD;
	long stimIndices[kGabors];
	long stimOffFrames[kGabors];
	long gaborFrames[kGabors];
	LLGabor *theGabor;
	NSAutoreleasePool *threadPool;
	BOOL listDone = NO;
	long stimCounter = 0;
	
    threadPool = [[NSAutoreleasePool alloc] init];		// create a threadPool for this thread
	[LLSystemUtil setThreadPriorityPeriodMS:1.0 computationFraction:0.250 constraintFraction:1.0];
	
	stimLists = [[NSArray arrayWithObjects:taskStimList, mapStimList0, mapStimList1, mapStimList2, nil] retain];            // [Vinay] - mapStimList2 added for the centre gabor

// Set up the stimulus calibration, including the offset then present the stimulus sequence

	[[task stimWindow] lock];
	[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
	[[task stimWindow] scaleDisplay];

// Set up the gabors

	[gabors makeObjectsPerformSelector:@selector(store)];
	for (index = 0; index < kGabors; index++) {
		stimIndices[index] = 0;
		gaborFrames[index] = 0;
		[[[stimLists objectAtIndex:index] objectAtIndex:0] getValue:&stimDescs[index]];
		[self loadGabor:[gabors objectAtIndex:index] withStimDesc:&stimDescs[index]];
		stimOffFrames[index] = stimDescs[index].stimOffFrame;
	}
	
	targetOnFrame = -1;

    for (trialFrame = taskGaborFrame = 0; !listDone && !abortStimuli; trialFrame++) {
		glClear(GL_COLOR_BUFFER_BIT);
		for (index = 0; index < kGabors; index++) {
			if (trialFrame >= stimDescs[index].stimOnFrame && trialFrame < stimDescs[index].stimOffFrame) {
				if (stimDescs[index].stimType != kNullStim) {
                    theGabor = [gabors objectAtIndex:index];
                    // [Vinay] - have commented the line below and now uncommented
                    [theGabor directSetFrame:[NSNumber numberWithLong:gaborFrames[index]]];	// advance for temporal modulation
                    [theGabor draw];
                }
				gaborFrames[index]++;
			}
		}
		[fixSpot draw];
		[[NSOpenGLContext currentContext] flushBuffer];
		glFinish();
		if (trialFrame == 0) {
			[monitor reset];
		}
		else {
			[monitor recordEvent];
		}

// Update Gabors as needed

		for (index = 0; index < kGabors; index++) {
			pSD = &stimDescs[index];

 // If this is the frame after the last draw of a stimulus, post an event declaring it off.  We have to do this first,
 // because the off of one stimulus may occur on the same frame as the on of the next

			if (trialFrame == stimOffFrames[index]) {
				[[task dataDoc] putEvent:@"stimulusOffTime"]; 
				[[task dataDoc] putEvent:@"stimulusOff" withData:&index];
                [digitalOut outputEventName:@"stimulusOff" withData:0x0000];
				if (++stimIndices[index] >= [[stimLists objectAtIndex:index] count]) {	// no more entries in list
					listDone = YES;
				}
			}
			
// If this is the first frame of a Gabor, post an event describing it

			if (trialFrame == pSD->stimOnFrame) {
				[[task dataDoc] putEvent:@"stimulusOnTime"]; 
				[[task dataDoc] putEvent:@"stimulusOn" withData:&index]; 
				[[task dataDoc] putEvent:@"stimulus" withData:pSD];
                [digitalOut outputEvent:0x00Fe withData:stimCounter++];
                
				// put the digital events
				if (index == kTaskGabor) {
					[digitalOut outputEventName:@"taskGabor" withData:(long)(pSD->stimType)];
				}
				else {
					if (pSD->stimType != kNullStim) {
						if (index == kMapGabor0)
							[digitalOut outputEventName:@"mapping0" withData:(long)(pSD->stimType)];
						if (index == kMapGabor1)
							[digitalOut outputEventName:@"mapping1" withData:(long)(pSD->stimType)];
                        if (index == kMapGabor2)
							[digitalOut outputEventName:@"mapping2" withData:(long)(pSD->stimType)];            // [Vinay] - for centre gabor
					}
				}
				
				// Other prperties of the Gabor
				if (index == kMapGabor0 && pSD->stimType != kNullStim && !([[task defaults] boolForKey:CRSHideSurroundDigitalKey])) {
                    // [Vinay] - CRSHideLeftDigitalKey changed to the above
					//NSLog(@"Sending left digital codes...");
					[digitalOut outputEventName:@"contrast" withData:(long)(100*(pSD->contrastPC))];
                    [digitalOut outputEventName:@"temporalFreq" withData:(long)(100*(pSD->temporalFreqHz))];
					[digitalOut outputEventName:@"azimuth" withData:(long)(100*(pSD->azimuthDeg))];
					[digitalOut outputEventName:@"elevation" withData:(long)(100*(pSD->elevationDeg))];
					[digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
					[digitalOut outputEventName:@"spatialFreq" withData:(long)(100*(pSD->spatialFreqCPD))];
					[digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
					[digitalOut outputEventName:@"sigma" withData:(long)(100*(pSD->sigmaDeg))];
                    [digitalOut outputEventName:@"spatialPhase" withData:(long)(pSD->spatialPhaseDeg)];
				}
				
				if (index == kMapGabor1 && pSD->stimType != kNullStim && !([[task defaults] boolForKey:CRSHideRingDigitalKey])) {
					// [Vinay] - CRSHideRightDigitalKey changed to the above
                    //NSLog(@"Sending right digital codes...");
					[digitalOut outputEventName:@"contrast" withData:(long)(100*(pSD->contrastPC))];
                    [digitalOut outputEventName:@"temporalFreq" withData:(long)(100*(pSD->temporalFreqHz))];
					[digitalOut outputEventName:@"azimuth" withData:(long)(100*(pSD->azimuthDeg))];
					[digitalOut outputEventName:@"elevation" withData:(long)(100*(pSD->elevationDeg))];
					[digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
					[digitalOut outputEventName:@"spatialFreq" withData:(long)(100*(pSD->spatialFreqCPD))];
					[digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
					[digitalOut outputEventName:@"sigma" withData:(long)(100*(pSD->sigmaDeg))];
                    [digitalOut outputEventName:@"spatialPhase" withData:(long)(pSD->spatialPhaseDeg)];
				}
                
                if (index == kMapGabor2 && pSD->stimType != kNullStim && !([[task defaults] boolForKey:CRSHideCentreDigitalKey])) {                                            // [Vinay] - for centre gabor. Not sure what would be the equivalent 'digital key' for this case i.e. Left or Right Digital codes as above. Clarify this!
                    // [Vinay] - added the relevant CRSHideCentreDigitalKey
					//NSLog(@"Sending right digital codes...");
					[digitalOut outputEventName:@"contrast" withData:(long)(100*(pSD->contrastPC))];
                    [digitalOut outputEventName:@"temporalFreq" withData:(long)(100*(pSD->temporalFreqHz))];
					[digitalOut outputEventName:@"azimuth" withData:(long)(100*(pSD->azimuthDeg))];
					[digitalOut outputEventName:@"elevation" withData:(long)(100*(pSD->elevationDeg))];
					[digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
					[digitalOut outputEventName:@"spatialFreq" withData:(long)(100*(pSD->spatialFreqCPD))];
					[digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
					[digitalOut outputEventName:@"sigma" withData:(long)(100*(pSD->sigmaDeg))];
                    [digitalOut outputEventName:@"spatialPhase" withData:(long)(pSD->spatialPhaseDeg)];
				}
                
				if (pSD->stimType == kTargetStim) {
					targetPresented = YES;
					targetOnFrame = trialFrame;
				}
				stimOffFrames[index] = stimDescs[index].stimOffFrame;		// previous done by now, save time for this one
			}

// If we've drawn the current stimulus for the last time, load the Gabor with the next stimulus settings

			if (trialFrame == stimOffFrames[index] - 1) {
				if ((stimIndices[index] + 1) < [[stimLists objectAtIndex:index] count]) {	// check there are more
					[[[stimLists objectAtIndex:index] objectAtIndex:(stimIndices[index] + 1)] getValue:&stimDescs[index]];
				[self loadGabor:[gabors objectAtIndex:index] withStimDesc:&stimDescs[index]];
					gaborFrames[index] = 0;
				}
			}
		}
    }
	
// If there was no target (catch trial), we nevertheless need to set a valid targetOnFrame time (now)

	targetOnFrame = (targetOnFrame < 0) ? trialFrame : targetOnFrame;

// Clear the display and leave the back buffer cleared

    glClear(GL_COLOR_BUFFER_BIT);
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();

	[[task stimWindow] unlock];
	
// The temporal counterphase might have changed some settings.  We restore these here.

	[gabors makeObjectsPerformSelector:@selector(restore)];
	stimulusOn = abortStimuli = NO;
	[stimLists release];
    [threadPool release];
}

- (void)setFixSpot:(BOOL)state;
{
	[fixSpot setState:state];
	if (state) {
		if (!stimulusOn) {
			[[task stimWindow] lock];
			[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
			[[task stimWindow] scaleDisplay];
			glClear(GL_COLOR_BUFFER_BIT);
			[fixSpot draw];
			[[NSOpenGLContext currentContext] flushBuffer];
			[[task stimWindow] unlock];
		}
	}
}

// Shuffle the stimulus sequence by repeated passed along the list and paired substitution

- (void)shuffleStimListFrom:(short)start count:(short)count;
{
	long rep, reps, stim, index, temp, indices[kMaxOriChanges];
	NSArray *block;
	
	reps = 5;	
	for (stim = 0; stim < count; stim++) {			// load the array of indices
		indices[stim] = stim;
	}
	for (rep = 0; rep < reps; rep++) {				// shuffle the array of indices
		for (stim = 0; stim < count; stim++) {
			index = rand() % count;
			temp = indices[index];
			indices[index] = indices[stim];
			indices[stim] = temp;
		}
	}
	block = [taskStimList subarrayWithRange:NSMakeRange(start, count)];
	for (index = 0; index < count; index++) {
		[taskStimList replaceObjectAtIndex:(start + index) withObject:[block objectAtIndex:indices[index]]];
	}
}

- (void)startStimSequence;
{
	if (stimulusOn) {
		return;
	}
	stimulusOn = YES;
	targetPresented = NO;
	[NSThread detachNewThreadSelector:@selector(presentStimSequence) toTarget:self
				withObject:nil];
}

- (BOOL)stimulusOn;
{
	return stimulusOn;
}

// Stop on-going stimulation and clear the display

- (void)stopAllStimuli;
{
	if (stimulusOn) {
		abortStimuli = YES;
		while (stimulusOn) {};
	}
	else {
		[stimuli setFixSpot:NO];
		[self erase];
	}
}

- (void)tallyStimLists:(long)count
{
	[[(CRSMap *)task mapStimTable0] tallyStimList:mapStimList0 count:count];
	[[(CRSMap *)task mapStimTable1] tallyStimList:mapStimList1 count:count];
    [[(CRSMap *)task mapStimTable2] tallyStimList:mapStimList2 count:count];            // [Vinay] - for centre gabor
}

- (long)targetOnFrame;
{
	return targetOnFrame;
}

- (BOOL)targetPresented;
{
	return targetPresented;
}

- (LLGabor *)taskGabor;
{
	return [gabors objectAtIndex:kTaskGabor];
}

@end
