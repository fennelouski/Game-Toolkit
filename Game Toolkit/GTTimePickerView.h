//
//  GTTimePickerView.h
//  Game Toolkit
//
//  Created by Developer Nathan on 2/11/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GTTimePickerView : UIPickerView <UIPickerViewDelegate, UIPickerViewDataSource>

@property NSTimeInterval time;
@property (nonatomic, strong) NSString *timeString;
@property (nonatomic, strong) UILabel *hourLabel, *minuteLabel, *secondLabel;

@end
