//
//  GTPlayerManagerViewController.h
//  Game Toolkit
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTTimePickerView.h"

@interface GTPlayerManagerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *playerTableView;
@property (nonatomic, strong) NSMutableArray *textFields;
@property (nonatomic, strong) UIToolbar *accessoryView, *headerToolbar;
@property (nonatomic, strong) UIButton *resetButton, *resetScoreButton, *resetTimeButton, *resetDiceButton;
@property (nonatomic, strong) GTTimePickerView *timerPicker;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *diceCountLabel, *diceLabel;
@property (nonatomic, strong) UISlider *diceCountSlider;
@property (nonatomic, strong) UILabel *showDiceTotalLabel;
@property (nonatomic, strong) UISwitch *showDiceTotalSwitch;
@property (nonatomic, strong) UILabel *numberOfDiceSidesLabel;
@property (nonatomic, strong) UILabel *numberOfDiceSidesCountLabel;
@property (nonatomic, strong) UISlider *numberOfDiceSidesSlider;
@property float keyboardHeight;
@property BOOL keyboardIsShowing;

@end
