/*
CRSStimuli.h
*/

#import "CRS.h"
#import "CRSMapStimTable.h"

@interface CRSStimuli : NSObject {

	BOOL				 	abortStimuli;
	DisplayParam			display;
	long					durationMS;
	float					fixSizePix;
	LLFixTarget				*fixSpot;
	BOOL					fixSpotOn;
	NSArray					*fixTargets;
	NSArray					*gabors;
	NSMutableArray			*mapStimList0;
	NSMutableArray			*mapStimList1;
    NSMutableArray          *mapStimList2;                  // [Vinay] - added for centre gabors

	LLIntervalMonitor 		*monitor;
	short					selectTable[kMaxOriChanges];
	long					targetOnFrame;
	NSMutableArray			*taskStimList;
	BOOL					stimulusOn;
	BOOL					targetPresented;
    TrialDesc               trial;
    LLFixTarget				*targetSpot;
//	LLGabor 				*taskGabor;
    //BOOL                    matchSurroundCentre;           // [Vinay] - added this to indicate if surround and centre should have some common attributes
    LLFixTarget             *colorSpot;
    RGBFloat                rgb;
    int                     *stimIndexList;
    
}

- (void)doFixSettings;
- (void)doGabor0Settings;
- (void)presentStimSequence;
- (void)dumpStimList;
- (void)erase;
- (LLGabor *)mappingGabor0;
- (LLGabor *)mappingGabor1;
- (LLGabor *)mappingGabor2; // [Vinay] - Added Gabor2 for the centre gabor
- (LLGabor *)taskGabor;
- (LLGabor *)initGabor:(BOOL)bindTemporalFreq;
- (void)loadGabor:(LLGabor *)gabor withStimDesc:(StimDesc *)pSD;
- (void)makeStimLists:(TrialDesc *)pTrial;
- (void)clearStimLists:(TrialDesc *)pTrial;
- (LLIntervalMonitor *)monitor;
- (void)setFixSpot:(BOOL)state;
- (void)shuffleStimListFrom:(short)start count:(short)count;
- (void)startStimSequence;
- (BOOL)stimulusOn;
- (void)stopAllStimuli;
- (void)tallyStimLists:(long)count;
- (long)targetOnFrame;
- (BOOL)targetPresented;
- (RGBFloat)RGBFromIndex:(int)index factor:(int)factor;

@end
