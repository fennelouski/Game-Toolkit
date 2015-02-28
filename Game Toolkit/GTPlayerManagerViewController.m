//
//  GTPlayerManagerViewController.m
//  Game Toolkit
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTPlayerManagerViewController.h"
#import "GTPlayerManager.h"
#import "UIColor+AppColors.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kStatusBarHeight (([[UIApplication sharedApplication] statusBarFrame].size.height == 20.0f) ? 20.0f : (([[UIApplication sharedApplication] statusBarFrame].size.height == 40.0f) ? 20.0f : 0.0f))
#define kScreenHeight (([[UIApplication sharedApplication] statusBarFrame].size.height > 20.0f) ? [UIScreen mainScreen].bounds.size.height - 20.0f : [UIScreen mainScreen].bounds.size.height)
#define CELL_HEIGHT 44.0f
#define BUFFER 20.0f
#define FOOTER_HEIGHT 49.0f
#define PICKER_HEIGHT 216.0f
#define GameTableCellIdentifier @"GameTableCellIdentifier"

@implementation GTPlayerManagerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tintColor = [UIColor rubyRed];
    [self.view setBackgroundColor:[UIColor white]];
    [self.view addSubview:self.playerTableView];
    [self.view addSubview:self.headerToolbar];
    self.keyboardHeight = FOOTER_HEIGHT;
    self.keyboardIsShowing = NO;
    [self setUpTableView];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self  selector:@selector(updateViews)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    [nc addObserver:self  selector:@selector(reloadPickerView)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    [nc addObserver:self selector:@selector(updateViews) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
//    [nc addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [self updateViews];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.playerTableView reloadData];
    [self updateViews];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *key;
    int numberOfPlayers = 0;
    for (int i = 0; i < self.textFields.count; i++) {
        key = [NSString stringWithFormat:@"Player%dName", i + 1];
        UITextField *textField = [self.textFields objectAtIndex:i];
        if ([[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
            [defaults setObject:[textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:key];
            numberOfPlayers++;
        }
        
        else {
            [defaults removeObjectForKey:key];
        }
    }
    
    NSNumber *lastPlayerCount = [NSNumber numberWithInt:numberOfPlayers + 1];
    [defaults setObject:lastPlayerCount forKey:@"This Was ThE Last Count 0f Players"];
    
    [[GTPlayerManager sharedReferenceManager] setNumberOfDice:self.diceCountSlider.value];
    [[GTPlayerManager sharedReferenceManager] setNumberOfDiceSides:self.numberOfDiceSidesSlider.value];
}

- (void)updateViews {
    [UIView animateWithDuration:0.35f animations:^{
        [self.playerTableView setFrame:CGRectMake(0.0, 0.0f, kScreenWidth, kScreenHeight)];
        [self.playerTableView setContentInset:UIEdgeInsetsMake(kStatusBarHeight, 0.0f, self.keyboardHeight, 0.0f)];
        [self.playerTableView setScrollIndicatorInsets:self.playerTableView.contentInset];
        [self.headerToolbar setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, kStatusBarHeight)];
        [self.resetTimeButton setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
        [self.resetScoreButton setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
        [self.resetButton setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
        [self.timerPicker layoutSubviews];
    } completion:^(BOOL finished) {
        if (!self.keyboardIsShowing) {
            [self.playerTableView reloadData];
        }
    }];
}

- (void)reloadPickerView {
    [self.playerTableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)setUpTableView {
    [self.playerTableView setSeparatorStyle:UITableViewCellSeparatorStyleSingleLineEtched];
    [self.playerTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:GameTableCellIdentifier];
    
    self.textFields = [[NSMutableArray alloc] initWithCapacity:10];
    for (int i = 0; i < 10; i++) {
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectZero];
        [textField setPlaceholder:[NSString stringWithFormat:@"Player %d's Name", i+1]];
        [textField setDelegate:self];
        [textField setAutocapitalizationType:UITextAutocapitalizationTypeWords];
        [textField setAutocorrectionType:UITextAutocorrectionTypeNo];
        [textField setReturnKeyType:UIReturnKeyDone];
        [textField setTag:i];
        [textField setTintColor:self.tintColor];
        [self.textFields addObject:textField];
    }
}

#pragma mark - subviews

- (UITableView *)playerTableView {
    if (!_playerTableView) {
        _playerTableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, kScreenHeight) style:UITableViewStyleGrouped];
        [_playerTableView setDataSource:self];
        [_playerTableView setDelegate:self];
    }
    
    return _playerTableView;
}

- (UIToolbar *)headerToolbar {
    if (!_headerToolbar) {
        _headerToolbar = [[UIToolbar alloc] initWithFrame:CGRectZero];
    }
    
    return _headerToolbar;
}

- (UIToolbar *)accessoryView {
    if (!_accessoryView) {
        _accessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
    }
    
    return _accessoryView;
}

- (UIButton *)resetButton {
    if (!_resetButton) {
        _resetButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_resetButton setTitle:@"Reset" forState:UIControlStateNormal];
        [_resetButton setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [_resetButton setBackgroundColor:self.tintColor];
        [_resetButton addTarget:self action:@selector(resetButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _resetButton;
}

- (UIButton *)resetScoreButton {
    if (!_resetScoreButton) {
        _resetScoreButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_resetScoreButton setTitle:@"Reset Scores" forState:UIControlStateNormal];
        [_resetScoreButton setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [_resetScoreButton setBackgroundColor:self.tintColor];
        [_resetScoreButton addTarget:self action:@selector(resetScoresButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _resetScoreButton;
}

- (UIButton *)resetTimeButton {
    if (!_resetTimeButton) {
        _resetTimeButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_resetTimeButton setTitle:@"Reset Timers" forState:UIControlStateNormal];
        [_resetTimeButton setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [_resetTimeButton setBackgroundColor:self.tintColor];
        [_resetTimeButton addTarget:self action:@selector(resetTimerButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _resetTimeButton;
}

- (UIButton *)resetDiceButton {
    if (!_resetDiceButton) {
        _resetDiceButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_resetDiceButton setTitle:@"Reset Dice" forState:UIControlStateNormal];
        [_resetDiceButton setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [_resetDiceButton setBackgroundColor:self.tintColor];
        [_resetDiceButton addTarget:self action:@selector(resetDiceButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _resetDiceButton;
}

- (GTTimePickerView *)timerPicker {
    if (!_timerPicker) {
        _timerPicker = [[GTPlayerManager sharedReferenceManager] timerPicker];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewDidAppear:)];
        [_timerPicker addGestureRecognizer:tap];
    }
    
    return _timerPicker;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
        [_timeLabel setTextAlignment:NSTextAlignmentCenter];
        [_timeLabel setTextColor:[UIColor darkTextColor]];
    }
    
    return _timeLabel;
}

- (UILabel *)diceCountLabel {
    if (!_diceCountLabel) {
        _diceCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
        [_diceCountLabel setText:[NSString stringWithFormat:@"%d", (int)self.diceCountSlider.value]];
        [_diceCountLabel setTextColor:[UIColor darkTextColor]];
        [_diceCountLabel setTextAlignment:NSTextAlignmentRight];
    }
    
    return _diceCountLabel;
}

- (UILabel *)diceLabel {
    if (!_diceLabel) {
        _diceLabel = [[UILabel alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
        [_diceLabel setText:@"Number of Dice"];
        [_diceLabel setTextColor:[UIColor darkTextColor]];
        [_diceLabel setTextAlignment:NSTextAlignmentLeft];
    }
    
    return _diceLabel;
}

- (UISlider *)diceCountSlider {
    if (!_diceCountSlider) {
        _diceCountSlider = [[UISlider alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
        [_diceCountSlider setMinimumTrackTintColor:[UIColor darkTextColor]];
        [_diceCountSlider setMinimumValue:1.0f];
        [_diceCountSlider setMaximumValue:(floorf(((kScreenHeight + kScreenWidth) / 44.3f) / 5)) * 5];
        [_diceCountSlider setValue:[[GTPlayerManager sharedReferenceManager] numberOfDice]];
        [_diceCountSlider setMinimumTrackTintColor:self.tintColor];
        
        [_diceCountSlider addTarget:self action:@selector(sliderTouched:) forControlEvents:UIControlEventTouchDragInside];
        [_diceCountSlider addTarget:self action:@selector(sliderTouched:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _diceCountSlider;
}

- (UILabel *)showDiceTotalLabel {
    if (!_showDiceTotalLabel) {
        _showDiceTotalLabel = [[UILabel alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth, CELL_HEIGHT)];
        [_showDiceTotalLabel setText:@"Show Dice Total"];
        [_showDiceTotalLabel setTextAlignment:NSTextAlignmentLeft];
        [_showDiceTotalLabel setTextColor:[UIColor darkTextColor]];
    }
    
    return _showDiceTotalLabel;
}

- (UISwitch *)showDiceTotalSwitch {
    if (!_showDiceTotalSwitch) {
        _showDiceTotalSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(kScreenWidth - 40.0f, 0.0f, 40.0f, kScreenWidth)];
        [_showDiceTotalSwitch setOnTintColor:self.tintColor];
        [_showDiceTotalSwitch setOn:[[GTPlayerManager sharedReferenceManager] showDiceTotal] animated:YES];
        [_showDiceTotalSwitch addTarget:self action:@selector(switchShowDice) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _showDiceTotalSwitch;
}

- (UILabel *)numberOfDiceSidesLabel {
    if (!_numberOfDiceSidesLabel) {
        _numberOfDiceSidesLabel = [[UILabel alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth, CELL_HEIGHT)];
        [_numberOfDiceSidesLabel setTextAlignment:NSTextAlignmentLeft];
        [_numberOfDiceSidesLabel setTextColor:[UIColor darkTextColor]];
        
        [_numberOfDiceSidesLabel setText:@"Number of sides on dice"];
        
        if (self.diceCountSlider.value <= 1) {
            [self.numberOfDiceSidesLabel setText:@"Number of sides on die"];
        }
    }
    
    return _numberOfDiceSidesLabel;
}

- (UILabel *)numberOfDiceSidesCountLabel {
    if (!_numberOfDiceSidesCountLabel) {
        _numberOfDiceSidesCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2, CELL_HEIGHT)];
        [_numberOfDiceSidesCountLabel setText:[NSString stringWithFormat:@"%d", [[GTPlayerManager sharedReferenceManager] numberOfDiceSides]]];
        [_numberOfDiceSidesCountLabel setTextAlignment:NSTextAlignmentRight];
        [_numberOfDiceSidesCountLabel setTextColor:[UIColor darkTextColor]];
    }
    
    return _numberOfDiceSidesCountLabel;
}

- (UISlider *)numberOfDiceSidesSlider {
    if (!_numberOfDiceSidesSlider) {
        _numberOfDiceSidesSlider = [[UISlider alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2, CELL_HEIGHT)];
        [_numberOfDiceSidesSlider setMinimumValue:2.0f];
        [_numberOfDiceSidesSlider setMaximumValue:20.0f];
        [_numberOfDiceSidesSlider setValue:[[GTPlayerManager sharedReferenceManager] numberOfDiceSides] animated:YES];
        [_numberOfDiceSidesSlider setMinimumTrackTintColor:self.tintColor];
        
        [_numberOfDiceSidesSlider addTarget:self action:@selector(sliderTouched:) forControlEvents:UIControlEventTouchDragInside];
        [_numberOfDiceSidesSlider addTarget:self action:@selector(sliderTouched:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _numberOfDiceSidesSlider;
}

- (UILabel *)sizeOfDiceLabel {
    if (!_sizeOfDiceLabel) {
        _sizeOfDiceLabel = [[UILabel alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth, CELL_HEIGHT)];
        [_sizeOfDiceLabel setTextAlignment:NSTextAlignmentLeft];
        [_sizeOfDiceLabel setTextColor:[UIColor darkTextColor]];
        
        [_sizeOfDiceLabel setText:@"Size of dots on dice"];
        
        if (self.diceCountSlider.value <= 1) {
            [_sizeOfDiceLabel setText:@"Size of dots on die"];
        }
    }
    
    return _sizeOfDiceLabel;
}

- (UILabel *)sizeOfDiceLabelSMLXL {
    if (!_sizeOfDiceLabelSMLXL) {
        _sizeOfDiceLabelSMLXL = [[UILabel alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2, CELL_HEIGHT)];
        [_sizeOfDiceLabelSMLXL setText:[self sizeOfDotsLabelText]];
        [_sizeOfDiceLabelSMLXL setTextAlignment:NSTextAlignmentRight];
        [_sizeOfDiceLabelSMLXL setTextColor:[UIColor darkTextColor]];
    }
    
    return _sizeOfDiceLabelSMLXL;
}

- (UISlider *)sizeOfDiceDotsSlider {
    if (!_sizeOfDiceDotsSlider) {
        _sizeOfDiceDotsSlider = [[UISlider alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2, CELL_HEIGHT)];
        [_sizeOfDiceDotsSlider setMinimumValue:-1.0f];
        [_sizeOfDiceDotsSlider setMaximumValue:5.1f];
        [_sizeOfDiceDotsSlider setValue:[[GTPlayerManager sharedReferenceManager] sizeOfDiceDots] animated:YES];
        [_sizeOfDiceDotsSlider setMinimumTrackTintColor:self.tintColor];
        
        [_sizeOfDiceDotsSlider addTarget:self action:@selector(sliderTouched:) forControlEvents:UIControlEventTouchDragInside];
        [_sizeOfDiceDotsSlider addTarget:self action:@selector(sliderTouched:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _sizeOfDiceDotsSlider;
}

- (UILabel *)advancedDiceFeaturesLabel {
    if (!_advancedDiceFeaturesLabel) {
        _advancedDiceFeaturesLabel = [[UILabel alloc] initWithFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth, CELL_HEIGHT)];
        [_advancedDiceFeaturesLabel setTextAlignment:NSTextAlignmentLeft];
        [_advancedDiceFeaturesLabel setTextColor:[UIColor darkTextColor]];
        [_advancedDiceFeaturesLabel setText:@"Advanced Dice Features"];
    }
    
    return _advancedDiceFeaturesLabel;
}

- (UISwitch *)advancedDiceFeaturesSwitch {
    if (!_advancedDiceFeaturesSwitch) {
        _advancedDiceFeaturesSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(kScreenWidth - 40.0f, 0.0f, 40.0f, kScreenWidth)];
        [_advancedDiceFeaturesSwitch setOnTintColor:self.tintColor];
        [_advancedDiceFeaturesSwitch setOn:NO animated:YES];
        [_advancedDiceFeaturesSwitch addTarget:self action:@selector(updateViews) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _advancedDiceFeaturesSwitch;
}

#pragma mark - Size of Dots Label Text

- (NSString *)sizeOfDotsLabelText {
    int sizeOfDots = [[GTPlayerManager sharedReferenceManager] sizeOfDiceDots];
    
    switch (sizeOfDots) {
        case -1:
            return @"Tiny";
            break;
            
        case 0:
            return @"Extra-Small";
            break;
            
        case 1:
            return @"Small";
            break;
            
        case 2:
            return @"Medium";
            break;
            
        case 3:
            return @"Large";
            break;
            
        case 4:
            return @"Extra-Large";
            break;
            
        case 5:
            return @"Comically Large";
            break;
            
        default:
            break;
    }
    
    return @"";
}

#pragma mark - Table View Data Source and Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    
    switch (section) {
            // players
        case 0:
            numberOfRows = [[[GTPlayerManager sharedReferenceManager] players] count] + 1;
            if (numberOfRows > 9) {
                numberOfRows = 9;
            }
            break;
            
            // timer picker view
        case 1:
            numberOfRows = 1;
            break;
            
            // reset timers
        case 2:
            numberOfRows = 1;
            break;
        
            // reset scores
        case 3:
            numberOfRows = 1;
            break;
            
            // reset everything
        case 4:
            numberOfRows = 1;
            break;
            
            // dice
        case 5:
            if (self.advancedDiceFeaturesSwitch.on) {
                numberOfRows = 8;
            }
            
            else {
                numberOfRows = 4;
            }

            break;
            
            // reset dice
        case 6:
            numberOfRows = 1;
            break;
            
        default:
            break;
    }
    
    return numberOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // time picker section
    if ([indexPath section] == 1) {
        return PICKER_HEIGHT;
    }
    
    return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:GameTableCellIdentifier forIndexPath:indexPath];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
    }
    
    for (UIView *subview in cell.subviews) {
        [subview removeFromSuperview];
    }
    
    // players
    if ([indexPath section] == 0) {
        UITextField *textField = [self.textFields objectAtIndex:[indexPath row]];
        if ([[[GTPlayerManager sharedReferenceManager] players] count] > [indexPath row]) [textField setText:[[[[GTPlayerManager sharedReferenceManager] players] objectAtIndex:[indexPath row]] name]];
        [textField setFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2, CELL_HEIGHT)];
        [cell addSubview:textField];
    }
    
    // timer picker
    else if ([indexPath section] == 1) {
        [cell addSubview:self.timerPicker];
        [self.timerPicker setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, PICKER_HEIGHT)];
        [cell setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
    }
    
    // reset timer
    else if ([indexPath section] == 2) {
        [cell addSubview:self.resetTimeButton];
        [self.resetButton setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
    }
    
    // reset scores
    else if ([indexPath section] == 3) {
        [cell addSubview:self.resetScoreButton];
        [self.resetButton setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
    }
    
    // reset scores and timer
    else if ([indexPath section] == 4) {
        [cell addSubview:self.resetButton];
        [self.resetButton setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
    }
    
    // dice
    else if ([indexPath section] == 5) {
        // dice count label
        if ([indexPath row] == 0) {
            [cell addSubview:self.diceCountLabel];
            [cell addSubview:self.diceLabel];
            
            [self.diceLabel setFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
            [self.diceCountLabel setFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
            [self.diceCountLabel setText:[NSString stringWithFormat:@"%d", [[GTPlayerManager sharedReferenceManager] numberOfDice]]];
        }
        
        // number of dice
        else if ([indexPath row] == 1) {
            [cell addSubview:self.diceCountSlider];
            
            [self.diceCountSlider setFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
            
            [self.diceCountSlider setValue:[[GTPlayerManager sharedReferenceManager] numberOfDice] animated:YES];
        }
        
        // show dice total
        else if ([indexPath row] == 2) {
            [cell addSubview:self.showDiceTotalLabel];
            [cell addSubview:self.showDiceTotalSwitch];
            
            [self.showDiceTotalSwitch setFrame:CGRectMake(kScreenWidth - 70.0f, 4.0f, 40.0f, kScreenWidth)];
        }
        
        // advanced features switch
        else if ([indexPath row] == 3) {
            [cell addSubview:self.advancedDiceFeaturesLabel];
            [cell addSubview:self.advancedDiceFeaturesSwitch];
            
            [self.advancedDiceFeaturesSwitch setFrame:CGRectMake(kScreenWidth - 70.0f, 4.0f, 40.0f, kScreenWidth)];
        }
        
        // number of sides on dice label
        else if ([indexPath row] == 4) {
            [cell addSubview:self.numberOfDiceSidesLabel];
            [cell addSubview:self.numberOfDiceSidesCountLabel];
            
            [self.numberOfDiceSidesLabel setFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
            [self.numberOfDiceSidesCountLabel setFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
            
            [self.numberOfDiceSidesCountLabel setText:[NSString stringWithFormat:@"%d", [[GTPlayerManager sharedReferenceManager] numberOfDiceSides]]];
        }
        
        // number of sides on dice slider
        else if ([indexPath row] == 5) {
            [cell addSubview:self.numberOfDiceSidesSlider];
            
            [self.numberOfDiceSidesSlider setValue:[[GTPlayerManager sharedReferenceManager] numberOfDiceSides] animated:YES];
            [self.numberOfDiceSidesSlider setFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
        }
        
        // size of dice label
        else if ([indexPath row] == 6) {
            [cell addSubview:self.sizeOfDiceLabel];
            [cell addSubview:self.sizeOfDiceLabelSMLXL];
            
            [self.sizeOfDiceLabel setFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
            [self.sizeOfDiceLabelSMLXL setFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
            
            [self.sizeOfDiceLabelSMLXL setText:[self sizeOfDotsLabelText]];
        }
        
        // size of dice slider
        else if ([indexPath row] == 7) {
            [cell addSubview:self.sizeOfDiceDotsSlider];
            
            [self.sizeOfDiceDotsSlider setValue:[[GTPlayerManager sharedReferenceManager] sizeOfDiceDots] animated:YES];
            [self.sizeOfDiceDotsSlider setFrame:CGRectMake(BUFFER, 0.0f, kScreenWidth - BUFFER * 2.0f, CELL_HEIGHT)];
        }
    }
    
    else if ([indexPath section] == 6) {
        [cell addSubview:self.resetDiceButton];
        [self.resetDiceButton setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, CELL_HEIGHT)];
    }
    
    else if ([indexPath section] == 7) {
        [cell setBackgroundColor:[UIColor royalBlue2]];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Selected row: %@", indexPath);
    
    if ([indexPath section] == 1) {
        [self.playerTableView reloadData];
    }
    
    return NO;
}

#pragma mark - Text Field Delegate Methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (kScreenHeight < 480.0f) {
        return NO;
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self filterThroughTextFields];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
//    [self filterThroughTextFields];
    [textField resignFirstResponder];
    return YES;
}

- (void)filterThroughTextFields {
    BOOL shouldReset = NO;

    // iterate through all text fields and pull out just the ones that have names in them
    NSMutableArray *playerNames = [[NSMutableArray alloc] init];
    NSMutableDictionary *playerNamePositions = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [self.textFields count]; i++) {
        UITextField *preMadeTextField = [self.textFields objectAtIndex:i];
        if ([[preMadeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
            NSString *name = [preMadeTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [playerNames addObject:name];
            [playerNamePositions setObject:[NSNumber numberWithInt:i] forKey:name];
        }
        
        [preMadeTextField setText:@""];
    }
    
    if ([playerNames count] != [[[GTPlayerManager sharedReferenceManager] players] count]) {
        shouldReset = YES;
    }
    
    // iterate through all players that exist and cross reference with the names to see which ones need to be added and which ones need to be removed
    NSMutableArray *playersToRemove = [[NSMutableArray alloc] init];
    for (GTPlayer *player in [[GTPlayerManager sharedReferenceManager] players]) {
        BOOL playerExists = NO;
        
        for (int i = 0; i < playerNames.count; i++) {
            NSString *playerName = [playerNames objectAtIndex:i];
            
            if ([player.name isEqualToString:playerName]) {
                playerExists = YES;
                [playerNames removeObject:playerName];
            }
        }
        
        if (!playerExists) {
            [playersToRemove addObject:player];
        }
    }
    
    // create new players for new names
    for (int i = 0; i < [playerNames count]; i++) {
        NSString *playerName = [playerNames objectAtIndex:i];
        GTPlayer *newPlayer = [[GTPlayer alloc] initWithName:playerName];
        [newPlayer setName:playerName];
        [newPlayer setTimeRemaining:self.timerPicker.time];
        [[GTPlayerManager sharedReferenceManager] addPlayer:newPlayer atIndex:[[playerNamePositions objectForKey:playerName] intValue]];
    }
    
    [[GTPlayerManager sharedReferenceManager] removePlayers:playersToRemove];
    
    // if there are more players than there were before, then reset each player's score
    if (shouldReset) {
        [self resetGame];
    }
    
    [self.playerTableView reloadData];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if ([textField.text rangeOfString:@"Player "].location != NSNotFound) {
        if (string.length <= 0) {
            [textField setText:@""];
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Button Actions

- (void)resetButtonTouched {
    [self resetGame];
}

- (void)resetTimerButtonTouched {
    [[GTPlayerManager sharedReferenceManager] resetTimers:self.timerPicker.time];
    [self flashButton:self.resetTimeButton];
}

- (void)resetScoresButtonTouched {
    [[GTPlayerManager sharedReferenceManager] resetScores];
    [self flashButton:self.resetScoreButton];
}

- (void)resetGame {
    [[GTPlayerManager sharedReferenceManager] resetScores];
    [[GTPlayerManager sharedReferenceManager] resetTimers:self.timerPicker.time];
    [self flashButton:self.resetButton];
}

- (void)resetDiceButtonTouched {
    [[GTPlayerManager sharedReferenceManager] setNumberOfDiceSides:6];
    [[GTPlayerManager sharedReferenceManager] setNumberOfDice:5];
    [self.showDiceTotalSwitch setOn:NO animated:YES];
    [self switchShowDice];
    
    [self.numberOfDiceSidesCountLabel setText:[NSString stringWithFormat:@"%d", [[GTPlayerManager sharedReferenceManager] numberOfDiceSides]]];
    [self.diceCountLabel setText:[NSString stringWithFormat:@"%d", [[GTPlayerManager sharedReferenceManager] numberOfDice]]];
    
    [self.diceCountSlider setValue:[[GTPlayerManager sharedReferenceManager] numberOfDice] animated:YES];
    [self.numberOfDiceSidesSlider setValue:[[GTPlayerManager sharedReferenceManager] numberOfDiceSides] animated:YES];
    
    [self flashButton:self.resetDiceButton];
}

- (void)sliderTouched:(UISlider *)slider {
    if ([slider isEqual:self.diceCountSlider]) {
        [self.diceCountLabel setText:[NSString stringWithFormat:@"%d", (int)self.diceCountSlider.value]];
        if (self.diceCountSlider.value <= 1) {
            [self.numberOfDiceSidesLabel setText:@"Number of sides on die"];
        }
        
        else {
            [self.numberOfDiceSidesLabel setText:@"Number of sides on dice"];
        }
        [[GTPlayerManager sharedReferenceManager] setNumberOfDice:self.diceCountSlider.value];
    }
    
    else if ([slider isEqual:self.numberOfDiceSidesSlider]) {
        [self.numberOfDiceSidesCountLabel setText:[NSString stringWithFormat:@"%d", (int)self.numberOfDiceSidesSlider.value]];
        [[GTPlayerManager sharedReferenceManager] setNumberOfDiceSides:self.numberOfDiceSidesSlider.value];
    }
    
    else if ([slider isEqual:self.sizeOfDiceDotsSlider]) {
        [self.sizeOfDiceLabelSMLXL setText:[self sizeOfDotsLabelText]];
        [[GTPlayerManager sharedReferenceManager] setSizeOfDiceDots:self.sizeOfDiceDotsSlider.value];
    }
}

- (void)flashButton:(UIView *)button {
    [UIView animateWithDuration:0.17f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [button setBackgroundColor:[UIColor red]];
    }completion:^(BOOL finished){
        [UIView animateWithDuration:0.18f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [button setBackgroundColor:self.tintColor];
        }completion:^(BOOL finished){}];
    }];
}

- (void)switchShowDice {
    [[GTPlayerManager sharedReferenceManager] changeShowDiceTotal:self.showDiceTotalSwitch.on];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithBool:self.showDiceTotalSwitch.on] forKey:@"showDiceTotal"];
}

#pragma mark - Keyboard Notifications

- (void)keyboardDidShow:(NSNotification *)notification {
    self.keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    self.keyboardIsShowing = YES;
    
    [self updateViews];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    self.keyboardHeight = FOOTER_HEIGHT;
    self.keyboardIsShowing = NO;
    
    [self updateViews];
}

#pragma mark Motion Gesture Methods

- (BOOL)canBecomeFirstResponder {
    return !self.keyboardIsShowing;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake ) {
        NSMutableArray *players = [NSMutableArray arrayWithArray:[[GTPlayerManager sharedReferenceManager] players]];;
        NSMutableString *playerString = [[NSMutableString alloc] init];
        int currentPlayerCount = 1;
        while (players.count > 0) {
            GTPlayer *currentPlayer = [players objectAtIndex:arc4random()%players.count];
            [playerString appendFormat:@"%d. %@\n", currentPlayerCount, currentPlayer.name];
            [players removeObject:currentPlayer];
            currentPlayerCount++;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Random order of players" message:[playerString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            
        }];
        [alertController addAction:okAction];
        
        UIAlertAction *newOrderAction = [UIAlertAction actionWithTitle:@"New Order" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self motionBegan:motion withEvent:event];
        }];
        [alertController addAction:newOrderAction];
        
        [self presentViewController:alertController animated:YES completion:^{
            
        }];
    }
}

@end
