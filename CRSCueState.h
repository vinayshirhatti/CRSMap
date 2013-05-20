//
//  CRSCueState.h
//  OrientationChange
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "CRSStateSystem.h"

@interface CRSCueState : NSObject {

	long			cueMS;
	NSTimeInterval	expireTime;
}

@end
