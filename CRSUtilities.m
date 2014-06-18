//
//  CRSUtilities.m
//  CRSMap
//
//  Created by Bram on 4/18/13.
//
//

#import "CRSUtilities.h"

enum {kUseLeftEye = 0, kUseRightEye, kUseBinocular};

NSString *CRSEyeToUseKey = @"CRSEyeToUse";

@implementation CRSUtilities

+ (BOOL)inWindow:(LLEyeWindow *)window;
{
    BOOL inWindow = NO;
    
    switch ([[task defaults] integerForKey:CRSEyeToUseKey]) {
        case kUseLeftEye:
        default:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kLeftEye]];
            break;
        case kUseRightEye:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kRightEye]];
            break;
        case kUseBinocular:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kLeftEye]] &&
            [window inWindowDeg:([task currentEyesDeg])[kRightEye]];
            break;
    }
    return inWindow;
}


@end
