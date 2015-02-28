//
//  GTPlayer.m
//  Game Timer
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTPlayer.h"

@implementation GTPlayer

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.scoreHistory = [[NSMutableArray alloc] init];
        self.moveTimes = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)commitPendingScore {
    [self.scoreHistory addObject:[NSNumber numberWithInt:self.pendingScore]];
    self.pendingScore = 0;
}

@end
