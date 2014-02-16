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
    BOOL doneList[kMaxMapValuesFixed][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValuesFixed][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues]; // [Vinay] - changed it from 7 to a 9 dimensional List, to include dimensions for spatialPhase and radius // [Vinay] - Also changed kMaxMapValues to kMaxMapValuesFixed, corresponding to azimuth, elevation and sigma, since will be kept fixed and therefore take just 1 value in session/block
    long mapIndex;                  // index to instance of CRSMapStimTable
	int stimRemainingInBlock;
	int stimInBlock;
	NSMutableArray *currentStimList; //*copyList; [Vinay] - added copyList to copy stimulus list attributes from one gabor to another (surround gabor to the centre gabor). Have removed this later. 
}

- (long)blocksDone;
- (void)dumpStimList:(NSMutableArray *)list listIndex:(long)listIndex;
- (float)contrastValueFromIndex:(long)index count:(long)count min:(float)min max:(float)max;
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
- (void)updateBlockParameters:(long)mapIndex; // [Vinay] added the arg 'mapIndec' to have separate updates for different gabors

@end
