//
//  GTDieView.h
//  Game Toolkit
//
//  Created by Developer Nathan on 2/11/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GTDieView : UIView

@property int maximumChanges;
@property int value;
@property BOOL selected, selectable;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIView *shadingView;

- (void)randomize;
- (void)drawSpots;
- (void)dieTapped;

@end
