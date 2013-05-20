//
//  CRSSpikeController.h
//  CRSMap
//
//  Copyright (c) 2006-2012. All rights reserved.
//

#include "CRS.h"

#define kMaxSpikeMS				10000
#define	kLocations				3
#define kNumSpikes              2

enum PlotTypes {kDirectionPlot = 0, kSFPlot, kSigmaPlot, kContrastPlot, kNumPlots};

@interface CRSSpikeController : LLScrollZoomWindow {

    NSMutableArray	*attRates;								// an array of LLNormDist
	BlockStatus		blockStatus;
	NSView			*documentView;
    LLHeatMapView	*heatMaps[kNumSpikes];
    NSMutableArray	*heatMapRates[kNumSpikes];             //  LLNormDist for plotting
    NSColor 		*highlightColor;
    long			interstimDurMS;
    NSMutableArray	*labelArray;
	BlockStatus		lastBlockStatus;
	StimParams		lastStimParams;
    MapSettings     mapSettings[kNumSpikes];
    NSMutableArray	*rates[kNumSpikes][kNumPlots];          //  LLNormDist for plotting
    LLPlotView		*ratePlots[kNumSpikes][kNumPlots];
	unsigned		referenceOnTimeMS;                      // onset time of reference direction
    NSMutableArray  *stimDescs[kNumSpikes];
    NSMutableArray  *stimTimes[kNumSpikes];
    long			stimDurMS;
	float			spikePeriodMS;
	unsigned long	targetOnTimeMS;
	TrialDesc		trial;
	long            trialStartTime;
	short           trialSpikes[kNumSpikes][kMaxSpikeMS];
    NSMutableArray	*xAxisLabels[kNumSpikes][kNumPlots];
    NSMutableArray	*xHMAxisLabels[kNumSpikes];
    NSMutableArray	*yHMAxisLabels[kNumSpikes];
}

- (void)checkParams;
- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;

@end

