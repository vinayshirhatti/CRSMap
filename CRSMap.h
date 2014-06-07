//
//  CRSMap.h
//  CRSMap
//
//  Copyright 2006. All rights reserved.
//

#import "CRS.h"
#import "CRSStateSystem.h"
#import "CRSEyeXYController.h"
#import "CRSRoundToStimCycle.h"
#import "CRSDigitalOut.h"
@class CRSMapStimTable;

@interface CRSMap:LLTaskPlugIn {

	NSMenuItem				*actionsMenuItem;
    NSWindowController 		*behaviorController;
	LLControlPanel			*controlPanel;
	NSPoint					currentEyesUnits[kEyes];
    CRSEyeXYController		*eyeXYController;				// Eye position display
	NSMenuItem				*settingsMenuItem;
    NSWindowController 		*spikeController;
    NSWindowController 		*summaryController;
	LLTaskStatus			*taskStatus;
    NSArray                 *topLevelObjects;
    NSWindowController 		*xtController;
	
	CRSMapStimTable			*mapStimTable0; 
	CRSMapStimTable			*mapStimTable1; 

    IBOutlet NSMenu			*actionsMenu;
    IBOutlet NSMenu			*settingsMenu;
	IBOutlet NSMenuItem		*runStopMenuItem;
}

- (IBAction)doFixSettings:(id)sender;
- (IBAction)doJuice:(id)sender;
- (void)doJuiceOff;
- (IBAction)doReset:(id)sender;
- (IBAction)doRFMap:(id)sender;
- (IBAction)doRunStop:(id)sender;
- (IBAction)doTaskGaborSettings:(id)sender;
- (CRSStimuli *)stimuli;
- (CRSMapStimTable *)mapStimTable0;
- (CRSMapStimTable *)mapStimTable1;
- (void)updateChangeTable;

@end
