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
#define degreesToRadians(x) (M_PI * (x) / 180.0)
#define kAnimationRotateDeg 0.5f
#define kAnimationTranslateX 2.0f
#define kAnimationTranslateY 2.0f

@implementation GTDieView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.selectable = YES;
        self.value = arc4random()%[[GTPlayerManager sharedReferenceManager] numberOfDiceSides] + 1;
        [self setClipsToBounds:YES];
        
        [self setBackgroundColor:[[GTPlayerManager sharedReferenceManager] diceColor]];
        
        [self drawSpots];
        
        [self.layer setBorderColor:[[GTPlayerManager sharedReferenceManager] diceBorderColor].CGColor];
        [self.layer setBorderWidth:self.frame.size.height / 20.0f];
        [self.layer setCornerRadius:frame.size.height / CORNER_RADIUS_RATIO];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dieTapped)];
        [self addGestureRecognizer:tap];
        
        [self addSubview:self.shadingView];
        
        self.defaultFrame = frame;
        self.theta = 0.0f;
    }
    
    return self;
}

- (void)randomize {
    [self.valueLabel setFont:[UIFont systemFontOfSize:self.frame.size.height/FONT_SIZE_RATIO]];
    
    self.maximumChanges = arc4random()%12 + 8;
    if (!self.selected) {
        [self animateSpots:[NSNumber numberWithInt:0]];
        float randomDelay = ((float)(arc4random()%50))/100.0f;
        [self performSelector:@selector(startJiggling) withObject:self afterDelay:randomDelay];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self setBackgroundColor:[[GTPlayerManager sharedReferenceManager] diceColor]];
    [self.layer setBorderColor:[[GTPlayerManager sharedReferenceManager] diceBorderColor].CGColor];
    [self.layer addSublayer:self.gradientLayer];
    [self.gradientLayer setFrame:self.bounds];
}

- (void)animateSpots:(NSNumber *)changesMade {
    int changesMadeInt = [changesMade intValue];
    
    self.value = arc4random()%[[GTPlayerManager sharedReferenceManager] numberOfDiceSides] + 1;
    [self drawSpots];
    
    if (changesMadeInt < self.maximumChanges) {
        float duration = ((float)(changesMadeInt + 1)) / (180.0f + (float)self.maximumChanges);
        [UIView animateWithDuration:duration delay:0.0f usingSpringWithDamping:0.001f initialSpringVelocity:10.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            float randomX = (((float)(arc4random()%100))/50.0f - 1.0f) * self.frame.size.width / (20.0f + changesMadeInt*2);
            float randomY = (((float)(arc4random()%100))/50.0f - 1.0f) * self.frame.size.height / (20.0f + changesMadeInt*2);
            self.center = CGPointMake(self.center.x + randomX, self.center.y + randomY);
        } completion:^(BOOL finished){
            NSNumber *changesToBeMade = [NSNumber numberWithInt:changesMadeInt + 1];
            [self animateSpots:changesToBeMade];
        }];
    }
    
    else {
        [self performSelector:@selector(stopJiggling) withObject:self afterDelay:0.2f];
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
    float marginRatio = 1.0f;
    float recenteringAmount = 0.04f;
    float sideNumator = sideDistance - marginRatio - recenteringAmount;
    float dotSize = self.frame.size.height / (9.0f - [[GTPlayerManager sharedReferenceManager] sizeOfDiceDots] * 1.2f);
    float cornerRadius = dotSize/1.89f;
    
    UIColor *dotColor = [[GTPlayerManager sharedReferenceManager] diceDotsColor];
    
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
            [centerSpot setBackgroundColor:dotColor];
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
            [topLeftSpot setBackgroundColor:dotColor];
            [self addSubview:topLeftSpot];

            UIView *bottomRightSpot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * sideNumator / sideDistance - dotSize / 2.0f,
                                                                               self.frame.size.height * sideNumator / sideDistance - dotSize / 2.0f,
                                                                               dotSize,
                                                                               dotSize)];
            [bottomRightSpot setCenter:CGPointMake(self.frame.size.width * sideNumator / sideDistance,
                                                   self.frame.size.height * sideNumator / sideDistance)];
            [bottomRightSpot.layer setCornerRadius:cornerRadius];
            [bottomRightSpot setBackgroundColor:dotColor];
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
            [topRightSpot setBackgroundColor:dotColor];
            [self addSubview:topRightSpot];
            
            UIView *bottomLeftSpot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * marginRatio / sideDistance - dotSize / 2.0f,
                                                                              self.frame.size.height * sideNumator / sideDistance - dotSize / 2.0f,
                                                                              dotSize,
                                                                              dotSize)];
            [bottomLeftSpot setCenter:CGPointMake(self.frame.size.width * marginRatio / sideDistance,
                                                  self.frame.size.height * sideNumator / sideDistance)];
            [bottomLeftSpot.layer setCornerRadius:cornerRadius];
            [bottomLeftSpot setBackgroundColor:dotColor];
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
            [leftSpot setBackgroundColor:dotColor];
            [self addSubview:leftSpot];
            
            UIView *rightSpot = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width * sideNumator / sideDistance - dotSize / 2.0f,
                                                                         self.frame.size.height / 2.0f - dotSize / 2.0f,
                                                                         dotSize,
                                                                         dotSize)];
            [rightSpot setCenter:CGPointMake(self.frame.size.width * sideNumator / sideDistance,
                                             self.frame.size.height / 2.0f)];
            [rightSpot.layer setCornerRadius:cornerRadius];
            [rightSpot setBackgroundColor:dotColor];
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
        [self.shadingView setBackgroundColor:[UIColor colorWithWhite:grayValue alpha:0.97f]];
    }
    
    else {
        [self.shadingView setBackgroundColor:[UIColor clearColor]];
        [self setBackgroundColor:[[GTPlayerManager sharedReferenceManager] diceColor]];
    }
    
    self.selectable = YES;
}

- (void)startJiggling {
    NSInteger randomInt = arc4random_uniform(500);
    float r = (randomInt/500.0)+0.5;
    
    CGAffineTransform leftWobble = CGAffineTransformMakeRotation(degreesToRadians((kAnimationRotateDeg * -1.0) - r ));
    CGAffineTransform rightWobble = CGAffineTransformMakeRotation(degreesToRadians(kAnimationRotateDeg + r ));
    
    self.transform = leftWobble;  // starting point
    
    [[self layer] setAnchorPoint:CGPointMake(0.5, 0.5)];
    
    [UIView animateWithDuration:0.1
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse
                     animations:^{
                         [UIView setAnimationRepeatCount:NSNotFound];
                         self.transform = rightWobble; }
                     completion:nil];
}
- (void)stopJiggling {
    [self.layer removeAllAnimations];
    self.transform = CGAffineTransformIdentity;
}

#pragma mark - User Interaction

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event {
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
        [_valueLabel setTextColor:[[GTPlayerManager sharedReferenceManager] diceDotsColor]];
        [_valueLabel setText:[NSString stringWithFormat:@"%d", self.value]];
        [_valueLabel setClipsToBounds:NO];
    }
    
    return _valueLabel;
}

- (UIView *)shadingView {
    if (!_shadingView) {
        _shadingView = [[UILabel alloc] initWithFrame:self.bounds];
        [_shadingView setAlpha:0.7f];
        [_shadingView.layer setCornerRadius:5.0f];
        [_shadingView setBackgroundColor:[UIColor colorWithWhite:0.5f alpha:0.0f]];
        [_shadingView setClipsToBounds:YES];
    }
    
    return _shadingView;
}

- (CAGradientLayer *)gradientLayer {
    if (!_gradientLayer) {
        _gradientLayer = [self shadowGradient];
        [_gradientLayer setFrame:self.bounds];
    }
    
    return _gradientLayer;
}

#pragma mark - gradient

- (CAGradientLayer *)shadowGradient {
    NSArray *colors = [NSArray arrayWithObjects:(id)[UIColor colorWithWhite:1.0f alpha:0.41f].CGColor,
                       (id)[UIColor colorWithWhite:0.9f alpha:0.0f].CGColor,
                       (id)[UIColor clearColor].CGColor,
                       (id)[UIColor colorWithWhite:0.0f alpha:0.2f].CGColor, nil];
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0f];
    NSNumber *stopTwo = [NSNumber numberWithFloat:0.15f];
    NSNumber *stopThree = [NSNumber numberWithFloat:0.75f];
    NSNumber *stopFour = [NSNumber numberWithFloat:1.0f];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, stopThree, stopFour, nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.locations = locations;
    
    return headerLayer;
}


@end
