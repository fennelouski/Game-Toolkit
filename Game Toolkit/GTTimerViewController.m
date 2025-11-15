//
//  GTTimerViewController.m
//  Game Toolkit
//
//  Created by Developer Nathan on 2/10/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTTimerViewController.h"
#import "GTPlayerManager.h"
#import "UIColor+AppColors.h"
#import "GTPlayerTimeButton.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define CELL_HEIGHT 44.0f
#define FOOTER_HEIGHT 49.0f
#define DESELECTED_BRIGHTNESS 0.4f
#define SELECTED_BRIGHTNESS 0.75f

@implementation GTTimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Use system background color for automatic dark mode support
    if (@available(iOS 13.0, *)) {
        [self.view setBackgroundColor:[UIColor systemBackgroundColor]];
    } else {
        [self.view setBackgroundColor:[UIColor whiteColor]];
    }
//    [self.view addSubview:self.headerToolbar];
    self.playerButtons = [[NSMutableDictionary alloc] initWithCapacity:[[[GTPlayerManager sharedReferenceManager] players] count]];
    
        
    [self updateViews];
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateViews];
    [[GTPlayerManager sharedReferenceManager] setDelegate:self];
    [[GTPlayerManager sharedReferenceManager] setTimerDelegate:self];
    [self timerButtonTouched:nil];
}

- (void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    [self updateViews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self updateViews];
}

- (void)delayUpdateViews {
    [self performSelector:@selector(updateViews) withObject:self afterDelay:0.1f];
}

- (void)updateViews {
    CGFloat safeAreaTop = self.view.safeAreaInsets.top;

    [UIView animateWithDuration:0.0f animations:^{
        [self.headerToolbar setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, safeAreaTop)];
        [self layoutButtons];
    } completion:^(BOOL finished) {

    }];
}

- (void)layoutButtons {
    CGFloat safeAreaTop = self.view.safeAreaInsets.top;

    if (self.playerButtons.count == [[[GTPlayerManager sharedReferenceManager] players] count]) {
        int playerNumber = 0, totalPlayers = (int)[[[GTPlayerManager sharedReferenceManager] players] count];
        for (GTPlayer *player in [[GTPlayerManager sharedReferenceManager] players]) {
            UIButton *button = [self.playerButtons objectForKey:player.name];

            if (!button) {
                NSLog(@"Button doesn't exist for %@", player.name);
                [self setUpButtons];
                break;
            }

            [self.view addSubview:button];
            CGRect frame = [self frameForButton:playerNumber totalPlayers:totalPlayers];
            if (frame.origin.y > 0.0f && frame.origin.y <= safeAreaTop) {
                frame.size.height += frame.origin.y;
                frame.origin.y = 0.0f;
            }
            [button setFrame:frame];
            playerNumber++;
        }
    }
    
    else {
        [self setUpButtons];
    }
    
    if ([[GTPlayerManager sharedReferenceManager] currentPlayer]) {
        [self timerButtonTouched:nil];
    }
}

- (void)setUpButtons {
    CGFloat safeAreaTop = self.view.safeAreaInsets.top;

    for (NSObject *key in self.playerButtons.allKeys) {
        UIView *buttonView = [self.playerButtons objectForKey:key];
        [buttonView removeFromSuperview];
    }

    int playerNumber = 0, totalPlayers = (int)[[[GTPlayerManager sharedReferenceManager] players] count];
    for (GTPlayer *player in [[GTPlayerManager sharedReferenceManager] players]) {
        CGRect frame = [self frameForButton:playerNumber totalPlayers:totalPlayers];
        if (frame.origin.y > 0.0f && frame.origin.y <= safeAreaTop) {
            frame.size.height += frame.origin.y;
            frame.origin.y = 0.0f;
        }
        
        GTPlayerTimeButton *button = [[GTPlayerTimeButton alloc] initWithFrame:frame];
        [button setPlayer:player];
        [button setTitle:player.name forState:UIControlStateNormal];
        [button setBackgroundColor:[[UIColor randomDarkColorFromString:player.name] makeBrightnessOf:DESELECTED_BRIGHTNESS]];
        [button addTarget:self action:@selector(timerButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        
        [self.playerButtons setObject:button forKey:player.name];
        
        playerNumber++;
    }
}

- (CGRect)frameForButton:(int)playerNumber totalPlayers:(int)totalPlayers {
    CGRect frame;
    if (totalPlayers <= 0) {
        NSLog(@"Can't divide by 0");
        return frame;
    }

    CGFloat safeAreaTop = self.view.safeAreaInsets.top;
    CGFloat safeAreaBottom = self.view.safeAreaInsets.bottom;
    float availableHeight = kScreenHeight - safeAreaTop - safeAreaBottom - FOOTER_HEIGHT;

    if (totalPlayers <= 3 || totalPlayers == 5 || totalPlayers == 7) {
        // portrait
        if (kScreenHeight > kScreenWidth) {
            frame = CGRectMake(0.0f,
                               safeAreaTop + (float)playerNumber / (float)totalPlayers * availableHeight,
                               kScreenWidth,
                               availableHeight / (float)totalPlayers);
        }

        else {
            frame = CGRectMake((float)playerNumber / (float)totalPlayers * kScreenWidth,
                               safeAreaTop,
                               kScreenWidth / (float)totalPlayers,
                               availableHeight);
        }
    }

    else if (totalPlayers == 4 || totalPlayers == 6 || totalPlayers == 8 || totalPlayers == 9) {
        float numberOfRows = 2.0f;
        float numberOfColumns = 2.0f;

        float squareRoot = 1.41421356237f;
        while (squareRoot * squareRoot < totalPlayers) {
            squareRoot *= 1.05f;
        }
        squareRoot = (float)(int)squareRoot;


        if (totalPlayers != squareRoot * squareRoot) {
            // portrait
            if (kScreenHeight > kScreenWidth) {
                numberOfColumns = squareRoot;
                numberOfRows = squareRoot + 1;

                while (numberOfColumns * numberOfRows < totalPlayers) {
                    numberOfRows++;
                }
            }

            else {
                numberOfRows = squareRoot;
                numberOfColumns = squareRoot + 1;

                while (numberOfColumns * numberOfRows < totalPlayers) {
                    numberOfColumns++;
                }
            }
        }

        else {
            numberOfRows = squareRoot;
            numberOfColumns = squareRoot;
        }

        frame = CGRectMake((playerNumber % (int)numberOfColumns) * kScreenWidth / numberOfColumns,
                           safeAreaTop + (playerNumber / (int)numberOfColumns) * availableHeight / numberOfRows,
                           kScreenWidth / numberOfColumns,
                           availableHeight / numberOfRows);
    }

    return frame;
}

- (void)timerButtonTouched:(GTPlayerTimeButton *)button {
    GTPlayer *currentPlayer = [[GTPlayerManager sharedReferenceManager] currentPlayer];
    for (int i = 0; i < self.playerButtons.allKeys.count; i++) {
        GTPlayerTimeButton *timerButton = [self.playerButtons objectForKey:[[self.playerButtons allKeys] objectAtIndex:i]];
        
        if ([timerButton.player isEqual:currentPlayer]) {
            [UIView animateWithDuration:0.15f animations:^{
                [timerButton setBackgroundColor:[timerButton.backgroundColor makeBrightnessOf:SELECTED_BRIGHTNESS]];
                [timerButton.nameLabel setTextColor:[UIColor blackColor]];
                [timerButton.timeLabel setTextColor:[UIColor blackColor]];
                [timerButton setSelected:YES];
            }];
        }
        
        else {
            [UIView animateWithDuration:0.15f animations:^{
                [timerButton setBackgroundColor:[[UIColor randomDarkColorFromString:timerButton.player.name] makeBrightnessOf:DESELECTED_BRIGHTNESS]];
                [timerButton.nameLabel setTextColor:[UIColor whiteColor]];
                [timerButton.timeLabel setTextColor:[UIColor whiteColor]];
                [timerButton setSelected:NO];
            }];
        }
    }
}

#pragma mark - GTPlayerManager Delegate

- (void)presentViewControllerFromPlayerManager:(UIViewController *)viewControllerToPresent {
    [self presentViewController:viewControllerToPresent animated:YES completion:^{
        
    }];
}

#pragma mark - GTPlayerManagerTimer Delegate

- (void)timerStopped {
    [self timerButtonTouched:nil];
}

@end
