//
//  CRSEyeXYController.h
//  CRSMap
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSStateSystem.h"

@interface CRSEyeXYController : NSWindowController <LLDrawable> {

	NSBezierPath			*calBezierPath;
	NSColor					*calColor;
	NSPoint					currentEyeDeg;
 	NSAffineTransform		*degToUnits;
	NSMutableData			*eyeXSamples;
	NSMutableData			*eyeYSamples;
	NSRect					eyeWindowRectDeg;
	NSColor					*fixWindowColor;
	BOOL					inTrial;
	NSColor					*respWindowColor;
	long					respWindowIndex;
	NSRect					respWindowRectDeg;
	NSLock					*sampleLock;
	TrialDesc				trial;
 	NSAffineTransform		*unitsToDeg;
  
    IBOutlet LLEyeXYView 	*eyePlot;
    IBOutlet NSScrollView 	*scrollView;
    IBOutlet NSSlider		*slider;
    IBOutlet NSPanel		*optionsSheet;
}

- (IBAction)centerDisplay:(id)sender;
- (IBAction)changeZoom:(id)sender;
- (IBAction)doOptions:(id)sender;
- (IBAction)endOptionSheet:(id)sender;

- (void)deactivate;
- (void)processEyeSamplePairs;
- (void)setEyePlotValues;
- (void)setScaleFactor:(double)factor;

@end
