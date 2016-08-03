//
//  CRSDigitalOut.h
//  CRSMap
//
//  Created by Marlene Cohen on 12/6/07.
//  Copyright 2007 . All rights reserved.
//

#import "CRS.h"
#import <LablibITC18/LablibITC18.h>

@interface CRSDigitalOut : NSObject {

	LLITC18DataDevice		*digitalOutDevice;
	NSLock					*lock;

}

- (NSString *)digitalCodeDictionary:(NSString *)eventName;
- (int)getDigitalValue:(NSString *)eventName;
- (BOOL)outputEvent:(long)event withData:(long)data;
- (BOOL)outputEvent:(long)event sleepInMicrosec:(int)sleepTimeInMicrosec;
- (BOOL)outputEventName:(NSString *)eventName withData:(long)data;
- (BOOL)outputEventName:(NSString *)eventName withData:(long)data sleepInMicrosec:(int)sleepTimeInMicrosec;
@end
