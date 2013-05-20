//
//  CRSBehaviorController.m
//  CRSMap
//
//  Window with summary information about behavioral performance.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

#import "CRS.h"

#import "UtilityFunctions.h"
#import "CRSBehaviorController.h"

#define kHistsPerRow		4
#define kHistHeightPix		150
#define kHistWidthPix		((kViewWidthPix - (kHistsPerRow + 1) * kMarginPix) / kHistsPerRow)
#define kMarginPix			10
#define kMaxTimes			7
#define kPlotBinsDefault	10
#define kPlotHeightPix		250
#define kPlots				3
#define kPlotWidthPix		250
#define kViewWidthPix		(kPlots * (kPlotWidthPix) + (kPlots + 1) * kMarginPix)
#define	kXTickSpacing		100

#define contentWidthPix		(kHistsPerRow  * kHistWidthPix +  + (kHistsPerRow + 1) * kMarginPix)
#define contentHeightPix	(kPlotHeightPix + kHistHeightPix * histRows + (histRows + 2) * kMarginPix)
#define histRows			(ceil(displayedHists / (double)kHistsPerRow))
#define	displayedHists		(MIN(blockStatus.changes, kMaxOriChanges))

@implementation CRSBehaviorController

- (void)changeResponseTimeMS;
{
    long h, index, base, labelSpacing;
    long factors[] = {1, 2, 5};
 
// Find the appropriate spacing for x axis labels

	index = 0;
	base = 1;
    while ((responseTimeMS / kXTickSpacing) / (base * factors[index]) > 2) {
        index = (index + 1) % (sizeof(factors) / sizeof(long));
        if (index == 0) {
            base *= 10;
        }
    }
    labelSpacing = base * factors[index];

// Change the ticks and tick label spacing for each histogram

    for (h = 0; h < kMaxOriChanges; h++) {
        [hist[h] setDataLength:MIN(responseTimeMS, kMaxRT)];
        [hist[h] setDisplayXMin:0 xMax:MIN(responseTimeMS, kMaxRT)];
        [hist[h] setXAxisTickSpacing:kXTickSpacing];
        [hist[h] setXAxisTickLabelSpacing:labelSpacing];
        [hist[h] setNeedsDisplay:YES];
    }
}

- (void)checkParams;
{
	long index;
	BlockStatus *pCurrent, *pLast;
	BOOL dirty = NO;
	
	pCurrent = &blockStatus;
	pLast = &lastBlockStatus;
	
	if (pCurrent->changes == 0) {								// not initialized yet
		return;
	}
	if (pCurrent->changes != pLast->changes) {
		dirty = YES;
		pLast->changes = pCurrent->changes;
	}
	for (index = 0; index < pCurrent->changes; index++) {
		if (pCurrent->orientationChangeDeg[index] != pLast->orientationChangeDeg[index]) {
			dirty = YES;
			pLast->orientationChangeDeg[index] = pCurrent->orientationChangeDeg[index];
		}
		if (pCurrent->validReps[index] != pLast->validReps[index]) {
			dirty = YES;
			pLast->validReps[index] = pCurrent->validReps[index];
		}
	}
	if (!dirty) {
		return;
	}
	[self makeLabels];
	[reactPlot setPoints:pCurrent->changes];
	[reactPlot setXAxisLabel:@"Direction Change (deg)"];
	[perfPlot setPoints:pCurrent->changes];
	[perfPlot setXAxisLabel:@"Direction Change (deg)"];
	[self positionPlots];

// If settings have changed (number of stimulus levels, type of stim, etc.  we reset and redraw

	[self reset:[NSData data] eventTime:[NSNumber numberWithLong:0]]; 
}

- (void)checkTimeParams;
{
	if (maxTargetTimeMS != lastMaxTargetTimeMS || minTargetTimeMS != lastMinTargetTimeMS) {
		[self makeTimeLabels];
		lastMaxTargetTimeMS = maxTargetTimeMS;
		lastMinTargetTimeMS = minTargetTimeMS;

// If settings have changed (number of stimulus levels, type of stim, etc.  we reset and redraw

		[self reset:[NSData data] eventTime:[NSNumber numberWithLong:0]]; 
	}
}

- (void)dealloc {

    [labelArray release];
    [timeLabelArray release];
	[xAxisLabelArray release];
	[super dealloc];
}

- (id) init {

    if ((self = [super initWithWindowNibName:@"CRSBehaviorController" defaults:[task defaults]]) != nil) {
    }
    return self;
}

- (LLHistView *)myInitHist:(LLViewScale *)scale data:(double *)data {

	LLHistView *h;
    
	h = [[[LLHistView alloc] initWithFrame:NSMakeRect(0, 0, kHistWidthPix, kHistHeightPix)
									scaling:scale] autorelease];
	[h setScale:scale];
	[h setData:data length:kMaxRT color:[NSColor colorWithDeviceRed:0.0 green:0.0 blue:1.0 alpha:0.6]];
	[h setPlotBins:kPlotBinsDefault];
	[h setAutoBinWidth:YES];
	[h setSumWhenBinning:YES];
	[h hide:YES];
	[documentView addSubview:h];
	return h;
}

- (void)makeLabels;		// make X labels for contrast
{
    long index, levels;
	double stimValue;
	NSString *string;

    
	levels = blockStatus.changes;
    [labelArray removeAllObjects];
    [xAxisLabelArray removeAllObjects];
    for (index = 0; index < levels; index++) {
		stimValue = blockStatus.orientationChangeDeg[index];
		string = [NSString stringWithFormat:@"%.*f",  
					(int)[LLTextUtil precisionForValue:stimValue significantDigits:2],
					stimValue];
		[labelArray addObject:string];
		if ((levels >= 6) && ((index % 2) == (levels % 2))) {
			[xAxisLabelArray addObject:@""];
		}
		else {
			[xAxisLabelArray addObject:string];
		}
    }
}


- (void)makeTimeLabels;
{
    long index;
	NSString *string;
    
    [timeLabelArray removeAllObjects];
    for (index = 0; index < kMaxTimes; index++) {
		string = [NSString stringWithFormat:@"%ld",
					minTargetTimeMS + (maxTargetTimeMS - minTargetTimeMS) * index / (kMaxTimes - 1)];
		if ((index % 2)) {
			[timeLabelArray addObject:@""];
		}
		else {
			[timeLabelArray addObject:string];
		}
    }
}

- (void)positionPlots;
{
	long level, row, column;

// Position the plots

	[reactPlot setFrameOrigin:NSMakePoint(kMarginPix, 
					histRows * (kHistHeightPix + kMarginPix) + kMarginPix)];
	[perfPlot setFrameOrigin:NSMakePoint(kMarginPix + (kPlotWidthPix + kMarginPix), 
					histRows * (kHistHeightPix + kMarginPix) + kMarginPix)];
	[perfTimePlot setFrameOrigin:NSMakePoint(kMarginPix + 2 * (kPlotWidthPix + kMarginPix), 
					histRows * (kHistHeightPix + kMarginPix) + kMarginPix)];

// Position and hide/show the individual histograms

	for (level = 0; level < kMaxOriChanges; level++) {
		if (level < displayedHists) {
			row = level / kHistsPerRow;
			column = (level % kHistsPerRow);
			[hist[level] setFrameOrigin:NSMakePoint(kMarginPix + column * (kHistWidthPix + kMarginPix), 
					kMarginPix + (histRows - row - 1) * (kHistHeightPix + kMarginPix))];
			[hist[level] setTitle:[NSString stringWithFormat: @"%@ %@ deg", 
							@"Dir. Change", [labelArray objectAtIndex:level]]];
			if (row == histRows - 1) {
				[hist[level] setXAxisLabel:@"Time (ms)"];
			}
			[hist[level] hide:NO];
			[hist[level] setNeedsDisplay:YES];
		}
		else {
			[hist[level] hide:YES];
		}
	}
		
// Set the window to the correct size for the new number of rows and columns, forcing a 
// re-draw of all the exposed histograms.

	[documentView setFrame:NSMakeRect(0, 0, contentWidthPix, contentHeightPix)];
	[super setBaseMaxContentSize:NSMakeSize(contentWidthPix, contentHeightPix)];
}

- (void) windowDidLoad {

    long index, p, h;
    
    [super windowDidLoad];
	documentView = [scrollView documentView];
    labelArray = [[NSMutableArray alloc] init];
    timeLabelArray = [[NSMutableArray alloc] init];
    xAxisLabelArray = [[NSMutableArray alloc] init];
    [self makeLabels];
    highlightColor = [NSColor colorWithDeviceRed:0.85 green:0.85 blue:0.85 alpha:1.0];

// Initialize the reaction time plot

    reactTimes = [[[NSMutableArray alloc] init] autorelease];
    for (index = 0; index < kMaxOriChanges; index++) {
        [reactTimes addObject:[[[LLNormDist alloc] init] autorelease]];
    }
	reactPlot = [[[LLPlotView alloc] initWithFrame:
			NSMakeRect(0, 0, kPlotWidthPix, kPlotHeightPix)] autorelease];
    [reactPlot addPlot:reactTimes plotColor:nil];
    [reactPlot setXAxisLabel:@"Direction Change (deg)"];
    [reactPlot setXAxisTickLabels:xAxisLabelArray];
    [reactPlot setHighlightXRangeColor:highlightColor];
	[documentView addSubview:reactPlot];
	
// Initialize the performance (by change value) plot.  We set the color for kEOTFail to clear, because we don't 
// want to see those values.  They are mirror image to the correct data

	perfPlot = [[[LLPlotView alloc] initWithFrame:
			NSMakeRect(0, 0, kPlotWidthPix, kPlotHeightPix)] autorelease];
    for (p = 0; p < kEOTs; p++) {
		performance[p] = [[[NSMutableArray alloc] init] autorelease];
		for (index = 0; index < kMaxOriChanges; index++) {
			[performance[p] addObject:[[[LLBinomDist alloc] init] autorelease]];
		}		
		[perfPlot addPlot:performance[p] plotColor:[LLStandardDataEvents eotColor:p]];
    }
    [perfPlot setXAxisLabel:@"Direction Change (deg)"];
    [perfPlot setXAxisTickLabels:xAxisLabelArray];
    [[perfPlot scale] setAutoAdjustYMax:NO];
    [[perfPlot scale] setHeight:1];
    [perfPlot setHighlightXRangeColor:highlightColor];
	[perfPlot setHighlightYRangeFrom:0.49 to:0.51];
    [perfPlot setHighlightYRangeColor:highlightColor];
	[documentView addSubview:perfPlot];

// Initialize the performance-by-time plot.  We set the color for kEOTWrong to clear, because we don't 
// want to see those values.  They are mirror image to the correct data

	perfTimePlot = [[[LLPlotView alloc] initWithFrame:
			NSMakeRect(0, 0, kPlotWidthPix, kPlotHeightPix)] autorelease];
    for (p = 0; p < kEOTs; p++) {
		performanceByTime[p] = [[[NSMutableArray alloc] init] autorelease];
		for (index = 0; index < kMaxTimes; index++) {
			[performanceByTime[p] addObject:[[[LLBinomDist alloc] init] autorelease]];
		}		
		[perfTimePlot addPlot:performanceByTime[p] plotColor:[LLStandardDataEvents eotColor:p]];
    }
    [perfTimePlot setXAxisLabel:@"Time (ms)"];
    [[perfTimePlot scale] setAutoAdjustYMax:NO];
    [[perfTimePlot scale] setHeight:1];
    [perfTimePlot setHighlightXRangeColor:highlightColor];
	[perfTimePlot setHighlightYRangeFrom:0.49 to:0.51];
    [perfTimePlot setHighlightYRangeColor:highlightColor];
	[documentView addSubview:perfTimePlot];
	
	[perfTimePlot setXAxisTickLabels:timeLabelArray];

// Initialize the histogram views
    
    histScaling = [[[LLViewScale alloc] init] autorelease];
    for (h = 0; h < kMaxOriChanges; h++) {
		hist[h] = [self myInitHist:histScaling data:rtDist[h]];
    }
    histHighlightIndex = -1;

    [[zoomButton cell] setBordered:NO];
    [[zoomButton cell] setBezeled:YES];
    [[zoomButton cell] setFont:[NSFont labelFontOfSize:10.0]];

// Work down from the default window max size to a default content max size, which 
// we will use as a reference for setting window max size when the view scaling is changed.

    [self checkParams];
	[self changeResponseTimeMS];
}

- (void)blockStatus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&blockStatus];
	[self checkParams];
}


- (void)maxTargetTimeMS:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&maxTargetTimeMS];
	[self checkTimeParams];
}

- (void)minTargetTimeMS:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[eventData getBytes:&minTargetTimeMS];
	[self checkTimeParams];
}


- (void)saccade:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{    
    saccadeStartTimeMS = [eventTime unsignedLongValue] - stimStartTimeMS;
}


- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long index, p, bin;
    	
	[reactTimes makeObjectsPerformSelector:@selector(clear)];
	for (p = 0; p < kEOTs; p++) {
		[performance[p] makeObjectsPerformSelector:@selector(clear)];
		[performanceByTime[p] makeObjectsPerformSelector:@selector(clear)];
	}
    for (index = 0; index < kMaxOriChanges; index++) {
        for (bin = 0; bin < kMaxRT; bin++) {
            rtDist[index][bin] = 0;
        }
    }
	[[reactPlot scale] setHeight:100];					// Reset scaling as well
    [[[self window] contentView] setNeedsDisplay:YES];
}

- (void)responseTimeMS:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long newResponseTimeMS;
    
    [eventData getBytes:&newResponseTimeMS];
    if (responseTimeMS != newResponseTimeMS) {
        responseTimeMS = newResponseTimeMS;
        [self changeResponseTimeMS];
    }
}

- (void)stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	StimDesc stimDesc;
	
	if (stimStartTimeMS == 0) {
		stimStartTimeMS = [eventTime unsignedLongValue];
	}
	[eventData getBytes:&stimDesc];
	if (stimDesc.stimType == kTargetStim) {
		targetOnTimeMS = [eventTime unsignedLongValue];
	}
}

- (void)taskMode:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long taskMode;
    
	[eventData getBytes:&taskMode];
    if (taskMode == kTaskIdle) {
        if (histHighlightIndex >= 0) {
            [hist[histHighlightIndex] setHighlightHist:NO];
            histHighlightIndex = -1;
        }
        [reactPlot setHighlightXRangeFrom:0 to:0];
        [perfPlot setHighlightXRangeFrom:0 to:0];
        [perfTimePlot setHighlightXRangeFrom:0 to:0];
    }
}

- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	long timeIndex, targetOnEstimateMS;
	
	[eventData getBytes:&trial];
//	trialStartTimeMS = [eventTime unsignedLongValue];
	saccadeStartTimeMS = stimStartTimeMS = targetOnTimeMS = 0;
	
// Highlight the appropriate histogram

	if (histHighlightIndex != trial.orientationChangeIndex) {
        if (histHighlightIndex >= 0) {
            [hist[histHighlightIndex] setHighlightHist:NO];
        }
		histHighlightIndex = trial.orientationChangeIndex;
        if (histHighlightIndex >= 0) {
			[hist[histHighlightIndex] setHighlightHist:YES];
			[reactPlot setHighlightXRangeFrom:histHighlightIndex - 0.25 to:histHighlightIndex + 0.25];
			[perfPlot setHighlightXRangeFrom:histHighlightIndex - 0.25 to:histHighlightIndex + 0.25];
//			[perfTimePlot setHighlightXRangeFrom:histHighlightIndex - 0.25 to:histHighlightIndex + 0.25];
		}
    }
	targetOnEstimateMS =  trial.targetOnTimeMS;					// estimated target on time
	if (targetOnEstimateMS == 0) {								// catch trials?
		targetOnEstimateMS = [eventTime unsignedLongValue] - stimStartTimeMS;
	}
	timeIndex = ((float)targetOnEstimateMS - minTargetTimeMS) / 
							(maxTargetTimeMS - minTargetTimeMS) * kMaxTimes;
	timeIndex = MAX(0, MIN(timeIndex, kMaxTimes - 1));
	if (timeIndex >= 0) {
		[perfTimePlot setHighlightXRangeFrom:timeIndex - 0.25 to:timeIndex + 0.25];
	}
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
    long level, eot, minN, reactTimeMS, eotCode, ignoredValue, wrongValue, brokeValue, dirChangeIndex, timeIndex;
    long levels = blockStatus.changes;
	
// No update on catch trials
    
	if (trial.catchTrial == YES) {
		return;
	}
	
	dirChangeIndex = trial.orientationChangeIndex;
	
	[eventData getBytes:&eotCode];
	
// Process reaction time on correct trials only

	if (targetOnTimeMS == 0) {
		targetOnTimeMS = trial.targetOnTimeMS;				// trial.targetOnTimeMS is trial time
	}
	else {
		targetOnTimeMS -= stimStartTimeMS;					// we got a target and targetOnTimeMS is time of day
	}
	if ((eotCode == kMyEOTCorrect) & (saccadeStartTimeMS > 0)) {
		reactTimeMS = MAX(0, saccadeStartTimeMS - targetOnTimeMS);
		[[reactTimes objectAtIndex:dirChangeIndex] addValue:reactTimeMS];
		if (reactTimeMS < kMaxRT) {
			rtDist[dirChangeIndex][reactTimeMS]++;
			[hist[dirChangeIndex] setNeedsDisplay:YES];
		}
		for (level = (levels > 1) ? 1 : 0, minN = LONG_MAX; level < levels; level++) {
			minN = MIN(minN, [[reactTimes objectAtIndex:level] n]);
		}
		[reactPlot setTitle:[NSString stringWithFormat:@"Reaction Times (n >= %ld)", minN]];
		[reactPlot setNeedsDisplay:YES];
	}

// For behavior as a function of change increment, we increment the counts of different eots in a customized way.
// We want corrects and fails to add to 100%, because these are outcomes of completed trials.  Because they are
// perfectly complementary, we only display the corrects.  Ignores, breaks and wrongs (early) are
// computed to be percentages of all trials for change values (but not for times)
// because they occur before a change value is defined.   
	
	ignoredValue = wrongValue = brokeValue = 0;
	switch (eotCode) {
	case kEOTCorrect:
			[[performance[kEOTCorrect] objectAtIndex:dirChangeIndex] addValue:1];
		break;
	case kEOTFailed:
			[[performance[kEOTCorrect] objectAtIndex:dirChangeIndex] addValue:0];
		break;
	case kEOTBroke:
		brokeValue = 1;
		break;
	case kEOTWrong:
		wrongValue = 1;
		break;
	case kEOTIgnored:
		ignoredValue = 1;
		break;
	default:
		break;
	}
	if (eotCode < kEOTs) {
		for (level = 0; level < levels; level++) {
			[[performance[kEOTIgnored] objectAtIndex:level] addValue:ignoredValue];
			[[performance[kEOTBroke] objectAtIndex:level] addValue:brokeValue];
			[[performance[kEOTWrong] objectAtIndex:level] addValue:wrongValue];
		}
	}

// For performance as a function of time, we simple record events as they occurred, assigning them
// each to the time that the change would have occurred.

	if (stimStartTimeMS == 0) {
		timeIndex = -1;
	}
	else {
		timeIndex = ((float)targetOnTimeMS - minTargetTimeMS) / 
										(maxTargetTimeMS - minTargetTimeMS) * kMaxTimes;
		timeIndex = MAX(0, MIN(timeIndex, kMaxTimes - 1));
	}
	if (timeIndex >= 0) {
		for (eot = 0; eot < kEOTs; eot++) {
			[[performanceByTime[eot] objectAtIndex:timeIndex] addValue:((eot == eotCode) ? 1 : 0)];
		}
	}
    for (level = 0, minN = LONG_MAX; level < levels; level++) {
        for (eot = 0; eot < kEOTs; eot++) {
            if (eot != kEOTBroke && eot != kEOTIgnored) {
                minN = MIN(minN, [[performance[eot] objectAtIndex:level] n]);
            }
        }
    }
	[perfPlot setTitle:[NSString stringWithFormat:@"Trial Outcomes (n >= %ld)", minN]];
	[perfPlot setNeedsDisplay:YES];

	if (eotCode < kEOTs) {
		for (level = (levels > 1) ? 1 : 0; level < kMaxTimes; level++) {
			[[performanceByTime[kEOTIgnored] objectAtIndex:level] addValue:ignoredValue];
		}
	}
    for (level = (levels > 1) ? 1 : 0, minN = LONG_MAX; level < kMaxTimes; level++) {
        for (eot = 0; eot < kEOTs; eot++) {
            if (eot != kEOTBroke && eot != kEOTIgnored) {
                minN = MIN(minN, [[performanceByTime[eot] objectAtIndex:level] n]);
            }
        }
    }
	[perfTimePlot setTitle:[NSString stringWithFormat:@"Trial Outcomes (n >= %ld)", minN]];
	[perfTimePlot setNeedsDisplay:YES];
}

@end
