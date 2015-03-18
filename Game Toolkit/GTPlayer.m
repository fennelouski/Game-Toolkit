//
//  GTPlayer.m
//  Game Timer
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTPlayer.h"
#import "UIColor+AppColors.h"

@implementation GTPlayer

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    
    if (self) {
        self.scoreHistory = [[NSMutableArray alloc] init];
        self.moveTimes = [[NSMutableArray alloc] init];
        self.isPendingNegative = YES;
        self.name = name;
        self.color = [UIColor randomDarkColorFromString:name];
        
        self.isPendingNegative = NO;
    }
    
    return self;
}

- (void)commitPendingScore {
    [self.scoreHistory addObject:[NSNumber numberWithInt:self.pendingScore * ((self.isPendingNegative) ? -1 : 1)]];
    self.isPendingNegative = NO;
    self.pendingScore = 0;
}

@end
