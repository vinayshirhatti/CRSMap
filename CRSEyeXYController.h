//
//  CRSEyeXYController.h
//  CRSMap
//
//  Copyright (c) 2006. All rights reserved.
//

#import "CRSStateSystem.h"

@interface CRSEyeXYController : NSWindowController <LLDrawable> {

	NSBezierPath			*calBezierPath[kEyes];
	NSColor					*calColor;
	NSPoint					currentEyeDeg[kEyes];
 	NSAffineTransform		*degToUnits[kEyes];
	NSMutableData			*eyeXSamples[kEyes];
	NSMutableData			*eyeYSamples[kEyes];
	NSRect					eyeWindowRectDeg;
	NSColor					*fixWindowColor;
	BOOL					inTrial;
	NSColor					*respWindowColor;
	long					respWindowIndex;
	NSRect					respWindowRectDeg;
	NSLock					*sampleLock;
	TrialDesc				trial;
 	NSAffineTransform		*unitsToDeg[kEyes];
  
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
- (void)processEyeSamplePairs:(long)eyeIndex;
- (void)setEyePlotValues;
- (void)setScaleFactor:(double)factor;
- (void)updateEyeCalibration:(long)eyeIndex eventData:(NSData *)eventData;

@end
