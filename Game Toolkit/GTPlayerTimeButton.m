//
//  GTPlayerTimeButton.m
//  Game Toolkit
//
//  Created by Developer Nathan on 2/11/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTPlayerTimeButton.h"
#import "GTPlayerManager.h"
#import "UIColor+AppColors.h"
#import "NSString+AppFunctions.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kStatusBarHeight (([[UIApplication sharedApplication] statusBarFrame].size.height == 20.0f) ? 20.0f : (([[UIApplication sharedApplication] statusBarFrame].size.height == 40.0f) ? 20.0f : 0.0f))
#define kScreenHeight (([[UIApplication sharedApplication] statusBarFrame].size.height > 20.0f) ? [UIScreen mainScreen].bounds.size.height - 20.0f : [UIScreen mainScreen].bounds.size.height)
#define ANIMATION_DURATION 0.25f
#define DESELECTED_BRIGHTNESS 0.4f
#define SELECTED_BRIGHTNESS 0.75f

@implementation GTPlayerTimeButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self addTarget:self action:@selector(buttonTouched) forControlEvents:UIControlEventTouchUpInside];
        
        [self performSelector:@selector(updateTimerLabel) withObject:self afterDelay:0.03f];
        
        [self calculateFontSize];
        
        [self.layer addSublayer:self.gradientLayer];
    }
    
    return self;
}

- (void)calculateFontSize {
    NSInteger playerCount = [[[GTPlayerManager sharedReferenceManager] players] count];
    
    float fontSize = 30.0f;
    
    if ((kScreenWidth + kScreenHeight) / [[[GTPlayerManager sharedReferenceManager] players] count] > 150.0f) {
        fontSize = 30.0f;
    }
    
    else if (playerCount % 2 == 0 && playerCount <= 10) {
        fontSize = 30.0f;
    }
    
    else if (playerCount % 3 == 0) {
        fontSize = 28.0f;
    }
    
    else if (playerCount % 5 == 0) {
        fontSize = 22.0f;
    }
    
    else if (playerCount % 7 == 0) {
        fontSize = 20.0f;
    }
    
    else {
        fontSize = 30.0f;
    }
    
    self.font = [UIFont systemFontOfSize:fontSize];
}

- (void)updateTimerLabel {
    if (self.player && self.nameLabel.text.length == 0) {
        [self updateName];
    }
    
    if (self.player && self.player.timeRemaining > 0.0f) {
        [self.timeLabel setText:[NSString stringWithFormat:@"%d", (int)self.player.timeRemaining]];
    }
    
    else if (self.player && [self.timeLabel.text floatValue] != 0.0f) {
        [self.timeLabel setText:@"0"];
    }
    
    [self performSelector:@selector(updateTimerLabel) withObject:self afterDelay:0.03f];
}

- (void)layoutSubviews {
    [self addSubview:self.nameLabel];
    [self addSubview:self.timeLabel];
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.nameLabel setFrame:CGRectMake(0.0f,
                                            self.frame.size.height / 3.0f,
                                            self.frame.size.width,
                                            self.frame.size.height / 3.0f)];
        [self.timeLabel setFrame:CGRectMake(0.0f,
                                            self.frame.size.height / 2.0f,
                                            self.frame.size.width,
                                            self.frame.size.height / 3.0f)];
        [self.nameLabel setCenter:CGPointMake(self.frame.size.width / 2.0f,
                                              self.frame.size.height / 3.0f)];
        [self.timeLabel setCenter:CGPointMake(self.frame.size.width / 2.0f,
                                              self.frame.size.height * 2.0f / 3.0f)];
        
        [self.gradientLayer setFrame:CGRectMake(0.0f,
                                                0.0f,
                                                self.frame.size.width,
                                                self.frame.size.height)];
        
        if (self.selected) {
            NSNumber *stopOne = [NSNumber numberWithFloat:0.75f];
            NSNumber *stopTwo = [NSNumber numberWithFloat:1.3f];
            
            NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
            [self.gradientLayer setLocations:locations];
        }
        
        else {
            NSNumber *stopOne = [NSNumber numberWithFloat:0.5f];
            NSNumber *stopTwo = [NSNumber numberWithFloat:1.0f];
            
            NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
            [self.gradientLayer setLocations:locations];
        }
    }];

    [self updateName];
}

- (void)updateName {
    [self.nameLabel setText:self.player.name];

    CGSize labelSize = [[self.nameLabel text] sizeWithAttributes:@{NSFontAttributeName:self.font}];
    NSArray *names = [self.player.name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([names count] > 1 && labelSize.width > self.nameLabel.frame.size.width) {
        [self.nameLabel setText:[NSString stringWithFormat:@"%@ %c", [names firstObject], [[names lastObject] characterAtIndex:0]]];
        labelSize = [[self.nameLabel text] sizeWithAttributes:@{NSFontAttributeName:self.font}];
        
        if (labelSize.width > self.nameLabel.frame.size.width) {
            [self.nameLabel setText:[NSString stringWithFormat:@"%c %c", [[names firstObject] characterAtIndex:0], [[names lastObject] characterAtIndex:0]]];
        }
    }
    
    NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComps = [gregorianCal components: (NSCalendarUnitMonth | NSCalendarUnitDay)
                                                  fromDate: [NSDate date]];

    if ([dateComps month] == 3 && [dateComps day] == 14) {
        [self.nameLabel setText:[self.nameLabel.text piIfy]];
    }
}

#pragma mark - Subviews

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,
                                                               self.frame.size.height / 3.0f,
                                                               self.frame.size.width,
                                                               self.frame.size.height / 3.0f)];
        [_nameLabel setTextAlignment:NSTextAlignmentCenter];
        [_nameLabel setTextColor:[UIColor whiteColor]];
        [_nameLabel setCenter:CGPointMake(self.frame.size.width / 2.0f,
                                              self.frame.size.height / 3.0f)];
        [_nameLabel setFont:self.font];
    }
    
    return _nameLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,
                                                               self.frame.size.height / 2.0f,
                                                               self.frame.size.width,
                                                               self.frame.size.height / 3.0f)];
        [_timeLabel setTextAlignment:NSTextAlignmentCenter];
        [_timeLabel setTextColor:[UIColor whiteColor]];
        [_timeLabel setCenter:CGPointMake(self.frame.size.width / 2.0f,
                                          self.frame.size.height * 2.0f / 3.0f)];
        [_timeLabel setFont:self.font];
    }
    
    return _timeLabel;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [self lightBlueGradient];
        [_gradientLayer setFrame:self.bounds];
    }
    
    return _gradientLayer;
}

- (void)buttonTouched {
    [[GTPlayerManager sharedReferenceManager] makeCurrentPlayer:self.player];
}

- (CAGradientLayer *)lightBlueGradient {
    NSArray *colors = [NSArray arrayWithObjects:(id)[UIColor clearColor].CGColor, [UIColor colorWithWhite:0.0f alpha:0.5f].CGColor, nil];
    
    NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComps = [gregorianCalendar components:(NSCalendarUnitHour) fromDate: [NSDate date]];
    NSInteger hour = [dateComps hour];
    
    if (hour < 6 || hour > 22) {
        colors = @[(id)[UIColor clearColor].CGColor,
                   (id)[UIColor blackColor].CGColor];
    }
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.5f];
    NSNumber *stopTwo = [NSNumber numberWithFloat:1.0f];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.locations = locations;
    
    return headerLayer;
}

@end
