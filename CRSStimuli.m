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
    [targetSpot release];
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

	gabors = [[NSArray arrayWithObjects:[self initGabor:YES],
               [self initGabor:NO], [self initGabor:NO], [self initGabor:NO], nil] retain];         // [Vinay] - one extra [self initGabor] added here for centre gabor
    // [Vinay] - added YES, NO arguments as per the latest GaborRFMap protocol (07/06/2014 version)
	[[gabors objectAtIndex:kMapGabor0] setAchromatic:YES];
	[[gabors objectAtIndex:kMapGabor1] setAchromatic:YES];
    [[gabors objectAtIndex:kMapGabor2] setAchromatic:YES];                  // [Vinay] - for centre gabor
	fixSpot = [[LLFixTarget alloc] init];
	[fixSpot bindValuesToKeysWithPrefix:@"CRSFix"];
    targetSpot = [[LLFixTarget alloc] init];
	//[targetSpot bindValuesToKeysWithPrefix:@"CRSFix"];


	return self;
}

- (LLGabor *)initGabor:(BOOL)bindTemporalFreq;
{
	static long counter = 0;
	LLGabor *gabor;
	
	gabor = [[LLGabor alloc] init];				// Create a gabor stimulus
	[gabor setDisplays:[[task stimWindow] displays] displayIndex:[[task stimWindow] displayIndex]];

    //[gabor removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborDirectionDegKey,
    //                LLGaborTemporalPhaseDegKey, LLGaborSpatialPhaseDegKey, nil]]; // [Vinay] - I have commented these just to check their effect

    if (bindTemporalFreq) {
        [gabor removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborDirectionDegKey, 
                    LLGaborTemporalPhaseDegKey, LLGaborContrastKey, LLGaborSpatialPhaseDegKey, nil]];
    }
    else {
        [gabor removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborDirectionDegKey, LLGaborTemporalPhaseDegKey,
                    LLGaborContrastKey, LLGaborSpatialPhaseDegKey, LLGaborTemporalFreqHzKey, nil]];
    }
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
	
    trial = *pTrial;
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
/*
    // randomize
    if ([[task defaults] boolForKey:CRSRandTaskGaborDirectionKey]) {
        [taskGabor setDirectionDeg:rand() % 180];
    }
*/
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
                (stimDesc.sequenceIndex > targetIndex && [[task defaults] boolForKey:CRSChangeRemainKey])) {
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
    // 8 - drifting phase protocol; 9 - cross orientation suppression protocol (COS) (Don't use this as yet); 10 - Annulus fixed protocol (annulus width is fixed, but radius changes)
    // ------------------------------------------------
    
    // [Vinay] - Don't match centre and surround for the dual protocols since the surround is off in these cases anyway. Same applies to the COS protocol
    // if (([[task defaults] boolForKey:CRSDualContrastProtocolKey]) || ([[task defaults] boolForKey:CRSDualOrientationProtocolKey]) || ([[task defaults] boolForKey:CRSDualPhaseProtocolKey])) { was removed and replaced as following
    if ((protocolNumber == 3) || (protocolNumber == 4) || (protocolNumber == 5) || (protocolNumber == 9)) {
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
    if ((matchCentreSurround == YES) || (protocolNumber == 1) || (protocolNumber == 2) || (protocolNumber == 6) || (protocolNumber == 7) || (protocolNumber == 8) || (protocolNumber == 10)) {
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
            
            copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex; // [Vinay] - keep the gaborIndex the same, else there are two gabors with same index number and it would become difficult to read their parameters later. In this case, since the copyStimDesc corresponding to gabor0 is being written to mapStimList2 corresponding to gabor2 we replace the gaborIndex accordingly. Basicially if the same stimDesc as corresponding to the gabor being remapped is being copied then there's no need to change the gaborIndex. However, it needs to be restored to the correct gaborIndex otherwise.
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
            
            //copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex; // [Vinay] - keep the gaborIndex the same, else there are two gabors with same index number and it would become difficult to read their parameters later
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
            
            //copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex; // [Vinay] - keep the gaborIndex the same, else there are two gabors with same index number and it would become difficult to read their parameters later
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
            
            //copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex; // [Vinay] - keep the gaborIndex the same, else there are two gabors with same index number and it would become difficult to read their parameters later
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
            
            //copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex; // [Vinay] - keep the gaborIndex the same, else there are two gabors with same index number and it would become difficult to read their parameters later
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
            
            //copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex; // [Vinay] - keep the gaborIndex the same, else there are two gabors with same index number and it would become difficult to read their parameters later
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
            
            //copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex; // // [Vinay] - keep the gaborIndex the same, else there are two gabors with same index number and it would become difficult to read their parameters later
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
    
    
    // [Vinay] - Match some parameters of ring gabor with the centre gabor for the drifting phase protocol. Except temporal frequency and radius, the rest of the values are changed to be equal to those of the centre gabor. Trivially azimuth, elevation and sigma are also not changed. If required then they may be matched in the future. Changed this: if (([[task defaults] boolForKey:CRSContrastRingProtocolKey])) to read the value from pop up menu
    if (protocolNumber == 8) {
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
            
            //copyStimDesc.temporalFreqHz = copyStimDesc2.temporalFreqHz;
            //copyStimDesc.temporalFreqIndex = copyStimDesc2.temporalFreqIndex;
            
            copyStimDesc.spatialPhaseDeg = copyStimDesc2.spatialPhaseDeg; // [Vinay] - because phase is maintained for the ring gabor here
            copyStimDesc.spatialPhaseIndex = copyStimDesc2.spatialPhaseIndex;
            
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            //copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex; // [Vinay] - keep the gaborIndex the same, else there are two gabors with same index number and it would become difficult to read their parameters later
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

    
    // [Vinay] - Centre is matched to the Surround already (in an earlier loop). Ring contrast is set to zero in CRSMapStimTable.m. However, if required we can have a non-zero contrast (by removing that option from CRSMapStimTable.m). The properties of ring are matched to those of the centre keeping that option in mind. When the contrast is zero, this part is redundant anyway.
    //  [Vinay] - Key operation here is that the annulus width is set by the radius specified for the ring gabor. So the ring radius has to be reset to be equal to "ring radius + centre radius" so that the annulus is of the required width.
    if (protocolNumber == 10) {
        for (stim = 0; stim < [mapStimList1 count]; stim++) {
            val = [mapStimList1 objectAtIndex:stim]; // ring gabor
            [val getValue:&copyStimDesc];
            
            val2 = [mapStimList2 objectAtIndex:stim]; // centre gabor
            [val2 getValue:&copyStimDesc2];
            
            copyStimDesc.radiusDeg = copyStimDesc.radiusDeg + copyStimDesc2.radiusDeg; // [Vinay] - adjusting the ring radius to get teh required annulus width
            copyStimDesc.radiusIndex = copyStimDesc2.radiusIndex;
            
            copyStimDesc.spatialFreqCPD = copyStimDesc2.spatialFreqCPD;
            copyStimDesc.spatialFreqIndex = copyStimDesc2.spatialFreqIndex;
            
            copyStimDesc.directionDeg = copyStimDesc2.directionDeg;
            copyStimDesc.directionIndex = copyStimDesc2.directionIndex;
            
            copyStimDesc.temporalFreqHz = copyStimDesc2.temporalFreqHz;
            copyStimDesc.temporalFreqIndex = copyStimDesc2.temporalFreqIndex;
            
            copyStimDesc.spatialPhaseDeg = copyStimDesc2.spatialPhaseDeg;
            copyStimDesc.spatialPhaseIndex = copyStimDesc2.spatialPhaseIndex;
            
            // [Vinay] - The following line were added later to copy some more parameters so that LL data can be read consistently
            
            //copyStimDesc.gaborIndex = copyStimDesc2.gaborIndex; // [Vinay] - keep the gaborIndex the same, else there are two gabors with same index number and it would become difficult to read their parameters later
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
    // [Vinay] - To match centre and ring if required. NOTE: Later this has been commented. This matching is instead achieved by just 'not drawing' the centre gabor by setting its hideStimulus in CRSMapStimTable
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
    
    
     // [Vinay] - To match ring and surround if required. NOTE: Later this has been commented. This matching is instead achieved by just 'not drawing' the centre gabor by setting its hideStimulus in CRSMapStimTable
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
	[gabor directSetSpatialPhaseDeg:pSD->spatialPhaseDeg];          // [Vinay] - added for gabor phase
    // [Vinay] - later moved this above the following loop, otherwise that loop is overridden by this assignment
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
    if (pSD->temporalFreqHz == [[task stimWindow] frameRateHz]/2) { // [Vinay] - added this to adjust the temporal phase when the temporal frequency = (refresh rate)/2 (the maximum level allowed) so that each frame doesn't capture the zero level but the max and min levels every alternate frame
        [gabor directSetTemporalPhaseDeg:90.0];
    }
    else {
        [gabor directSetTemporalPhaseDeg:0];
    }
    
    //[Vinay] - For the dual phase protocol and the phase ring protocol, if TF is non-zero then the spatial phase is reset as per the temporal phase while enabling the drifting for the gabors. Therefore the phase shift between centre and ring is not drawn (they have the same phase). To avoid this set the value of temporal phase to that of spatial phase in case TF is non-zero
    if ([[task defaults] integerForKey:@"CRSProtocolNumber"] == 5 || [[task defaults] integerForKey:@"CRSProtocolNumber"] == 7) {
        if (pSD->temporalFreqHz != 0) {
            [gabor directSetTemporalPhaseDeg:pSD->spatialPhaseDeg];
        }
    }
    
    [gabor setTemporalModulation:pSD->temporalModulation];
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
//	long stimCounter = 0;
    BOOL useSingleITC18;
//	long stimCounter = 0; // [Vinay] = commented because it is not being used
    
    /* [Vinay] - Added these lines and some more ahead to conditionally make the gabors partially transparent by adjusting their alpha values. This way superimposed gabors can look like a plaid */
    int protocolNumber = [[task defaults] integerForKey:@"CRSProtocolNumber"];
    BOOL crossOrientationProtocol = NO; // [Vinay] - Added to check for the COS protocol condition to draw superimposed, partially transparent gabors so that it looks like a plaid
    if (protocolNumber == 9)
        crossOrientationProtocol = YES;
    // [Vinay] - till here
	
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
    
    // Set up the targetSpot if needed
/*
    if ([[task defaults] boolForKey:CRSAlphaTargetDetectionTaskKey]) {
        [targetSpot setState:YES];
        NSColor *targetColor = [[fixSpot foreColor]retain];
        [targetSpot setForeColor:[targetColor colorWithAlphaComponent:[[task defaults] floatForKey:CRSTargetAlphaKey]]];
        [targetSpot setOuterRadiusDeg:[[task defaults]floatForKey:CRSTargetRadiusKey]];
        [targetSpot setShape:kLLCircle];
        [targetColor release];
    }
*/	
	targetOnFrame = -1;

    for (trialFrame = taskGaborFrame = 0; !listDone && !abortStimuli; trialFrame++) {
		glClear(GL_COLOR_BUFFER_BIT);
        
        if (crossOrientationProtocol) {
            // [Vinay] - adding these lines to test transparency options
            glDisable(GL_DEPTH_TEST);
            glActiveTexture(GL_TEXTURE1_ARB);				// activate texture unit 0 and cycle texture
            glEnable(GL_TEXTURE_2D);
            
            glPushMatrix(); // [Vinay]
            glPushAttrib(GL_COLOR_BUFFER_BIT); // [Vinay] - testing transparency options
            glEnable (GL_BLEND); // [Vinay] - testing transparency options
            //glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);
            glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); // [Vinay] - testing transparency options
            //glBlendFuncSeparate(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA, GL_ONE, GL_ONE);
            //glBlendFunc (GL_ONE, GL_); // [Vinay] - testing transparency options
        }
		for (index = 0; index < kGabors; index++) {
			if (trialFrame >= stimDescs[index].stimOnFrame && trialFrame < stimDescs[index].stimOffFrame) {
				if (stimDescs[index].stimType != kNullStim) {
                    theGabor = [gabors objectAtIndex:index];
                    // [Vinay] - have commented the line below and now uncommented
                    [theGabor directSetFrame:[NSNumber numberWithLong:gaborFrames[index]]];	// advance for temporal modulation
                    if (crossOrientationProtocol) {
                        [theGabor setForeColor:[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:0.33]]; // [Vinay] - testing transparency options
                    }
                    else {
                        [theGabor setForeColor:[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1]]; // [Vinay] - change alpha back to 1 when it is not the COS protocol
                    }
                    [theGabor draw];
/*
                    if (!trial.catchTrial && index == kTaskGabor && stimDescs[index].stimType == kTargetStim) {
                        [targetSpot setAzimuthDeg:stimDescs[index].azimuthDeg elevationDeg:stimDescs[index].elevationDeg];
                        [targetSpot draw];
                    }
*/
                    gaborFrames[index]++;
                }
			}
		}
        
        if (crossOrientationProtocol) {
            glDisable(GL_BLEND); // [Vinay] - testing transparency options
            glPopAttrib();
            glPopMatrix();
            glActiveTexture(GL_TEXTURE1_ARB);		// Do texture unit 0 last, so we leave it active (for other tasks)
            glDisable(GL_TEXTURE_2D);
            
            
            //[fixSpot setForeColor:[NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:0.33]];
            //[fixSpot setFixTargetColor:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.33]]; // [Vinay] - Added to redraw fixSpot properly
        }
		
        /**** [Vinay] - till here   */
        
        
        /*-----[Vinay] Adding lines to show a centred image */
        
        if ([[task defaults] boolForKey:CRSFixImageKey]) {
            
            //[[task stimWindow] unlock];
            //NSString* imageName = [[NSBundle mainBundle] pathForResource:@"/Users/vinay/Downloads/Bonnet Macaque.JPG" ofType:@"JPG"];
            //NSImage* tempImage = [[NSImage alloc] initWithContentsOfFile:imageName];
            //NSImage *tempImage = [NSImage imageNamed:@"/Users/vinay/Downloads/R94LG00Z.jpg"];
            
            NSImage* tempImage = [[NSImage alloc] initWithContentsOfFile:@"/Users/vinay/Downloads/bm1.tiff"];
            
            NSLog(@"size %f %f",tempImage.size.width, tempImage.size.height);
            if( tempImage ){
                NSLog(@"Picture is not null");
            }else {
                NSLog(@"Picture is null.");
            }
            
            //[tempImage drawAtPoint: NSMakePoint(0.0, 0.0)
            //              fromRect: NSMakeRect(0.0, 0.0, 100.0, 100.0)
            //             operation: NSCompositeCopy
            //              fraction: 1.0];
            NSSize imageSize = [tempImage size];
            NSRect imageRect = NSMakeRect(-imageSize.width/2, -imageSize.height/2, imageSize.width/2, imageSize.height/2);
            /*
             [tempImage lockFocus];
             [[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
             NSRectFillUsingOperation(imageRect, NSCompositeSourceAtop);
             [tempImage unlockFocus];
             */
            [tempImage drawInRect:imageRect fromRect:imageRect operation:NSCompositeSourceAtop fraction:1.0];
            //[tempImage drawAtPoint:NSMakePoint(10.0, 10.0) fromRect:NSMakeRect(0,0,[tempImage size].width, [tempImage size].height) operation:NSCompositeCopy fraction:1.0];
            
            
            glPushMatrix(); // [Vinay]
            glPushAttrib(GL_COLOR_BUFFER_BIT); // [Vinay] - testing transparency options
            glEnable (GL_BLEND); // [Vinay] - testing transparency options
            glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            glDisable(GL_DEPTH_TEST);
            glActiveTexture(GL_TEXTURE1_ARB);				// activate texture unit 1
            glEnable(GL_TEXTURE_2D);
            
            //glEnable(GL_TEXTURE_2D);
            glBindTexture(GL_TEXTURE_2D, tempImage);
            glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
            
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_STORAGE_HINT_APPLE, GL_STORAGE_CACHED_APPLE);
            
            // There seems to be a rounding problem if we use a bias of 0.5.
            
            glPixelTransferf(GL_RED_BIAS, 0.5001);
            glPixelTransferf(GL_GREEN_BIAS, 0.5001);
            glPixelTransferf(GL_BLUE_BIAS, 0.5001);
            glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
            
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128, 128, 0, GL_ALPHA, GL_FLOAT, tempImage);
            
            glEnable(GL_STENCIL_TEST);
            glStencilFunc(GL_EQUAL, 0x1, 0x1);
            glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);
            
            /*
            glBegin(GL_QUADS);
            // Front Face
            glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);  // Bottom Left Of The Texture and Quad
            glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);  // Bottom Right Of The Texture and Quad
            glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);  // Top Right Of The Texture and Quad
            glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);  // Top Left Of The Texture and Quad
            // Back Face
            glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);  // Bottom Right Of The Texture and Quad
            glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);  // Top Right Of The Texture and Quad
            glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);  // Top Left Of The Texture and Quad
            glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);  // Bottom Left Of The Texture and Quad
            // Top Face
            glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);  // Top Left Of The Texture and Quad
            glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f,  1.0f,  1.0f);  // Bottom Left Of The Texture and Quad
            glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f,  1.0f,  1.0f);  // Bottom Right Of The Texture and Quad
            glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);  // Top Right Of The Texture and Quad
            // Bottom Face
            glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f, -1.0f, -1.0f);  // Top Right Of The Texture and Quad
            glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f, -1.0f, -1.0f);  // Top Left Of The Texture and Quad
            glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);  // Bottom Left Of The Texture and Quad
            glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);  // Bottom Right Of The Texture and Quad
            // Right face
            glTexCoord2f(1.0f, 0.0f); glVertex3f( 1.0f, -1.0f, -1.0f);  // Bottom Right Of The Texture and Quad
            glTexCoord2f(1.0f, 1.0f); glVertex3f( 1.0f,  1.0f, -1.0f);  // Top Right Of The Texture and Quad
            glTexCoord2f(0.0f, 1.0f); glVertex3f( 1.0f,  1.0f,  1.0f);  // Top Left Of The Texture and Quad
            glTexCoord2f(0.0f, 0.0f); glVertex3f( 1.0f, -1.0f,  1.0f);  // Bottom Left Of The Texture and Quad
            // Left Face
            glTexCoord2f(0.0f, 0.0f); glVertex3f(-1.0f, -1.0f, -1.0f);  // Bottom Left Of The Texture and Quad
            glTexCoord2f(1.0f, 0.0f); glVertex3f(-1.0f, -1.0f,  1.0f);  // Bottom Right Of The Texture and Quad
            glTexCoord2f(1.0f, 1.0f); glVertex3f(-1.0f,  1.0f,  1.0f);  // Top Right Of The Texture and Quad
            glTexCoord2f(0.0f, 1.0f); glVertex3f(-1.0f,  1.0f, -1.0f);  // Top Left Of The Texture and Quad
            glEnd();
            */
            
            //glDrawPixels(imageSize.width, imageSize.height, GL_RGBA, GL_FLOAT, tempImage);
            
            //glEnable(GL_BLEND);
            //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            
            /*
            int x = 0; int y = 0;
            //int w = [tempImage size].width;
            //int h = [tempImage size].height;
            
            //GLfloat Vertices[] = {(float)x, (float)y, 0,
            //    (float)x + (float)w, (float)y, 0,
            //    (float)x + (float)w, (float)y + (float)h, 0,
            //    (float)x, (float)y + (float)h, 0};
            
            //GLfloat Vertices[] = {(float)x - (float)w/2, (float)y - (float)h/2, 0,
            //    (float)x + (float)w/2, (float)y - (float)h/2, 0,
            //    (float)x + (float)w/2, (float)y + (float)h/2, 0,
            //    (float)x - (float)w/2, (float)y + (float)h/2, 0};
            
            GLfloat Vertices[] = {(float)x-0.5, (float)y-0.5, 0,
                0.5, -0.5, 0,
                0.5, 0.5, 0,
                -0.5, 0.5, 0};
            
            
            GLfloat TexCoord[] = {0, 0,
                1, 0,
                1, 1,
                0, 1,
            };
            GLubyte indices[] = {0,1,2, // first triangle (bottom left - top left - top right)
                0,2,3}; // second triangle (bottom left - top right - bottom right)
            
            glEnableClientState(GL_VERTEX_ARRAY);
            glVertexPointer(3, GL_FLOAT, 0, Vertices);
            
            glEnableClientState(GL_TEXTURE_COORD_ARRAY);
            glTexCoordPointer(2, GL_FLOAT, 0, TexCoord);
            
            glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, indices);
            */
            //glFlush();
            
            //glDisableClientState(GL_TEXTURE_COORD_ARRAY);
            //glDisableClientState(GL_VERTEX_ARRAY);
            
            
            glDisable(GL_BLEND); // [Vinay] - testing transparency options
            glPopAttrib();
            glPopMatrix();
            glActiveTexture(GL_TEXTURE0_ARB);		// Do texture unit 0 last, so we leave it active (for other tasks)
            glDisable(GL_STENCIL_TEST);
            glDisable(GL_TEXTURE_2D);
            
            
            glFlush();
            
            /*
             NSData *imdata =[[NSData alloc] initWithContentsOfFile:@"/Users/vinay/Documents/Lablib-Plugins/CRSMap/monkeyPic.jpg"];
             
             if(!imdata){
             NSLog(@"there is data");
             }
             
             NSImage *imag=[[NSImage alloc]initWithData:imdata];
             NSImageView *imageView = [[NSImageView alloc] initWithFrame:frame];
             [imageView setImage:imag];
             [self addSubview:imageView];
             */
            
            
            
        }
        
        else
            [fixSpot draw];

        
        // [Vinay] - till here
        
        //[fixSpot draw]; //[Vinay] - have commented this because it's included in the loop above instead
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

            useSingleITC18 = [[task defaults] boolForKey:CRSUseSingleITC18Key];
            
			if (trialFrame == stimOffFrames[index]) {
                [[task dataDoc] putEvent:@"stimulusOff" withData:&index];
                [[task dataDoc] putEvent:@"stimulusOffTime"];
                if (!useSingleITC18) {
                    [digitalOut outputEvent:kStimulusOffDigitOutCode withData:index];
                }
				if (++stimIndices[index] >= [[stimLists objectAtIndex:index] count]) {	// no more entries in list
					listDone = YES;
				}
			}
			
// If this is the first frame of a Gabor, post an event describing it

			if (trialFrame == pSD->stimOnFrame) {
				[[task dataDoc] putEvent:@"stimulusOn" withData:&index];
                [[task dataDoc] putEvent:@"stimulusOnTime"];
                [[task dataDoc] putEvent:@"stimulus" withData:pSD];

                if (!useSingleITC18) {
                    [digitalOut outputEvent:kStimulusOnDigitOutCode withData:index];
                }
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
					[digitalOut outputEventName:@"contrast" withData:(long)(10*(pSD->contrastPC))];
                    [digitalOut outputEventName:@"temporalFreq" withData:(long)(10*(pSD->temporalFreqHz))];
					[digitalOut outputEventName:@"azimuth" withData:(long)(100*(pSD->azimuthDeg))];
					[digitalOut outputEventName:@"elevation" withData:(long)(100*(pSD->elevationDeg))];
					[digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
					[digitalOut outputEventName:@"spatialFreq" withData:(long)(100*(pSD->spatialFreqCPD))];
					[digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
					[digitalOut outputEventName:@"sigma" withData:(long)((pSD->sigmaDeg))];
                    [digitalOut outputEventName:@"spatialPhase" withData:(long)(pSD->spatialPhaseDeg)];
				}
				
				if (index == kMapGabor1 && pSD->stimType != kNullStim && !([[task defaults] boolForKey:CRSHideRingDigitalKey])) {
					// [Vinay] - CRSHideRightDigitalKey changed to the above
                    //NSLog(@"Sending right digital codes...");
                    // [Vinay] - commenting the lines below to avoid sending all the digital codes (since, some might be redundant
                    /*
					[digitalOut outputEventName:@"contrast" withData:(long)(10*(pSD->contrastPC))];
                    [digitalOut outputEventName:@"temporalFreq" withData:(long)(10*(pSD->temporalFreqHz))];
					[digitalOut outputEventName:@"azimuth" withData:(long)(100*(pSD->azimuthDeg))];
					[digitalOut outputEventName:@"elevation" withData:(long)(100*(pSD->elevationDeg))];
					[digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
					[digitalOut outputEventName:@"spatialFreq" withData:(long)(100*(pSD->spatialFreqCPD))];
					[digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
					[digitalOut outputEventName:@"sigma" withData:(long)(100*(pSD->sigmaDeg))];
                    [digitalOut outputEventName:@"spatialPhase" withData:(long)(pSD->spatialPhaseDeg)];
                     */
                    // [Vinay] selectively sending digital codes as per the specific protocol
                    if (protocolNumber == 0 || protocolNumber == 9) { // noneProtocol and crossOrientationProtocol - fill list of parameters
                        [digitalOut outputEventName:@"contrast" withData:(long)(10*(pSD->contrastPC))];
                        [digitalOut outputEventName:@"temporalFreq" withData:(long)(10*(pSD->temporalFreqHz))];
                        [digitalOut outputEventName:@"azimuth" withData:(long)(100*(pSD->azimuthDeg))];
                        [digitalOut outputEventName:@"elevation" withData:(long)(100*(pSD->elevationDeg))];
                        [digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
                        [digitalOut outputEventName:@"spatialFreq" withData:(long)(100*(pSD->spatialFreqCPD))];
                        [digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
                        [digitalOut outputEventName:@"sigma" withData:(long)((pSD->sigmaDeg))];
                        [digitalOut outputEventName:@"spatialPhase" withData:(long)(pSD->spatialPhaseDeg)];
                    }
                    
                    else if (protocolNumber == 1) // ringProtocol
                    {
                        [digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
                    }
                    else if (protocolNumber == 2 || protocolNumber == 3 || protocolNumber == 10) // contrastRing, dualContrast, annulusFixed protocols
                    {
                        [digitalOut outputEventName:@"contrast" withData:(long)(10*(pSD->contrastPC))];
                        [digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
                    }
                    else if (protocolNumber == 4 || protocolNumber == 6) // dualOrientation, orientationRing protocols
                    {
                        [digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
                        [digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
                    }
                    else if (protocolNumber == 5 || protocolNumber == 7) // dualPhase, phaseRing protocols
                    {
                        [digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
                        [digitalOut outputEventName:@"spatialPhase" withData:(long)(pSD->spatialPhaseDeg)];
                    }
                    else if (protocolNumber == 8) // driftingPhaseProtocol
                    {
                        [digitalOut outputEventName:@"temporalFreq" withData:(long)(10*(pSD->temporalFreqHz))];
                        [digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
                    }
                    
				}
                
                if (index == kMapGabor2 && pSD->stimType != kNullStim && !([[task defaults] boolForKey:CRSHideCentreDigitalKey])) {                                            // [Vinay] - for centre gabor. Not sure what would be the equivalent 'digital key' for this case i.e. Left or Right Digital codes as above. Clarify this!
                    // [Vinay] - added the relevant CRSHideCentreDigitalKey
					//NSLog(@"Sending right digital codes...");
                    // [Vinay] - commenting the lines below to avoid sending all the digital codes (since, some might be redundant
                    /*
					[digitalOut outputEventName:@"contrast" withData:(long)(10*(pSD->contrastPC))];
                    [digitalOut outputEventName:@"temporalFreq" withData:(long)(10*(pSD->temporalFreqHz))];
					[digitalOut outputEventName:@"azimuth" withData:(long)(100*(pSD->azimuthDeg))];
					[digitalOut outputEventName:@"elevation" withData:(long)(100*(pSD->elevationDeg))];
					[digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
					[digitalOut outputEventName:@"spatialFreq" withData:(long)(100*(pSD->spatialFreqCPD))];
					[digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
					[digitalOut outputEventName:@"sigma" withData:(long)(100*(pSD->sigmaDeg))];
                    [digitalOut outputEventName:@"spatialPhase" withData:(long)(pSD->spatialPhaseDeg)];
                     */
                    // [Vinay] selectively sending digital codes as per the specific protocol
                    
                    if (protocolNumber == 0 || protocolNumber == 3 || protocolNumber == 4 || protocolNumber == 5 || protocolNumber == 9) {
                        // none, dualContrast, dualOrientation, dualPhase, crossOrientation protocols - send the full list of parameters
                        [digitalOut outputEventName:@"contrast" withData:(long)(10*(pSD->contrastPC))];
                        [digitalOut outputEventName:@"temporalFreq" withData:(long)(10*(pSD->temporalFreqHz))];
                        [digitalOut outputEventName:@"azimuth" withData:(long)(100*(pSD->azimuthDeg))];
                        [digitalOut outputEventName:@"elevation" withData:(long)(100*(pSD->elevationDeg))];
                        [digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
                        [digitalOut outputEventName:@"spatialFreq" withData:(long)(100*(pSD->spatialFreqCPD))];
                        [digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
                        [digitalOut outputEventName:@"sigma" withData:(long)((pSD->sigmaDeg))];
                        [digitalOut outputEventName:@"spatialPhase" withData:(long)(pSD->spatialPhaseDeg)];
                    }
                    else // for all other protocols only the 'radius' is required to be sent
                    {
                        [digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
                    }

				}
                
                if (pSD->stimType == kTargetStim) {
					targetPresented = YES;
					targetOnFrame = trialFrame;
                    if (!useSingleITC18) {
                        [digitalOut outputEvent:kTargetOnDigitOutCode withData:(kTargetOnDigitOutCode+1)];
                    }
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
	/* Added these lines and some more ahead to check for COS protocol and change the transparency of the fixSpot by adjusting its alpha value */
    int protocolNumber = [[task defaults] integerForKey:@"CRSProtocolNumber"];
    BOOL crossOrientationProtocol = NO; // [Vinay] - Added to check for the COS protocol condition to draw superimposed, partially transparent gabors so that it looks like a plaid
    if (protocolNumber == 9)
        crossOrientationProtocol = YES;
    // [Vinay] - till here
    
    [fixSpot setState:state];
    
    //NSColor *foreColorTemp;
    
	if (state) {
		if (!stimulusOn) {
			[[task stimWindow] lock];
			[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
			[[task stimWindow] scaleDisplay];
			glClear(GL_COLOR_BUFFER_BIT);
            
            /**** // [Vinay] - Adding the following lines to show just an image instead of the fixation spot, if required */
            /**** // [Vinay] - Also adding a loop to explore flickering of the fixation point - doesn't seem to be working. Instead the loop is invoked whne drawing plaid stimuli */
            
            if ([[task defaults] boolForKey:CRSFixImageKey]) {
                
                //[[task stimWindow] unlock];
                //NSString* imageName = [[NSBundle mainBundle] pathForResource:@"/Users/vinay/Downloads/Bonnet Macaque.JPG" ofType:@"JPG"];
                //NSImage* tempImage = [[NSImage alloc] initWithContentsOfFile:imageName];
                NSImage *tempImage = [NSImage imageNamed:@"/Users/vinay/Downloads/Bonnet Macaque.JPG"];
                //[tempImage drawAtPoint: NSMakePoint(0.0, 0.0)
                //              fromRect: NSMakeRect(0.0, 0.0, 100.0, 100.0)
                //             operation: NSCompositeCopy
                //              fraction: 1.0];
                NSSize imageSize = [tempImage size];
                NSRect imageRect = NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height);
                /*
                [tempImage lockFocus];
                [[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
                NSRectFillUsingOperation(imageRect, NSCompositeSourceAtop);
                [tempImage unlockFocus];
                 */
                [tempImage drawInRect:imageRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];
                //[tempImage drawAtPoint:NSMakePoint(10.0, 10.0) fromRect:NSMakeRect(0,0,[tempImage size].width, [tempImage size].height) operation:NSCompositeCopy fraction:1.0];
                
                glDisable(GL_DEPTH_TEST);
                glActiveTexture(GL_TEXTURE4);				// activate texture unit 0 and cycle texture
                glEnable(GL_TEXTURE_2D);
                
                glPushMatrix(); // [Vinay]
                glPushAttrib(GL_COLOR_BUFFER_BIT); // [Vinay] - testing transparency options
                glEnable (GL_BLEND); // [Vinay] - testing transparency options
                glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                glEnable(GL_TEXTURE_2D);
                glBindTexture(GL_TEXTURE_2D, tempImage);
                
                //glEnable(GL_BLEND);
                //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
                
                int x = 0; int y = 0;
                int w = [tempImage size].width;
                int h = [tempImage size].height;
                
                GLfloat Vertices[] = {(float)x, (float)y, 0,
                    (float)x + (float)w, (float)y, 0,
                    (float)x + (float)w, (float)y + (float)h, 0,
                    (float)x, (float)y + (float)h, 0};
                
                GLfloat TexCoord[] = {0, 0,
                    1, 0,
                    1, 1,
                    0, 1,
                };
                GLubyte indices[] = {0,1,2, // first triangle (bottom left - top left - top right)
                    0,2,3}; // second triangle (bottom left - top right - bottom right)
                
                glEnableClientState(GL_VERTEX_ARRAY);
                glVertexPointer(3, GL_FLOAT, 0, Vertices);
                
                glEnableClientState(GL_TEXTURE_COORD_ARRAY);
                glTexCoordPointer(2, GL_FLOAT, 0, TexCoord);
                
                glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, indices);
                
                //glFlush();
                
                glDisableClientState(GL_TEXTURE_COORD_ARRAY);
                glDisableClientState(GL_VERTEX_ARRAY);
                
                
                glDisable(GL_BLEND); // [Vinay] - testing transparency options
                glPopAttrib();
                glPopMatrix();
                glActiveTexture(GL_TEXTURE4);		// Do texture unit 0 last, so we leave it active (for other tasks)
                glDisable(GL_TEXTURE_2D);
                
                glFlush();
                
                /*
                 NSData *imdata =[[NSData alloc] initWithContentsOfFile:@"/Users/vinay/Documents/Lablib-Plugins/CRSMap/monkeyPic.jpg"];
                 
                 if(!imdata){
                 NSLog(@"there is data");
                 }
                 
                 NSImage *imag=[[NSImage alloc]initWithData:imdata];
                 NSImageView *imageView = [[NSImageView alloc] initWithFrame:frame];
                 [imageView setImage:imag];
                 [self addSubview:imageView];
                 */
                
                
                
            }
            else if(crossOrientationProtocol && ![[task defaults] boolForKey:CRSFixImageKey])
            {
                /*
                [fixSpot setForeColor:[NSColor colorWithCalibratedRed:1.0 green:0 blue:0 alpha:0.1]];
                //[fixSpot setBackColor:[NSColor colorWithCalibratedRed:0.4 green:0.4 blue:0 alpha:0.4]];
                
                long frame;
                float frameRateHz, framesPerHalfCycle, temporalFreqFlicker;
                NSNumber *frameNumber = 0;
                
                frame = [frameNumber longValue];
                //frameRateHz = ([fixSpot displays] == nil) ? 60.0 : [[fixSpot displays] frameRateHz:2];
                frameRateHz = 60;
                temporalFreqFlicker = 2;
                framesPerHalfCycle = frameRateHz / temporalFreqFlicker / 2.0;
                [fixSpot setForeColor:[NSColor colorWithCalibratedRed:1.0 green:0 blue:0 alpha:1.0*(sin(frame / framesPerHalfCycle * kPI * kRadiansPerDeg))]];
                */
                
                //[fixSpot setForeColor:[NSColor colorWithCalibratedRed:[fixSpot->foreColor redComponent] green:[fixSpot->foreColor greenComponent] blue:[fixSpot->foreColor blueComponent] alpha:0.33]];
                
                //foreColorTemp = [fixSpot foreColor];
                
                //[fixSpot setFixTargetColor:[NSColor colorWithCalibratedRed:[foreColorTemp redComponent] green:[foreColorTemp greenComponent] blue:[foreColorTemp blueComponent] alpha:0.33]];
                
                
                [fixSpot setFixTargetColor:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.33]];
                //[fixSpot->foreColor alphaComponent];
                
                [fixSpot draw];
            }
            
            if (![[task defaults] boolForKey:CRSFixImageKey] && !crossOrientationProtocol)
            {
                [fixSpot setFixTargetColor:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1]];
                [fixSpot draw];
            }
            // [Vinay] - till here
			
            //[fixSpot draw]; // [Vinay] - have commented this
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
