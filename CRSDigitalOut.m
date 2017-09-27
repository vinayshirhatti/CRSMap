//
//  CRSDigitalOut.m
//  OrientationChange
//
//  Created by Marlene Cohen on 12/6/07.
//  Copyright 2007. All rights reserved.

//  20/5/13. Supratim Ray
//  Including option to control juice system as well as send digital codes using a single ITC.

//  Notes
//  Each digital code has two letters. We send the ascii value of each letter using 7 bits each. The first bit (least significant) is used for controlling the reward system. The 16th bit is used to indicate a code (rather than a data value).

//  We can actually make a code using only 12 bits (5 bits for the first letter+6 bits for the second+1 bit to indicate code versus data), which will leave us with 4 bits for controlling a device (like the juice reward system). However, 12 bits of data are not enough (we get values only upto -2048 to 2048). So we use 14 bits for code/data (range: -8192 to 8192) and just a single bit (LSB) for controlling the juice.

//  doJuice method in CRSMap.m (used to control the reward system) uses the digitalOutputBitsOff method, therefore putting the first bit to zero to turn the juice system on. To be consistent, we keep the first bit high for any code/data value, making sure that the juice is not turned on. Also, we use digitalOutputBits, not digitalOutputBitsOff, for both code/value and reward control, to make sure that the precise 16 bit code/data is put in the digital stream.

//  In general, we should avoid pressing the juice button because it may interfere with the digital code/value transmission. In CRSEndtrialState, digital codes are put before turning the juice on/off because otherwise they interfere with each other.

#import "CRSDigitalOut.h" 

@implementation CRSDigitalOut

-(void)dealloc;
{
	[lock release];
	[super dealloc];
}

- (NSString *)digitalCodeDictionary:(NSString *)eventName;
{
    NSString *thisEventName = nil;
    
    if ([eventName isEqualTo:@"attendLoc"] || [eventName isEqualTo:@"AL"] )
        thisEventName = @"AL";
	else if ([eventName isEqualTo:@"azimuth"] || [eventName isEqualTo:@"AZ"] )
		thisEventName = @"AZ";
	else if ([eventName isEqualTo:@"break"] || [eventName isEqualTo:@"BR"] )
		thisEventName = @"BR";
	else if ([eventName isEqualTo:@"contrast"] || [eventName isEqualTo:@"CO"] )
		thisEventName = @"CO";
	else if ([eventName isEqualTo:@"catchTrial"] || [eventName isEqualTo:@"CT"] )
		thisEventName = @"CT";
	else if ([eventName isEqualTo:@"eccentricity"] || [eventName isEqualTo:@"EC"] )
		thisEventName = @"EC";
	else if ([eventName isEqualTo:@"elevation"] || [eventName isEqualTo:@"EL"] )
		thisEventName = @"EL";
	else if ([eventName isEqualTo:@"fixate"] || [eventName isEqualTo:@"FI"] )
		thisEventName = @"FI";
	else if ([eventName isEqualTo:@"fixOn"] || [eventName isEqualTo:@"FO"] )
		thisEventName = @"FO";
	else if ([eventName isEqualTo:@"instructTrial"] || [eventName isEqualTo:@"IT"] )
		thisEventName = @"IT";
    else if ([eventName isEqualTo:@"mapping0"] || [eventName isEqualTo:@"M0"] )
		thisEventName = @"M0";
	else if ([eventName isEqualTo:@"mapping1"] || [eventName isEqualTo:@"M1"] )
		thisEventName = @"M1";
    else if ([eventName isEqualTo:@"mapping2"] || [eventName isEqualTo:@"M2"] )
		thisEventName = @"M2";
    else if ([eventName isEqualTo:@"stimulusOn"] || [eventName isEqualTo:@"ON"] )
		thisEventName = @"ON";
	else if ([eventName isEqualTo:@"stimulusOff"] || [eventName isEqualTo:@"OF"] )
		thisEventName = @"OF";
	else if ([eventName isEqualTo:@"orientation"] || [eventName isEqualTo:@"OR"] )
		thisEventName = @"OR";
	else if ([eventName isEqualTo:@"polarAngle"] || [eventName isEqualTo:@"PA"] )
		thisEventName = @"PA";
	else if ([eventName isEqualTo:@"radius"] || [eventName isEqualTo:@"RA"] )
		thisEventName = @"RA";
	else if ([eventName isEqualTo:@"saccade"] || [eventName isEqualTo:@"SA"] )
		thisEventName = @"SA";
	else if ([eventName isEqualTo:@"spatialFreq"] || [eventName isEqualTo:@"SF"] )
		thisEventName = @"SF";
	else if ([eventName isEqualTo:@"sigma"] || [eventName isEqualTo:@"SI"] )
		thisEventName = @"SI";
	else if ([eventName isEqualTo:@"stimType"] || [eventName isEqualTo:@"ST"] )
		thisEventName = @"ST";
	else if ([eventName isEqualTo:@"trialCertify"] || [eventName isEqualTo:@"TC"] )
		thisEventName = @"TC";
	else if ([eventName isEqualTo:@"trialEnd"] || [eventName isEqualTo:@"TE"] )
		thisEventName = @"TE";
	else if ([eventName isEqualTo:@"temporalFreq"] || [eventName isEqualTo:@"TF"] )
		thisEventName = @"TF";
	else if ([eventName isEqualTo:@"taskGabor"] || [eventName isEqualTo:@"TG"] )
		thisEventName = @"TG";
    else if ([eventName isEqualTo:@"trialStart"] || [eventName isEqualTo:@"TS"] )
		thisEventName = @"TS";
	else if ([eventName isEqualTo:@"type0"] || [eventName isEqualTo:@"T0"] )
		thisEventName = @"T0";
	else if ([eventName isEqualTo:@"type1"] || [eventName isEqualTo:@"T1"] )
		thisEventName = @"T1";
    else if ([eventName isEqualTo:@"spatialPhase"] || [eventName isEqualTo:@"SP"] )
        thisEventName = @"SP";
    else if ([eventName isEqualTo:@"protocolNumber"] || [eventName isEqualTo:@"PN"] )
        thisEventName = @"PN";
    else if ([eventName isEqualTo:@"lagGaborsMS"] || [eventName isEqualTo:@"LG"] )
        thisEventName = @"LG";
	else
        thisEventName = @"";
//		NSRunAlertPanel(@"CRSDigitalOut",  @"Can't find digital event named \"%@\".",
//						@"OK", nil, nil, eventName);

    
    return thisEventName;
}

- (int)getDigitalValue:(NSString *)eventName;
{
    int val, val0, val1;
    
    val0 = [eventName characterAtIndex:0];
    val1 = [eventName characterAtIndex:1];
 
/*  Scheme for only 12 bits. Not used
 
    if (val0<65 || val0>90)
        NSLog(@"First letter of the digital code must be between capital A-Z");
    
    if (val1<48 || val1>90)
        NSLog(@"Second letter of the digital code must be either between capital A-Z or a number between 0-9");
        
    val = ((1024*(val0-65) + 16*(val1-48)) | 0x8001); // Use 5 bits (10, 11, 12, 13 and 14th) for the first and 6 bits (4, 5, 6, 7, 8 and 9) for the second letter. Bits 0-3 are reserved for controlling other devices. Bit 15 indicates that this is a digital code (1), not data (0).
*/
 
// Because each character has an ascii value less than 127, it can be represented using 7 bits. We leave 0th bit (LSB) for reward, 1-7 for second letter, 8-14 for the first letter, and set 15th bit to 1 to indicate a digital code (not a value)
    
    val = ((256*val0+2*val1) | 0x8001);
    return val;
}


-(id) init;
{
	if ((self = [super init])) {
		digitalOutDevice = (LLITC18DataDevice *)[[task dataController] deviceWithName:@"ITC-18 1"];
		if (digitalOutDevice == nil) {
//			NSRunAlertPanel(@"CRSDigitalOut",  @"Can't find data device named \"%@\", trying ITC-18 instead.",
//						@"OK", nil, nil, @"ITC-18 1");
			digitalOutDevice = (LLITC18DataDevice *)[[task dataController] deviceWithName:@"ITC-18"];
			if (digitalOutDevice == nil) {
//				NSRunAlertPanel(@"CRSMap",  @"Can't find data device named \"%@\" (Quitting)",
//							@"OK", nil, nil, @"ITC-18");
				//exit(0);
			}
		}
		lock = [[NSLock alloc] init];
	}
	return self;
}

- (BOOL)outputEvent:(long)event withData:(long)data;
{
    BOOL useSingleITC18;
    
	if (digitalOutDevice == nil) {
		return NO;
	}
	[lock lock];
	
    useSingleITC18 = [[task defaults] boolForKey:CRSUseSingleITC18Key];
    
    if (useSingleITC18) {
        [[task dataController] digitalOutputBits:((event | 0x8001))];
        
        if ((data>8192) || (data<-8192)) {
            NSLog(@"Event: %ld, actual dat val: %ld is out of range, val sent: %ld",event, data, (2*data+1 & 0x7fff));
        }
        [[task dataController] digitalOutputBits:((2*data+1) & 0x7fff)];
	}
    else {
        [digitalOutDevice digitalOutputBits:(event | 0x8000)];
        [digitalOutDevice digitalOutputBits:(data & 0x7fff)];
        //NSLog(@"Digital out %ld %ld", (event | 0x8000), (data & 0x7fff));
    }
    
    [lock unlock];
	
	return YES;
}

- (BOOL)outputEvent:(long)event sleepInMicrosec:(int)sleepTimeInMicrosec;
{
    
    if (digitalOutDevice == nil) {
        return NO;
    }
    [lock lock];
    
    [[task dataController] digitalOutputBits:((event | 0x8001))];
    if (sleepTimeInMicrosec>0)
        usleep(sleepTimeInMicrosec);
    
    [lock unlock];
    return YES;
}

- (BOOL)outputEventName:(NSString *)eventName withData:(long)data;
{
    [self outputEventName:eventName withData:data sleepInMicrosec:0];
    return YES;
}

- (BOOL)outputEventName:(NSString *)eventName withData:(long)data sleepInMicrosec:(int)sleepTimeInMicrosec;
{
    NSString *thisEventName;
	BOOL useSingleITC18;
    
	if (digitalOutDevice == nil) {
		return NO;
	}
	[lock lock];
	
    thisEventName = [self digitalCodeDictionary:eventName];
    useSingleITC18 = [[task defaults] boolForKey:CRSUseSingleITC18Key];
    
    if (useSingleITC18) {
        
        [[task dataController] digitalOutputBits:[self getDigitalValue:thisEventName]];
        
        if ((data>8192) || (data<-8192)) {
            NSLog(@"Event: %@, actual dat val: %ld is out of range, val sent: %ld",thisEventName,data, (2*data+1 & 0x7fff));
        }
        if (sleepTimeInMicrosec>0)
            usleep(sleepTimeInMicrosec);
        [[task dataController] digitalOutputBits:((2*data+1) & 0x7fff)];
        if (sleepTimeInMicrosec>0)
            usleep(sleepTimeInMicrosec);
	}
    else {
        [digitalOutDevice digitalOutputBits:[self getDigitalValue:thisEventName]];
        if (sleepTimeInMicrosec>0)
            usleep(sleepTimeInMicrosec);
        [digitalOutDevice digitalOutputBits:(data & 0x7fff)];
        if (sleepTimeInMicrosec>0)
            usleep(sleepTimeInMicrosec);
    }
	[lock unlock];
    //	NSLog(@"Digital out %ld %ld", (event | 0x8000), (data & 0x7fff));
	return YES;
}


@end
