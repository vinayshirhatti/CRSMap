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

- (id)initWithIndex:(long)index;
{
	if (!(self = [super init])) {
		return nil;
	}
    mapIndex = index;
	[self updateBlockParameters:mapIndex]; // [Vinay] added mapIndex argument here because updateBlockParameters has been redefined here to work on each gabor separately
	[self newBlock];
	return self;
}

// No one should init without using [initWithIndex:], but if they do, we automatically increment the index counter;

- (id)init;
{
	if (!(self = [super init])) {
		return nil;
	}
    mapIndex = CRSMapStimTableCounter++;
    NSLog(@"CRSMapStimTable: initializing with index %ld", mapIndex);
	[self updateBlockParameters:mapIndex]; // [Vinay] added mapIndex argument here because updateBlockParameters has been redefined here to work on each gabor separately
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

// [Vinay] - to map values logarithmically from max to min with a factor of 0.5
- (float)logMaxToMinValueFromIndex:(long)index count:(long)count min:(float)min max:(float)max;
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
				level = max-min;
				for (c = stimLevels - 1; c > index; c--) {
					level *= stimFactor;
				}
				stimValue = level+min;
			}
	}
	return(stimValue);
}

//[Vinay] - to map tf values the same way as for contrast. However the max limit is (frame refresh rate)/2 set as per the refresh rate of the monitor
- (float)tfValueFromIndex:(long)index count:(long)count min:(float)min max:(float)max;
{
	short c, stimLevels;
	float stimValue, level, stimFactor, maxLimit;
	
    maxLimit = [[task stimWindow] frameRateHz]/2;
    
	stimLevels = count;
	stimFactor = 0.5;
	switch (stimLevels) {
		case 1:								// Just the min stimulus
			stimValue = min;
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
    stimValue = (stimValue > maxLimit) ? maxLimit : stimValue; // [Vinay] - adjust the stimValue if it exceeds the maximum allowed limit
	return(stimValue);
}


- (float)linearValueWithIndex:(long)index count:(long)count min:(float)min max:(float)max;
{
	return (count < 2) ? min : (min + ((max - min) / (count - 1)) * index);
}

- (float)logValueWithIndex:(long)index count:(long)count min:(float)min max:(float)max;
{
	if (count==2) { // [Vinay] - adding this condition to cover the case where only two values are required
        return (index == 0) ? min : max;
    }
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
    
    /*----------------------[Vinay] - Have changed the doneList strategy to a dynamically updating doneList size now-------------
     */
    // [Vinay] - following lines have been commented and the modified lines follow next
	// BOOL localList[kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues]; // [Vinay] - commented this
    BOOL localList[kMaxMapValuesFixed][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues]; // [Vinay] : changed it from a 7 to a 9 dimensional list to include dimensions for spatial phase and radius. The order is: [a][e][sf][sig][o][c][tf][p][r]
    // [Vinay] - changed the localList to include another dimension for gabor index
    // BOOL localList[kGabors-1][kMaxMapValuesFixed][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues]; // [Vinay] : changed it from a 7 to a 9 dimensional list to include dimensions for spatial phase and radius. The order is: [a][e][sf][sig][o][c][tf][p][r]
    
    /*
    int aziCount, eleCount, sfCount, sigCount, oriCount, conCount,tfCount, spCount, radCount; // int variables to hold the count values for the parameters
    NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTableCounts"] objectAtIndex:0];
    
    //aziCount = fmax([[countsDict objectForKey:@"azimuthCount0"] intValue],fmax([[countsDict objectForKey:@"azimuthCount1"] intValue], [[countsDict objectForKey:@"azimuthCount2"] intValue])); //aziCount is assigned the bigger of the three counts corresponding to the three gabors
    aziCount = [[countsDict objectForKey:[NSString stringWithFormat:@"azimuthCount%ld",index]] intValue];
    eleCount = [[countsDict objectForKey:[NSString stringWithFormat:@"elevationCount%ld",index]] intValue];
    sfCount = [[countsDict objectForKey:[NSString stringWithFormat:@"spatialFreqCount%ld",index]] intValue];
    sigCount = [[countsDict objectForKey:[NSString stringWithFormat:@"sigmaCount%ld",index]] intValue];
    oriCount = [[countsDict objectForKey:[NSString stringWithFormat:@"orientationCount%ld",index]] intValue];
    conCount = [[countsDict objectForKey:[NSString stringWithFormat:@"contrastCount%ld",index]] intValue];
    tfCount = [[countsDict objectForKey:[NSString stringWithFormat:@"temporalFreqCount%ld",index]] intValue];
    spCount = [[countsDict objectForKey:[NSString stringWithFormat:@"spatialPhaseCount%ld",index]] intValue];
    radCount = [[countsDict objectForKey:[NSString stringWithFormat:@"radiusCount%ld",index]] intValue];
    
    BOOL localList[aziCount][eleCount][sfCount][sigCount][oriCount][conCount][tfCount][spCount][radCount];
    */
    /*----------------[Vinay] - Till here-----------------*/
    
	
    float azimuthDegMin, azimuthDegMax, elevationDegMin, elevationDegMax, sigmaDegMin, sigmaDegMax, spatialFreqCPDMin, spatialFreqCPDMax, directionDegMin, directionDegMax, radiusSigmaRatio, contrastPCMin, contrastPCMax, temporalFreqHzMin, temporalFreqHzMax, spatialPhaseDegMin, spatialPhaseDegMax, radiusDegMin, radiusDegMax; //[Vinay] -  Added spatialPhaseDegMin, spatialPhaseDegMax, radiusDegMin, radiusDegMax
	BOOL hideStimulus, convertToGrating, noneProtocol=NO, ringProtocol=NO, contrastRingProtocol=NO, dualContrastProtocol=NO, dualOrientationProtocol=NO, dualPhaseProtocol=NO, orientationRingProtocol=NO, phaseRingProtocol=NO, driftingPhaseProtocol=NO, crossOrientationProtocol=NO, annulusFixedProtocol = NO; // [Vinay] - added matchCentreSurround to indicate similarity between the centre and surround attributes whenever required. , matchCentreSurround=NO was removed because it isn't being used in this loop
    
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
        case 8:
            driftingPhaseProtocol = YES; // [Vinay] - not being used in this loop anywhere actually
            break;
        case 9:
            crossOrientationProtocol = YES;
            break;
        case 10:
            annulusFixedProtocol = YES;
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
            hideStimulus = (dualContrastProtocol || dualOrientationProtocol || dualPhaseProtocol || crossOrientationProtocol || ([[task defaults] boolForKey:CRSHideSurroundKey] && noneProtocol)); // [Vinay] - To hide the surround stimulus if the protocol is any of these three dual protocols or if it is COS protocol where plaids are drawn. The stimulus is drawn completely with just the centre and the surround stimulus. Also hide if explicitly asked to do so, but only during none protocol mode. gabor0 corresponds to the surround gabor.
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
            if(ringProtocol || annulusFixedProtocol){
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
	
	//memcpy(&localList, &doneList, sizeof(doneList)); [Vinay] - changed this line to the line below so that the corresponding doneList is copied as per the gabor index
    memcpy(&localList, &doneList[index], sizeof(doneList[index]));
	//localFreshCount = stimRemainingInBlock; //[Vinay] commented
    localFreshCount = stimRemainingInBlockGabor[index]; // [Vinay] - separate index for separate gabors
	frameRateHz = [[task stimWindow] frameRateHz];
/*
    // debugging start
    short a, e, sig, sf, dir, c, debugLocalListCount = 0, debugDoneListCount = 0;
    NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTableCounts"] objectAtIndex:0];
    
    for (a = 0;  a < [[countsDict objectForKey:@"azimuthCount"] intValue]; a++) {
        for (e = 0;  e < [[countsDict objectForKey:@"elevationCount"] intValue]; e++) {
            for (sig = 0;  sig < [[countsDict objectForKey:@"sigmaCount"] intValue]; sig++) {
                for (sf = 0;  sf < [[countsDict objectForKey:@"spatialFreqCount"] intValue]; sf++) {
                    for (dir = 0;  dir < [[countsDict objectForKey:@"orientationCount"] intValue]; dir++) {
                        for (c = 0;  c < [[countsDict objectForKey:@"contrastCount"] intValue]; c++) {
                            if (localList[a][e][sig][sf][dir][c]) {
                                debugLocalListCount++;
                                debugDoneListCount++;
                            }
                        }
                    }
                }
            }
        }
    }
    
    NSLog(@"debugLocalListCount is %d", debugLocalListCount);
    NSLog(@"debugDoneListCount is %d", debugDoneListCount);
    // debugging end
*/
	mapDurFrames = MAX(1, ceil([[task defaults] integerForKey:CRSMapStimDurationMSKey] / 1000.0 * frameRateHz));
	interDurFrames = ceil([[task defaults] integerForKey:CRSMapInterstimDurationMSKey] / 1000.0 * frameRateHz);
	
	[list removeAllObjects];
	
	for (stim = frame = 0; frame < lastFrame; stim++, frame += mapDurFrames + interDurFrames) {
		
		int azimuthIndex, elevationIndex, sigmaIndex, spatialFreqIndex, directionDegIndex, contrastIndex, temporalFreqIndex, spatialPhaseIndex, radiusIndex; // spatialFreqIndexCopy=0, directionDegIndexCopy=0, contrastIndexCopy=0, temporalFreqIndexCopy=0, spatialPhaseIndexCopy=0; // [Vinay] - Added spatialPhaseIndex, radiusIndex. Added - spatialFreqIndexCopy, directionDegIndexCopy, contrastIndexCopy, temporalFreqIndexCopy, spatialPhaseIndexCopy to store their alues for one gabor to be assigned to another gabor when required. They have been initialized because otherwise an error was throwing up. Now commented
		NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTableCounts"] objectAtIndex:0];
		int azimuthCount, elevationCount, sigmaCount, spatialFreqCount, directionDegCount, contrastCount, temporalFreqCount, spatialPhaseCount, radiusCount; // [Vinay - Added spatialPhaseCount, radiusCount
		int startAzimuthIndex, startElevationIndex, startSigmaIndex, startSpatialFreqIndex, startDirectionDegIndex, startContrastIndex,startTemporalFreqIndex, startSpatialPhaseIndex, startRadiusIndex; // [Vinay] - Added startSpatialPhaseIndex, startRadiusIndex
		BOOL stimDone = YES;
        
        
        // [Vinay] - The following code for reading the count values has been changed to instead read and assign values as per the specific protocol. Hence the follwoing code is commented temporarily and the new code is placed ahead. This code has been taken from updateBlockParameters which is a function ahead in this program.
    /*
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
    */      
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
    /*        break;
                
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
    */    
        /*
        // [Vinay] The earlier code is commented - (and now uncommented)
	
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
        
        // [Vinay] New code to evaluate the count values
        
        long azimuthCount0, elevationCount0, sigmaCount0, spatialFreqCount0, directionCount0, contrastCount0, temporalFreqCount0, spatialPhaseCount0, radiusCount0, azimuthCount1, elevationCount1, sigmaCount1, spatialFreqCount1, directionCount1, contrastCount1, temporalFreqCount1, spatialPhaseCount1, radiusCount1, azimuthCount2, elevationCount2, sigmaCount2, spatialFreqCount2, directionCount2, contrastCount2, temporalFreqCount2, spatialPhaseCount2, radiusCount2;   // [Vinay] - Added spatialPhaseCount, radiusCount and later added the parameters for the other two gabors
        
        azimuthCount0 = [[countsDict objectForKey:@"azimuthCount0"] intValue];
        elevationCount0 = [[countsDict objectForKey:@"elevationCount0"] intValue];
        sigmaCount0 = [[countsDict objectForKey:@"sigmaCount0"] intValue];
        spatialFreqCount0 = [[countsDict objectForKey:@"spatialFreqCount0"] intValue];
        directionCount0 = [[countsDict objectForKey:@"orientationCount0"] intValue];
        contrastCount0 = [[countsDict objectForKey:@"contrastCount0"] intValue];
        temporalFreqCount0 = [[countsDict objectForKey:@"temporalFreqCount0"] intValue];
        spatialPhaseCount0 = [[countsDict objectForKey:@"spatialPhaseCount0"] intValue]; // [Vinay] - added for spatial phase
        radiusCount0 = [[countsDict objectForKey:@"radiusCount0"] intValue]; // [Vinay] - added for radius
        
        azimuthCount1 = [[countsDict objectForKey:@"azimuthCount1"] intValue];
        elevationCount1 = [[countsDict objectForKey:@"elevationCount1"] intValue];
        sigmaCount1 = [[countsDict objectForKey:@"sigmaCount1"] intValue];
        spatialFreqCount1 = [[countsDict objectForKey:@"spatialFreqCount1"] intValue];
        directionCount1 = [[countsDict objectForKey:@"orientationCount1"] intValue];
        contrastCount1 = [[countsDict objectForKey:@"contrastCount1"] intValue];
        temporalFreqCount1 = [[countsDict objectForKey:@"temporalFreqCount1"] intValue];
        spatialPhaseCount1 = [[countsDict objectForKey:@"spatialPhaseCount1"] intValue]; // [Vinay] - added for spatial phase
        radiusCount1 = [[countsDict objectForKey:@"radiusCount1"] intValue]; // [Vinay] - added for radius
        
        azimuthCount2 = [[countsDict objectForKey:@"azimuthCount2"] intValue];
        elevationCount2 = [[countsDict objectForKey:@"elevationCount2"] intValue];
        sigmaCount2 = [[countsDict objectForKey:@"sigmaCount2"] intValue];
        spatialFreqCount2 = [[countsDict objectForKey:@"spatialFreqCount2"] intValue];
        directionCount2 = [[countsDict objectForKey:@"orientationCount2"] intValue];
        contrastCount2 = [[countsDict objectForKey:@"contrastCount2"] intValue];
        temporalFreqCount2 = [[countsDict objectForKey:@"temporalFreqCount2"] intValue];
        spatialPhaseCount2 = [[countsDict objectForKey:@"spatialPhaseCount2"] intValue]; // [Vinay] - added for spatial phase
        radiusCount2 = [[countsDict objectForKey:@"radiusCount2"] intValue]; // [Vinay] - added for radius
        
        
        //==========================^^^^^^^^
        // [Vinay] - change the counts based on specific protocols. This is necessary because some features of the gabors are matched as per the requirements of the specific protocols and therefore the total count actually reduces
        
        //### [Vinay] - this method of setting the values for the count keys as used below is failing! So comment this out!
        
        switch ([[task defaults] integerForKey:@"CRSProtocolNumber"]) {
            case 0:
                //noneProtocol
                // Do nothing, except for when particular keys are raised. Eg. hide a certain gabor => pull all its counts to 1 OR in match conditions pull the redundant counts to 1
                if ([[task defaults] boolForKey:CRSHideSurroundKey]) {
                    azimuthCount0 = 1;
                    elevationCount0 = 1;
                    sigmaCount0 = 1;
                    spatialFreqCount0 = 1;
                    directionCount0 = 1;
                    contrastCount0 = 1;
                    temporalFreqCount0 = 1;
                    spatialPhaseCount0 = 1;
                    radiusCount0 = 1;
                }
                
                if ([[task defaults] boolForKey:CRSHideRingKey]) {
                    azimuthCount1 = 1;
                    elevationCount1 = 1;
                    sigmaCount1 = 1;
                    spatialFreqCount1 = 1;
                    directionCount1 = 1;
                    contrastCount1 = 1;
                    temporalFreqCount1 = 1;
                    spatialPhaseCount1 = 1;
                    radiusCount1 = 1;
                    
                }
                else if (![[task defaults] boolForKey:CRSHideRingKey] && [[task defaults] boolForKey:CRSMatchRingSurroundKey]) {
                    azimuthCount1 = 1;
                    elevationCount1 = 1;
                    sigmaCount1 = 1;
                    spatialFreqCount1 = 1;
                    directionCount1 = 1;
                    contrastCount1 = 1;
                    temporalFreqCount1 = 1;
                    spatialPhaseCount1 = 1;
                    //radiusCount1 = 1; //[Vinay] - make every count 1 except radiusCount
                }
                
                if ([[task defaults] boolForKey:CRSHideCentreKey]) {
                    azimuthCount2 = 1;
                    elevationCount2 = 1;
                    sigmaCount2 = 1;
                    spatialFreqCount2 = 1;
                    directionCount2 = 1;
                    contrastCount2 = 1;
                    temporalFreqCount2 = 1;
                    spatialPhaseCount2 = 1;
                    radiusCount2 = 1;
                }
                else if (![[task defaults] boolForKey:CRSHideCentreKey] && ([[task defaults] boolForKey:CRSMatchCentreRingKey] || [[task defaults] boolForKey:CRSMatchCentreSurroundKey])) {
                    azimuthCount2 = 1;
                    elevationCount2 = 1;
                    sigmaCount2 = 1;
                    spatialFreqCount2 = 1;
                    directionCount2 = 1;
                    contrastCount2 = 1;
                    temporalFreqCount2 = 1;
                    spatialPhaseCount2 = 1;
                    //radiusCount2 = 1; //[Vinay] - make every count 1 except radiusCount
                }
                break;
            case 1:
                //ringProtocol
                //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
                azimuthCount2 = 1;
                elevationCount2 = 1;
                sigmaCount2 = 1;
                spatialFreqCount2 = 1;
                directionCount2 = 1;
                contrastCount2 = 1;
                temporalFreqCount2 = 1;
                spatialPhaseCount2 = 1;
                
                // [Vinay] - ring contrast is set to 0. Therefore take all the counts to 1 except radius
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                directionCount1 = 1;
                contrastCount1 = 1;
                temporalFreqCount1 = 1;
                spatialPhaseCount1 = 1;
                
                break;
            case 2:
                //contrastRingProtocol
                //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
                azimuthCount2 = 1;
                elevationCount2 = 1;
                sigmaCount2 = 1;
                spatialFreqCount2 = 1;
                directionCount2 = 1;
                contrastCount2 = 1;
                temporalFreqCount2 = 1;
                spatialPhaseCount2 = 1;
                
                // [Vinay] - Therefore take all the counts to 1 except contrast and radius
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                directionCount1 = 1;
                //contrastCount1 = 1;
                temporalFreqCount1 = 1;
                spatialPhaseCount1 = 1;
                break;
            case 3:
                //dualContrastProtocol
                //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
                azimuthCount0 = 1;
                elevationCount0 = 1;
                sigmaCount0 = 1;
                spatialFreqCount0 = 1;
                directionCount0 = 1;
                contrastCount0 = 1;
                temporalFreqCount0 = 1;
                spatialPhaseCount0 = 1;
                radiusCount0 = 1;
                
                //[Vinay] - ring radius set to maximum => radiusCount = 1. Except contrast rest are matched to the centre => theirCount = 1
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                directionCount1 = 1;
                //contrastCount1 = 1;
                temporalFreqCount1 = 1;
                spatialPhaseCount1 = 1;
                radiusCount1 = 1;
                
                break;
            case 4:
                //dualOrientationProtocol
                //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
                azimuthCount0 = 1;
                elevationCount0 = 1;
                sigmaCount0 = 1;
                spatialFreqCount0 = 1;
                directionCount0 = 1;
                contrastCount0 = 1;
                temporalFreqCount0 = 1;
                spatialPhaseCount0 = 1;
                radiusCount0 = 1;
                
                //[Vinay] - ring radius set to maximum => radiusCount = 1. Except orientation i.e. direction rest are matched to the centre => theirCount = 1
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                //directionCount1 = 1;
                contrastCount1 = 1;
                temporalFreqCount1 = 1;
                spatialPhaseCount1 = 1;
                radiusCount1 = 1;
                
                break;
            case 5:
                //dualPhaseProtocol
                //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
                azimuthCount0 = 1;
                elevationCount0 = 1;
                sigmaCount0 = 1;
                spatialFreqCount0 = 1;
                directionCount0 = 1;
                contrastCount0 = 1;
                temporalFreqCount0 = 1;
                spatialPhaseCount0 = 1;
                radiusCount0 = 1;
                
                //[Vinay] - ring radius set to maximum => radiusCount = 1. Except spatial phase rest are matched to the centre => theirCount = 1
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                directionCount1 = 1;
                contrastCount1 = 1;
                temporalFreqCount1 = 1;
                //spatialPhaseCount1 = 1;
                radiusCount1 = 1;
                
                break;
            case 6:
                //orientationRingProtocol
                //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
                azimuthCount2 = 1;
                elevationCount2 = 1;
                sigmaCount2 = 1;
                spatialFreqCount2 = 1;
                directionCount2 = 1;
                contrastCount2 = 1;
                temporalFreqCount2 = 1;
                spatialPhaseCount2 = 1;
                
                // [Vinay] - Therefore take all the counts to 1 except orientation i.e. direction and radius
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                //directionCount1 = 1;
                contrastCount1 = 1;
                temporalFreqCount1 = 1;
                spatialPhaseCount1 = 1;
                break;
            case 7:
                //phaseRingProtocol
                //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
                azimuthCount2 = 1;
                elevationCount2 = 1;
                sigmaCount2 = 1;
                spatialFreqCount2 = 1;
                directionCount2 = 1;
                contrastCount2 = 1;
                temporalFreqCount2 = 1;
                spatialPhaseCount2 = 1;
                
                // [Vinay] - Therefore take all the counts to 1 except spatial phase and radius
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                directionCount1 = 1;
                contrastCount1 = 1;
                temporalFreqCount1 = 1;
                //spatialPhaseCount1 = 1;
                break;
            case 8:
                //driftingPhaseProtocol
                //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
                azimuthCount2 = 1;
                elevationCount2 = 1;
                sigmaCount2 = 1;
                spatialFreqCount2 = 1;
                directionCount2 = 1;
                contrastCount2 = 1;
                temporalFreqCount2 = 1;
                spatialPhaseCount2 = 1;
                
                // [Vinay] - Therefore take all the counts to 1 except temporal frequency and radius
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                directionCount1 = 1;
                contrastCount1 = 1;
                //temporalFreqCount1 = 1;
                spatialPhaseCount1 = 1;
                
                break;
            case 9:
                //crossOrientationProtocol
                //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
                azimuthCount0 = 1;
                elevationCount0 = 1;
                sigmaCount0 = 1;
                spatialFreqCount0 = 1;
                directionCount0 = 1;
                contrastCount0 = 1;
                temporalFreqCount0 = 1;
                spatialPhaseCount0 = 1;
                radiusCount0 = 1;
                
                break;
            case 10:
                //annulusFixedProtocol
                //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround).
                azimuthCount2 = 1;
                elevationCount2 = 1;
                sigmaCount2 = 1;
                spatialFreqCount2 = 1;
                directionCount2 = 1;
                contrastCount2 = 1;
                temporalFreqCount2 = 1;
                spatialPhaseCount2 = 1;
                //radiusCount2 = 1;
                
                // [Vinay] - ring contrast is set to 0. Therefore take all the counts to 1. The radiusCount for gabor1 (ring) is also accounted for by the count for gabor2 i.e. the centre gabor. Therefore set this to 1 as well.
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                directionCount1 = 1;
                contrastCount1 = 1; // [Vinay] - comment this if using a ring (fixed annulus in this case) of varying contrasts
                temporalFreqCount1 = 1;
                spatialPhaseCount1 = 1;
                //radiusCount1 = 1; // [Vinay] - comment this if using a ring (fixed annulus in this case) of multiple widths
                
                break;

            default:
                break;
        }
        
        //==========================~~~~~~~~~
        
        //-----------------------------------
        // [Vinay] - next switch loop changed to read the modified count values as per the specific protocol instead of directly from the corresponding keys
        /*
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
         */
        // [Vinay] - Now follows the modified switch case
        switch (index){
            case 0:
            default:
                azimuthCount = azimuthCount0;
                elevationCount = elevationCount0;
                sigmaCount = sigmaCount0;
                spatialFreqCount = spatialFreqCount0;
                directionDegCount = directionCount0; // [Vinay] - In this loop directionCount is directionDegCount. Hence the difference from the code in updateBlockParameters
                contrastCount = contrastCount0;
                temporalFreqCount = temporalFreqCount0;
                spatialPhaseCount = spatialPhaseCount0;
                radiusCount = radiusCount0;
                break;
                
            case 1:
                azimuthCount = azimuthCount1;
                elevationCount = elevationCount1;
                sigmaCount = sigmaCount1;
                spatialFreqCount = spatialFreqCount1;
                directionDegCount = directionCount1; // [Vinay] - In this loop directionCount is directionDegCount. Hence the difference from the code in updateBlockParameters
                contrastCount = contrastCount1;
                temporalFreqCount = temporalFreqCount1;
                spatialPhaseCount = spatialPhaseCount1;
                radiusCount = radiusCount1;
                break;
                
            case 2:
                azimuthCount = azimuthCount2;
                elevationCount = elevationCount2;
                sigmaCount = sigmaCount2;
                spatialFreqCount = spatialFreqCount2;
                directionDegCount = directionCount2; // [Vinay] - In this loop directionCount is directionDegCount. Hence the difference from the code in updateBlockParameters
                contrastCount = contrastCount2;
                temporalFreqCount = temporalFreqCount2;
                spatialPhaseCount = spatialPhaseCount2;
                radiusCount = radiusCount2;
                break;
        }
        
        //---------------------------------------
        
        
        
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
        
        // [Vinay] - since sigma calculation depends on radius value, it is now pushed after radius value is determined
        /*
		if (convertToGrating) { // Sigma very high
			stimDesc.sigmaDeg = 100000;
			//stimDesc.radiusDeg = [self linearValueWithIndex:sigmaIndex count:sigmaCount min:sigmaDegMin max:sigmaDegMax] * radiusSigmaRatio; //[Vinay] I have commented this to check its effect
		}
		else {
			//stimDesc.sigmaDeg = [self linearValueWithIndex:sigmaIndex count:sigmaCount min:sigmaDegMin max:sigmaDegMax];
			//stimDesc.radiusDeg = stimDesc.sigmaDeg * radiusSigmaRatio; //[Vinay] I have commented this to check its effect
            stimDesc.sigmaDeg = stimDesc.radiusDeg/radiusSigmaRatio; // [Vinay] - since sigma count is always 1, sigma is instead calculated based on the radius and the radiusSigmaRatio

		}
         */
        
        
        // [Vinay] - calculating spatial frequency (SF) depending on the selected mapping method
        int sfMapping;
        switch (index) {
            case 0:
            default:
                sfMapping = [[task defaults] integerForKey:@"CRSMapSFMappingSurround"];
                break;
                
            case 1:
                sfMapping = [[task defaults] integerForKey:@"CRSMapSFMappingRing"];
                break;
                
            case 2:
                sfMapping = [[task defaults] integerForKey:@"CRSMapSFMappingCentre"];
                break;
        }
        
        switch (sfMapping) {
            case 0: // [Vinay] - default log mapping with a factor of 0.5
                stimDesc.spatialFreqCPD = [self contrastValueFromIndex:spatialFreqIndex count:spatialFreqCount min:spatialFreqCPDMin max:spatialFreqCPDMax];
                break;
            case 1: // [Vinay] - log mapping from max to min with a factor of 0.5
                stimDesc.spatialFreqCPD = [self logMaxToMinValueFromIndex:spatialFreqIndex count:spatialFreqCount min:spatialFreqCPDMin max:spatialFreqCPDMax];
                break;
            case 2: // [Vinay] - linear mapping
                stimDesc.spatialFreqCPD = [self linearValueWithIndex:spatialFreqIndex count:spatialFreqCount min:spatialFreqCPDMin max:spatialFreqCPDMax];
                break;
            default:
                stimDesc.spatialFreqCPD = [self contrastValueFromIndex:spatialFreqIndex count:spatialFreqCount min:spatialFreqCPDMin max:spatialFreqCPDMax];
                break;
        }

        //stimDesc.spatialFreqCPD = [self logValueWithIndex:spatialFreqIndex count:spatialFreqCount min:spatialFreqCPDMin max:spatialFreqCPDMax];
		
        stimDesc.directionDeg = [self linearValueWithIndex:directionDegIndex count:directionDegCount min:directionDegMin max:directionDegMax];
		
        // [Vinay] - calculating contrast depending on the selected mapping method
        int contrastMapping;
        switch (index) {
            case 0:
            default:
                contrastMapping = [[task defaults] integerForKey:@"CRSMapContrastMappingSurround"];
                break;
                
            case 1:
                contrastMapping = [[task defaults] integerForKey:@"CRSMapContrastMappingRing"];
                break;
                
            case 2:
                contrastMapping = [[task defaults] integerForKey:@"CRSMapContrastMappingCentre"];
                break;
        }
        
        switch (contrastMapping) {
            case 0: // [Vinay] - default log mapping with a factor of 0.5
                stimDesc.contrastPC = [self contrastValueFromIndex:contrastIndex count:contrastCount min:contrastPCMin max:contrastPCMax];
                break;
            case 1: // [Vinay] - log mapping from max to min with a factor of 0.5
                stimDesc.contrastPC = [self logMaxToMinValueFromIndex:contrastIndex count:contrastCount min:contrastPCMin max:contrastPCMax];
                break;
            case 2: // [Vinay] - linear mapping
                stimDesc.contrastPC = [self linearValueWithIndex:contrastIndex count:contrastCount min:contrastPCMin max:contrastPCMax];
                break;
            default:
                stimDesc.contrastPC = [self contrastValueFromIndex:contrastIndex count:contrastCount min:contrastPCMin max:contrastPCMax];
                break;
        }

		//stimDesc.contrastPC = [self contrastValueFromIndex:contrastIndex count:contrastCount min:contrastPCMin max:contrastPCMax];
        //stimDesc.contrastPC = [self linearValueWithIndex:contrastIndex count:contrastCount min:contrastPCMin max:contrastPCMax];
        
        
        
        // [Vinay] - calculating contrast depending on the selected mapping method
        int tfMapping;
        switch (index) {
            case 0:
            default:
                tfMapping = [[task defaults] integerForKey:@"CRSMapTFMappingSurround"];
                break;
                
            case 1:
                tfMapping = [[task defaults] integerForKey:@"CRSMapTFMappingRing"];
                break;
                
            case 2:
                tfMapping = [[task defaults] integerForKey:@"CRSMapTFMappingCentre"];
                break;
        }
        
        switch (contrastMapping) {
            case 0: // [Vinay] - default log mapping with a factor of 0.5
                stimDesc.temporalFreqHz = [self tfValueFromIndex:temporalFreqIndex count:temporalFreqCount min:temporalFreqHzMin max:temporalFreqHzMax];
                break;
            case 1: // [Vinay] - log mapping from max to min with a factor of 0.5
                stimDesc.temporalFreqHz = [self logMaxToMinValueFromIndex:temporalFreqIndex count:temporalFreqCount min:temporalFreqHzMin max:temporalFreqHzMax];
                break;
            case 2: // [Vinay] - linear mapping
                stimDesc.temporalFreqHz = [self linearValueWithIndex:temporalFreqIndex count:temporalFreqCount min:temporalFreqHzMin max:temporalFreqHzMax];
                break;
            default:
                stimDesc.temporalFreqHz = [self tfValueFromIndex:temporalFreqIndex count:temporalFreqCount min:temporalFreqHzMin max:temporalFreqHzMax];
                break;
        }

		//stimDesc.temporalFreqHz = [self logValueWithIndex:temporalFreqIndex count:temporalFreqCount min:temporalFreqHzMin max:temporalFreqHzMax];
        //stimDesc.temporalFreqHz = [self tfValueFromIndex:temporalFreqIndex count:temporalFreqCount min:temporalFreqHzMin max:temporalFreqHzMax]; // [Vinay] - commented the above line and added this to temporarily map tf values differently, for monitor calibration
        
        stimDesc.spatialPhaseDeg = [self linearValueWithIndex:spatialPhaseIndex count:spatialPhaseCount min:spatialPhaseDegMin max:spatialPhaseDegMax]; // [Vinay] - added this for spatial phase. 'logValueWithIndex' was giving a 'nan' value for spatial phase (because of 0deg phase). Therefore using 'linearValueWithIndex' instead.
        
        // [Vinay] - calculating radius depending on the selected mapping method
        int radiusMapping;
        switch (index) {
            case 0:
            default:
                radiusMapping = [[task defaults] integerForKey:@"CRSMapRadiusMappingSurround"];
                break;
                
            case 1:
                radiusMapping = [[task defaults] integerForKey:@"CRSMapRadiusMappingRing"];
                break;
                
            case 2:
                radiusMapping = [[task defaults] integerForKey:@"CRSMapRadiusMappingCentre"];
                break;
        }

        switch (radiusMapping) {
            case 0: // [Vinay] - default log mapping with a factor of 0.5
                stimDesc.radiusDeg = [self contrastValueFromIndex:radiusIndex count:radiusCount min:radiusDegMin max:radiusDegMax];
                break;
            case 1: // [Vinay] - log mapping from max to min with a factor of 0.5
                stimDesc.radiusDeg = [self logMaxToMinValueFromIndex:radiusIndex count:radiusCount min:radiusDegMin max:radiusDegMax];
                break;
            case 2: // [Vinay] - linear mapping
                stimDesc.radiusDeg = [self linearValueWithIndex:radiusIndex count:radiusCount min:radiusDegMin max:radiusDegMax];
                break;
            default:
                stimDesc.radiusDeg = [self contrastValueFromIndex:radiusIndex count:radiusCount min:radiusDegMin max:radiusDegMax];
                break;
        }

        //[Vinay] - commenting the earlier calculation method
        //stimDesc.radiusDeg = [self contrastValueFromIndex:radiusIndex count:radiusCount min:radiusDegMin max:radiusDegMax]; // [Vinay] - added this for radius. Have commented this temporarily; now uncommented
        
        // [Vinay] - Now calculate sigma
        if (convertToGrating) { // Sigma very high
			stimDesc.sigmaDeg = 100000;
			//stimDesc.radiusDeg = [self linearValueWithIndex:sigmaIndex count:sigmaCount min:sigmaDegMin max:sigmaDegMax] * radiusSigmaRatio; //[Vinay] I have commented this to check its effect
		}
		else {
			//stimDesc.sigmaDeg = [self linearValueWithIndex:sigmaIndex count:sigmaCount min:sigmaDegMin max:sigmaDegMax];
			//stimDesc.radiusDeg = stimDesc.sigmaDeg * radiusSigmaRatio; //[Vinay] I have commented this to check its effect
            stimDesc.sigmaDeg = stimDesc.radiusDeg/radiusSigmaRatio; // [Vinay] - since sigma count is always 1, sigma is instead calculated based on the radius and the radiusSigmaRatio. This enables proper drawing of gabors
            
		}
        
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
			//bzero(&localList,sizeof(doneList)); //[Vinay] - changed this line to assign the corresponding doneList as per the gabor index
            bzero(&localList,sizeof(doneList[index]));
			//localFreshCount = stimInBlock; //[Vinay] - changed this to the line below
            localFreshCount = stimInBlockGabor[index];
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
    //stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[1]*stimInBlockGabor[2]; //[Vinay] - total value as a product of individual gabor values
    //[self updateBlockParameters];
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
        // doneList[a][e][sf][sig][o][c][t][p][r] = TRUE;                // [Vinay] - and swapped [sf] and [sig] since [sig] is the 4th dimension. It was causing errors otherwise
        // [Vinay] - chaned the above to include the extra dimension for the gabor index
        doneList[stimDesc.gaborIndex-1][a][e][sf][sig][o][c][t][p][r] = TRUE;                // [Vinay] - and swapped [sf] and [sig] since [sig] is the 4th dimension. It was causing errors otherwise
        
		if (--stimRemainingInBlock == 0 ) {
			[self newBlock];
			blocksDone++;
		}
    // [Vinay] - added display line for debugging
    NSLog(@"Count loop: Stim remaining in this block = %d",stimRemainingInBlock);
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
		//doneList[a][e][sf][sig][o][c][t][p][r] = TRUE;                // [Vinay] - and swapped [sf] and [sig] since [sig] is the 4th dimension. It was causing errors otherwise
        // [Vinay] - chaned the above to include the extra dimension for the gabor index
        doneList[stimDesc.gaborIndex-1][a][e][sf][sig][o][c][t][p][r] = TRUE;                // [Vinay] - and swapped [sf] and [sig] since [sig] is the 4th dimension. It was causing errors otherwise
        
        // [Vinay] - added the following lines to update stimRemainingInBlock for each Gabor
        if ((--stimRemainingInBlockGabor[stimDesc.gaborIndex - 1] == 0) && stimRemainingInBlock != 0) {
            bzero(&doneList[stimDesc.gaborIndex-1], sizeof(doneList[stimDesc.gaborIndex-1])); //[Vinay] - reset the doneList of the corresponding gabor only
            stimRemainingInBlockGabor[stimDesc.gaborIndex - 1] = stimInBlockGabor[stimDesc.gaborIndex -1]; //[Vinay] - reset the stimRemaining number for the corresponding gabor only
        }
        NSLog(@"stim remaining this gabor %ld: %d",stimDesc.gaborIndex,stimRemainingInBlockGabor[stimDesc.gaborIndex - 1]);
        
        // [Vinay] - till here
        
        
        if (--stimRemainingInBlock == 0 ) {
			[self newBlock];
			blocksDone++;
		}
        // [Vinay] - added display line for debugging
        NSLog(@"Frame count loop: Gabor: %ld, Stim remaining in this block = %d",stimDesc.gaborIndex, stimRemainingInBlock);
	}
	return;
}

- (long)stimDoneInBlock;
{
	return stimInBlock - stimRemainingInBlock;
    // [Vinay] - added display line for debugging
    NSLog(@"Stim done in this block = %d",stimInBlock - stimRemainingInBlock);
}

- (long)stimInBlock;
{
	return stimInBlock;
}


- (void)updateBlockParameters:(long)index;
//- (void)updateBlockParameters;
{
	long azimuthCount, elevationCount, sigmaCount, spatialFreqCount, directionCount, contrastCount, temporalFreqCount, spatialPhaseCount, radiusCount; // [Vinay] - Added spatialPhaseCount, radiusCount and later added the parameters for the other two gabors
    
    // [Vinay] - added these additional variables to use them for determining stim numbers in specific protocols
    long azimuthCount0, elevationCount0, sigmaCount0, spatialFreqCount0, directionCount0, contrastCount0, temporalFreqCount0, spatialPhaseCount0, radiusCount0, azimuthCount1, elevationCount1, sigmaCount1, spatialFreqCount1, directionCount1, contrastCount1, temporalFreqCount1, spatialPhaseCount1, radiusCount1, azimuthCount2, elevationCount2, sigmaCount2, spatialFreqCount2, directionCount2, contrastCount2, temporalFreqCount2, spatialPhaseCount2, radiusCount2;   // [Vinay] - Added spatialPhaseCount, radiusCount and later added the parameters for the other two gabors
     
     NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTableCounts"] objectAtIndex:0];
    
    /*
    //==========================^^^^^^^^
    // [Vinay] - change the counts based on specific protocols. This is necessary because some features of the gabors are matched as per the requirements of the specific protocols and therefore the total count actually reduces
    
    //### [Vinay] - this method of setting the values for the count keys as used below is failing! So comment this out!
    
    switch ([[task defaults] integerForKey:@"CRSProtocolNumber"]) {
        case 0:
            //noneProtocol
            // Do nothing, except for when particular keys are raised. Eg. hide a certain gabor => pull all its counts to 1 OR in match conditions pull the redundant counts to 1
            if ([[task defaults] boolForKey:CRSHideSurroundKey]) {
                [countsDict setValue:1 forKey:@"azimuthCount0"];
                [countsDict setValue:1 forKey:@"elevationCount0"];
                [countsDict setValue:1 forKey:@"sigmaCount0"];
                [countsDict setValue:1 forKey:@"spatialFreqCount0"];
                [countsDict setValue:1 forKey:@"directionCount0"];
                [countsDict setValue:1 forKey:@"contrastCount0"];
                [countsDict setValue:1 forKey:@"temporalFreqCount0"];
                [countsDict setValue:1 forKey:@"spatialPhaseCount0"];
                //[countsDict setValue:1 forKey:@"radiusCount0"];
            }
            else if ([[task defaults] boolForKey:CRSHideRingKey] || [[task defaults] boolForKey:CRSMatchRingSurroundKey]) {
                [countsDict setValue:1 forKey:@"azimuthCount1"];
                [countsDict setValue:1 forKey:@"elevationCount1"];
                [countsDict setValue:1 forKey:@"sigmaCount1"];
                [countsDict setValue:1 forKey:@"spatialFreqCount1"];
                [countsDict setValue:1 forKey:@"directionCount1"];
                [countsDict setValue:1 forKey:@"contrastCount1"];
                [countsDict setValue:1 forKey:@"temporalFreqCount1"];
                [countsDict setValue:1 forKey:@"spatialPhaseCount1"];
                //[countsDict setValue:1 forKey:@"radiusCount1"];
            }
            else if ([[task defaults] boolForKey:CRSHideCentreKey] || [[task defaults] boolForKey:CRSMatchCentreRingKey] || [[task defaults] boolForKey:CRSMatchCentreSurroundKey]) {
                [countsDict setValue:1 forKey:@"azimuthCount2"];
                [countsDict setValue:1 forKey:@"elevationCount2"];
                [countsDict setValue:1 forKey:@"sigmaCount2"];
                [countsDict setValue:1 forKey:@"spatialFreqCount2"];
                [countsDict setValue:1 forKey:@"directionCount2"];
                [countsDict setValue:1 forKey:@"contrastCount2"];
                [countsDict setValue:1 forKey:@"temporalFreqCount2"];
                [countsDict setValue:1 forKey:@"spatialPhaseCount2"];
                //[countsDict setValue:1 forKey:@"radiusCount2"];
            }
            break;
        case 1:
            //ringProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
            [countsDict setValue:1 forKey:@"azimuthCount2"];
            [countsDict setValue:1 forKey:@"elevationCount2"];
            [countsDict setValue:1 forKey:@"sigmaCount2"];
            [countsDict setValue:1 forKey:@"spatialFreqCount2"];
            [countsDict setValue:1 forKey:@"directionCount2"];
            [countsDict setValue:1 forKey:@"contrastCount2"];
            [countsDict setValue:1 forKey:@"temporalFreqCount2"];
            [countsDict setValue:1 forKey:@"spatialPhaseCount2"];
            break;
        case 2:
            //contrastRingProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
            [countsDict setValue:1 forKey:@"azimuthCount2"];
            [countsDict setValue:1 forKey:@"elevationCount2"];
            [countsDict setValue:1 forKey:@"sigmaCount2"];
            [countsDict setValue:1 forKey:@"spatialFreqCount2"];
            [countsDict setValue:1 forKey:@"directionCount2"];
            [countsDict setValue:1 forKey:@"contrastCount2"];
            [countsDict setValue:1 forKey:@"temporalFreqCount2"];
            [countsDict setValue:1 forKey:@"spatialPhaseCount2"];
            break;
        case 3:
            //dualContrastProtocol
            //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
            [countsDict setValue:1 forKey:@"azimuthCount0"];
            [countsDict setValue:1 forKey:@"elevationCount0"];
            [countsDict setValue:1 forKey:@"sigmaCount0"];
            [countsDict setValue:1 forKey:@"spatialFreqCount0"];
            [countsDict setValue:1 forKey:@"directionCount0"];
            [countsDict setValue:1 forKey:@"contrastCount0"];
            [countsDict setValue:1 forKey:@"temporalFreqCount0"];
            [countsDict setValue:1 forKey:@"spatialPhaseCount0"];
            [countsDict setValue:1 forKey:@"radiusCount0"];
            break;
        case 4:
            //dualOrientationProtocol
            //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
            [countsDict setValue:1 forKey:@"azimuthCount0"];
            [countsDict setValue:1 forKey:@"elevationCount0"];
            [countsDict setValue:1 forKey:@"sigmaCount0"];
            [countsDict setValue:1 forKey:@"spatialFreqCount0"];
            [countsDict setValue:1 forKey:@"directionCount0"];
            [countsDict setValue:1 forKey:@"contrastCount0"];
            [countsDict setValue:1 forKey:@"temporalFreqCount0"];
            [countsDict setValue:1 forKey:@"spatialPhaseCount0"];
            [countsDict setValue:1 forKey:@"radiusCount0"];
            break;
        case 5:
            //dualPhaseProtocol
            //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
            [countsDict setValue:1 forKey:@"azimuthCount0"];
            [countsDict setValue:1 forKey:@"elevationCount0"];
            [countsDict setValue:1 forKey:@"sigmaCount0"];
            [countsDict setValue:1 forKey:@"spatialFreqCount0"];
            [countsDict setValue:1 forKey:@"directionCount0"];
            [countsDict setValue:1 forKey:@"contrastCount0"];
            [countsDict setValue:1 forKey:@"temporalFreqCount0"];
            [countsDict setValue:1 forKey:@"spatialPhaseCount0"];
            [countsDict setValue:1 forKey:@"radiusCount0"];
            break;
        case 6:
            //orientationRingProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
            [countsDict setValue:1 forKey:@"azimuthCount2"];
            [countsDict setValue:1 forKey:@"elevationCount2"];
            [countsDict setValue:1 forKey:@"sigmaCount2"];
            [countsDict setValue:1 forKey:@"spatialFreqCount2"];
            [countsDict setValue:1 forKey:@"directionCount2"];
            [countsDict setValue:1 forKey:@"contrastCount2"];
            [countsDict setValue:1 forKey:@"temporalFreqCount2"];
            [countsDict setValue:1 forKey:@"spatialPhaseCount2"];
            break;
        case 7:
            //phaseRingProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
            [countsDict setValue:1 forKey:@"azimuthCount2"];
            [countsDict setValue:1 forKey:@"elevationCount2"];
            [countsDict setValue:1 forKey:@"sigmaCount2"];
            [countsDict setValue:1 forKey:@"spatialFreqCount2"];
            [countsDict setValue:1 forKey:@"directionCount2"];
            [countsDict setValue:1 forKey:@"contrastCount2"];
            [countsDict setValue:1 forKey:@"temporalFreqCount2"];
            [countsDict setValue:1 forKey:@"spatialPhaseCount2"];
            break;
        case 8:
            //driftingPhaseProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
            [countsDict setValue:1 forKey:@"azimuthCount2"];
            [countsDict setValue:1 forKey:@"elevationCount2"];
            [countsDict setValue:1 forKey:@"sigmaCount2"];
            [countsDict setValue:1 forKey:@"spatialFreqCount2"];
            [countsDict setValue:1 forKey:@"directionCount2"];
            [countsDict setValue:1 forKey:@"contrastCount2"];
            [countsDict setValue:1 forKey:@"temporalFreqCount2"];
            [countsDict setValue:1 forKey:@"spatialPhaseCount2"];
            break;
        case 9:
            //crossOrientationProtocol
            //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
            [countsDict setValue:1 forKey:@"azimuthCount0"];
            [countsDict setValue:1 forKey:@"elevationCount0"];
            [countsDict setValue:1 forKey:@"sigmaCount0"];
            [countsDict setValue:1 forKey:@"spatialFreqCount0"];
            [countsDict setValue:1 forKey:@"directionCount0"];
            [countsDict setValue:1 forKey:@"contrastCount0"];
            [countsDict setValue:1 forKey:@"temporalFreqCount0"];
            [countsDict setValue:1 forKey:@"spatialPhaseCount0"];
            [countsDict setValue:1 forKey:@"radiusCount0"];
            break;
        default:
            break;
    }
    
    //==========================~~~~~~~~~
    */
    
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
    // [Vinay] - commented these steps above and put the switch loop below
    */
    
    azimuthCount0 = [[countsDict objectForKey:@"azimuthCount0"] intValue];
    elevationCount0 = [[countsDict objectForKey:@"elevationCount0"] intValue];
    sigmaCount0 = [[countsDict objectForKey:@"sigmaCount0"] intValue];
    spatialFreqCount0 = [[countsDict objectForKey:@"spatialFreqCount0"] intValue];
    directionCount0 = [[countsDict objectForKey:@"orientationCount0"] intValue];
    contrastCount0 = [[countsDict objectForKey:@"contrastCount0"] intValue];
    temporalFreqCount0 = [[countsDict objectForKey:@"temporalFreqCount0"] intValue];
    spatialPhaseCount0 = [[countsDict objectForKey:@"spatialPhaseCount0"] intValue]; // [Vinay] - added for spatial phase
    radiusCount0 = [[countsDict objectForKey:@"radiusCount0"] intValue]; // [Vinay] - added for radius
    
    azimuthCount1 = [[countsDict objectForKey:@"azimuthCount1"] intValue];
    elevationCount1 = [[countsDict objectForKey:@"elevationCount1"] intValue];
    sigmaCount1 = [[countsDict objectForKey:@"sigmaCount1"] intValue];
    spatialFreqCount1 = [[countsDict objectForKey:@"spatialFreqCount1"] intValue];
    directionCount1 = [[countsDict objectForKey:@"orientationCount1"] intValue];
    contrastCount1 = [[countsDict objectForKey:@"contrastCount1"] intValue];
    temporalFreqCount1 = [[countsDict objectForKey:@"temporalFreqCount1"] intValue];
    spatialPhaseCount1 = [[countsDict objectForKey:@"spatialPhaseCount1"] intValue]; // [Vinay] - added for spatial phase
    radiusCount1 = [[countsDict objectForKey:@"radiusCount1"] intValue]; // [Vinay] - added for radius
    
    azimuthCount2 = [[countsDict objectForKey:@"azimuthCount2"] intValue];
    elevationCount2 = [[countsDict objectForKey:@"elevationCount2"] intValue];
    sigmaCount2 = [[countsDict objectForKey:@"sigmaCount2"] intValue];
    spatialFreqCount2 = [[countsDict objectForKey:@"spatialFreqCount2"] intValue];
    directionCount2 = [[countsDict objectForKey:@"orientationCount2"] intValue];
    contrastCount2 = [[countsDict objectForKey:@"contrastCount2"] intValue];
    temporalFreqCount2 = [[countsDict objectForKey:@"temporalFreqCount2"] intValue];
    spatialPhaseCount2 = [[countsDict objectForKey:@"spatialPhaseCount2"] intValue]; // [Vinay] - added for spatial phase
    radiusCount2 = [[countsDict objectForKey:@"radiusCount2"] intValue]; // [Vinay] - added for radius
    
    
    //==========================^^^^^^^^
    // [Vinay] - change the counts based on specific protocols. This is necessary because some features of the gabors are matched as per the requirements of the specific protocols and therefore the total count actually reduces
    
    //### [Vinay] - this method of setting the values for the count keys as used below is failing! So comment this out!
    
    switch ([[task defaults] integerForKey:@"CRSProtocolNumber"]) {
        case 0:
            //noneProtocol
            // Do nothing, except for when particular keys are raised. Eg. hide a certain gabor => pull all its counts to 1 OR in match conditions pull the redundant counts to 1
            if ([[task defaults] boolForKey:CRSHideSurroundKey]) {
                azimuthCount0 = 1;
                elevationCount0 = 1;
                sigmaCount0 = 1;
                spatialFreqCount0 = 1;
                directionCount0 = 1;
                contrastCount0 = 1;
                temporalFreqCount0 = 1;
                spatialPhaseCount0 = 1;
                radiusCount0 = 1;
            }
            
            if ([[task defaults] boolForKey:CRSHideRingKey]) {
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                directionCount1 = 1;
                contrastCount1 = 1;
                temporalFreqCount1 = 1;
                spatialPhaseCount1 = 1;
                radiusCount1 = 1;

            }
            else if (![[task defaults] boolForKey:CRSHideRingKey] && [[task defaults] boolForKey:CRSMatchRingSurroundKey]) {
                azimuthCount1 = 1;
                elevationCount1 = 1;
                sigmaCount1 = 1;
                spatialFreqCount1 = 1;
                directionCount1 = 1;
                contrastCount1 = 1;
                temporalFreqCount1 = 1;
                spatialPhaseCount1 = 1;
                //radiusCount1 = 1; //[Vinay] - make every count 1 except radiusCount
            }
            
            if ([[task defaults] boolForKey:CRSHideCentreKey]) {
                azimuthCount2 = 1;
                elevationCount2 = 1;
                sigmaCount2 = 1;
                spatialFreqCount2 = 1;
                directionCount2 = 1;
                contrastCount2 = 1;
                temporalFreqCount2 = 1;
                spatialPhaseCount2 = 1;
                radiusCount2 = 1;
            }
            else if (![[task defaults] boolForKey:CRSHideCentreKey] && ([[task defaults] boolForKey:CRSMatchCentreRingKey] || [[task defaults] boolForKey:CRSMatchCentreSurroundKey])) {
                azimuthCount2 = 1;
                elevationCount2 = 1;
                sigmaCount2 = 1;
                spatialFreqCount2 = 1;
                directionCount2 = 1;
                contrastCount2 = 1;
                temporalFreqCount2 = 1;
                spatialPhaseCount2 = 1;
                //radiusCount2 = 1; //[Vinay] - make every count 1 except radiusCount
            }
            break;
        case 1:
            //ringProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
            azimuthCount2 = 1;
            elevationCount2 = 1;
            sigmaCount2 = 1;
            spatialFreqCount2 = 1;
            directionCount2 = 1;
            contrastCount2 = 1;
            temporalFreqCount2 = 1;
            spatialPhaseCount2 = 1;
            
            // [Vinay] - ring contrast is set to 0. Therefore take all the counts to 1 except radius
            azimuthCount1 = 1;
            elevationCount1 = 1;
            sigmaCount1 = 1;
            spatialFreqCount1 = 1;
            directionCount1 = 1;
            contrastCount1 = 1;
            temporalFreqCount1 = 1;
            spatialPhaseCount1 = 1;
            
            break;
        case 2:
            //contrastRingProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
            azimuthCount2 = 1;
            elevationCount2 = 1;
            sigmaCount2 = 1;
            spatialFreqCount2 = 1;
            directionCount2 = 1;
            contrastCount2 = 1;
            temporalFreqCount2 = 1;
            spatialPhaseCount2 = 1;
            
            // [Vinay] - Therefore take all the counts to 1 except contrast and radius
            azimuthCount1 = 1;
            elevationCount1 = 1;
            sigmaCount1 = 1;
            spatialFreqCount1 = 1;
            directionCount1 = 1;
            //contrastCount1 = 1;
            temporalFreqCount1 = 1;
            spatialPhaseCount1 = 1;
            break;
        case 3:
            //dualContrastProtocol
            //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
            azimuthCount0 = 1;
            elevationCount0 = 1;
            sigmaCount0 = 1;
            spatialFreqCount0 = 1;
            directionCount0 = 1;
            contrastCount0 = 1;
            temporalFreqCount0 = 1;
            spatialPhaseCount0 = 1;
            radiusCount0 = 1;
            
            //[Vinay] - ring radius set to maximum => radiusCount = 1. Except contrast rest are matched to the centre => theirCount = 1
            azimuthCount1 = 1;
            elevationCount1 = 1;
            sigmaCount1 = 1;
            spatialFreqCount1 = 1;
            directionCount1 = 1;
            //contrastCount1 = 1;
            temporalFreqCount1 = 1;
            spatialPhaseCount1 = 1;
            radiusCount1 = 1;
            
            break;
        case 4:
            //dualOrientationProtocol
            //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
            azimuthCount0 = 1;
            elevationCount0 = 1;
            sigmaCount0 = 1;
            spatialFreqCount0 = 1;
            directionCount0 = 1;
            contrastCount0 = 1;
            temporalFreqCount0 = 1;
            spatialPhaseCount0 = 1;
            radiusCount0 = 1;
            
            //[Vinay] - ring radius set to maximum => radiusCount = 1. Except orientation i.e. direction rest are matched to the centre => theirCount = 1
            azimuthCount1 = 1;
            elevationCount1 = 1;
            sigmaCount1 = 1;
            spatialFreqCount1 = 1;
            //directionCount1 = 1;
            contrastCount1 = 1;
            temporalFreqCount1 = 1;
            spatialPhaseCount1 = 1;
            radiusCount1 = 1;

            break;
        case 5:
            //dualPhaseProtocol
            //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
            azimuthCount0 = 1;
            elevationCount0 = 1;
            sigmaCount0 = 1;
            spatialFreqCount0 = 1;
            directionCount0 = 1;
            contrastCount0 = 1;
            temporalFreqCount0 = 1;
            spatialPhaseCount0 = 1;
            radiusCount0 = 1;
            
            //[Vinay] - ring radius set to maximum => radiusCount = 1. Except spatial phase rest are matched to the centre => theirCount = 1
            azimuthCount1 = 1;
            elevationCount1 = 1;
            sigmaCount1 = 1;
            spatialFreqCount1 = 1;
            directionCount1 = 1;
            contrastCount1 = 1;
            temporalFreqCount1 = 1;
            //spatialPhaseCount1 = 1;
            radiusCount1 = 1;

            break;
        case 6:
            //orientationRingProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
            azimuthCount2 = 1;
            elevationCount2 = 1;
            sigmaCount2 = 1;
            spatialFreqCount2 = 1;
            directionCount2 = 1;
            contrastCount2 = 1;
            temporalFreqCount2 = 1;
            spatialPhaseCount2 = 1;
            
            // [Vinay] - Therefore take all the counts to 1 except orientation i.e. direction and radius
            azimuthCount1 = 1;
            elevationCount1 = 1;
            sigmaCount1 = 1;
            spatialFreqCount1 = 1;
            //directionCount1 = 1;
            contrastCount1 = 1;
            temporalFreqCount1 = 1;
            spatialPhaseCount1 = 1;
            break;
        case 7:
            //phaseRingProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
            azimuthCount2 = 1;
            elevationCount2 = 1;
            sigmaCount2 = 1;
            spatialFreqCount2 = 1;
            directionCount2 = 1;
            contrastCount2 = 1;
            temporalFreqCount2 = 1;
            spatialPhaseCount2 = 1;
            
            // [Vinay] - Therefore take all the counts to 1 except spatial phase and radius
            azimuthCount1 = 1;
            elevationCount1 = 1;
            sigmaCount1 = 1;
            spatialFreqCount1 = 1;
            directionCount1 = 1;
            contrastCount1 = 1;
            temporalFreqCount1 = 1;
            //spatialPhaseCount1 = 1;
            break;
        case 8:
            //driftingPhaseProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround)
            azimuthCount2 = 1;
            elevationCount2 = 1;
            sigmaCount2 = 1;
            spatialFreqCount2 = 1;
            directionCount2 = 1;
            contrastCount2 = 1;
            temporalFreqCount2 = 1;
            spatialPhaseCount2 = 1;
            
            // [Vinay] - Therefore take all the counts to 1 except temporal frequency and radius
            azimuthCount1 = 1;
            elevationCount1 = 1;
            sigmaCount1 = 1;
            spatialFreqCount1 = 1;
            directionCount1 = 1;
            contrastCount1 = 1;
            //temporalFreqCount1 = 1;
            spatialPhaseCount1 = 1;

            break;
        case 9:
            //crossOrientationProtocol
            //Set all counts for gabor0(surround) to 1, since gabor0 has been made null in this protocol
            azimuthCount0 = 1;
            elevationCount0 = 1;
            sigmaCount0 = 1;
            spatialFreqCount0 = 1;
            directionCount0 = 1;
            contrastCount0 = 1;
            temporalFreqCount0 = 1;
            spatialPhaseCount0 = 1;
            radiusCount0 = 1;
            
            break;
        case 10:
            //annulusFixedProtocol
            //Set all counts for gabor2(centre) to 1 except the radiusCount. All other parameters are mapped to the same values as for gabor0(surround). Their counts are therefore accounted for by the counts for gabor0(surround).
            azimuthCount2 = 1;
            elevationCount2 = 1;
            sigmaCount2 = 1;
            spatialFreqCount2 = 1;
            directionCount2 = 1;
            contrastCount2 = 1;
            temporalFreqCount2 = 1;
            spatialPhaseCount2 = 1;
            //radiusCount2 = 1;
            
            // [Vinay] - ring contrast is set to 0. Therefore take all the counts to 1. The radiusCount for gabor1 (ring) is also accounted for by the count for gabor2 i.e. the centre gabor. Therefore set this to 1 as well.
            azimuthCount1 = 1;
            elevationCount1 = 1;
            sigmaCount1 = 1;
            spatialFreqCount1 = 1;
            directionCount1 = 1;
            contrastCount1 = 1; // [Vinay] - comment this if using a ring (fixed annulus in this case) of varying contrasts
            temporalFreqCount1 = 1;
            spatialPhaseCount1 = 1;
            //radiusCount1 = 1; // [Vinay] - comment this if using a ring (fixed annulus in this case) of multiple widths
            
            break;

        default:
            break;
    }
    
    //==========================~~~~~~~~~

    //-----------------------------------
    // [Vinay] - next switch loop changed to read the modified count values as per the specific protocol instead of directly from the corresponding keys
    /*
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
    */
    // [Vinay] - Now follows the modified switch case
    switch (index){
        case 0:
        default:
            azimuthCount = azimuthCount0;
            elevationCount = elevationCount0;
            sigmaCount = sigmaCount0;
            spatialFreqCount = spatialFreqCount0;
            directionCount = directionCount0;
            contrastCount = contrastCount0;
            temporalFreqCount = temporalFreqCount0;
            spatialPhaseCount = spatialPhaseCount0;
            radiusCount = radiusCount0;
            break;
            
        case 1:
            azimuthCount = azimuthCount1;
            elevationCount = elevationCount1;
            sigmaCount = sigmaCount1;
            spatialFreqCount = spatialFreqCount1;
            directionCount = directionCount1;
            contrastCount = contrastCount1;
            temporalFreqCount = temporalFreqCount1;
            spatialPhaseCount = spatialPhaseCount1;
            radiusCount = radiusCount1;
            break;
            
        case 2:
            azimuthCount = azimuthCount2;
            elevationCount = elevationCount2;
            sigmaCount = sigmaCount2;
            spatialFreqCount = spatialFreqCount2;
            directionCount = directionCount2;
            contrastCount = contrastCount2;
            temporalFreqCount = temporalFreqCount2;
            spatialPhaseCount = spatialPhaseCount2;
            radiusCount = radiusCount2;
            break;
    }
    
    //---------------------------------------
    
    // [Vinay] - modified the next line to assign separate values for each gabor
    //stimInBlock = stimRemainingInBlock = azimuthCount * elevationCount * sigmaCount * spatialFreqCount * directionCount * contrastCount * temporalFreqCount * spatialPhaseCount * radiusCount;  // [Vinay] - Added the factor spatialPhaseCount*radiusCount
    
    stimInBlockGabor[index] = stimRemainingInBlockGabor[index] = azimuthCount * elevationCount * sigmaCount * spatialFreqCount * directionCount * contrastCount * temporalFreqCount * spatialPhaseCount * radiusCount;  // [Vinay] - Added the factor spatialPhaseCount*radiusCount
    
    // ================================================================
    // *************[Vinay] - Decide the total number of stimuli in the protocol based on the stim numbers of all the gabors and the particular protocol that is running
    // [Vinay] - This switch case isn't required now since the counts have been adjusted/reassigned based on the specific protocol in the previous switch loop.
    /* //[Vinay] - commenting this switch case loop because the adjustments in the counts have been done in the loop before this
    switch ([[task defaults] integerForKey:@"CRSProtocolNumber"]) {
        case 0:
            //noneProtocol
            
            if ([[task defaults] boolForKey:CRSHideSurroundKey]) {
                stimInBlock = stimRemainingInBlock = stimInBlockGabor[1]*stimInBlockGabor[2];
            }
            else if ([[task defaults] boolForKey:CRSHideRingKey] || [[task defaults] boolForKey:CRSMatchRingSurroundKey]) {
                stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[2];
            }
            else if ([[task defaults] boolForKey:CRSHideCentreKey] || [[task defaults] boolForKey:CRSMatchCentreRingKey] || [[task defaults] boolForKey:CRSMatchCentreSurroundKey]) {
                stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[1];
            }
            else {
                stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[1]*stimInBlockGabor[2]; //[Vinay] - total value as a product of individual gabor values
            }
            break;
        case 1:
            //ringProtocol
            stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[1]*radiusCount2; //[Vinay] - total = no. of gabor0 (surround) x no. of gabor1 (ring) x no. of radii of the centre gabor (thsi would normally be set to 1). Centre matched to the surround, except its radius
            break;
        case 2:
            //contrastRingProtocol
            stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[1]*radiusCount2; //[Vinay] - total = no. of gabor0 (surround) x no. of gabor1 (ring) x no. of radii of the centre gabor (thsi would normally be set to 1). Centre matched to the surround, except its radius            break;
        case 3:
            //dualContrastProtocol
            stimInBlock = stimRemainingInBlock = stimInBlockGabor[1]*stimInBlockGabor[2]; //[Vinay] - total = no. of gabor1 (ring) x no. of gabor2 (centre). Surround is hidden i.e. made a null stimulus
            break;
        case 4:
            //dualOrientationProtocol
            stimInBlock = stimRemainingInBlock = stimInBlockGabor[1]*stimInBlockGabor[2]; //[Vinay] - total = no. of gabor1 (ring) x no. of gabor2 (centre). Surround is hidden i.e. made a null stimulus
            break;
        case 5:
            //dualPhaseProtocol
            stimInBlock = stimRemainingInBlock = stimInBlockGabor[1]*stimInBlockGabor[2]; //[Vinay] - total = no. of gabor1 (ring) x no. of gabor2 (centre). Surround is hidden i.e. made a null stimulus
            break;
        case 6:
            //orientationRingProtocol
            stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[1]; //[Vinay] - total = no. of gabor0 (surround) x no. of gabor1 (ring). Centre matched to the surround
            break;
        case 7:
            //phaseRingProtocol
            stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[1]; //[Vinay] - total = no. of gabor0 (surround) x no. of gabor1 (ring). Centre matched to the surround
            break;
        case 8:
            //driftingPhaseProtocol
            stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[1]; //[Vinay] - total = no. of gabor0 (surround) x no. of gabor1 (ring). Centre matched to the surround
            break;
        case 9:
            //crossOrientationProtocol
            stimInBlock = stimRemainingInBlock = stimInBlockGabor[1]*stimInBlockGabor[2]; //[Vinay] - total = no. of gabor1 (ring) x no. of gabor2 (centre). Surround is hidden i.e. made a null stimulus
            break;
        default:
            stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[1]*stimInBlockGabor[2]; //[Vinay] - total value as a product of individual gabor
            break;
    }
    */
    
    stimInBlock = stimRemainingInBlock = stimInBlockGabor[0]*stimInBlockGabor[1]*stimInBlockGabor[2]; //[Vinay] - total value as a product of individual gabor values
    
    // [Vinay] - till here
    // ================================================================
    
	//stimInBlock = stimRemainingInBlock = azimuthCount * elevationCount * sigmaCount * spatialFreqCount * directionCount * contrastCount * temporalFreqCount * spatialPhaseCount * radiusCount * azimuthCount1 * elevationCount1 * sigmaCount1 * spatialFreqCount1 * directionCount1 * contrastCount1 * temporalFreqCount1 * spatialPhaseCount1 * radiusCount1 * azimuthCount2 * elevationCount2 * sigmaCount2 * spatialFreqCount2 * directionCount2 * contrastCount2 * temporalFreqCount2 * spatialPhaseCount2 * radiusCount2;        // [Vinay] - Added the factor spatialPhaseCount*radiusCount
	blockLimit = [[task defaults] integerForKey:CRSMappingBlocksKey];
    
    /*------[Vinay] - Initializing doneList in this new approach of dynamically assigning its size------*/
    
    /*int aziCount, eleCount, sfCount, sigCount, oriCount, conCount,tfCount, spCount, radCount; // int variables to hold the count values for the parameters
    
    aziCount = fmax([[countsDict objectForKey:@"azimuthCount0"] intValue],fmax([[countsDict objectForKey:@"azimuthCount1"] intValue], [[countsDict objectForKey:@"azimuthCount2"] intValue])); //aziCount is assigned the bigger of the three counts corresponding to the three gabors
    eleCount = fmax([[countsDict objectForKey:@"elevationCount0"] intValue],fmax([[countsDict objectForKey:@"elevationCount1"] intValue], [[countsDict objectForKey:@"elevationCount2"] intValue])); //eleCount is assigned the bigger of the three counts corresponding to the three gabors
    sfCount = fmax([[countsDict objectForKey:@"spatialFreqCount0"] intValue],fmax([[countsDict objectForKey:@"spatialFreqCount1"] intValue], [[countsDict objectForKey:@"spatialFreqCount2"] intValue])); //sfCount is assigned the bigger of the three counts corresponding to the three gabors
    sigCount = fmax([[countsDict objectForKey:@"sigmaCount0"] intValue],fmax([[countsDict objectForKey:@"sigmaCount1"] intValue], [[countsDict objectForKey:@"sigmaCount2"] intValue])); //sigCount is assigned the bigger of the three counts corresponding to the three gabors
    oriCount = fmax([[countsDict objectForKey:@"orientationCount0"] intValue],fmax([[countsDict objectForKey:@"orientationCount1"] intValue], [[countsDict objectForKey:@"orientationCount2"] intValue])); //oriCount is assigned the bigger of the three counts corresponding to the three gabors
    conCount = fmax([[countsDict objectForKey:@"contrastCount0"] intValue],fmax([[countsDict objectForKey:@"contrastCount1"] intValue], [[countsDict objectForKey:@"contrastCount2"] intValue])); //conCount is assigned the bigger of the three counts corresponding to the three gabors
    tfCount = fmax([[countsDict objectForKey:@"temporalFreqCount0"] intValue],fmax([[countsDict objectForKey:@"temporalFreqCount1"] intValue], [[countsDict objectForKey:@"temporalFreqCount2"] intValue])); //tfCount is assigned the bigger of the three counts corresponding to the three gabors
    spCount = fmax([[countsDict objectForKey:@"spatialPhaseCount0"] intValue],fmax([[countsDict objectForKey:@"spatialPhaseCount1"] intValue], [[countsDict objectForKey:@"spatialPhaseCount2"] intValue])); //spCount is assigned the bigger of the three counts corresponding to the three gabors
    radCount = fmax([[countsDict objectForKey:@"radiusCount0"] intValue],fmax([[countsDict objectForKey:@"radiusCount1"] intValue], [[countsDict objectForKey:@"radiusCount2"] intValue])); //sigCount is assigned the bigger of the three counts corresponding to the three gabors
    */ // [Vinay] - These line above aren't required now
    
    //doneList = malloc(azimuthCount * elevationCount * sigmaCount * spatialFreqCount * directionCount * contrastCount * temporalFreqCount * spatialPhaseCount * radiusCount * sizeof(BOOL)); // [Vinay] : Initializing doneList here depending upon the gabor index. Therefore doneList will be different for each gabor depending upon the respective counts. Have put this in newBlock now
    
    //--------[Vinay] - till here------------
}

/*
- (void)doneListDefine:(long)index;
{
    //------[Vinay] --- Adding the following lines o initialize doneList dynamically depending on the current gabor
    long azimuthCount, elevationCount, sigmaCount, spatialFreqCount, directionCount, contrastCount, temporalFreqCount, spatialPhaseCount, radiusCount;   // [Vinay] - Added spatialPhaseCount, radiusCount
	NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"CRSStimTableCounts"] objectAtIndex:0];
    
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
    
    doneList = malloc(azimuthCount * elevationCount * sigmaCount * spatialFreqCount * directionCount * contrastCount * temporalFreqCount * spatialPhaseCount * radiusCount * sizeof(BOOL*)); // [Vinay] : Initializing doneList here depending upon the gabor index. Therefore doneList will be different for each gabor depending upon the respective counts

}
*/

@end
