//
//  CRSMapStimTable.m
//  CRSMap
//
//  Created by John Maunsell on 11/2/07.
//  Copyright 2007. All rights reserved.
//

#import "CRS.h"
#import "CRSMapStimTable.h"

static long CRSMapStimTableCounter = 0;

@implementation CRSMapStimTable

- (long)blocksDone;
{
	return blocksDone;
}

- (void)dumpStimList:(NSMutableArray *)list listIndex:(long)listIndex;
{
	StimDesc stimDesc;
	long index;
	
	NSLog(@"Mapping Stim List %ld", listIndex);
	NSLog(@"index type onFrame offFrame azi ele sig sf  ori  con tf  sp r");          // [Vinay] - Added 'sp' for spatial phase and 'r' for radius
	for (index = 0; index < [list count]; index++) {
		[[list objectAtIndex:index] getValue:&stimDesc];
		NSLog(@"%4ld:\t%4d\t%4ld\t%4ld\t%4.1f\t%4.1f\t%4.1f\t%4.1f\t%4.1f\t%4.1f\t%4.1f\t%4.1f\t%4.1f", index, stimDesc.stimType,
			stimDesc.stimOnFrame, stimDesc.stimOffFrame, stimDesc.azimuthDeg, stimDesc.elevationDeg,
			stimDesc.sigmaDeg, stimDesc.spatialFreqCPD, stimDesc.directionDeg,stimDesc.contrastPC,stimDesc.temporalFreqHz,stimDesc.spatialPhaseDeg,stimDesc.radiusDeg);        //[Vinay] - added spatialPhaseDeg and radiusDeg
	}
	NSLog(@"\n");
}

- (id) init
{
	if (!(self = [super init])) {
		return nil;
	}
    mapIndex = CRSMapStimTableCounter++;
	[self updateBlockParameters:mapIndex];
	[self newBlock];
	return self;
}

- (float)contrastValueFromIndex:(long)index count:(long)count min:(float)min max:(float)max;
{
	short c, stimLevels;
	float stimValue, level, stimFactor;
	
	stimLevels = count;
	stimFactor = 0.5;
	switch (stimLevels) {
		case 1:								// Just the 100% stimulus
			stimValue = max;
			break;
		case 2:								// Just 100% and 0% stimuli
			stimValue = (index == 0) ? min : max;
			break;
		default:							// Other values as well
			if (index == 0) {
				stimValue = min;
			}
			else {
				level = max;
				for (c = stimLevels - 1; c > index; c--) {
					level *= stimFactor;
				}
				stimValue = level;
			}
	}
	return(stimValue);
}


- (float)linearValueWithIndex:(long)index count:(long)count min:(float)min max:(float)max;
{
	return (count < 2) ? min : (min + ((max - min) / (count - 1)) * index);
}

- (float)logValueWithIndex:(long)index count:(long)count min:(float)min max:(float)max;
{
	return (count < 2) ? min : min * (powf(max / min, (float)index/(count - 1)));
}

/* makeMapStimList

Make a mapping stimulus lists for one trial.  The list is constructed as an NSMutableArray of StimDesc or 
StimDesc structures.

In the simplest case, we just draw n unused entries from the done table.  If there are fewer than n entries
remaining, we take them all, clear the table, and then proceed.  We also make a provision for the case where 
several full table worth's will be needed to make the list.  Whenever we take all the entries remaining in 
the table, we simply draw them in order and then use shuffleStimList() to randomize their order.  Shuffling 
does not span the borders between successive doneTables, to ensure that each stimulus pairing will 
be presented n times before any appears n + 1 times, even if each appears several times within 
one trial.

Two types of padding stimuli are used.  Padding stimuli are inserted in the list after the target, so
that the stream of stimuli continues through the reaction time.  Padding stimuli are also optionally
put at the start of the trial.  This is so the first few stimulus presentations, which might have 
response transients, are not counted.  The number of padding stimuli at the end of the trial is 
determined by stimRateHz and reactTimeMS.  The number of padding stimuli at the start of the trial
is determined by rate of presentation and stimLeadMS.  Note that it is possible to set parameters 
so that there will never be anything except targets and padding stimuli (e.g., with a short 
maxTargetS and a long stimLeadMS).
*/

- (void)makeMapStimList:(NSMutableArray *)list index:(long)index lastFrame:(long)lastFrame pTrial:(TrialDesc *)pTrial
{
	long stim, frame, mapDurFrames, interDurFrames;
	float frameRateHz;
	StimDesc stimDesc; // [Vinay] - have added copyStimDesc to copy some stimulus attributes of the centre gabor and assign to the surround gabor when required. Now removed
	int localFreshCount;
	// BOOL localList[kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues]; // [Vinay] - commented this
    BOOL localList[kMaxMapValuesFixed][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues]; // [Vinay] : changed it from a 7 to a 9 dimensional list to include dimensions for spatial phase and radius
	float azimuthDegMin, azimuthDegMax, elevationDegMin, elevationDegMax, sigmaDegMin, sigmaDegMax, spatialFreqCPDMin, spatialFreqCPDMax, directionDegMin, directionDegMax, radiusSigmaRatio, contrastPCMin, contrastPCMax, temporalFreqHzMin, temporalFreqHzMax, spatialPhaseDegMin, spatialPhaseDegMax, radiusDegMin, radiusDegMax; //[Vinay] -  Added spatialPhaseDegMin, spatialPhaseDegMax, radiusDegMin, radiusDegMax
	BOOL hideStimulus, convertToGrating, noneProtocol=NO, ringProtocol=NO, contrastRingProtocol=NO, dualContrastProtocol=NO, dualOrientationProtocol=NO, dualPhaseProtocol=NO, orientationRingProtocol=NO, phaseRingProtocol=NO; // [Vinay] - added matchCentreSurround to indicate similarity between the centre and surround attributes whenever required. , matchCentreSurround=NO was removed because it isn't being used in this loop
    
	NSArray *stimTableDefaults = [[task defaults] arrayForKey:@"CRSStimTables"];
	NSDictionary *minDefaults = [stimTableDefaults objectAtIndex:0];
	NSDictionary *maxDefaults = [stimTableDefaults objectAtIndex:1];                    // [Vinay] - Changed the value to 2 from 1 to include the extra gabor. Changed back to 1 now...I think the 0 and 1 here are just for left and right in GRFMap. I may just have to add defaults for the third within each. Nop, they are for min and max values. The respective min and max values for the thirg (centre) gabor have been added to CRSStimTables. Check this out!
	
	radiusSigmaRatio = [[[task defaults] objectForKey:CRSMapStimRadiusSigmaRatioKey] floatValue];
    
    // [Vinay] - have added the following lines (bool variables) to make changes in mapping related to specific protocols
    /*
    matchCentreSurround = [[task defaults] boolForKey:CRSMatchCentreSurroundKey];
    ringProtocol = [[task defaults] boolForKey:CRSRingProtocolKey];
    contrastRingProtocol = [[task defaults] boolForKey:CRSContrastRingProtocolKey];
    dualContrastProtocol = [[task defaults] boolForKey:CRSDualContrastProtocolKey];
    dualOrientationProtocol = [[task defaults] boolForKey:CRSDualOrientationProtocolKey];
    dualPhaseProtocol = [[task defaults] boolForKey:CRSDualPhaseProtocolKey];
    */
    
    switch ([[task defaults] integerForKey:@"CRSProtocolNumber"]) {
        case 0:
            noneProtocol = YES;
            break;
        case 1:
            ringProtocol = YES;
            break;
        case 2:
            contrastRingProtocol = YES; // [Vinay] - not being used in this loop anywhere actually, but included here for the sake of completion (could have avoided this variable and just gone to the default case here)
            break;
        case 3:
            dualContrastProtocol = YES;
            break;
        case 4:
            dualOrientationProtocol = YES;
            break;
        case 5:
            dualPhaseProtocol = YES;
            break;
        case 6:
            orientationRingProtocol = YES; // [Vinay] - not being used in this loop anywhere actually
            break;
        case 7:
            phaseRingProtocol = YES; // [Vinay] - not being used in this loop anywhere actually
            break;
        default:
            break;
    }
    
    // [Vinay] - till here
    
    switch (index) {
        case 0:
        default:
            azimuthDegMin = [[minDefaults objectForKey:@"azimuthDeg0"] floatValue];
            elevationDegMin = [[minDefaults objectForKey:@"elevationDeg0"] floatValue];
            spatialFreqCPDMin = [[minDefaults objectForKey:@"spatialFreqCPD0"] floatValue];
            sigmaDegMin = [[minDefaults objectForKey:@"sigmaDeg0"] floatValue];
            directionDegMin = [[minDefaults objectForKey:@"orientationDeg0"] floatValue];
            contrastPCMin = [[minDefaults objectForKey:@"contrastPC0"] floatValue];
            temporalFreqHzMin = [[minDefaults objectForKey:@"temporalFreqHz0"] floatValue];
            spatialPhaseDegMin = [[minDefaults objectForKey:@"spatialPhaseDeg0"] floatValue]; // [Vinay] - Added for spatial phase min value
            radiusDegMin = [[minDefaults objectForKey:@"radiusDeg0"] floatValue]; // [Vinay] - Added for radius min value

            azimuthDegMax = [[maxDefaults objectForKey:@"azimuthDeg0"] floatValue];
            elevationDegMax = [[maxDefaults objectForKey:@"elevationDeg0"] floatValue];
            sigmaDegMax = [[maxDefaults objectForKey:@"sigmaDeg0"] floatValue];
            spatialFreqCPDMax = [[maxDefaults objectForKey:@"spatialFreqCPD0"] floatValue];
            directionDegMax = [[maxDefaults objectForKey:@"orientationDeg0"] floatValue];
            contrastPCMax = [[maxDefaults objectForKey:@"contrastPC0"] floatValue];
            temporalFreqHzMax = [[maxDefaults objectForKey:@"temporalFreqHz0"] floatValue];
            spatialPhaseDegMax = [[maxDefaults objectForKey:@"spatialPhaseDeg0"] floatValue]; // [Vinay] - Added for spatial phase max value
            radiusDegMax = [[maxDefaults objectForKey:@"radiusDeg0"] floatValue]; // [Vinay] - Added for radius max value
            
            //hideStimulus = [[task defaults] boolForKey:CRSHideLeftKey]; // [Vinay] - Have commented this and have instead added the next line
            hideStimulus = (dualContrastProtocol || dualOrientationProtocol || dualPhaseProtocol || ([[task defaults] boolForKey:CRSHideSurroundKey] && noneProtocol)); // [Vinay] - To hide the surround stimulus if the protocol is any of these three. The stimulus is drawn completely with just the centre and the surround stimulus. Also hide if explicitly asked to do so, but only during none protocol mode. gabor0 corresponds to the surround gabor.
            break;
        case 1:
            azimuthDegMin = [[minDefaults objectForKey:@"azimuthDeg1"] floatValue];
            elevationDegMin = [[minDefaults objectForKey:@"elevationDeg1"] floatValue];
            spatialFreqCPDMin = [[minDefaults objectForKey:@"spatialFreqCPD1"] floatValue];
            sigmaDegMin = [[minDefaults objectForKey:@"sigmaDeg1"] floatValue];
            directionDegMin = [[minDefaults objectForKey:@"orientationDeg1"] floatValue];
            contrastPCMin = [[minDefaults objectForKey:@"contrastPC1"] floatValue];
            temporalFreqHzMin = [[minDefaults objectForKey:@"temporalFreqHz1"] floatValue];
            spatialPhaseDegMin = [[minDefaults objectForKey:@"spatialPhaseDeg1"] floatValue]; // [Vinay] - Added for spatial phase min value
            radiusDegMin = [[minDefaults objectForKey:@"radiusDeg1"] floatValue]; // [Vinay] - Added for radius min value

            azimuthDegMax = [[maxDefaults objectForKey:@"azimuthDeg1"] floatValue];
            elevationDegMax = [[maxDefaults objectForKey:@"elevationDeg1"] floatValue];
            spatialFreqCPDMax = [[maxDefaults objectForKey:@"spatialFreqCPD1"] floatValue];
            sigmaDegMax = [[maxDefaults objectForKey:@"sigmaDeg1"] floatValue];
            directionDegMax = [[maxDefaults objectForKey:@"orientationDeg1"] floatValue];
            contrastPCMax = [[maxDefaults objectForKey:@"contrastPC1"] floatValue];
            temporalFreqHzMax = [[maxDefaults objectForKey:@"temporalFreqHz1"] floatValue];
            spatialPhaseDegMax = [[maxDefaults objectForKey:@"spatialPhaseDeg1"] floatValue]; // [Vinay] - Added for spatial phase max value
            radiusDegMax = [[maxDefaults objectForKey:@"radiusDeg1"] floatValue]; // [Vinay] - Added for radius max value
            
            //hideStimulus = [[task defaults] boolForKey:CRSHideRightKey]; // [Vinay] - have commented this and modified as below
            hideStimulus = ((([[task defaults] boolForKey:CRSHideRingKey]) || ([[task defaults] boolForKey:CRSMatchRingSurroundKey])) && noneProtocol); // for match ring-surround, just don't draw the ring gabor. Explicitly hide only when there's no specific mode selected
            
            // [Vinay] - have added the following lines for protocol specific changes in mapping; since this gabor1 corresponds to the ring gabor
            if(ringProtocol){
                contrastPCMin = 0;
                contrastPCMax = 0;
            }
            
            if (dualContrastProtocol || dualOrientationProtocol || dualPhaseProtocol) {
                radiusDegMin = radiusDegMax;
            }
            
            break; // [Vinay] - had forgotten this break command. Hence the values for ring gabor were getting overwritten! x-( :)
            
            //*************** [Vinay] - Added this section (case 2) for the centre gabor
        case 2:
            azimuthDegMin = [[minDefaults objectForKey:@"azimuthDeg2"] floatValue];
            elevationDegMin = [[minDefaults objectForKey:@"elevationDeg2"] floatValue];
            spatialFreqCPDMin = [[minDefaults objectForKey:@"spatialFreqCPD2"] floatValue];
            sigmaDegMin = [[minDefaults objectForKey:@"sigmaDeg2"] floatValue];
            directionDegMin = [[minDefaults objectForKey:@"orientationDeg2"] floatValue];
            contrastPCMin = [[minDefaults objectForKey:@"contrastPC2"] floatValue];
            temporalFreqHzMin = [[minDefaults objectForKey:@"temporalFreqHz2"] floatValue];
            spatialPhaseDegMin = [[minDefaults objectForKey:@"spatialPhaseDeg2"] floatValue]; // [Vinay] - Added for spatial phase min value
            radiusDegMin = [[minDefaults objectForKey:@"radiusDeg2"] floatValue]; // [Vinay] - Added for radius min value
            
            azimuthDegMax = [[maxDefaults objectForKey:@"azimuthDeg2"] floatValue];
            elevationDegMax = [[maxDefaults objectForKey:@"elevationDeg2"] floatValue];
            spatialFreqCPDMax = [[maxDefaults objectForKey:@"spatialFreqCPD2"] floatValue];
            sigmaDegMax = [[maxDefaults objectForKey:@"sigmaDeg2"] floatValue];
            directionDegMax = [[maxDefaults objectForKey:@"orientationDeg2"] floatValue];
            contrastPCMax = [[maxDefaults objectForKey:@"contrastPC2"] floatValue];
            temporalFreqHzMax = [[maxDefaults objectForKey:@"temporalFreqHz2"] floatValue];
            spatialPhaseDegMax = [[maxDefaults objectForKey:@"spatialPhaseDeg2"] floatValue]; // [Vinay] - Added for spatial phase max value
            radiusDegMax = [[maxDefaults objectForKey:@"radiusDeg2"] floatValue]; // [Vinay] - Added for radius max value
            
            //hideStimulus = [[task defaults] boolForKey:CRSHideRightKey];                          // [Vinay] - Have to decide the key here - Therefore commented temporarily
            hideStimulus = ((([[task defaults] boolForKey:CRSHideCentreKey]) || ([[task defaults] boolForKey:CRSMatchCentreRingKey])) && noneProtocol); // for match centre-ring, just don't draw the centre gabor. Explicitly hide only when there's no specific mode selected
            
            break;
	}
    
    convertToGrating = [[task defaults] boolForKey:CRSConvertToGratingKey];
	
	memcpy(&localList, &doneList, sizeof(doneList));
	localFreshCount = stimRemainingInBlock;
	frameRateHz = [[task stimWindow] frameRateHz];
	
	mapDurFrames = MAX(1, ceil([[task defaults] integerForKey:CRSMapStimDurationMSKey] / 1000.0 * frameRateHz));
	interDurFrames = ceil([[task defaults] integerForKey:CRSMapInterstimDurationMSKey] / 1000.0 * frameRateHz);
	
	[list removeAllObjects];
	
	for (stim = frame = 0; frame < lastFrame; stim++, frame += mapDurFrames + interDurFrames) {
		
		int azimuthIndex, elevationIndex, sigmaIndex, spatialFreqIndex, directionDegIndex, contrastIndex, temporalFreqIndex, spatialPhaseIndex, radiusIndex; // spatialFreqIndexCopy=0, directionDegIndexCopy=0, contrastIndexCopy=0, temporalFreqIndexCopy=0, spatialPhaseIndexCopy=0; // [Vinay] - Added spatialPhaseIndex, radiusIndex. Added - spatialFreqIndexCopy, directionDegIndexCopy, contrastIndexCopy, temporalFreqIndexCopy, spatialPhaseIndexCopy to store their alues for one gabor to be assigned to another gabor when required. They have been initialized because otherwise an error was throwing up. Now commented
		NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTableCounts"] objectAtIndex:0];
		int azimuthCount, elevationCount, sigmaCount, spatialFreqCount, directionDegCount, contrastCount, temporalFreqCount, spatialPhaseCount, radiusCount; // [Vinay - Added spatialPhaseCount, radiusCount
		int startAzimuthIndex, startElevationIndex, startSigmaIndex, startSpatialFreqIndex, startDirectionDegIndex, startContrastIndex,startTemporalFreqIndex, startSpatialPhaseIndex, startRadiusIndex; // [Vinay] - Added startSpatialPhaseIndex, startRadiusIndex
		BOOL stimDone = YES;
        
        
        // [Vinay] - Adding switch case here to assign counts based on the current gabor (not common count values as used earlier)
        
        switch (index){
            case 0:
            default:
                azimuthCount = [[countsDict objectForKey:@"azimuthCount0"] intValue];
                elevationCount = [[countsDict objectForKey:@"elevationCount0"] intValue];
                sigmaCount = [[countsDict objectForKey:@"sigmaCount0"] intValue];
                spatialFreqCount = [[countsDict objectForKey:@"spatialFreqCount0"] intValue];
                directionDegCount = [[countsDict objectForKey:@"orientationCount0"] intValue];
                contrastCount = [[countsDict objectForKey:@"contrastCount0"] intValue];
                temporalFreqCount = [[countsDict objectForKey:@"temporalFreqCount0"] intValue];
                spatialPhaseCount = [[countsDict objectForKey:@"spatialPhaseCount0"] intValue]; // [Vinay] - added for spatial phase
                radiusCount = [[countsDict objectForKey:@"radiusCount0"] intValue]; // [Vinay] - added for radius
                break;
                
            case 1:
                azimuthCount = [[countsDict objectForKey:@"azimuthCount1"] intValue];
                elevationCount = [[countsDict objectForKey:@"elevationCount1"] intValue];
                sigmaCount = [[countsDict objectForKey:@"sigmaCount1"] intValue];
                spatialFreqCount = [[countsDict objectForKey:@"spatialFreqCount1"] intValue];
                directionDegCount = [[countsDict objectForKey:@"orientationCount1"] intValue];
                contrastCount = [[countsDict objectForKey:@"contrastCount1"] intValue];
                temporalFreqCount = [[countsDict objectForKey:@"temporalFreqCount1"] intValue];
                spatialPhaseCount = [[countsDict objectForKey:@"spatialPhaseCount1"] intValue]; // [Vinay] - added for spatial phase
                radiusCount = [[countsDict objectForKey:@"radiusCount1"] intValue]; // [Vinay] - added for radius
                
                // [Vinay] - have added the following lines for protocol specific changes in mapping; since this corresponds to the ring gabor
                /*
                if(ringProtocol){
                    spatialFreqCount = 1;
                    directionDegCount = 1;
                    contrastCount = 1;
                    temporalFreqCount = 1;
                    spatialPhaseCount = 1;
                }
                
                if (dualContrastProtocol || dualOrientationProtocol || dualPhaseProtocol) {
                    radiusCount = 1;
                }
                */
                // [Vinay] - till here
                break;
                
            case 2:
                azimuthCount = [[countsDict objectForKey:@"azimuthCount2"] intValue];
                elevationCount = [[countsDict objectForKey:@"elevationCount2"] intValue];
                sigmaCount = [[countsDict objectForKey:@"sigmaCount2"] intValue];
                spatialFreqCount = [[countsDict objectForKey:@"spatialFreqCount2"] intValue];
                directionDegCount = [[countsDict objectForKey:@"orientationCount2"] intValue];
                contrastCount = [[countsDict objectForKey:@"contrastCount2"] intValue];
                temporalFreqCount = [[countsDict objectForKey:@"temporalFreqCount2"] intValue];
                spatialPhaseCount = [[countsDict objectForKey:@"spatialPhaseCount2"] intValue]; // [Vinay] - added for spatial phase
                radiusCount = [[countsDict objectForKey:@"radiusCount2"] intValue]; // [Vinay] - added for radius
                break;
        }
        
        /*
        // [Vinay] The earlier code is commented - (and now uncommented
	
		azimuthCount = [[countsDict objectForKey:@"azimuthCount"] intValue];
		elevationCount = [[countsDict objectForKey:@"elevationCount"] intValue];
		sigmaCount = [[countsDict objectForKey:@"sigmaCount"] intValue];
		spatialFreqCount = [[countsDict objectForKey:@"spatialFreqCount"] intValue];
		directionDegCount = [[countsDict objectForKey:@"orientationCount"] intValue];
		contrastCount = [[countsDict objectForKey:@"contrastCount"] intValue];
        temporalFreqCount = [[countsDict objectForKey:@"temporalFreqCount"] intValue];
        spatialPhaseCount = [[countsDict objectForKey:@"spatialPhaseCount"] intValue]; // [Vinay] - added for spatial phase
        radiusCount = [[countsDict objectForKey:@"radiusCount"] intValue]; // [Vinay] - added for radius
        
        // [Vinay] till here
        */
        
        startAzimuthIndex = azimuthIndex = rand() % azimuthCount;
		startElevationIndex = elevationIndex = rand() % elevationCount;
		startSigmaIndex = sigmaIndex = rand() % sigmaCount;
		startSpatialFreqIndex = spatialFreqIndex = rand() % spatialFreqCount;
		startDirectionDegIndex = directionDegIndex = rand() % directionDegCount;
		startContrastIndex = contrastIndex = rand() % contrastCount;
        startTemporalFreqIndex = temporalFreqIndex = rand() % temporalFreqCount;
        startSpatialPhaseIndex = spatialPhaseIndex = rand() % spatialPhaseCount; // [Vinay] - Added for spatial phase
        startRadiusIndex = radiusIndex = rand() % radiusCount; // [Vinay] - Added for radius
        
        // [Vinay] - added the following loop to copy the index values of centre gabor to those of surround gabor when they need to have some similar attributes
        // This doesn't work!
        // matchCentreSurround = 1; //[Vinay] - setting this TRUE for checking now. And commented later since the associated key has been defined
        /*
        if (matchCentreSurround == TRUE & index == 2) {
            NSValue *val = [copyList objectAtIndex:0];
            [val getValue:&stimDesc];
            startSpatialFreqIndex = spatialFreqIndex = stimDesc.spatialFreqIndex;
            startDirectionDegIndex = directionDegIndex = stimDesc.directionIndex;
            startContrastIndex = contrastIndex = stimDesc.contrastIndex;
            startTemporalFreqIndex = temporalFreqIndex = stimDesc.temporalFreqIndex;
            startSpatialPhaseIndex = spatialPhaseIndex = stimDesc.spatialPhaseIndex;
        }
        */
        /*
        if (matchCentreSurround == TRUE) {
            switch (index) {
                case 0:
                    break;
                case 1:
                    break;
                case 2:
                    startSpatialFreqIndex = spatialFreqIndex = [[mapStimList0 objectAtIndex:0] spatialFreqIndex];
                    startDirectionDegIndex = directionDegIndex = directionDegIndexCopy;
                    startContrastIndex = contrastIndex = contrastIndexCopy;
                    startTemporalFreqIndex = temporalFreqIndex = temporalFreqIndexCopy;
                    startSpatialPhaseIndex = spatialPhaseIndex = spatialPhaseIndexCopy;
                default:
                    break;
            }
        }
		*/
        
        
        
		for (;;) {
			stimDone=localList[azimuthIndex][elevationIndex][sigmaIndex][spatialFreqIndex][directionDegIndex][contrastIndex][temporalFreqIndex][spatialPhaseIndex][radiusIndex]; // [Vinay] - added [spatialPhaseIndex][radiusIndex] term
			if (!stimDone) {
				break;
			}
            /* // [Vinay] - have commented out from here
			if ((azimuthIndex = ((azimuthIndex+1)%azimuthCount)) == startAzimuthIndex) {
				if ((elevationIndex = ((elevationIndex+1)%elevationCount)) == startElevationIndex) {
					if ((sigmaIndex = ((sigmaIndex+1)%sigmaCount)) == startSigmaIndex) {
						if ((spatialFreqIndex = ((spatialFreqIndex+1)%spatialFreqCount)) == startSpatialFreqIndex) {
							if ((directionDegIndex = ((directionDegIndex+1)%directionDegCount)) == startDirectionDegIndex) {
								if ((contrastIndex = ((contrastIndex+1)%contrastCount)) == startContrastIndex) {
                                    if ((temporalFreqIndex = ((temporalFreqIndex+1)%temporalFreqCount)) == startTemporalFreqIndex) {
                                        NSLog(@"Failed to find empty entry: Expected %d", localFreshCount);
                                        exit(0);
                                    }
								}
							}
						}
					}
				}
			}
		}
			*/ // [Vinay] - have commented out till here
            
            // [Vinay] - This is the modified loop. I have added two extra loops for spatial phase and radius
            if ((azimuthIndex = ((azimuthIndex+1)%azimuthCount)) == startAzimuthIndex) {
				if ((elevationIndex = ((elevationIndex+1)%elevationCount)) == startElevationIndex) {
					if ((sigmaIndex = ((sigmaIndex+1)%sigmaCount)) == startSigmaIndex) {
						if ((spatialFreqIndex = ((spatialFreqIndex+1)%spatialFreqCount)) == startSpatialFreqIndex) {
							if ((directionDegIndex = ((directionDegIndex+1)%directionDegCount)) == startDirectionDegIndex) {
								if ((contrastIndex = ((contrastIndex+1)%contrastCount)) == startContrastIndex) {
                                    if ((temporalFreqIndex = ((temporalFreqIndex+1)%temporalFreqCount)) == startTemporalFreqIndex) {
                                        if ((spatialPhaseIndex = ((spatialPhaseIndex+1)%spatialPhaseCount)) == startSpatialPhaseIndex) {
                                            if ((radiusIndex = ((radiusIndex+1)%radiusCount)) == startRadiusIndex) {
                                                NSLog(@"Failed to find empty entry: Expected %d", localFreshCount);
                                                exit(0);
                                            }
                                        }
                                    }
								}
							}
						}
					}
				}
			}
		}

		// this stimulus has not been done - add it to the list

		stimDesc.gaborIndex = index + 1;
		stimDesc.sequenceIndex = stim;
		stimDesc.stimOnFrame = frame;
		stimDesc.stimOffFrame = frame + mapDurFrames;
        
        if (pTrial->instructTrial) {
			stimDesc.stimType = kNullStim;
		}
		else {
            if (hideStimulus==TRUE)
				stimDesc.stimType = kNullStim;
			else
				stimDesc.stimType = kValidStim;
		}
		
		stimDesc.azimuthIndex = azimuthIndex;
		stimDesc.elevationIndex = elevationIndex;
		stimDesc.sigmaIndex = sigmaIndex;
		stimDesc.spatialFreqIndex = spatialFreqIndex;
		stimDesc.directionIndex = directionDegIndex;
		stimDesc.contrastIndex = contrastIndex;
        stimDesc.temporalFreqIndex = temporalFreqIndex;
        stimDesc.spatialPhaseIndex = spatialPhaseIndex; // [Vinay] - added this for spatial phase
        stimDesc.radiusIndex = radiusIndex; // [Vinay] - added this for radius
		
		stimDesc.azimuthDeg = [self linearValueWithIndex:azimuthIndex count:azimuthCount min:azimuthDegMin max:azimuthDegMax];
		stimDesc.elevationDeg = [self linearValueWithIndex:elevationIndex count:elevationCount min:elevationDegMin max:elevationDegMax];
        
		if (convertToGrating) { // Sigma very high
			stimDesc.sigmaDeg = 100000;
			//stimDesc.radiusDeg = [self linearValueWithIndex:sigmaIndex count:sigmaCount min:sigmaDegMin max:sigmaDegMax] * radiusSigmaRatio; //[Vinay] I have commented this to check its effect
		}
		else {
			stimDesc.sigmaDeg = [self linearValueWithIndex:sigmaIndex count:sigmaCount min:sigmaDegMin max:sigmaDegMax];
			//stimDesc.radiusDeg = stimDesc.sigmaDeg * radiusSigmaRatio; //[Vinay] I have commented this to check its effect

		}
        
        stimDesc.spatialFreqCPD = [self logValueWithIndex:spatialFreqIndex count:spatialFreqCount min:spatialFreqCPDMin max:spatialFreqCPDMax];
		stimDesc.directionDeg = [self linearValueWithIndex:directionDegIndex count:directionDegCount min:directionDegMin max:directionDegMax];
		
		stimDesc.contrastPC = [self contrastValueFromIndex:contrastIndex count:contrastCount min:contrastPCMin max:contrastPCMax];
		stimDesc.temporalFreqHz = [self logValueWithIndex:temporalFreqIndex count:temporalFreqCount min:temporalFreqHzMin max:temporalFreqHzMax];
        
        stimDesc.spatialPhaseDeg = [self linearValueWithIndex:spatialPhaseIndex count:spatialPhaseCount min:spatialPhaseDegMin max:spatialPhaseDegMax]; // [Vinay] - added this for spatial phase. 'logValueWithIndex' was giving a 'nan' value for spatial phase (because of 0deg phase). Therefore using 'linearValueWithIndex' instead.
        stimDesc.radiusDeg = [self logValueWithIndex:radiusIndex count:radiusCount min:radiusDegMin max:radiusDegMax]; // [Vinay] - added this for radius. Have commented this temporarily; now uncommented
        
        stimDesc.temporalModulation = [[task defaults] integerForKey:@"CRSMapTemporalModulation"];
		
		// Unused field
		
		stimDesc.orientationChangeDeg = 0.0;
		
		[list addObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];
        
        /* [Vinay] - had added the next loop. But have commented it now, since it is not required
        // [Vinay] - added to store the list corresponding to the surround gabor for copying to the surround gabor when required
        if (matchCentreSurround == TRUE & index == 0) {
            copyList = list;
        }
		*/
         
		localList[azimuthIndex][elevationIndex][sigmaIndex][spatialFreqIndex][directionDegIndex][contrastIndex][temporalFreqIndex][spatialPhaseIndex][radiusIndex] = TRUE; // [Vinay] - added [spatialPhaseIndex][radiusIndex] term
		//		NSLog(@"%d %d %d %d %d",stimDesc.azimuthIndex,stimDesc.elevationIndex,stimDesc.sigmaIndex,stimDesc.spatialFreqIndex,stimDesc.directionIndex);
		if (--localFreshCount == 0) {
			bzero(&localList,sizeof(doneList));
			localFreshCount = stimInBlock;
		}
	}
//	[self dumpStimList:list listIndex:index];
	[currentStimList release];
	currentStimList = [list retain];
	// Count the stimlist as completed
    
}

- (MappingBlockStatus)mappingBlockStatus;
{
	MappingBlockStatus status;
    
	status.stimDone = stimInBlock - stimRemainingInBlock;
	status.blocksDone = blocksDone;
	status.stimLimit = stimInBlock;
	status.blockLimit = blockLimit;
	return status;
}

- (MapSettings)mapSettings;
{
 	MapSettings settings;
  	NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTableCounts"] objectAtIndex:0];
  	NSDictionary *valuesDict;
   
	settings.azimuthDeg.n = [[countsDict objectForKey:@"azimuthCount"] intValue];
	settings.elevationDeg.n = [[countsDict objectForKey:@"elevationCount"] intValue];
	settings.sigmaDeg.n = [[countsDict objectForKey:@"sigmaCount"] intValue];
	settings.spatialFreqCPD.n = [[countsDict objectForKey:@"spatialFreqCount"] intValue];
	settings.directionDeg.n = [[countsDict objectForKey:@"orientationCount"] intValue];
	settings.contrastPC.n = [[countsDict objectForKey:@"contrastCount"] intValue];
    settings.temporalFreqHz.n = [[countsDict objectForKey:@"temporalFreqCount"] intValue];
    settings.spatialPhaseDeg.n = [[countsDict objectForKey:@"spatialPhaseCount"] intValue]; // [Vinay] - Added to match the variable in CRSStimTableCounts
    settings.radiusDeg.n = [[countsDict objectForKey:@"radiusCount"] intValue]; // [Vinay] - Added to match the variable in CRSStimTableCounts
 
  	valuesDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTables"] objectAtIndex:0];
    settings.azimuthDeg.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"azimuthDeg%ld", mapIndex]] floatValue];
    settings.elevationDeg.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"elevationDeg%ld", mapIndex]] floatValue];
    settings.sigmaDeg.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"sigmaDeg%ld", mapIndex]] floatValue];
    settings.spatialFreqCPD.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"spatialFreqCPD%ld", mapIndex]] floatValue];
    settings.directionDeg.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"orientationDeg%ld", mapIndex]] floatValue];
    settings.contrastPC.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"contrastPC%ld", mapIndex]] floatValue];
    settings.temporalFreqHz.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"temporalFreqHz%ld", mapIndex]] floatValue];
    settings.spatialPhaseDeg.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"spatialPhaseDeg%ld", mapIndex]] floatValue]; // [Vinay] - Added for spatial Phase min value
    settings.radiusDeg.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"radiusDeg%ld", mapIndex]] floatValue]; // [Vinay] - Added for radius min value
    
 	valuesDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTables"] objectAtIndex:1];
    settings.azimuthDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"azimuthDeg%ld", mapIndex]] floatValue];
    settings.elevationDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"elevationDeg%ld", mapIndex]] floatValue];
    settings.sigmaDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"sigmaDeg%ld", mapIndex]] floatValue];
    settings.spatialFreqCPD.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"spatialFreqCPD%ld", mapIndex]] floatValue];
    settings.directionDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"orientationDeg%ld", mapIndex]] floatValue];
    settings.contrastPC.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"contrastPC%ld", mapIndex]] floatValue];
    settings.temporalFreqHz.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"temporalFreqHz%ld", mapIndex]] floatValue];
    settings.spatialPhaseDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"spatialPhaseDeg%ld", mapIndex]] floatValue]; // [Vinay] - Added for spatial Phase min value
    settings.radiusDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"radiusDeg%ld", mapIndex]] floatValue]; // [Vinay] - Added for radius min value
    
    /*valuesDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTables"] objectAtIndex:2];                                          // [Vinay] - Added for centre gabor. And then commented, becuase this isn't required. This is just reading from min and max items of CRSStimTables
    settings.azimuthDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"azimuthDeg%ld", mapIndex]] floatValue];
    settings.elevationDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"elevationDeg%ld", mapIndex]] floatValue];
    settings.sigmaDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"sigmaDeg%ld", mapIndex]] floatValue];
    settings.spatialFreqCPD.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"spatialFreqCPD%ld", mapIndex]] floatValue];
    settings.directionDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"orientationDeg%ld", mapIndex]] floatValue];
    settings.contrastPC.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"contrastPC%ld", mapIndex]] floatValue];
    settings.temporalFreqHz.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"temporalFreqHz%ld", mapIndex]] floatValue];
     */
    return settings;
}

- (void)newBlock;
{
	bzero(&doneList, sizeof(doneList));
	stimRemainingInBlock = stimInBlock;
}

- (void)reset;
{
	long index;
    for (index = 0; index<kGabors-1; index++) {
        [self updateBlockParameters:index];
    }
    [self newBlock];
    blocksDone = 0;
}

- (void)tallyStimList:(NSMutableArray *)list  count:(long)count;
{
	// count = the number of stims that have been processed completely.
	//         The list is processed in order so the first count stims
	//         can be marked done.
	StimDesc stimDesc;
	int stim;
	NSMutableArray *l;
	
	if (list == nil) {
		l = currentStimList;
	}
	else {
		l = list;
	}
	
	for (stim = 0; stim < count; stim++) {
		short a=0, e=0, sf=0, sig=0, o=0, c=0, t=0, p=0, r=0;        // [Vinay] - Added 'p=0' for spatial phase and 'r=0' for radius
		NSValue *val = [l objectAtIndex:stim];
		
		[val getValue:&stimDesc];
		a=stimDesc.azimuthIndex;
		e=stimDesc.elevationIndex;
		sf=stimDesc.spatialFreqIndex;
		sig=stimDesc.sigmaIndex;
		o=stimDesc.directionIndex;
		c=stimDesc.contrastIndex;
        t=stimDesc.temporalFreqIndex;
        p=stimDesc.spatialPhaseIndex;                             // [Vinay] - Added this for spatial phase. Was erroneously equal to value instead of index. Have corrected it now
        r=stimDesc.radiusIndex;                                   // [Vinay] - Added this for radius. Was erroneously equal to value instead of index. Have corrected it now
		
		//doneList[a][e][sig][sf][o][c][t][p][r] = TRUE;                // [Vinay] - Have to increase the dimension of donelist and add [p] and [r] here. Have done so now.
        doneList[a][e][sf][sig][o][c][t][p][r] = TRUE;                // [Vinay] - and swapped [sf] and [sig] since [sig] is the 4th dimension. It was causing errors otherwise
        
		if (--stimRemainingInBlock == 0 ) {
			[self newBlock];
			blocksDone++;
		}
	}
	return;
}

- (void)tallyStimList:(NSMutableArray *)list  upToFrame:(long)frameLimit;
{
	StimDesc stimDesc;
	long a, e, sf, sig, o, stim, c, t, p, r;       // [Vinay] - Added 'p' for spatial phase and 'r' for radius
	NSValue *val;
	NSMutableArray *l;
	
	l = (list == nil) ? currentStimList : list;
	for (stim = 0; stim < [l count]; stim++) {
		val = [l objectAtIndex:stim];
		[val getValue:&stimDesc];
		if (stimDesc.stimOffFrame > frameLimit) {
			break;
		}
		a = stimDesc.azimuthIndex;
		e = stimDesc.elevationIndex;
		sf = stimDesc.spatialFreqIndex;
		sig = stimDesc.sigmaIndex;
		o = stimDesc.directionIndex;
		c = stimDesc.contrastIndex;
        t=stimDesc.temporalFreqIndex;
        p=stimDesc.spatialPhaseIndex;                 // [Vinay] - Added this for spatial phase. Was erroneously equal to value instead of index. Have corrected it now
        r=stimDesc.radiusIndex;                 // [Vinay] - Added this for radius. Was erroneously equal to value instead of index. Have corrected it now
		//doneList[a][e][sig][sf][o][c][t][p][r] = YES;     // [Vinay] - Have to increase the dimension of donelist and add [p] and [r] here. Have done so now.
		doneList[a][e][sf][sig][o][c][t][p][r] = TRUE;                // [Vinay] - and swapped [sf] and [sig] since [sig] is the 4th dimension. It was causing errors otherwise
        
        if (--stimRemainingInBlock == 0 ) {
			[self newBlock];
			blocksDone++;
		}
	}
	return;
}

- (long)stimDoneInBlock;
{
	return stimInBlock - stimRemainingInBlock;
}

- (long)stimInBlock;
{
	return stimInBlock;
}

- (void)updateBlockParameters:(long)index;
{
	long azimuthCount, elevationCount, sigmaCount, spatialFreqCount, directionCount, contrastCount, temporalFreqCount, spatialPhaseCount, radiusCount;   // [Vinay] - Added spatialPhaseCount, radiusCount
	NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTableCounts"] objectAtIndex:0];
    
    /*
    azimuthCount = [[countsDict objectForKey:@"azimuthCount"] intValue];
	elevationCount = [[countsDict objectForKey:@"elevationCount"] intValue];
	sigmaCount = [[countsDict objectForKey:@"sigmaCount"] intValue];
	spatialFreqCount = [[countsDict objectForKey:@"spatialFreqCount"] intValue];
	directionCount = [[countsDict objectForKey:@"orientationCount"] intValue];
	contrastCount = [[countsDict objectForKey:@"contrastCount"] intValue];
	temporalFreqCount = [[countsDict objectForKey:@"temporalFreqCount"] intValue];
    spatialPhaseCount = [[countsDict objectForKey:@"spatialPhaseCount"] intValue];              // [Vinay] - Added this for spatialPhase
    radiusCount = [[countsDict objectForKey:@"radiusCount"] intValue];              // [Vinay] - Added this for radius
    */ // [Vinay] - commented these steps above and put the switch loop below
     
    switch (index){
        case 0:
        default:
            azimuthCount = [[countsDict objectForKey:@"azimuthCount0"] intValue];
            elevationCount = [[countsDict objectForKey:@"elevationCount0"] intValue];
            sigmaCount = [[countsDict objectForKey:@"sigmaCount0"] intValue];
            spatialFreqCount = [[countsDict objectForKey:@"spatialFreqCount0"] intValue];
            directionCount = [[countsDict objectForKey:@"orientationCount0"] intValue];
            contrastCount = [[countsDict objectForKey:@"contrastCount0"] intValue];
            temporalFreqCount = [[countsDict objectForKey:@"temporalFreqCount0"] intValue];
            spatialPhaseCount = [[countsDict objectForKey:@"spatialPhaseCount0"] intValue]; // [Vinay] - added for spatial phase
            radiusCount = [[countsDict objectForKey:@"radiusCount0"] intValue]; // [Vinay] - added for radius
            break;
            
        case 1:
            azimuthCount = [[countsDict objectForKey:@"azimuthCount1"] intValue];
            elevationCount = [[countsDict objectForKey:@"elevationCount1"] intValue];
            sigmaCount = [[countsDict objectForKey:@"sigmaCount1"] intValue];
            spatialFreqCount = [[countsDict objectForKey:@"spatialFreqCount1"] intValue];
            directionCount = [[countsDict objectForKey:@"orientationCount1"] intValue];
            contrastCount = [[countsDict objectForKey:@"contrastCount1"] intValue];
            temporalFreqCount = [[countsDict objectForKey:@"temporalFreqCount1"] intValue];
            spatialPhaseCount = [[countsDict objectForKey:@"spatialPhaseCount1"] intValue]; // [Vinay] - added for spatial phase
            radiusCount = [[countsDict objectForKey:@"radiusCount1"] intValue]; // [Vinay] - added for radius
            break;
            
        case 2:
            azimuthCount = [[countsDict objectForKey:@"azimuthCount2"] intValue];
            elevationCount = [[countsDict objectForKey:@"elevationCount2"] intValue];
            sigmaCount = [[countsDict objectForKey:@"sigmaCount2"] intValue];
            spatialFreqCount = [[countsDict objectForKey:@"spatialFreqCount2"] intValue];
            directionCount = [[countsDict objectForKey:@"orientationCount2"] intValue];
            contrastCount = [[countsDict objectForKey:@"contrastCount2"] intValue];
            temporalFreqCount = [[countsDict objectForKey:@"temporalFreqCount2"] intValue];
            spatialPhaseCount = [[countsDict objectForKey:@"spatialPhaseCount2"] intValue]; // [Vinay] - added for spatial phase
            radiusCount = [[countsDict objectForKey:@"radiusCount2"] intValue]; // [Vinay] - added for radius
            break;
    }

    
	stimInBlock = stimRemainingInBlock = azimuthCount * elevationCount * sigmaCount * spatialFreqCount * directionCount * contrastCount * temporalFreqCount * spatialPhaseCount*radiusCount;        // [Vinay] - Added the factor spatialPhaseCount*radiusCount
	blockLimit = [[task defaults] integerForKey:CRSMappingBlocksKey];
}

@end
