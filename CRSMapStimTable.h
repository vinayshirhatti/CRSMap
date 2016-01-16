//
//  CRSMapStimTable.h
//  CRSMap
//
//  Created by John Maunsell on 11/2/07.
//  Copyright 2007. All rights reserved.
//

#import "CRS.h"

@interface CRSMapStimTable : NSObject
{
	long blocksDone;
	long blockLimit;
	// BOOL doneList[kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues]; // [Vinay] - commented this
    //BOOL doneList[kMaxMapValuesFixed][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues]; // [Vinay] - changed it from 7 to a 9 dimensional List, to include dimensions for spatialPhase and radius // [Vinay] - Also changed kMaxMapValues to kMaxMapValuesFixed, corresponding to azimuth, elevation and sigma, since will be kept fixed and therefore take just 1 value in session/block
    // [ Vinay] - changing the above doneList to have a separate list for each Gabor. There are kGabors-1 number of stimuli Gabor excluding the Task gabor
    // [Vinay] - final maintained version entry, 12 Jan 2016
    // BOOL doneList[kGabors-1][kMaxMapValuesFixed][kMaxMapValuesFixed][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues]; // [Vinay] - changed it from 7 to a 9 dimensional List, to include dimensions for spatialPhase and radius // [Vinay] - Also changed kMaxMapValues to kMaxMapValuesFixed, corresponding to azimuth, elevation and sigma, since will be kept fixed and therefore take just 1 value in session/block
    
    //BOOL ********* doneList; // 9 pointers corresponding to 9 dimensions (parameters).
    
    // [Vinay] - 06/09/15 Changed the dimension order: sigma and sf interchanged from [sf][sigma] to [sigma][sf] (dim[3][4])
    
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    //[Vinay] - incorporating changes from GaborRFMap for maintaining doneList, 12 Jan 2016
    CFMutableBitVectorRef doneList[3]; // maintained as a 1-D bit vector
    long azimuthCount;
    long elevationCount;
    long sigmaCount;
    long spatialFreqCount;
    long directionDegCount;
    long contrastCount;
    long temporalFreqCount;
    long spatialPhaseCount;
    long radiusCount;
    //~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
    long mapIndex;                  // index to instance of CRSMapStimTable
	// [Vinay] - modified the meaning of the next two lines. These quantities now mean the total stimRemaining in the block and total stimInBlock considering the number of variations in all three gabors. The next two variables are maintained individually for each gabor
    int stimRemainingInBlock;
	int stimInBlock;
    int stimRemainingInBlockGabor[3]; // [Vinay] - for 3 gabors
	int stimInBlockGabor[3]; // [Vinay] - for 3 gabors

	NSMutableArray *currentStimList; //*copyList; [Vinay] - added copyList to copy stimulus list attributes from one gabor to another (surround gabor to the centre gabor). Have removed this later. 
}

- (long)blocksDone;
- (void)dumpStimList:(NSMutableArray *)list listIndex:(long)listIndex;
- (float)contrastValueFromIndex:(long)index count:(long)count min:(float)min max:(float)max;
- (float)logMaxToMinValueFromIndex:(long)index count:(long)count min:(float)min max:(float)max; // [Vinay] - to map values logarithmically from max to min with a factor of 0.5
- (float)tfValueFromIndex:(long)index count:(long)count min:(float)min max:(float)max; // [Vinay] - map tf levels the same way as contrast, but make sure that the maximum level doesn't exceed (refresh rate)/2
- (id)initWithIndex:(long)index;
- (float)linearValueWithIndex:(long)index count:(long)count min:(float)min max:(float)max;
- (float)logValueWithIndex:(long)index count:(long)count min:(float)min max:(float)max;
- (void)makeMapStimList:(NSMutableArray *)list index:(long)index lastFrame:(long)lastFrame pTrial:(TrialDesc *)pTrial;
- (MappingBlockStatus)mappingBlockStatus;
- (MapSettings)mapSettings;
- (void)newBlock;
- (void)reset;
- (long)stimInBlock;
- (void)tallyStimList:(NSMutableArray *)list  count:(long)count;
- (void)tallyStimList:(NSMutableArray *)list  upToFrame:(long)frameLimit;
- (long)stimDoneInBlock;
//- (void)updateBlockParameters;
- (void)updateBlockParameters:(long)mapIndex; // [Vinay] added the arg 'mapIndex' to have separate updates for different gabors
//- (void)doneListDefine:(long)index; // [Vinay] Added to dynamically define doneList depending on the gabor index, to get a flexible size of doneList for each gabor corresponding to the respective mapping parameters

@end
