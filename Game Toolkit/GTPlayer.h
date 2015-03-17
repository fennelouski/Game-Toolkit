//
//  GTPlayer.h
//  Game Timer
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GTPlayer : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSDate *mostRecentStartTime;
@property (nonatomic, strong) NSMutableArray *moveTimes;
@property (nonatomic, strong) UIColor *color;
@property BOOL isTurn;
@property NSTimeInterval timeRemaining;
@property (nonatomic, strong) NSMutableArray *scoreHistory;
@property int currentScore, pendingScore;
@property BOOL isPendingNegative;
@property CGPoint point;


- (instancetype)initWithName:(NSString *)name;
- (void)commitPendingScore;

@end
