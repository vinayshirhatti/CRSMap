//
//  CRSDigitalOut.m
//  OrientationChange
//
//  Created by Marlene Cohen on 12/6/07.
//  Copyright 2007. All rights reserved.
//

#import "CRSDigitalOut.h" 

@implementation CRSDigitalOut

-(void)dealloc;
{
	[lock release];
	[super dealloc];
}

-(id) init;
{
	if ((self = [super init])) {
		digitalOutDevice = (LLITC18DataDevice *)[[task dataController] deviceWithName:@"ITC-18 1"];
		if (digitalOutDevice == nil) {
			NSRunAlertPanel(@"CRSDigitalOut",  @"Can't find data device named \"%@\", trying ITC-18 instead.", 
						@"OK", nil, nil, @"ITC-18 1");
			digitalOutDevice = (LLITC18DataDevice *)[[task dataController] deviceWithName:@"ITC-18"];
			if (digitalOutDevice == nil) {
				NSRunAlertPanel(@"CRSMap",  @"Can't find data device named \"%@\" (Quitting)", 
							@"OK", nil, nil, @"ITC-18");
				//exit(0);
			}
		}
		lock = [[NSLock alloc] init];
	}
	return self;
}

- (BOOL)outputEvent:(long)event withData:(long)data;
{
	if (digitalOutDevice == nil) {
		return NO;
	}
	[lock lock];
	[digitalOutDevice digitalOutputBits:(event | 0x8000)];
	[digitalOutDevice digitalOutputBits:(data & 0x7fff)];
	[lock unlock];
	NSLog(@"Digital out %ld %ld", (event | 0x8000), (data & 0x7fff));
	return YES;
}

- (BOOL)outputEventName:(NSString *)eventName withData:(long)data;
{
	
	if (digitalOutDevice == nil) {
		return NO;
	}
	[lock lock];
	
	if ([eventName isEqualTo:@"attendLoc"] || [eventName isEqualTo:@"AL"] )
		[digitalOutDevice digitalOutputBits:(0x414C | 0x8000)];
	else if ([eventName isEqualTo:@"azimuth"] || [eventName isEqualTo:@"AZ"] ) // New for CRS
		[digitalOutDevice digitalOutputBits:(0x415A | 0x8000)];
	else if ([eventName isEqualTo:@"break"] || [eventName isEqualTo:@"BR"] )
		[digitalOutDevice digitalOutputBits:(0x4252 | 0x8000)];
	else if ([eventName isEqualTo:@"contrast"] || [eventName isEqualTo:@"CO"] )
		[digitalOutDevice digitalOutputBits:(0x434F | 0x8000)];
	else if ([eventName isEqualTo:@"catchTrial"] || [eventName isEqualTo:@"CT"] )
		[digitalOutDevice digitalOutputBits:(0x4354 | 0x8000)];
	else if ([eventName isEqualTo:@"eccentricity"] || [eventName isEqualTo:@"EC"] )
		[digitalOutDevice digitalOutputBits:(0x4543 | 0x8000)];
	else if ([eventName isEqualTo:@"elevation"] || [eventName isEqualTo:@"EL"] ) // New for CRS
		[digitalOutDevice digitalOutputBits:(0x454C | 0x8000)];
	else if ([eventName isEqualTo:@"fixate"] || [eventName isEqualTo:@"FI"] )
		[digitalOutDevice digitalOutputBits:(0x4649 | 0x8000)];
	else if ([eventName isEqualTo:@"fixOn"] || [eventName isEqualTo:@"FO"] )
		[digitalOutDevice digitalOutputBits:(0x464F | 0x8000)];
	else if ([eventName isEqualTo:@"instructTrial"] || [eventName isEqualTo:@"IT"] )
		[digitalOutDevice digitalOutputBits:(0x4954 | 0x8000)];
	else if ([eventName isEqualTo:@"mapping0"] || [eventName isEqualTo:@"M0"] ) // New for CRS
		[digitalOutDevice digitalOutputBits:(0x4D30 | 0x8000)];
	else if ([eventName isEqualTo:@"mapping1"] || [eventName isEqualTo:@"M1"] ) // New for CRS
		[digitalOutDevice digitalOutputBits:(0x4D31 | 0x8000)];
	else if ([eventName isEqualTo:@"stimulusOn"] || [eventName isEqualTo:@"ON"] )
		[digitalOutDevice digitalOutputBits:(0x4F4E | 0x8000)];
	else if ([eventName isEqualTo:@"stimulusOff"] || [eventName isEqualTo:@"OF"] )
		[digitalOutDevice digitalOutputBits:(0x4F46 | 0x8000)];
	else if ([eventName isEqualTo:@"orientation"] || [eventName isEqualTo:@"OR"] )
		[digitalOutDevice digitalOutputBits:(0x4F52 | 0x8000)];
	else if ([eventName isEqualTo:@"polarAngle"] || [eventName isEqualTo:@"PA"] )
		[digitalOutDevice digitalOutputBits:(0x5041 | 0x8000)];
	else if ([eventName isEqualTo:@"radius"] || [eventName isEqualTo:@"RA"] )
		[digitalOutDevice digitalOutputBits:(0x5241 | 0x8000)];
	else if ([eventName isEqualTo:@"saccade"] || [eventName isEqualTo:@"SA"] )
		[digitalOutDevice digitalOutputBits:(0x5341 | 0x8000)];
	else if ([eventName isEqualTo:@"spatialFreq"] || [eventName isEqualTo:@"SF"] )
		[digitalOutDevice digitalOutputBits:(0x5346 | 0x8000)];
	else if ([eventName isEqualTo:@"sigma"] || [eventName isEqualTo:@"SI"] )
		[digitalOutDevice digitalOutputBits:(0x5349 | 0x8000)];
	else if ([eventName isEqualTo:@"stimType"] || [eventName isEqualTo:@"ST"] ) // New for CRS
		[digitalOutDevice digitalOutputBits:(0x5354 | 0x8000)];
	else if ([eventName isEqualTo:@"trialCertify"] || [eventName isEqualTo:@"TC"] )
		[digitalOutDevice digitalOutputBits:(0x5443 | 0x8000)];
	else if ([eventName isEqualTo:@"trialEnd"] || [eventName isEqualTo:@"TE"] )
		[digitalOutDevice digitalOutputBits:(0x5445 | 0x8000)];
	else if ([eventName isEqualTo:@"temporalFreq"] || [eventName isEqualTo:@"TF"] )
		[digitalOutDevice digitalOutputBits:(0x5446 | 0x8000)];
	else if ([eventName isEqualTo:@"taskGabor"] || [eventName isEqualTo:@"TG"] ) // New for CRS
		[digitalOutDevice digitalOutputBits:(0x5447 | 0x8000)];
	else if ([eventName isEqualTo:@"trialStart"] || [eventName isEqualTo:@"TS"] )
		[digitalOutDevice digitalOutputBits:(0x5453 | 0x8000)];
	else if ([eventName isEqualTo:@"type0"] || [eventName isEqualTo:@"T0"] )
		[digitalOutDevice digitalOutputBits:(0x5430 | 0x8000)];
	else if ([eventName isEqualTo:@"type1"] || [eventName isEqualTo:@"T1"] )
		[digitalOutDevice digitalOutputBits:(0x5431 | 0x8000)];
	
	else
		NSRunAlertPanel(@"CRSDigitalOut",  @"Can't find digital event named \"%@\".",
						@"OK", nil, nil, eventName);
	
	
	[digitalOutDevice digitalOutputBits:(data & 0x7fff)];
	[lock unlock];
	return YES;
}

@end
