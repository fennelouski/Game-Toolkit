//
//  GTPlayerManager.m
//  Game Toolkit
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTPlayerManager.h"
#import "GTTimePickerView.h"
#import <AudioToolbox/AudioToolbox.h>
#import "UIColor+AppColors.h"
#import "NSString+AppFunctions.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define MINIMUM_NUMBER_OF_PLAYERS 2
#define MAX_SIZE_OF_DICE_DOTS 5.5f

#define SIZE_OF_DICE_DOTS_KEY @"5123 0F D1C3 D0Ts"
#define NUMBER_OF_DICE_SIDES_KEY @"Number 0f D1ce S1D35"
#define NUMBER_OF_DICE_KEY @"Number 0f D1ce"
#define COLOR_OF_DICE_KEY @"C0L0UR 0F D1C3"
#define PLAY_ALARM_TIME_KEY @"PL4Y 4l4rm T1m3"

@implementation GTPlayerManager {
    NSMutableArray *_players;
    BOOL _isTimerRunning;
    BOOL _showDiceTotal;
    int _numberOfDice, _numberOfDiceSides;
    float _sizeOfDiceDots;
    NSMutableDictionary *_diceColors;
    UIColor *_diceColor;
    NSString *_diceColorName;
    NSTimeInterval _playAlarmTime;
}

+ (instancetype)sharedReferenceManager {
    static GTPlayerManager *sharedReferenceManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedReferenceManager = [[GTPlayerManager alloc] init];
    });
    
    return sharedReferenceManager;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setUpPlayers];
        _isTimerRunning = YES;
        [self performSelector:@selector(runTimer) withObject:self afterDelay:1.0f];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSNumber *diceCount = [defaults objectForKey:NUMBER_OF_DICE_KEY];
        if (diceCount) {
            self.numberOfDice = [diceCount floatValue];
        }
        
        NSNumber *diceSideCount = [defaults objectForKey:NUMBER_OF_DICE_SIDES_KEY];
        if (diceSideCount) {
            self.numberOfDiceSides = [diceSideCount intValue];
        }
        
        else {
            self.numberOfDiceSides = 6;
        }
        
        NSNumber *sizeOfDiceDots = [defaults objectForKey:SIZE_OF_DICE_DOTS_KEY];
        if (sizeOfDiceDots) {
            _sizeOfDiceDots = [sizeOfDiceDots floatValue];
        }
        
        else {
            _sizeOfDiceDots = 3.0f;
        }
        
        NSNumber *showDiceTotal = [defaults objectForKey:@"showDiceTotal"];
        if (showDiceTotal) {
            _showDiceTotal = [showDiceTotal boolValue];
        }
        
        else {
            _showDiceTotal = NO;
        }
        
        NSNumber *playAlarmTime = [defaults objectForKey:PLAY_ALARM_TIME_KEY];
        if (playAlarmTime) {
            _playAlarmTime = [playAlarmTime floatValue];
        }
        
        else {
            _playAlarmTime = 3.0f;
        }
        
        _diceColors = [NSMutableDictionary dictionaryWithDictionary:@{@"White" : [UIColor white],
                                                                      @"Red" : [UIColor venetianRed],
                                                                      @"Blue" : [UIColor royalAzure],
                                                                      @"Yellow" : [UIColor yellowPantone],
                                                                      @"Black" : [UIColor black],
                                                                      @"Orange" : [UIColor persimmon],
                                                                      @"Pink" : [UIColor brinkPink]}];
        
        NSArray *holidayColors = [UIColor strictHolidayColorsForToday];
        if (holidayColors) {
            [_diceColors setObject:[holidayColors firstObject] forKey:@"Holiday"];
        }
        
        
        NSString *nameOfDiceColor = [defaults objectForKey:COLOR_OF_DICE_KEY];
        if (nameOfDiceColor) {
            _diceColorName = nameOfDiceColor;
            _diceColor = [_diceColors objectForKey:_diceColorName];
            if (!_diceColor) _diceColorName = @"Red";
        }
        
        else {
            if (holidayColors) {
                _diceColorName = @"Holiday";
            }
            
            else {
                _diceColorName = @"Red";
            }
        }
        
        _diceColor = [_diceColors objectForKey:_diceColorName];
    }
    
    return self;
}

- (GTTimePickerView *)timerPicker {
    if (!_timerPicker) {
        _timerPicker = [[GTTimePickerView alloc] initWithFrame:CGRectZero];
    }
    
    return _timerPicker;
}

- (void)runTimer {
    if (_isTimerRunning && self.currentPlayer) {
        self.currentPlayer.timeRemaining -= 0.03;
        if (self.currentPlayer.timeRemaining <= 0.0f) {
            NSLog(@"%@ %@ out of time!", self.currentPlayer.name, [self.currentPlayer.name areOrIs]);
            self.currentPlayer.timeRemaining = 0.0f;
            _isTimerRunning = NO;
            
            NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@.wav",
                                       [[NSBundle mainBundle] resourcePath], @"Fire Pager"];
            NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
            
            AVAudioPlayer *audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL
                                                                  error:nil];
            [audioPlayer play];
            [audioPlayer performSelector:@selector(stop) withObject:audioPlayer afterDelay:_playAlarmTime];
            
            UIAlertController *resetTimerAlertView = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@ out of time!", self.currentPlayer.name, [self.currentPlayer.name areOrIs]] message:@"Reset the timers?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *resetAction = [UIAlertAction actionWithTitle:@"Reset Timers" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action){
                [self resetTimers:self.timerPicker.time];
                [self.timerDelegate timerStopped];
            }];
            
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
                self.currentPlayer = nil;
                _isTimerRunning = YES;
                
                if ([self.timerDelegate respondsToSelector:@selector(timerStopped)]) {
                    [self.timerDelegate timerStopped];
                }
            }];
            
            [resetTimerAlertView addAction:resetAction];
            [resetTimerAlertView addAction:cancelAction];
            
            if ([self.delegate respondsToSelector:@selector(presentViewControllerFromPlayerManager:)]) {
                [self.delegate presentViewControllerFromPlayerManager:resetTimerAlertView];
            }
        }
    }
    
    [self performSelector:@selector(runTimer) withObject:self afterDelay:0.03f];
}

- (void)setUpPlayers {
    _players = [[NSMutableArray alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    int playerNumber = 1;
    NSNumber *lastPlayerCount = [defaults objectForKey:@"This Was ThE Last Count 0f Players"];
    NSString *key = [NSString stringWithFormat:@"Player%dName", playerNumber];
    NSString *playerName = [defaults objectForKey:key];
    while (playerNumber <= MINIMUM_NUMBER_OF_PLAYERS || (playerName && playerNumber < [lastPlayerCount intValue])) {
        if (!playerName) {
            playerName = [NSString stringWithFormat:@"Player %d", playerNumber];
            [defaults setObject:playerName forKey:key];
        }
        
        GTPlayer *player = [[GTPlayer alloc] initWithName:playerName];
        [player setName:playerName];
        [player setTimeRemaining:self.timerPicker.time];
        [_players addObject:player];
        
        playerNumber++;
        key = [NSString stringWithFormat:@"Player%dName", playerNumber];
        playerName = [defaults objectForKey:key];
    }

    // to initialize player times
    NSNumber *lastTime = [defaults objectForKey:@"Last Time Per User"];
    
    if (lastTime && [lastTime floatValue] > 0.0f) {
        [self resetTimers:[lastTime floatValue]];
    }
    
    else {
        [self resetTimers:90.0f];
    }
}

- (NSArray *)players {
    while ([_players count] < MINIMUM_NUMBER_OF_PLAYERS) {
        int playerCount = (int)[_players count];
        NSString *playerName = [NSString stringWithFormat:@"Player %d", playerCount];
        while ([self playerNameExists:playerName]) {
            playerCount++;
            playerName = [NSString stringWithFormat:@"Player %d", playerCount];
        }
        GTPlayer *newPlayer = [[GTPlayer alloc] initWithName:playerName];
        [newPlayer setTimeRemaining:self.timerPicker.time];
        [_players insertObject:newPlayer atIndex:0];
    }
    
    return _players;
}

- (BOOL)playerNameExists:(NSString *)playerName {
    BOOL nameExists = NO;
    
    for (GTPlayer *player in _players) {
        if ([playerName isEqualToString:player.name]) {
            nameExists = YES;
            break;
        }
    }
    
    return nameExists;
}

- (void)addPlayer:(GTPlayer *)player {
    if (![self playerNameExists:player.name]) {
        [_players addObject:player];
    }
    
    else {
        NSLog(@"Player already exists!");
    }
}

- (void)addPlayer:(GTPlayer *)player atIndex:(NSInteger)index {
    if (index < [_players count] && ![self playerNameExists:player.name]) {
        [_players insertObject:player atIndex:index];
    }
    
    else {
        [self addPlayer:player];
    }
}

- (void)addPlayers:(NSArray *)players {
    [_players addObjectsFromArray:players];
}

- (BOOL)removePlayer:(GTPlayer *)player {
    return [self removePlayers:@[player]];
}

- (BOOL)removePlayers:(NSArray *)players {
    BOOL allPlayersExist = NO;
    for (GTPlayer *player in players) {
        if ([_players containsObject:player]) {
            [_players removeObject:player];
            allPlayersExist = YES;
        }
        
        else {
            allPlayersExist = NO;
        }
    }
    
    if ([_players count] == 0) {
        GTPlayer *player1 = [[GTPlayer alloc] initWithName:@"Player 1"];
        [player1 setTimeRemaining:[[[GTPlayerManager sharedReferenceManager] timerPicker] time]];
        GTPlayer *player2 = [[GTPlayer alloc] initWithName:@"Player 2"];
        [player2 setTimeRemaining:[[[GTPlayerManager sharedReferenceManager] timerPicker] time]];
        [self addPlayers:@[player1, player2]];
    }
    
    return allPlayersExist;
}

- (GTPlayer *)playerAtIndex:(NSInteger)index {
    if (index < [_players count]) {
        return [_players objectAtIndex:index];
    }
    
    return nil;
}

- (void)reset {
    [self resetScores];
}

- (void)resetScores {
    for (GTPlayer *player in _players) {
        player.pendingScore = 0;
        player.isPendingNegative = YES;
        player.scoreHistory = [[NSMutableArray alloc] init];
    }
}

- (void)updateTimers:(NSTimeInterval)time {
    float firstPlayerTimer = [[self playerAtIndex:0] timeRemaining];
    
    for (int i = 1; i < _players.count; i++) {
        GTPlayer *player = [self playerAtIndex:i];
        if ([player timeRemaining] != firstPlayerTimer) {
            return;
        }
    }
    
    [self resetTimers:time];
}

- (void)resetTimers:(NSTimeInterval)time {
    self.currentPlayer = nil;
    _isTimerRunning = YES;
    for (GTPlayer *player in _players) {
        [player setTimeRemaining:time];
    }
}

- (void)makeCurrentPlayer:(GTPlayer *)player {
    if ([player isEqual:self.currentPlayer]) {
        self.currentPlayer = nil;
    }
    
    else {
        self.currentPlayer = player;
    }
}

- (BOOL)showDiceTotal {
    return _showDiceTotal;
}

- (void)changeShowDiceTotal:(BOOL)showDiceTotal {
    _showDiceTotal = showDiceTotal;
}

- (int)numberOfDice {
    return _numberOfDice;
}

- (int)numberOfDiceSides {
    if (_numberOfDiceSides < 2) {
        _numberOfDiceSides = 6;
        NSLog(@"number of Dice Sides was wrong!");
    }
    return _numberOfDiceSides;
}

- (float)sizeOfDiceDots {
    if (_sizeOfDiceDots > MAX_SIZE_OF_DICE_DOTS) {
        _sizeOfDiceDots = MAX_SIZE_OF_DICE_DOTS;
    }
    
    return _sizeOfDiceDots;
}

- (void)setNumberOfDice:(int)numberOfDice {
    _numberOfDice = numberOfDice;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:numberOfDice] forKey:NUMBER_OF_DICE_KEY];
}

- (void)setNumberOfDiceSides:(int)numberOfDiceSides {
    _numberOfDiceSides = numberOfDiceSides;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInt:numberOfDiceSides] forKey:NUMBER_OF_DICE_SIDES_KEY];
}

- (void)setSizeOfDiceDots:(float)sizeOfDiceDots {
    _sizeOfDiceDots = sizeOfDiceDots;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:sizeOfDiceDots] forKey:SIZE_OF_DICE_DOTS_KEY];
}

- (NSArray *)diceColorNames {
    return [_diceColors allKeys];
}

- (NSString *)diceColorName {
    return _diceColorName;
}

- (UIColor *)diceColorForName:(NSString *)colorName {
    if ([_diceColors objectForKey:colorName]) {
        return [_diceColors objectForKey:colorName];
    }
    
    // if the key is unrecognized, return the default white color
    NSLog(@"Color not found, return \"White\"");
    return [UIColor white];
}

- (UIColor *)diceColor {
    return _diceColor;
}

- (void)setDiceColor:(NSString *)diceColorName {
    if ([_diceColors objectForKey:diceColorName]) {
        _diceColorName = diceColorName;
        _diceColor = [_diceColors objectForKey:diceColorName];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:diceColorName forKey:COLOR_OF_DICE_KEY];
    }
    
    else {
        NSLog(@"Can't find color for key \"%@\"", diceColorName);
    }
}

- (UIColor *)diceDotsColor {
    if ([_diceColorName isEqual:@"White"]) {
        return [UIColor black];
    }
    
    else if ([_diceColorName isEqual:@"Holiday"]) {
        return [[UIColor holidayColorsForToday] objectAtIndex:1];
    }
    
    return [UIColor white];
}

- (UIColor *)diceBorderColor {
    if ([_diceColorName isEqual:@"Black"]) {
        return [UIColor white];
    }
    
    return [UIColor black];
}

- (NSTimeInterval)playAlarmTime {
    return _playAlarmTime;
}

- (void)setPlayAlarmTime:(NSTimeInterval)playAlarmTime {
    _playAlarmTime = playAlarmTime;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:playAlarmTime] forKey:PLAY_ALARM_TIME_KEY];
}

@end
