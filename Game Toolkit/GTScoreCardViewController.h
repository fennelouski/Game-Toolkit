//
//  GTScoreCardViewController.h
//  Game Timer
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GTScoreCardViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) NSMutableArray *playerTables;
@property (nonatomic, strong) UIScrollView *tableScrollView;
@property (nonatomic, strong) UITextField *currentFirstResponder;
@property (nonatomic, strong) UIToolbar *accessoryView;
@property (nonatomic, strong) UIButton *negativeButton, *saveButton;
@property (nonatomic, strong) NSMutableArray *headerSubviews, *textFields;
@property (nonatomic, strong) UIToolbar *headerToolbar;
@property float cellWidth, keyboardHeight;
@property BOOL firstResponderLoopCheck, keyboardIsShowing;
@property BOOL allowForPiDay;

@end
