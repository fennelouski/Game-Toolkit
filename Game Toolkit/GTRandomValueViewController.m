//
//  GTRandomValueViewController.m
//  Game Toolkit
//
//  Created by Developer Nathan on 2/11/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTRandomValueViewController.h"
#import "GTPlayerManager.h"
#import "GTDieView.h"
#import "UIColor+AppColors.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kStatusBarHeight (([[UIApplication sharedApplication] statusBarFrame].size.height == 20.0f) ? 20.0f : (([[UIApplication sharedApplication] statusBarFrame].size.height == 40.0f) ? 20.0f : 0.0f))
#define kScreenHeight (([[UIApplication sharedApplication] statusBarFrame].size.height > 20.0f) ? [UIScreen mainScreen].bounds.size.height - 20.0f : [UIScreen mainScreen].bounds.size.height)
#define CELL_HEIGHT 44.0f
#define BUFFER 20.0f
#define FOOTER_HEIGHT 49.0f
#define PICKER_HEIGHT 216.0f
#define WAIT_TIME 4.0f
#define LONG_WAIT_TIME 600.0f

@implementation GTRandomValueViewController

- (void)viewDidLoad {
    [self.view addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Green Background"]]];
    self.dice = [[NSMutableArray alloc] init];
//    [self.view addSubview:self.headerToolbar];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    [self setNeedsStatusBarAppearanceUpdate];
    [self.view addSubview:self.totalLabel];
    [self.view addGestureRecognizer:self.doubleTap];
    
    [self setUpDice];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self  selector:@selector(updateViews)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    [nc addObserver:self  selector:@selector(updateViews)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    [nc addObserver:self selector:@selector(updateViews) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    
    [self performSelector:@selector(checkForInstructions) withObject:self afterDelay:WAIT_TIME];
    [self performSelector:@selector(checkForInstructions) withObject:self afterDelay:LONG_WAIT_TIME]; // add a check for 10 minutes later to see if the user has both shaken and double tapped
}

- (void)viewWillAppear:(BOOL)animated {
    [self setUpDice];
    
    if (self.lastNumberOfDice != [[GTPlayerManager sharedReferenceManager] numberOfDice] || self.lastNumberOfDiceSides != [[GTPlayerManager sharedReferenceManager] numberOfDiceSides]) {
        [self layoutDice];
    }
    
    self.showInstructions = YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    self.showInstructions = NO;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)checkForInstructions {
//    NSLog(@"checkForInstructions");
    if (self.showInstructions) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastShakeDate = [defaults objectForKey:@"lastShakeDate"];
        NSDate *lastDoubleTapDate = [defaults objectForKey:@"lastDoubleTapDate"];
        
        // check to see if the user has rolled the dice within the last week
        // if not, then show an alert describing how to roll the dice
        if ((!lastShakeDate & !lastDoubleTapDate) || ((abs((int)[lastDoubleTapDate timeIntervalSinceNow]) > 86400 * 3) && (abs((int)[lastShakeDate timeIntervalSinceNow]) > 86400 * 3))) {
            NSString *deviceType = [[[[UIDevice currentDevice] model] componentsSeparatedByString:@" "] firstObject];
            NSString *message = [NSString stringWithFormat:@"Shake %@ or double tap to roll dice", deviceType];
            NSString *title = @"Shake or double tap to Roll";
            UIAlertController *instructionAlerController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Got it!" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                
            }];
            [instructionAlerController addAction:gotItAction];
            
            [self presentViewController:instructionAlerController animated:YES completion:^{
                
            }];
        }
        
        else if (abs((int)[lastDoubleTapDate timeIntervalSinceNow]) > 86400 * 3) {
            NSString *title = @"Double tap to Roll";
            NSString *message = [NSString stringWithFormat:@"You can also double tap to roll dice"];
            UIAlertController *instructionAlerController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Got it!" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                
            }];
            [instructionAlerController addAction:gotItAction];
            
            [self presentViewController:instructionAlerController animated:YES completion:^{
                
            }];
        }
        
        else if (abs((int)[lastShakeDate timeIntervalSinceNow]) > 86400 * 3) {
            NSString *deviceType = [[[[UIDevice currentDevice] model] componentsSeparatedByString:@" "] firstObject];
            NSString *title = @"Shake to Roll";
            NSString *message = [NSString stringWithFormat:@"You can also shake the %@ to roll dice", deviceType];
            UIAlertController *instructionAlerController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *gotItAction = [UIAlertAction actionWithTitle:@"Got it!" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                
            }];
            [instructionAlerController addAction:gotItAction];
            
            [self presentViewController:instructionAlerController animated:YES completion:^{
                
            }];
        }
    }
    
    else {
        [self performSelector:@selector(checkForInstructions) withObject:self afterDelay:WAIT_TIME];
    }
}

- (void)updateViews {
    [self.headerToolbar setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, kStatusBarHeight)];
    [self.totalLabel setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, -kScreenHeight/2.0f)];
    [self layoutDice];
}

- (void)setUpDice {
    // make sure that there's at least one die to show
    if ([[GTPlayerManager sharedReferenceManager] numberOfDice] < 1) {
        [[GTPlayerManager sharedReferenceManager] setNumberOfDice:2];
    }
    
    if (self.dice.count != [[GTPlayerManager sharedReferenceManager] numberOfDice]) {
        for (int i = 0; i < [[GTPlayerManager sharedReferenceManager] numberOfDice]; i ++) {
            GTDieView *die = [[GTDieView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
            [die setCenter:CGPointMake(kScreenWidth / 2.0f, kStatusBarHeight + 20.0f + 60.0f * i)];
            [self.dice addObject:die];
            [self.view addSubview:die];
        }
    }
    
    [self.view addSubview:self.totalLabel];
    
    while (self.dice.count > [[GTPlayerManager sharedReferenceManager] numberOfDice]) {
        [[self.dice firstObject] removeFromSuperview];
        [self.dice removeObject:[self.dice firstObject]];
    }
    
    [self layoutDice];
}

- (void)layoutDice {
    NSInteger dieNumber = 0, totalDice = self.dice.count;
    int diceTotal = 0;
    for (GTDieView *die in self.dice) {
        if (![die selected] || die.frame.origin.x + die.frame.size.width > kScreenWidth || die.frame.origin.y + die.frame.size.height + FOOTER_HEIGHT > kScreenHeight || die.frame.origin.x + die.frame.size.width / 2.0f < 0.0f || die.frame.origin.y + die.frame.size.height / 2.0f < 0.0f) {
            float dieSize = (kScreenWidth + kScreenHeight) / (4.0f + (totalDice / 1.5f));
            [die setFrame:[self frameForDice:dieNumber totalDice:totalDice]];
            CGPoint center = die.center;
            [die setFrame:CGRectMake(0.0f, 0.0f, dieSize, dieSize)];
            [die setCenter:center];
            [die drawSpots];
        }
        
        diceTotal += [die value];
        dieNumber++;
    }
    [self.totalLabel setText:[NSString stringWithFormat:@"%d", diceTotal]];
    
    self.lastNumberOfDice = self.dice.count;
    self.lastNumberOfDiceSides = [[GTPlayerManager sharedReferenceManager] numberOfDiceSides];
}

- (CGRect)frameForDice:(NSInteger)dieNumber totalDice:(NSInteger)totalDice {
    CGRect frame;
    if (totalDice <= 0) {
        NSLog(@"Can't divide by 0");
        return frame;
    }
    
    float availableHeight = kScreenHeight - kStatusBarHeight - FOOTER_HEIGHT;
    
    if (totalDice <= 3) {
        // portrait
        if (kScreenHeight > kScreenWidth) {
            frame = CGRectMake(0.0f,
                               kStatusBarHeight + (float)dieNumber / (float)totalDice * availableHeight,
                               kScreenWidth,
                               availableHeight / (float)totalDice);
        }
        
        // landscape
        else {
            frame = CGRectMake((float)dieNumber / (float)totalDice * kScreenWidth,
                               kStatusBarHeight,
                               kScreenWidth / (float)totalDice,
                               availableHeight);
        }
    }
    
    else {
        float numberOfRows = 2.0f;
        float numberOfColumns = 2.0f;
        
        // super simple and quick approximation for a square root
        float squareRoot = 1.41421356237f;
        while (squareRoot * squareRoot < totalDice) {
            squareRoot *= 1.05f;
        }
        squareRoot = (float)(int)squareRoot;
        
        
        if (totalDice != squareRoot * squareRoot) {
            // portrait
            if (kScreenHeight > kScreenWidth) {
                numberOfColumns = squareRoot;
                numberOfRows = squareRoot + 1;
                
                while (numberOfColumns * numberOfRows < totalDice) {
                    numberOfRows++;
                }
            }
            
            else {
                numberOfRows = squareRoot;
                numberOfColumns = squareRoot + 1;
                
                while (numberOfColumns * numberOfRows < totalDice) {
                    numberOfColumns++;
                }
            }
        }
        
        else {
            numberOfRows = squareRoot;
            numberOfColumns = squareRoot;
        }
        
        float rowPosition = (dieNumber / (int)numberOfColumns);
        float columnPosition = (dieNumber % (int)numberOfColumns);
        // if it's the last row then rearrange so that there's no empty space
        if ((rowPosition + 1) * numberOfColumns >= totalDice) {
            int possibleNumberOfColumns = (int)totalDice % (int)numberOfColumns;
            
            // don't want to divide by 0
            if (possibleNumberOfColumns > 0) {
                numberOfColumns = possibleNumberOfColumns;
            }
        }
        
        frame = CGRectMake(columnPosition * kScreenWidth / numberOfColumns,
                           kStatusBarHeight + rowPosition * availableHeight / numberOfRows,
                           kScreenWidth / numberOfColumns,
                           availableHeight / numberOfRows);
    }
    
    return frame;
}


#pragma mark - Subviews

- (UIToolbar *)headerToolbar {
    if (!_headerToolbar) {
        _headerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, kStatusBarHeight)];
    }
    
    return _headerToolbar;
}

- (UILabel *)totalLabel {
    if (!_totalLabel) {
        _totalLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, -kScreenHeight/2.0f)];
        [_totalLabel setTextColor:[UIColor champagne]];
        [_totalLabel setShadowColor:[UIColor lightGray]];
        [_totalLabel setShadowOffset:CGSizeMake(-1.0f, -1.0f)];
        [_totalLabel setAlpha:0.3f];
        [_totalLabel setTextAlignment:NSTextAlignmentCenter];
        [_totalLabel setFont:[UIFont systemFontOfSize:(kScreenHeight + kScreenWidth) / 4.0f]];
    }
    
    return _totalLabel;
}

#pragma mark - Gestures

- (UITapGestureRecognizer *)doubleTap {
    if (!_doubleTap) {
        _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped)];
        [_doubleTap setNumberOfTapsRequired:2];
    }
    
    return _doubleTap;
}

- (UISwipeGestureRecognizer *)swipeDown {
    if (!_swipeDown) {
        _swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedDown)];
        [_swipeDown setDirection:UISwipeGestureRecognizerDirectionDown];
    }
    
    return _swipeDown;
}

- (UISwipeGestureRecognizer *)swipeUp {
    if (!_swipeUp) {
        _swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipedUp)];
        [_swipeUp setDirection:UISwipeGestureRecognizerDirectionUp];
    }
    
    return _swipeUp;
}

#pragma mark - Gesture Actions

- (void)doubleTapped {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastDoubleTapDate = [NSDate date];
    [defaults setObject:lastDoubleTapDate forKey:@"lastDoubleTapDate"];

    [self rollDice];
}

- (void)swipedDown {
    NSLog(@"Swiped down");
}

- (void)swipedUp {
    NSLog(@"Swiped up");
}

#pragma mark Motion Gesture Methods

- (BOOL)canBecomeFirstResponder {
    return YES;
}


- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake ) {
        [self rollDice];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastShakeDate = [NSDate date];
        [defaults setObject:lastShakeDate forKey:@"lastShakeDate"];
    }
}

- (void)rollDice {
    
    [UIView animateWithDuration:0.35f animations:^{
        [self layoutDice];
    }];
    
    for (GTDieView *die in self.dice) {
        [die randomize];
    }
    
    if (self.dice.count > 1 && [[GTPlayerManager sharedReferenceManager] showDiceTotal]) {
        [self totalDiceCount:[NSNumber numberWithInt:120]];
        
        [self.totalLabel setCenter:CGPointMake(kScreenWidth/2.0f, -kScreenHeight/2.0f)];
        [self.totalLabel setAlpha:0.0f];
        [UIView animateWithDuration:0.35f delay:0.8f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.totalLabel setCenter:CGPointMake(kScreenWidth/2.0f, kScreenHeight/2.0f)];
            [self.totalLabel setAlpha:1.0f];
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.35f animations:^{
                [self.totalLabel setAlpha:1.0f];
            }];
        }];
    }
}

- (void)totalDice {
    int diceTotal = 0;
    for (GTDieView *die in self.dice) {
        diceTotal += [die value];
    }
    
    [self.totalLabel setText:[NSString stringWithFormat:@"%d", diceTotal]];
}

- (void)totalDiceCount:(NSNumber *)count {
    if ([count intValue] > 0) {
        [self performSelector:@selector(totalDiceCount:) withObject:[NSNumber numberWithInt:[count intValue] - 1] afterDelay:0.0167f];
        [self totalDice];
    }
    
    else {
        [UIView animateWithDuration:0.35f animations:^{
            [self.totalLabel setCenter:CGPointMake(kScreenWidth/2.0f, kScreenHeight + kScreenWidth)];
            [self.totalLabel setAlpha:0.0f];
        } completion:^(BOOL finished){
            [UIView animateWithDuration:0.35f animations:^{
                [self.totalLabel setAlpha:0.3f];
            }];
        }];
    }
}

@end
