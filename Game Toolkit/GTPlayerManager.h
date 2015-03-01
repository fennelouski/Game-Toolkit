//
//  GTPlayerManager.h
//  Game Toolkit
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GTPlayer.h"
#import "GTTimePickerView.h"

@protocol GTPlayerManagerDelegate <NSObject>

@optional
- (void)presentViewControllerFromPlayerManager:(UIViewController *)viewControllerToPresent;

@end

@protocol GTPlayerManagerTimerDelegate <NSObject>

@optional
- (void)timerStopped;

@end

@interface GTPlayerManager : NSObject

@property (nonatomic, strong) GTPlayer *currentPlayer;
@property (nonatomic, strong) GTTimePickerView *timerPicker;
@property (weak) id <GTPlayerManagerDelegate> delegate;
@property (weak) id <GTPlayerManagerTimerDelegate> timerDelegate;

- (void)makeCurrentPlayer:(GTPlayer *)player;
+ (instancetype)sharedReferenceManager;
- (NSArray *)players;
- (void)addPlayer:(GTPlayer *)player;
- (void)addPlayer:(GTPlayer *)player atIndex:(NSInteger)index;
- (void)addPlayers:(NSArray *)players;
- (BOOL)removePlayer:(GTPlayer *)player;
- (BOOL)removePlayers:(NSArray *)players;
- (GTPlayer *)playerAtIndex:(NSInteger)index;
- (void)reset;
- (void)resetScores;
- (void)updateTimers:(NSTimeInterval)time;
- (void)resetTimers:(NSTimeInterval)time;
- (BOOL)showDiceTotal;
- (void)changeShowDiceTotal:(BOOL)showDiceTotal;
- (int)numberOfDice;
- (int)numberOfDiceSides;
- (float)sizeOfDiceDots;
- (void)setNumberOfDice:(int)numberOfDice;
- (void)setNumberOfDiceSides:(int)numberOfDiceSides;
- (void)setSizeOfDiceDots:(float)sizeOfDiceDots;
- (NSArray *)diceColorNames;
- (UIColor *)diceColorForName:(NSString *)colorName;
- (UIColor *)diceColor;
- (void)setDiceColor:(NSString *)diceColorName;
- (UIColor *)diceDotsColor;
- (UIColor *)diceBorderColor;

@end
