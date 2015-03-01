//
//  GTRandomValueViewController.h
//  Game Toolkit
//
//  Created by Developer Nathan on 2/11/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GTRandomValueViewController : UIViewController

@property (nonatomic, strong) UIToolbar *headerToolbar;
@property (nonatomic, strong) NSMutableArray *dice;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTap;
@property (nonatomic, strong) UISwipeGestureRecognizer *swipeUp, *swipeDown;
@property (nonatomic, strong) UILabel *totalLabel;
@property NSInteger lastNumberOfDice, lastNumberOfDiceSides;
@property BOOL showInstructions, animatingScore;

@end
