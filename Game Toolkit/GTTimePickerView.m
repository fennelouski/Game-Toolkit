//
//  GTTimePickerView.m
//  Game Toolkit
//
//  Created by Developer Nathan on 2/11/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTTimePickerView.h"
#import "GTPlayerManager.h"

@implementation GTTimePickerView

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [self updateViews];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self updateViews];
    }
    
    return self;
}

- (void)updateViews {
    [self addSubview:self.hourLabel];
    [self addSubview:self.minuteLabel];
    [self addSubview:self.secondLabel];
    
    self.delegate = self;
    self.dataSource = self;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *lastTime = [defaults objectForKey:@"Last Time Per User"];
    
    if (lastTime) {
        int hours = [lastTime floatValue] / 3600.0f;
        int minutes = ((int)[lastTime floatValue] % 3600) / 60.0f;
        int seconds = ((int)[lastTime floatValue] % 60);
        
        [self selectRow:hours inComponent:0 animated:YES];
        [self selectRow:minutes inComponent:1 animated:YES];
        [self selectRow:seconds inComponent:2 animated:YES];
    }
    
    else {
        [self selectRow:0 inComponent:0 animated:YES];
        [self selectRow:1 inComponent:1 animated:YES];
        [self selectRow:30 inComponent:2 animated:YES];
    }
    
    self.time = [self selectedRowInComponent:0] * 3600 + [self selectedRowInComponent:1] * 60 + [self selectedRowInComponent:2];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.hourLabel setFrame:CGRectMake(42.0f, self.frame.size.height / 2.0f - 15.0f, 75.0f, 30.0f)];
    [self.minuteLabel setFrame:CGRectMake(42.0f + self.frame.size.width / 3.0f, self.frame.size.height / 2.0f - 15.0f, 75.0f, 30.0f)];
    [self.secondLabel setFrame:CGRectMake(42.0f + self.frame.size.width * 2.0f / 3.0f, self.frame.size.height / 2.0f - 15.0f, 75.0f, 30.0f)];
}

#pragma mark - Subviews

- (UILabel *)hourLabel {
    if (!_hourLabel) {
        _hourLabel = [[UILabel alloc] initWithFrame:CGRectMake(42.0f, self.frame.size.height / 2.0f - 15.0f, 75.0f, 30.0f)];
        [_hourLabel setText:@"Hour"];
    }
    
    return _hourLabel;
}

- (UILabel *)minuteLabel {
    if (!_minuteLabel) {
        _minuteLabel = [[UILabel alloc] initWithFrame:CGRectMake(42.0f + self.frame.size.width / 3.0f, self.frame.size.height / 2.0f - 15.0f, 75.0f, 30.0f)];
        [_minuteLabel setText:@"Min"];
    }
    
    return _minuteLabel;
}

- (UILabel *)secondLabel {
    if (!_secondLabel) {
        _secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(42.0f + self.frame.size.width * 2.0f / 3.0f, self.frame.size.height / 2.0f - 15.0f, 75.0f, 30.0f)];
        [_secondLabel setText:@"Sec"];
    }
    
    return _secondLabel;
}

#pragma mark - Picker View Delegate and Data Source Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 3;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(component == 0)
        return 24;
    
    return 60;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 30;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @"1234";
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *columnView = [[UILabel alloc] initWithFrame:CGRectMake(35, 0, self.frame.size.width/3 - 35, 30)];
    columnView.text = [NSString stringWithFormat:@"%lu", (long)row];
    columnView.textAlignment = NSTextAlignmentLeft;
    
    return columnView;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.time = [self selectedRowInComponent:0] * 3600 + [self selectedRowInComponent:1] * 60 + [self selectedRowInComponent:2];
    [[GTPlayerManager sharedReferenceManager] updateTimers:self.time];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithFloat:self.time] forKey:@"Last Time Per User"];
}



@end
