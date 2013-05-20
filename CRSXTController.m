//
//  CRSXTController.m
//  Experiment
//
//  Window with summary information trial events.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

#import "CRS.h"
#import "CRSXTController.h"

#define kPlotBinsDefault	10
#define	kXTickSpacing		100

NSString *trialWindowVisibleKey = @"Trial Window Visible";
NSString *trialWindowZoomKey = @"Trial Window Zoom";
NSString *CRSXTAutosaveKey = @"CRSXTAutosave";

@implementation CRSXTController

- (IBAction)changeFreeze:(id)sender {

    [xtView setFreeze:[sender intValue]];
    [sender setTitle:([sender intValue]) ? @"Unfreeze" : @"Freeze"];
}

- (IBAction)changeZoom:(id)sender {

    long zoomValue;
    
    zoomValue = [[sender selectedCell] tag];
    [self setScaleFactor:zoomValue / 100.0];
    [[task defaults] setObject:[NSNumber numberWithInt:zoomValue] 
                forKey:trialWindowZoomKey];
}

- (id)init {

    if ((self = [super initWithWindowNibName:@"CRSXTController"]) != nil) {
 		[self setShouldCascadeWindows:NO];
        [self setWindowFrameAutosaveName:CRSXTAutosaveKey];
        [self window];							// Force the window to load now
    }
    return self;
}

- (void) positionZoomButton {

    NSRect scrollerRect, buttonRect;
    
    scrollerRect = [[scrollView horizontalScroller] frame];
    scrollerRect.size.width = [scrollView frame].size.width - scrollerRect.size.height - 8;
    NSDivideRect(scrollerRect, &buttonRect, &scrollerRect, 60.0, NSMaxXEdge);
    [[scrollView horizontalScroller] setFrame:scrollerRect];
    [[scrollView horizontalScroller] setNeedsDisplay:YES];
    buttonRect.origin.y += buttonRect.size.height;				// Offset because the clipRect is flipped
    buttonRect.origin = [[[self window] contentView] convertPoint:buttonRect.origin fromView:scrollView];
    [zoomButton setFrame:NSInsetRect(buttonRect, 1.0, 1.0)];
    [zoomButton setNeedsDisplay:YES];
}

- (void)processSampleData:(NSData *)data channel:(long)channel;
{
	short *pSamples;
	long sample, samples;
	
	samples = [data length] / (sizeof(short));
	pSamples = (short *)[data bytes];
	for (sample = 0; sample < samples; sample++) {
		[xtView sampleChannel:channel value:*pSamples++];
	}
}

- (void)setScaleFactor:(float)newFactor;
{
    float delta;
	NSWindow *window;
    NSSize	baseViewSize, maxSize;
	NSRect frame;
	float scaleFactor;

// Calculate the current scaling.  We can derive it from the current bounds and frame width relative to their
// original widths (which were the same (originally): baseContentViewWidthPix)

	scaleFactor = (baseContentViewWidthPix / [[scrollView contentView] bounds].size.width) /
			(baseContentViewWidthPix / [[scrollView contentView] frame].size.width);
    if (scaleFactor != newFactor) {
        delta = newFactor / scaleFactor;
       [[scrollView contentView] scaleUnitSquareToSize:NSMakeSize(delta, delta)];
        [self positionZoomButton];
        [scrollView display];
   }
   
// Always set the maxSize, because this is called at initialization

    baseViewSize = [xtView sizePix];
	window = [self window];
    [window setMaxSize:NSMakeSize(baseViewSize.width * newFactor + staticWindowFrame.width, 
            baseViewSize.height * newFactor + staticWindowFrame.height)];
	frame = [window frame];
	maxSize = [window maxSize];
	if (maxSize.width < frame.size.width || maxSize.height < frame.size.height) {
		[window setFrame:NSMakeRect(frame.origin.x, frame.origin.y, maxSize.width, maxSize.height) 
						display:YES];
	}
}
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
{	
	[[task defaults] setObject:[NSNumber numberWithBool:YES] forKey:trialWindowVisibleKey];
}


- (void)windowDidLoad;
{
    long index, defaultZoom, deltaHeight, deltaWidth;
    NSSize baseScrollFrameSize, windowFrameSize, baseViewSize;

 //   [xtView setSamplePeriodMS:kSamplePeriodMS spikeChannels:kSpikeChannels spikeTickPerMS:kTimestampTickMS];
    [xtView setDurationS:5.0];   // ?? This should be controlled by a dialog and saved in preferences. 

// Calculate the base (1x scaling) content size for the window.  We will use this for
// setting the maximum zoom size when the scale changes.
    
    baseViewSize = [xtView sizePix];											// native size of the LLXTView
    baseScrollFrameSize = [NSScrollView frameSizeForContentSize:baseViewSize	// native size of frame for LLXTView
            hasHorizontalScroller:YES hasVerticalScroller:YES borderType:[scrollView borderType]];
	deltaWidth = baseScrollFrameSize.width - [scrollView frame].size.width;		// allow for frame's current size
    deltaHeight = baseScrollFrameSize.height - [scrollView frame].size.height;
    windowFrameSize = [[self window] frame].size;
    staticWindowFrame = NSMakeSize(windowFrameSize.width + deltaWidth - baseViewSize.width, 
               windowFrameSize.height + deltaHeight - baseViewSize.height);

    [[zoomButton cell] setBordered:NO];
    [[zoomButton cell] setBezeled:YES];
    [[zoomButton cell] setFont:[NSFont labelFontOfSize:10.0]];
	baseContentViewWidthPix = [[scrollView contentView] bounds].size.width;
    defaultZoom = [[task defaults] integerForKey:trialWindowZoomKey];
    for (index = 0; index < [[zoomButton itemArray] count]; index++) {
        if ([[zoomButton itemAtIndex:index] tag] == defaultZoom) {
            [zoomButton selectItemAtIndex:index];
            [self setScaleFactor:defaultZoom / 100.0];
            break;
        }
    }
        
	[[self window] setFrameUsingName:CRSXTAutosaveKey];			// Needed when opened a second time
    if ([[task defaults] boolForKey:trialWindowVisibleKey]) {
        [[self window] makeKeyAndOrderFront:self];
    }
    else {
        [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    }
    [self positionZoomButton];							// position zoom must be after visible
    [super windowDidLoad];
}

// We use a delegate method to detect when the window has resized, and 
// adjust the postion of the zoom button when it does.

- (void) windowDidResize:(NSNotification *)aNotification {

	[self positionZoomButton];
}

- (BOOL) windowShouldClose:(NSNotification *)aNotification {

    [[self window] orderOut:self];
    [[task defaults] setObject:[NSNumber numberWithBool:NO] 
                forKey:trialWindowVisibleKey];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

// Methods related to data events follow:
/*
- (void)cueOn:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[xtView stimulusBarColor:[NSColor yellowColor] eventTime:eventTime];
	[xtView eventName:@"Cue" eventTime:eventTime];
}
*/

- (void)dataParam:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	DataParam *pParam = (DataParam *)[eventData bytes];
	
	if (strcmp((char *)&pParam->dataName, "eyeXData") == 0) {
		[xtView setSamplePeriodMS:pParam->timing];
	}
	if (strcmp((char *)&pParam->dataName, "eyeYData") == 0) {
		[xtView setSamplePeriodMS:pParam->timing];
	}
	if (strcmp((char *)&pParam->dataName, "spike0") == 0) {
		[xtView setSpikePeriodMS:pParam->timing];
	}
}

- (void)eyeXData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[self processSampleData:eventData channel:0];
}

- (void)eyeYData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[self processSampleData:eventData channel:1];
}

- (void)eyeWindow:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	FixWindowData fixWindowData;
    
	[eventData getBytes:&fixWindowData];
    [xtView eyeRect:fixWindowData.windowUnits time:[eventTime longValue]];
}

- (void)fixate:(NSData *)eventData eventTime:(NSNumber *)eventTime {
    
    [xtView eventName:@"Fixate" eventTime:eventTime];
}

- (void)leverDown:(NSData *)eventData eventTime:(NSNumber *)eventTime {
    
    [xtView eventName:@"Lever" eventTime:eventTime];
}

- (void)preStimuli:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[xtView stimulusBarColor:[NSColor whiteColor] eventTime:eventTime];
}

- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    [xtView reset:[eventTime longValue]];
}

- (void)sampleZero:(NSData *)eventData eventTime:(NSNumber *)eventTime {

   [xtView sampleZeroTimeMS:[eventTime longValue]];
}

- (void)spike:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	long spike, spikes;
	TimestampData *pSpikes;
    
	pSpikes = (TimestampData *)[eventData bytes];
	spikes = [eventData length] / sizeof(TimestampData);
	for (spike = 0; spike < spikes; spike++, pSpikes++) {
		[xtView spikeChannel:pSpikes->channel time:pSpikes->time];
	}
}

- (void) spikeZero:(NSData *)eventData eventTime:(NSNumber *)eventTime {

   [xtView spikeZeroTimeMS:[eventTime longValue]];
}

- (void)stimulus:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	StimDesc stimDesc;
	
	[eventData getBytes:&stimDesc];
	[xtView stimulusBarColor:[NSColor grayColor] eventTime:eventTime];
	if (stimDesc.stimType == kTargetStim) {
		[xtView eventName:[NSString stringWithFormat:@"Valid %.0f deg", stimDesc.directionDeg]
											eventTime:eventTime];
	}
	else if (stimDesc.stimType == kTargetStim) {
		[xtView eventName:[NSString stringWithFormat:@"Invalid %.0f deg", stimDesc.directionDeg]
											eventTime:eventTime];
	}
}

- (void)stimulusOff:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	[xtView stimulusBarColor:[NSColor whiteColor] eventTime:eventTime];
}

- (void) trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    long eotCode;
    
	[eventData getBytes:&eotCode];
	[xtView eventName:[LLStandardDataEvents trialEndName:eotCode] eventTime:eventTime];
	[xtView stimulusBarColor:[NSColor whiteColor] eventTime:eventTime];
}

- (void) trialStart:(NSData *)eventData eventTime:(NSNumber *)eventTime {

    [xtView eventName:@"Trial start" eventTime:eventTime];
}

@end
