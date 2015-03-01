//
//  GTPlayerManagerViewController.h
//  Game Toolkit
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTTimePickerView.h"

@interface GTPlayerManagerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UITableView *playerTableView;
@property (nonatomic, strong) NSMutableArray *textFields;
@property (nonatomic, strong) UIToolbar *accessoryView, *headerToolbar;
@property (nonatomic, strong) UIButton *resetNamesButton, *resetScoreButton, *resetTimeButton, *resetDiceButton;
@property (nonatomic, strong) UILabel *showTimeLabel;
@property (nonatomic, strong) UISwitch *showTimeSwitch;
@property (nonatomic, strong) UILabel *amountOfTimeLabelQuantity;
@property (nonatomic, strong) UILabel *amountOfTimeLabel;
@property (nonatomic, strong) GTTimePickerView *timerPicker;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *diceCountLabel, *diceLabel;
@property (nonatomic, strong) UISlider *diceCountSlider;
@property (nonatomic, strong) UILabel *showDiceTotalLabel;
@property (nonatomic, strong) UISwitch *showDiceTotalSwitch;
@property (nonatomic, strong) UILabel *numberOfDiceSidesLabel;
@property (nonatomic, strong) UILabel *numberOfDiceSidesCountLabel;
@property (nonatomic, strong) UISlider *numberOfDiceSidesSlider;
@property (nonatomic, strong) UILabel *sizeOfDiceLabel;
@property (nonatomic, strong) UILabel *sizeOfDiceLabelSMLXL;
@property (nonatomic, strong) UISlider *sizeOfDiceDotsSlider;
@property (nonatomic, strong) UILabel *advancedDiceFeaturesLabel;
@property (nonatomic, strong) UISwitch *advancedDiceFeaturesSwitch;
@property (nonatomic, strong) UILabel *diceColorLabel;
@property (nonatomic, strong) UIPickerView *diceColorPickerView;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIColor *deselectedColor;
@property float keyboardHeight;
@property BOOL keyboardIsShowing;

@end
