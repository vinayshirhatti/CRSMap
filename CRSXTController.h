//
//  CRSXTController.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

extern NSString	*trialWindowVisibleKey;
extern NSString	*trialWindowZoomKey;

@interface CRSXTController : NSWindowController {

	float			baseContentViewWidthPix;				// original width of view frame (and bounds)
    NSSize			staticWindowFrame;

    IBOutlet		NSScrollView *scrollView;
    IBOutlet		LLXTView *xtView;
    IBOutlet		NSPopUpButton *zoomButton;
}

- (IBAction)changeFreeze:(id)sender;
- (IBAction)changeZoom:(id)sender;
- (void)positionZoomButton;
- (void)processSampleData:(NSData *)data channel:(long)channel;
- (void)setScaleFactor:(float)factor;
- (void)reset:(NSData *)eventData eventTime:(NSNumber *)eventTime;

@end
