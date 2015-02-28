//
//  GTDieView.m
//  Game Toolkit
//
//  Created by Developer Nathan on 2/11/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTDieView.h"
#import "GTPlayerManager.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kStatusBarHeight (([[UIApplication sharedApplication] statusBarFrame].size.height == 20.0f) ? 20.0f : (([[UIApplication sharedApplication] statusBarFrame].size.height == 40.0f) ? 20.0f : 0.0f))
#define kScreenHeight (([[UIApplication sharedApplication] statusBarFrame].size.height > 20.0f) ? [UIScreen mainScreen].bounds.size.height - 20.0f : [UIScreen mainScreen].bounds.size.height)
#define FONT_SIZE_RATIO 1.8f
#define CORNER_RADIUS_RATIO 5.0f

@implementation GTDieView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.selectable = YES;
        self.value = arc4random()%[[GTPlayerManager sharedReferenceManager] numberOfDiceSides] + 1;
        
        [self setBackgroundColor:[UIColor lightGrayColor]];
        
        [self drawSpots];
        
//        [self.layer setBorderColor:[UIColor blackColor].CGColor];
//        [self.layer setBorderWidth:self.frame.size.height / 20.0f];
        [self.layer setCornerRadius:frame.size.height / CORNER_RADIUS_RATIO];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dieTapped)];
        [self addGestureRecognizer:tap];
        
        [self addSubview:self.shadingView];
    }
    
    return self;
}

- (void)randomize {
    [self.valueLabel setFont:[UIFont systemFontOfSize:self.frame.size.height/FONT_SIZE_RATIO]];
    
    self.maximumChanges = arc4random()%12 + 8;
    if (!self.selected) {
        [self animateSpots:[NSNumber numberWithInt:0]];
    }
}

- (void)animateSpots:(NSNumber *)changesMade {
    int changesMadeInt = [changesMade intValue];
    
    self.value = arc4random()%[[GTPlayerManager sharedReferenceManager] numberOfDiceSides] + 1;
    [self drawSpots];
    
    if (changesMadeInt < self.maximumChanges) {
        NSNumber *changesToBeMade = [NSNumber numberWithInt:changesMadeInt + 1];
        float duration = ((float)(changesMadeInt + 1)) / (180.0f + (float)self.maximumChanges);
        [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            float randomX = (((float)(arc4random()%100))/50.0f - 1.0f) * self.frame.size.width / (20.0f + changesMadeInt*2);
            float randomY = (((float)(arc4random()%100))/50.0f - 1.0f) * self.frame.size.height / (20.0f + changesMadeInt*2);
            self.center = CGPointMake(self.center.x + randomX, self.center.y + randomY);
        } completion:^(BOOL finished){
            [self animateSpots:changesToBeMade];
        }];
    }
}

- (void)drawSpots {
    [self.layer setCornerRadius:self.frame.size.height / CORNER_RADIUS_RATIO];
    
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    [self addSubview:self.shadingView];
    [self.shadingView setFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    [self.shadingView setCenter:CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f)];
    
    if (self.value == 0) {
        self.value = arc4random()%[[GTPlayerManager sharedReferenceManager] numberOfDiceSides] + 1;
    }
    
    float sideDistance = 4.6f;
    float marginRatio = 1.2f;
    float sideNumator = sideDistance - marginRatio;
    float dotSize = self.frame.size.height / (9.0f - [[GTPlayerManager sharedReferenceManager] sizeOfDiceDots]);
    float cornerRadius = dotSize/1.88f;
    
    if ([[GTPlayerManager sharedReferenceManager] numberOfDiceSides] < 7) {
        // middle dot
        if (self.value == 1 || self.value == 3 || self.value == 5) {
            UIView *centerSpot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2.0f - dotSize / 2.0f,
                                                                          self.frame.size.height / 2.0f - dotSize / 2.0f,
                                                                          dotSize,
                                                                          dotSize)];
            [centerSpot setCenter:CGPointMake(self.frame.size.width / 2.0f,
                                              self.frame.size.height / 2.0f)];
            [centerSpot.layer setCornerRadius:cornerRadius];
            [centerSpot setBackgroundColor:[UIColor blackColor]];
            [self addSubview:centerSpot];
        }
        
        // top left and bottom right corners
        if (self.value == 2 || self.value == 3 || self.value == 4 || self.value == 5 || self.value == 6) {
            UIView *topLeftSpot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * marginRatio/ sideDistance - dotSize / 2.0f,
                                                                           self.frame.size.height * marginRatio / sideDistance - dotSize / 2.0f,
                                                                           dotSize,
                                                                           dotSize)];
            [topLeftSpot setCenter:CGPointMake(self.frame.size.width * marginRatio / sideDistance,
                                               self.frame.size.height * marginRatio / sideDistance)];
            [topLeftSpot.layer setCornerRadius:cornerRadius];
            [topLeftSpot setBackgroundColor:[UIColor blackColor]];
            [self addSubview:topLeftSpot];

            UIView *bottomRightSpot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * sideNumator / sideDistance - dotSize / 2.0f,
                                                                               self.frame.size.height * sideNumator / sideDistance - dotSize / 2.0f,
                                                                               dotSize,
                                                                               dotSize)];
            [bottomRightSpot setCenter:CGPointMake(self.frame.size.width * sideNumator / sideDistance,
                                                   self.frame.size.height * sideNumator / sideDistance)];
            [bottomRightSpot.layer setCornerRadius:cornerRadius];
            [bottomRightSpot setBackgroundColor:[UIColor blackColor]];
            [self addSubview:bottomRightSpot];
        }
        
        // bottom left and top right corners
        if (self.value == 4 || self.value == 5 || self.value == 6) {
            UIView *topRightSpot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * sideNumator / sideDistance - dotSize / 2.0f,
                                                                            self.frame.size.height * marginRatio / sideDistance - dotSize / 2.0f,
                                                                            dotSize,
                                                                            dotSize)];
            [topRightSpot setCenter:CGPointMake(self.frame.size.width * sideNumator / sideDistance,
                                                self.frame.size.height * marginRatio / sideDistance)];
            [topRightSpot.layer setCornerRadius:cornerRadius];
            [topRightSpot setBackgroundColor:[UIColor blackColor]];
            [self addSubview:topRightSpot];
            
            UIView *bottomLeftSpot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * marginRatio / sideDistance - dotSize / 2.0f,
                                                                              self.frame.size.height * sideNumator / sideDistance - dotSize / 2.0f,
                                                                              dotSize,
                                                                              dotSize)];
            [bottomLeftSpot setCenter:CGPointMake(self.frame.size.width * marginRatio / sideDistance,
                                                  self.frame.size.height * sideNumator / sideDistance)];
            [bottomLeftSpot.layer setCornerRadius:cornerRadius];
            [bottomLeftSpot setBackgroundColor:[UIColor blackColor]];
            [self addSubview:bottomLeftSpot];
        }
        
        // middle of the sides
        if (self.value == 6) {
            UIView *leftSpot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * marginRatio / sideDistance - dotSize / 2.0f,
                                                                        self.frame.size.height / 2.0f - dotSize / 2.0f,
                                                                        dotSize,
                                                                        dotSize)];
            [leftSpot setCenter:CGPointMake(self.frame.size.width * marginRatio / sideDistance,
                                            self.frame.size.height / 2.0f)];
            [leftSpot.layer setCornerRadius:cornerRadius];
            [leftSpot setBackgroundColor:[UIColor blackColor]];
            [self addSubview:leftSpot];
            
            UIView *rightSpot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * sideNumator / sideDistance - dotSize / 2.0f,
                                                                         self.frame.size.height / 2.0f - dotSize / 2.0f,
                                                                         dotSize,
                                                                         dotSize)];
            [rightSpot setCenter:CGPointMake(self.frame.size.width * sideNumator / sideDistance,
                                             self.frame.size.height / 2.0f)];
            [rightSpot.layer setCornerRadius:cornerRadius];
            [rightSpot setBackgroundColor:[UIColor blackColor]];
            [self addSubview:rightSpot];
        }
    }
    
    else {
        [self addSubview:self.valueLabel];
        [self.valueLabel setText:[NSString stringWithFormat:@"%d", self.value]];
        [self.valueLabel setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, kScreenHeight)];
        [self.valueLabel setCenter:CGPointMake(self.frame.size.width/2.0f, self.frame.size.height/2.0f)];
    }
}

- (void)dieTapped {
    self.selected = !self.selected;
    
    if (self.selected) {
        float grayValue = ((float)((arc4random()%20) + 35.0f) / 100.0f);
        [self.shadingView setBackgroundColor:[UIColor colorWithWhite:grayValue alpha:1.0f]];
        [self setBackgroundColor:[UIColor darkGrayColor]];
    }
    
    else {
        [self.shadingView setBackgroundColor:[UIColor whiteColor]];
        [self setBackgroundColor:[UIColor lightGrayColor]];
    }
    
    self.selectable = YES;
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
    self.selectable = NO;
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    CGPoint previous = [touch previousLocationInView:self];
    
    if (!CGAffineTransformIsIdentity(self.transform)) {
        location = CGPointApplyAffineTransform(location, self.transform);
        previous = CGPointApplyAffineTransform(previous, self.transform);
    }
    
    self.frame = CGRectOffset(self.frame,
                              (location.x - previous.x),
                              (location.y - previous.y));
}


#pragma mark - Subviews

- (UILabel *)valueLabel {
    if (!_valueLabel) {
        _valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
        [_valueLabel setFont:[UIFont systemFontOfSize:self.frame.size.height/FONT_SIZE_RATIO]];
        [_valueLabel setTextAlignment:NSTextAlignmentCenter];
        [_valueLabel setTextColor:[UIColor darkTextColor]];
        [_valueLabel setText:[NSString stringWithFormat:@"%d", self.value]];
        [_valueLabel setClipsToBounds:NO];
    }
    
    return _valueLabel;
}

- (UIView *)shadingView {
    if (!_shadingView) {
        _shadingView = [[UILabel alloc] initWithFrame:self.bounds];
        [_shadingView.layer setCornerRadius:self.frame.size.width/(CORNER_RADIUS_RATIO * 0.3f)];
        [_shadingView setBackgroundColor:[UIColor whiteColor]];
        [_shadingView setClipsToBounds:YES];
    }
    
    return _shadingView;
}

@end
