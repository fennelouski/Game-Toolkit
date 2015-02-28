//
//  BRReferenceManager.h
//  Bachelor Reference Manager
//
//  Created by Developer Nathan on 1/8/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BRBachelorette.h"

@interface BRReferenceManager : NSObject

+ (instancetype)sharedReferenceManager;
- (BRReferenceManager *)bachelorForRow:(int)row;
- (BRBachelorette *)star;
- (NSArray *)bachelors;
- (NSArray *)myTeam;
- (NSArray *)stillIn;

@end
