//
//  CRSEyeXYController.m
//  Experiment
//
//  XY Display of eye position.
//
//  Copyright (c) 2006. All rights reserved.
//

#define NoGlobals

#import "CRSEyeXYController.h"

#define kCircleRadiusDeg	0.15
#define kCrossArmDeg		0.25
#define kLineWidthDeg		0.02

NSString *CRSEyeXYDoGridKey = @"CRSEyeXYDoGrid";
NSString *CRSEyeXYDoTicksKey = @"CRSEyeXYDoTicks";
NSString *CRSEyeXYSamplesSavedKey = @"CRSEyeXYSamplesSaved";
NSString *CRSEyeXYDotSizeDegKey = @"CRSEyeXYDotSizeDeg";
NSString *CRSEyeXYDrawCalKey = @"CRSEyeXYDrawCal";
NSString *CRSEyeXYEyeColorKey = @"CRSEyeXYEyeColor";
NSString *CRSEyeXYFadeDotsKey = @"CRSEyeXYFadeDots";
NSString *CRSEyeXYGridDegKey = @"CRSEyeXYGridDeg";
NSString *CRSEyeXYHScrollKey = @"CRSEyeXYHScroll";
NSString *CRSEyeXYMagKey = @"CRSEyeXYMag";
NSString *CRSEyeXYOneInNKey = @"CRSEyeXYOneInN";
NSString *CRSEyeXYVScrollKey = @"CRSEyeXYVScroll";
NSString *CRSEyeXYTickDegKey = @"CRSEyeXYTickDeg";
NSString *CRSEyeXYWindowVisibleKey = @"CRSEyeXYWindowVisible";

NSString *CRSXYAutosaveKey = @"CRSXYAutosave";

@implementation CRSEyeXYController

- (IBAction)centerDisplay:(id)sender {

    [eyePlot centerDisplay];
}

- (IBAction)changeZoom:(id)sender {

    [self setScaleFactor:[sender floatValue]];
}

// Prepare to be destroyed.  This odd method is needed because we increased our retainCount when we added
// ourselves to eyePlot (in windowDidLoad).  Owing to that increment, the object that created us will never
// get us to a retainCount of zero when it releases us.  For that reason, we need this method as a route
// for our creating object to get us to get us released from eyePlot and prepared to be fully released.

- (void)deactivate;
{
	[eyePlot removeDrawable:self];			// Remove ourselves, lowering our retainCount;
	[self close];							// clean up
}

- (void) dealloc;
{
	NSRect r;

	r = [eyePlot visibleRect];
	[[task defaults] setFloat:r.origin.x forKey:CRSEyeXYHScrollKey];
	[[task defaults] setFloat:r.origin.y forKey:CRSEyeXYVScrollKey];
	[fixWindowColor release];
	[respWindowColor release];
	[calColor release];
	[unitsToDeg release];
	[degToUnits release];
	[calBezierPath release];
	[eyeXSamples release];
	[eyeYSamples release];
	[sampleLock release];
    [super dealloc];
}

- (IBAction) doOptions:(id)sender {

    [NSApp beginSheet:optionsSheet modalForWindow:[self window] modalDelegate:self
        didEndSelector:nil contextInfo:nil];
}

// Because we have added ourself as an LLDrawable to the eyePlot, this draw method
// will be called every time eyePlot redraws.  This allows us to put in any specific
// windows, etc that we want to display.

- (void)draw
{
	float defaultLineWidth = [NSBezierPath defaultLineWidth];

// Draw the fixation window

	if (NSPointInRect(currentEyeDeg, eyeWindowRectDeg)) {
		[[fixWindowColor highlightWithLevel:0.90] set];
		[NSBezierPath fillRect:eyeWindowRectDeg];
	}
	[fixWindowColor set];
	[NSBezierPath setDefaultLineWidth:defaultLineWidth * 4.0]; 
	[NSBezierPath strokeRect:eyeWindowRectDeg];

// Draw the response windows

	if (NSPointInRect(currentEyeDeg, respWindowRectDeg)) {
		[[respWindowColor highlightWithLevel:0.80] set];
		[NSBezierPath fillRect:respWindowRectDeg];
	}
	[respWindowColor set];
	[NSBezierPath setDefaultLineWidth:(defaultLineWidth * ((inTrial) ? 4.0 : 1.0))]; 
	[NSBezierPath strokeRect:respWindowRectDeg];
	[NSBezierPath setDefaultLineWidth:defaultLineWidth];
	
// Draw the calibration for the fixation window
	
	if ([[task defaults] integerForKey:CRSEyeXYDrawCalKey]) {
		[calColor set];
		[calBezierPath stroke];
	}
}

- (IBAction) endOptionSheet:(id)sender {

	[self setEyePlotValues];
    [optionsSheet orderOut:sender];
    [NSApp endSheet:optionsSheet returnCode:1];
}

- (id)init {

    if ((self = [super initWithWindowNibName:@"CRSEyeXYController"]) != nil) {
		[[task defaults] registerDefaults:
					[NSDictionary dictionaryWithObject:
					[NSArchiver archivedDataWithRootObject:[NSColor blueColor]] 
					forKey:CRSEyeXYEyeColorKey]];
		eyeXSamples = [[NSMutableData alloc] init];
		eyeYSamples = [[NSMutableData alloc] init];
		sampleLock = [[NSLock alloc] init];
 		[self setShouldCascadeWindows:NO];
        [self setWindowFrameAutosaveName:CRSXYAutosaveKey];
        [self window];							// Force the window to load now
    }
    return self;
}

- (void)processEyeSamplePairs;
{
	NSEnumerator *enumerator;
	NSArray *pairs;
	NSValue *value;
	
	[sampleLock lock];
	pairs = [LLDataUtil pairXSamples:eyeXSamples withYSamples:eyeYSamples];
	[sampleLock unlock];
	if (pairs != nil) {
		enumerator = [pairs objectEnumerator];
		while ((value = [enumerator nextObject])) {
			currentEyeDeg = [unitsToDeg transformPoint:[value pointValue]];
			[eyePlot addSample:currentEyeDeg];
		}
	}
}

- (void)setEyePlotValues {

	[eyePlot setDotSizeDeg:[[task defaults] floatForKey:CRSEyeXYDotSizeDegKey]];
	[eyePlot setDotFade:[[task defaults] boolForKey:CRSEyeXYFadeDotsKey]];
    [eyePlot setEyeColor:[NSUnarchiver 
                unarchiveObjectWithData:[[task defaults] 
                objectForKey:CRSEyeXYEyeColorKey]]];
	[eyePlot setGrid:[[task defaults] boolForKey:CRSEyeXYDoGridKey]];
	[eyePlot setGridDeg:[[task defaults] floatForKey:CRSEyeXYGridDegKey]];
	[eyePlot setOneInN:[[task defaults] integerForKey:CRSEyeXYOneInNKey]];
	[eyePlot setTicks:[[task defaults] boolForKey:CRSEyeXYDoTicksKey]];
	[eyePlot setTickDeg:[[task defaults] floatForKey:CRSEyeXYTickDegKey]];
	[eyePlot setSamplesToSave:[[task defaults] integerForKey:CRSEyeXYSamplesSavedKey]];
}

// Change the scaling factor for the view
// Because scaleUnitSquareToSize acts on the current scaling, not the original scaling,
// we have to work out the current scaling using the relative scaling of the eyePlot and
// its superview

- (void) setScaleFactor:(double)factor;
{
	float currentFactor, applyFactor;
  
	currentFactor = [eyePlot bounds].size.width / [[eyePlot superview] bounds].size.width;
	applyFactor = factor / currentFactor;
	[[scrollView contentView] scaleUnitSquareToSize:NSMakeSize(applyFactor, applyFactor)];
	[self centerDisplay:self];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification;
{
	[[task defaults] setObject:[NSNumber numberWithBool:YES] forKey:CRSEyeXYWindowVisibleKey];
}

// Initialization is handled through the following delegate method for our window 

- (void) windowDidLoad;
{
    calColor = [[NSColor colorWithDeviceRed:0.60 green:0.45 blue:0.15 alpha:1.0] retain];
    fixWindowColor = [[NSColor colorWithDeviceRed:0.00 green:0.00 blue:1.00 alpha:1.0] retain];
    respWindowColor = [[NSColor colorWithDeviceRed:0.95 green:0.55 blue:0.50 alpha:1.0] retain];
	unitsToDeg = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
	degToUnits = [[NSAffineTransform alloc] initWithTransform:[NSAffineTransform transform]];
    [self setScaleFactor:[[task defaults] floatForKey:CRSEyeXYMagKey]];
	[self setEyePlotValues];
    [eyePlot addDrawable:self];
	[self changeZoom:slider];
	[eyePlot scrollPoint:NSMakePoint(
            [[task defaults] floatForKey:CRSEyeXYHScrollKey], 
            [[task defaults] floatForKey:CRSEyeXYVScrollKey])];
	
	[[self window] setFrameUsingName:CRSXYAutosaveKey];			// Needed when opened a second time
    if ([[task defaults] boolForKey:CRSEyeXYWindowVisibleKey]) {
        [[self window] makeKeyAndOrderFront:self];
    }
    else {
        [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    }

    [scrollView setPostsBoundsChangedNotifications:YES];
    [super windowDidLoad];
}

- (BOOL) windowShouldClose:(NSNotification *)aNotification;
{
    [[self window] orderOut:self];
    [[task defaults] setObject:[NSNumber numberWithBool:NO] forKey:CRSEyeXYWindowVisibleKey];
    [NSApp addWindowsItem:[self window] title:[[self window] title] filename:NO];
    return NO;
}

// Methods related to data events follow:

// Update the display of the calibration in the xy window.  We get the calibration structure
// and use it to construct crossing lines that mark the current calibration.

- (void)eyeCalibration:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	LLEyeCalibrationData cal;

	[eventData getBytes:&cal];
	[unitsToDeg setTransformStruct:cal.calibration];
	[degToUnits setTransformStruct:cal.calibration];
	[degToUnits invert];

	[calBezierPath autorelease];
	calBezierPath = [LLEyeCalibrator bezierPathForCalibration:cal];
	[calBezierPath retain];
}

- (void)eyeWindow:(NSData *)eventData eventTime:(NSNumber *)eventTime {

	FixWindowData fixWindowData;
    
	[eventData getBytes:&fixWindowData];
	eyeWindowRectDeg = fixWindowData.windowDeg;
    [eyePlot setNeedsDisplay:YES];
}

// Just save the x eye data until we get the corresponding y eye data

- (void)eyeXData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[sampleLock lock];
	[eyeXSamples appendData:eventData];
	[sampleLock unlock];
	[self processEyeSamplePairs];
}

- (void)eyeYData:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[sampleLock lock];
	[eyeYSamples appendData:eventData];
	[sampleLock unlock];
	[self processEyeSamplePairs];
}

- (void)responseWindow:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	FixWindowData respWindowData;
    
	[eventData getBytes:&respWindowData];
	respWindowRectDeg = respWindowData.windowDeg;
}

- (void)trial:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	[eventData getBytes:&trial];
    inTrial = YES;
	respWindowIndex = kAttend0;
}

- (void)trialEnd:(NSData *)eventData eventTime:(NSNumber *)eventTime;
{
	inTrial = NO;
}

@end
