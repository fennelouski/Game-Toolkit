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
        for (int i = 0; i < 15; i++) {
            int randomScore = arc4random()%30 + arc4random()%2 + arc4random()%5%4%3%2 * 40 - 5;
            self.pendingScore = randomScore;
            [self commitPendingScore];
        }
    }
    
    return self;
}

- (void)commitPendingScore {
    [self.scoreHistory addObject:[NSNumber numberWithInt:self.pendingScore * ((self.isPendingNegative) ? -1 : 1)]];
    self.isPendingNegative = NO;
    self.pendingScore = 0;
}

@end
