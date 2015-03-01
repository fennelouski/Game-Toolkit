//
//  GTPlayerTimeButton.h
//  Game Toolkit
//
//  Created by Developer Nathan on 2/11/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTPlayer.h"

@interface GTPlayerTimeButton : UIButton

@property (nonatomic, strong) GTPlayer *player;
@property (nonatomic, strong) UILabel *nameLabel, *timeLabel;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end
