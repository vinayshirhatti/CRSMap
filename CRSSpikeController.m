//
//  CRSSpikeController.m
//  CRSMap
//
//  Window with summary information about behavioral performance.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

#import "CRS.h"
#import "CRSMapStimTable.h"
#import "UtilityFunctions.h"
#import "CRSSpikeController.h"

#define kContentHeightPix	((kPlotHeightPix + kMarginPix) * kNumSpikes + kMarginPix)
#define kContentWidthPix	((kPlotHeightPix + kMarginPix) * (kNumPlots + 1) + kMarginPix)
#define kMarginPix			10
#define kPlotHeightPix		250
#define kPlotWidthPix		250
#define kSpikeLatencyMS     50


@implementation CRSSpikeController

- (void)checkParams;
{
    long spikeIndex, plotIndex;
	BOOL dirty = NO;
    MapParams *pPtr, *pParam[kNumSpikes][kNumPlots] = {
        {&mapSettings[0].directionDeg, &mapSettings[0].spatialFreqCPD, &mapSettings[0].sigmaDeg,
            &mapSettings[0].contrastPC},
        {&mapSettings[1].directionDeg, &mapSettings[1].spatialFreqCPD, &mapSettings[1].sigmaDeg,
            &mapSettings[1].contrastPC}
    };
    
    if (mapSettings[0].azimuthDeg.n == 0) {                   // not initialized yet
        return;
    }
    for (spikeIndex = 0; spikeIndex < kNumSpikes; spikeIndex++) {
        pPtr = &mapSettings[spikeIndex].azimuthDeg;
        if (pPtr->n != [heatMaps[spikeIndex] plotXPoints] ||
                        pPtr->maxValue != [heatMaps[spikeIndex] xMaxValue] ||
                        pPtr->minValue != [heatMaps[spikeIndex] xMinValue]) {
            [heatMaps[spikeIndex] setPlotXPoints:pPtr->n];
            [heatMaps[spikeIndex] setXMaxValue:pPtr->n - 1];
            [heatMaps[spikeIndex] setXMinValue:0];
            [self changeHMAxis:heatMaps[spikeIndex] withSettings:*pPtr labelArray:xHMAxisLabels[spikeIndex]];
            dirty = YES;
        }
        pPtr = &mapSettings[spikeIndex].elevationDeg;
        if (pPtr->n != [heatMaps[spikeIndex] plotYPoints] ||
                        pPtr->maxValue != [heatMaps[spikeIndex] yMaxValue] ||
                        pPtr->minValue != [heatMaps[spikeIndex] yMinValue]) {
            [heatMaps[spikeIndex] setPlotYPoints:pPtr->n];
            [heatMaps[spikeIndex] setYMaxValue:pPtr->n - 1];
            [heatMaps[spikeIndex] setYMinValue:0];
            [self changeHMAxis:heatMaps[spikeIndex] withSettings:*pPtr labelArray:yHMAxisLabels[spikeIndex]];
            dirty = YES;
        }
        for (plotIndex = 0; plotIndex < kNumPlots; plotIndex++) {
            pPtr = pParam[spikeIndex][plotIndex];
            if (pPtr->n != [ratePlots[spikeIndex][plotIndex] points] ||
                pPtr->maxValue != [ratePlots[spikeIndex][plotIndex] xMaxDisplayValue] ||
                pPtr->minValue != [ratePlots[spikeIndex][plotIndex] xMinDisplayValue]) {
                [self changeXAxis:ratePlots[spikeIndex][plotIndex] withSettings:*pPtr
                       labelArray:xAxisLabels[spikeIndex][plotIndex]];
                dirty = YES;
            }
        }
    }
    if (dirty) {
        [self reset:[NSData data] eventTime:[NSNumber numberWithLong:0]];
    }
}

- (void)changeHMAxis:(LLHeatMapView *)plot withSettings:(MapParams)params labelArray:(NSMutableArray *)labels;
{
    long index;
	double stimValue;
	NSString *string;
    
    [labels removeAllObjects];
    for (index = 0; index < params.n; index++) {
        if (params.n < 2) {
            stimValue = params.minValue;
        }
        else {
            stimValue = params.minValue + index * (params.maxValue - params.minValue) / (params.n - 1);
        }
		string = [NSString stringWithFormat:@"%.*f", [LLTextUtil precisionForValue:stimValue significantDigits:2],
                  stimValue];
		if ((params.n >= 6) && ((index % 2) == (params.n % 2))) {
			[labels addObject:@""];
		}
		else {
			[labels addObject:string];
		}
    }
}

- (void)changeXAxis:(LLPlotView *)plot withSettings:(MapParams)params labelArray:(NSMutableArray *)labels;
{
    long index;
	double stimValue;
	NSString *string;
    
    [plot setPoints:params.n];
    [plot setXMin:0 xMax:params.n - 1];
    
    [labels removeAllObjects];
    for (index = 0; index < params.n; index++) {
        if (params.n < 2) {
            stimValue = params.minValue;
        }
        else {
            stimValue = params.minValue + index * (params.maxValue - params.minValue) / (params.n - 1);
        }
		string = [NSString stringWithFormat:@"%.*f", [LLTextUtil precisionForValue:stimValue significantDigits:2],
                  stimValue];
		if ((params.n >= 6) && ((index % 2) == (params.n % 2))) {
			[labels addObject:@""];
		}
		else {
			[labels addObject:string];
		}
    }
}

- (void)dataParam:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	DataParam *pParam = (DataParam *)[eventData bytes];
	
	if (strcmp((char *)&pParam->dataName, "spike0") == 0) {
		spikePeriodMS = pParam->timing;
	}
}

- (void)dealloc;
{
    long spikeIndex, plotIndex;
    
    for (spikeIndex = 0; spikeIndex < kNumSpikes; spikeIndex++) {
        [xHMAxisLabels[spikeIndex] dealloc];
        [yHMAxisLabels[spikeIndex] dealloc];
        for (plotIndex = 0; plotIndex < kNumPlots; plotIndex++) {
            [xAxisLabels[spikeIndex][plotIndex] release];
        }
        [stimDescs[spikeIndex] release];
        [stimTimes[spikeIndex] release];
    }
    [super dealloc];
}

- (id) init;
{
    if ((self = [super initWithWindowNibName:@"CRSSpikeController" defaults:[task defaults]]) != nil) {
		spikePeriodMS = 1.0;
    }
    return self;
}

- (void)mouseDown:(NSEvent *)theEvent;
{
    long spikeIndex, plotIndex;
    
    for (spikeIndex = 0; spikeIndex < kNumSpikes; spikeIndex++) {
        for (plotIndex = 0; plotIndex < kNumPlots; plotIndex++) {
            [ratePlots[spikeIndex][plotIndex] mouseDown:theEvent];
        }
    }
}

- (void) windowDidLoad;
{
    long index, eleIndex, aziIndex, spikeIndex, plotIndex;
    LLViewScale *plotScaling, *hmScaling;
    NSMutableArray *theArray;
    NSString *plotLabels[] = {@"Direction (deg)", @"Spatial Freq. (CPD)", @"Sigma (deg)", @" Contrast (%)"};
    
//	NSColor *redColor = [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:1.0];
//	NSColor *blueColor = [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:1.0];
	NSColor *grayColor = [NSColor colorWithCalibratedRed:0.7 green:0.7 blue:0.7 alpha:1.0];
	NSColor *greenColor = [NSColor colorWithCalibratedRed:0.0 green:0.7 blue:0.0 alpha:1.0];
	NSColor *brownColor = [NSColor colorWithCalibratedRed:0.6 green:0.4 blue:0.2 alpha:1.0];
	NSColor *plotColors[] = {greenColor, brownColor, grayColor};
//	NSColor *plotColors[] = {greenColor, brownColor};
	
	[super windowDidLoad];
    for (index = 0; index < kNumSpikes; index++) {
        stimDescs[index] = [[NSMutableArray alloc] init];
        stimTimes[index] = [[NSMutableArray alloc] init];
	}
	documentView = [scrollView documentView];
	[documentView setFrame:NSMakeRect(0, 0, kContentWidthPix, kContentHeightPix)];
	[super setBaseMaxContentSize:NSMakeSize(kContentWidthPix, kContentHeightPix)];

    highlightColor = [NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.85 alpha:1.0];

// Initialize the spike rate plots

    plotScaling = [[[LLViewScale alloc] init] autorelease];
    hmScaling = [[[LLViewScale alloc] init] autorelease];
    for (spikeIndex = 0; spikeIndex < kNumSpikes; spikeIndex++) {
        heatMaps[spikeIndex] = [[[LLHeatMapView alloc] initWithFrame:NSMakeRect(kMarginPix,
                                kMarginPix + (1 - spikeIndex) * (kMarginPix + kPlotHeightPix),
                                kPlotWidthPix, kPlotHeightPix)] autorelease];
        heatMapRates[spikeIndex] = [[[NSMutableArray alloc] init] autorelease];
        for (aziIndex = 0; aziIndex < kMaxMapValues; aziIndex++ ) {
            theArray = [[[NSMutableArray alloc] init] autorelease];
            for (eleIndex = 0; eleIndex < kMaxMapValues; eleIndex++) {
                [theArray addObject:[[[LLNormDist alloc] init] autorelease]];
            }
            [heatMapRates[spikeIndex] addObject:theArray];
        }
        [heatMaps[spikeIndex] setPlotValues:heatMapRates[spikeIndex]];
        xHMAxisLabels[spikeIndex] = [[NSMutableArray alloc] init];
        [heatMaps[spikeIndex] setXAxisTickLabels:xHMAxisLabels[spikeIndex]];
        yHMAxisLabels[spikeIndex] = [[NSMutableArray alloc] init];
        [heatMaps[spikeIndex] setYAxisTickLabels:yHMAxisLabels[spikeIndex]];
        [heatMaps[spikeIndex] setHighlightXRangeColor:highlightColor];
        [heatMaps[spikeIndex] setXAxisLabel:[NSString stringWithFormat:@"Spike %ld Azimuth", spikeIndex]];
        [heatMaps[spikeIndex] setYAxisLabel:[NSString stringWithFormat:@"Spike %ld Elevation", spikeIndex]];
        [documentView addSubview:heatMaps[spikeIndex]];
        for (plotIndex = 0; plotIndex < kNumPlots; plotIndex++) {
           ratePlots[spikeIndex][plotIndex] = [[[LLPlotView alloc] initWithFrame:NSMakeRect(
                        kMarginPix + (plotIndex + 1) * (kMarginPix + kPlotHeightPix),
                        kMarginPix + (1 - spikeIndex) * (kMarginPix + kPlotHeightPix),
                        kPlotWidthPix, kPlotHeightPix) scaling:plotScaling] autorelease];
            xAxisLabels[spikeIndex][plotIndex] = [[NSMutableArray alloc] init];
            [ratePlots[spikeIndex][plotIndex] setXAxisTickLabels:xAxisLabels[spikeIndex][plotIndex]];
            [ratePlots[spikeIndex][plotIndex] setHighlightXRangeColor:highlightColor];
            [ratePlots[spikeIndex][plotIndex] setXAxisLabel:
                [NSString stringWithFormat:@"Spike %ld %@", spikeIndex, plotLabels[plotIndex]]];
            rates[spikeIndex][plotIndex] = [[[NSMutableArray alloc] init] autorelease];
            for (index = 0; index < kMaxMapValues; index++) {
                [rates[spikeIndex][plotIndex] addObject:[[[LLNormDist alloc] init] autorelease]];
            }
            [ratePlots[spikeIndex][plotIndex] addPlot:rates[spikeIndex][plotIndex] plotColor:plotColors[spikeIndex]];
            [documentView addSubview:ratePlots[spikeIndex][plotIndex]];
        }
    }
    [self checkParams];
}

- (void)interstimMS:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&interstimDurMS length:sizeof(long)];
}

- (void)map0Settings:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&mapSettings[0] length:sizeof(MapSettings)];     // don't checkParams - wait for map1Settings
}

- (void)map1Settings:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&mapSettings[1] length:sizeof(MapSettings)];
	[self checkParams];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long spikeIndex, plotIndex, aziIndex;
    
    for (spikeIndex = 0; spikeIndex < kNumSpikes; spikeIndex++) {
        [[heatMaps[spikeIndex] scale] setHeight:10];					// Reset scaling as well
        for (aziIndex = 0; aziIndex < kMaxMapValues; aziIndex++ ) {
            [[heatMapRates[spikeIndex] objectAtIndex:aziIndex] makeObjectsPerformSelector:@selector(clear)];
        }
        for (plotIndex = 0; plotIndex < kNumPlots; plotIndex++) {
            [rates[spikeIndex][plotIndex] makeObjectsPerformSelector:@selector(clear)];
            [[ratePlots[spikeIndex][plotIndex] scale] setHeight:10];	// Reset scaling as well
        }
    }
    [[[self window] contentView] setNeedsDisplay:YES];
}

- (void)spike:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    TimestampData spikeData;
    
	[eventData getBytes:&spikeData length:sizeof(TimestampData)];
    if (spikeData.time >= 0 && spikeData.time < kMaxSpikeMS) {
        trialSpikes[spikeData.channel][spikeData.time]++;
    }
}

- (void)mapStimDurationMS:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&stimDurMS length:sizeof(long)];
}

- (void)stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	StimDesc stimDesc;
	
	[eventData getBytes:&stimDesc length:sizeof(StimDesc)];
    if (stimDesc.gaborIndex != kMapGabor0 && stimDesc.gaborIndex != kMapGabor1) {
        return;
    }
    [stimDescs[stimDesc.gaborIndex - kMapGabor0]
                        addObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];
    [stimTimes[stimDesc.gaborIndex - kMapGabor0] addObject:eventTime];
}

- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long index, bin;
    
	[eventData getBytes:&trial length:sizeof(TrialDesc)];
	trialStartTime = [eventTime longValue];
    NSLog(@"trialStartTime %ld", trialStartTime);
    for (index = 0; index < kNumSpikes; index++) {
        [stimDescs[index] removeAllObjects];
        [stimTimes[index] removeAllObjects];
        for (bin = 0; bin < kMaxSpikeMS; bin++) {
            trialSpikes[index][bin] = 0;
        }
    }
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long eotCode, startTimeMS, stopTimeMS, index, aziIndex, eleIndex, spikeIndex, spikeCount, plotIndex, bin, minN;
    float meanRate, maxRate, minRate;
    StimDesc stimDesc;
    NSNumber *number;
	NSValue *value;
    NSArray *eleArray;
    NSEnumerator *stimEnumerator, *timeEnumerator;
    long *pIndices[kNumPlots] = {&stimDesc.directionIndex, &stimDesc.spatialFreqIndex,
                                &stimDesc.sigmaIndex, &stimDesc.contrastIndex};
	
// Update only for correct trials
// Think about if there is any reason to update for other trials.
// Maybe separate superimposed histograms for failed trials

	[eventData getBytes:&eotCode length:sizeof(long)];
//	if (((eotCode != kEOTCorrect) && (eotCode != kEOTFailed)) || (trial.catchTrial == YES)) {
//		return;
//	}

    for (spikeIndex = 0; spikeIndex < kNumSpikes; spikeIndex++) {
        stimEnumerator = [stimDescs[spikeIndex] objectEnumerator];
        timeEnumerator = [stimTimes[spikeIndex] objectEnumerator];
        while (value = [stimEnumerator nextObject]) {					// For each stimulus
            [value getValue:&stimDesc];
            number = [timeEnumerator nextObject];
            startTimeMS = [number longValue] - trialStartTime + kSpikeLatencyMS;
            stopTimeMS = startTimeMS + stimDurMS;
            if (startTimeMS < 0 || stopTimeMS >= kMaxSpikeMS) {
                continue;
            }
            for (bin = startTimeMS, spikeCount = 0; bin < stopTimeMS; bin++) {
                spikeCount += trialSpikes[spikeIndex][bin];
            }
            for (plotIndex = 0; plotIndex < kNumPlots; plotIndex++) {
                [[rates[spikeIndex][plotIndex] objectAtIndex:*pIndices[plotIndex]]
                                                    addValue:spikeCount * 1000.0 / stimDurMS];
                for (index = 0, minN = LONG_MAX; index < kNumSpikes; index++) {
                    minN = MIN(minN, [[rates[spikeIndex][plotIndex] objectAtIndex:index] n]);
                }
                [ratePlots[spikeIndex][plotIndex] setTitle:[NSString stringWithFormat:@"(n >= %ld)", minN]];
                [ratePlots[spikeIndex][plotIndex] setNeedsDisplay:YES];
            }
            [[[heatMapRates[spikeIndex] objectAtIndex:stimDesc.azimuthIndex] objectAtIndex:stimDesc.elevationIndex]
                        addValue:spikeCount * 1000.0 / stimDurMS];
            minN = LONG_MAX;
            minRate = FLT_MAX;
            maxRate = FLT_MIN;
            for (aziIndex = 0; aziIndex < mapSettings[spikeIndex].azimuthDeg.n; aziIndex++) {
                eleArray = [heatMapRates[spikeIndex] objectAtIndex:aziIndex];
                for (eleIndex = 0; eleIndex < mapSettings[spikeIndex].elevationDeg.n; eleIndex++) {
                    minN = MIN(minN, [[eleArray objectAtIndex:eleIndex] n]);
                    meanRate = [[eleArray objectAtIndex:eleIndex] mean];
                    minRate = MIN(minRate, meanRate);
                    maxRate = MAX(maxRate, meanRate);
                }
            }
            [heatMaps[spikeIndex] setTitle:[NSString stringWithFormat:@"Rates %.1f-%.1f (n >= %ld)",
                                            minRate, maxRate, minN]];
            [heatMaps[spikeIndex] setNeedsDisplay:YES];
        }
    }
}

@end
