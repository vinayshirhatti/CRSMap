//
//  CRSRoundToStimCycle.m
//  CRSMap
//
//  Created by Incheol Kang on 3/6/07.
//  Copyright 2007. All rights reserved.
//

#import "CRS.h"
#import "CRSRoundToStimCycle.h"

@implementation CRSRoundToStimCycle

+ (Class)transformedValueClass;
{ 
	return [NSNumber class]; 
}

+ (BOOL)allowsReverseTransformation;
{
	return YES;
}

- (id)reverseTransformedValue:(id)value;
{
	long stimulusMS, interstimMS;
	float output;
	
	stimulusMS = [[task defaults] integerForKey:CRSStimDurationMSKey]; 
	interstimMS = [[task defaults] integerForKey:CRSInterstimMSKey];
	
	output = round((float)[value longValue] / (stimulusMS + interstimMS)) * (stimulusMS + interstimMS);
    return [NSNumber numberWithLong:output];
}

- (id)transformedValue:(id)value;
{
	long output;
	output = [value longValue];
	return [NSNumber numberWithLong:output];
}

@end
