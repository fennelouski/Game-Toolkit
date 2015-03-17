//
//  GTGraphView.m
//  Game Toolkit
//
//  Created by Developer Nathan on 3/16/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTGraphView.h"
#import "GTPlayerManager.h"
#import "GTPlayer.h"
#import "UIColor+AppColors.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width

@implementation GTGraphView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self.layer setCornerRadius:5.0f];
        [self setClipsToBounds:YES];
        [self setBackgroundColor:[UIColor snow]];
        
        [self performSelector:@selector(setNeedsDisplay) withObject:self afterDelay:0.5f];
    }
    
    return self;
}

- (void)setNeedsDisplay {
    for (UIView *subview in self.subviews) {
        [subview removeFromSuperview];
    }
    
    [super setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    NSArray *players = [[GTPlayerManager sharedReferenceManager] players];
    int numberOfRounds = 1;
    int highestScore = 0;
    int lowestScore = 0;
    int highestIndividualScore = 0;
    int lowestIndividualScore = 24000000;
    int scoreCorrelation = 0; // whether the overall scores are positive or negative
    for (GTPlayer *player in players) {
        if ([[player scoreHistory] count] > numberOfRounds) {
            numberOfRounds = (int)[[player scoreHistory] count];
        }
        
        int currentScore = 0;
        for (NSNumber *score in [player scoreHistory]) {
            currentScore += [score intValue];
            if (currentScore < lowestScore) {
                lowestScore = currentScore;
            }
            
            else if (currentScore > highestScore) {
                highestScore = currentScore;
            }
            
            if ([score intValue] < lowestIndividualScore) {
                lowestIndividualScore = [score intValue];
            }
            
            else if ([score intValue] > highestIndividualScore) {
                highestIndividualScore = [score intValue];
            }
        }
        
        if (currentScore > 0) {
            scoreCorrelation++;
        }
        
        else {
            scoreCorrelation--;
        }
    }
    
    if (numberOfRounds < 2) {
        [self setAlpha:0.0f];
        return;
    }
    
    highestScore *= 1.1;
    if (lowestScore < 0) lowestScore *= 1.1;
    else lowestScore *= 0.9;
    
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB();
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    int scoreRange = highestScore - lowestScore;
    int individualScoreRange = highestIndividualScore - lowestIndividualScore;
    
    if (self.shouldShowIndividualScores && (numberOfRounds < individualScoreRange * 6)) {
        if (self.player) {
            players = @[self.player];
            
            UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, rect.size.width, rect.size.height/4.0f)];
            [nameLabel setText:[self.player name]];
            [nameLabel setTextAlignment:NSTextAlignmentCenter];
            [nameLabel setTextColor:[self.player color]];
            [nameLabel setAlpha:0.9f];
            [self addSubview:nameLabel];
        }
        
        int powersOf2 = 0, checkValue = 1;
        int intervals = 1;
        int scoreFloor = lowestIndividualScore;
        while (checkValue < individualScoreRange) {
            checkValue *= 2;
            powersOf2++;
        }
        
        if (individualScoreRange < 5) {
            powersOf2 = 10;
        }
        
        else if (powersOf2 > 2) {
            if (powersOf2 > rect.size.height/22.0f) powersOf2 = rect.size.height/22.0f;
            if (powersOf2 > 10) powersOf2 = 10;
            
            
            int multiplesOf5 = 0;
            int intervalicDistance = 1;
            
            while (intervals * powersOf2 < individualScoreRange) {
                intervals += intervalicDistance;
                multiplesOf5++;
                
                if (intervals == 5) {
                    intervalicDistance = 5;
                }
                
                if (intervals == 25) {
                    intervalicDistance = 25;
                }
                
                else if (intervals == 50) {
                    intervalicDistance = 50;
                }
                
                else if (intervals == 100) {
                    intervalicDistance = 100;
                }
                
                else if (intervals == 1000) {
                    intervalicDistance = 1000;
                }
                
                else if (intervals == 5000) {
                    intervalicDistance = 5000;
                }
                
                else if (intervals == 25000) {
                    intervalicDistance = 25000;
                }
                
                else if (intervals == 100000) {
                    intervalicDistance = 100000;
                }
                
                else if (intervals == 1000000) {
                    intervalicDistance = 1000000;
                }
            }
        }
        
        scoreFloor = scoreFloor - scoreFloor % intervals;
        
        for (int i = 1; i < powersOf2; i++) {
            float y = rect.size.height - (i * intervals) * rect.size.height / individualScoreRange;
            CGPoint starting0Point = CGPointMake(0.0f, y);
            CGPoint ending0Point = CGPointMake(rect.size.width, y);
            UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(1.0f, (y < 0) ? -200.0f : y, rect.size.width, 20.0f)];
            if (i*intervals+scoreFloor == 0) {
                draw1PxStroke(context, starting0Point, ending0Point, [UIColor blackColor].CGColor);
                [valueLabel setTextColor:[UIColor blackColor]];
            }
            
            else {
                draw1PxStroke(context, starting0Point, ending0Point, [UIColor colorWithWhite:0.8f alpha:0.5f].CGColor);
                [valueLabel setTextColor:[UIColor lightGrayColor]];
                [valueLabel setAlpha:0.5f];
            }
            
            [valueLabel setText:[NSString stringWithFormat:@"%d", i * intervals + scoreFloor]];
            [self addSubview:valueLabel];
        }
        
        float squareRoot = 2;
        while (squareRoot * squareRoot < numberOfRounds) {
            squareRoot *= 1.05f;
        }
        squareRoot = (float)(int)squareRoot;
        
        int numberOfDerivatives = squareRoot;
        if (numberOfRounds < individualScoreRange * 2) {
            numberOfDerivatives = 1;
        }
        
        for (GTPlayer *player in players) {
            CGPoint lastPoint = CGPointMake(-2.0f, rect.size.height);
            CGPoint currentPoint = CGPointMake(0.0f, rect.size.height);
            
            float x = 0.0f;
            float y = 0.0f;
            float alpha = 0.4f;
            for (int derivative = numberOfDerivatives; derivative > 0; derivative--) {
                if (derivative == 1) alpha = 0.8f;
                for (int i = 0; i < [[player scoreHistory] count]; i += derivative) {
                    NSNumber *score = [[player scoreHistory] objectAtIndex:i];
                    int currentScore = [score intValue];
                    int numberOfValuesToAverage = 1;
                    for (int j = i + 1; j < i + derivative && j < [[player scoreHistory] count]; j++, numberOfValuesToAverage++) {
                        score = [[player scoreHistory] objectAtIndex:j];
                        currentScore += [score intValue];
                    }
                    currentScore /= numberOfValuesToAverage;
                    
                    x = (i + derivative/2) * rect.size.width / numberOfRounds - 1.0f;
                    y = rect.size.height - (currentScore - lowestIndividualScore) * rect.size.height / (highestIndividualScore - lowestIndividualScore);
                    currentPoint = CGPointMake(x,y);
                    if (i > 0) drawStroke(context, lastPoint, currentPoint, [[player color] colorWithAlphaComponent:alpha].CGColor, 1.5f + alpha);
                    
                    lastPoint = currentPoint;
                }
                
                alpha *= 0.5f;
            }
        }
    }
    
    
    else {
        // nominal line
        CGPoint starting0Point = CGPointMake(0.0f, rect.size.height - (-lowestScore * rect.size.height / scoreRange));
        CGPoint ending0Point = CGPointMake(rect.size.width, rect.size.height - (-lowestScore * rect.size.height / scoreRange));
        draw2PxStroke(context, starting0Point, ending0Point, [UIColor blackColor].CGColor);
        
        int powersOf2 = 0, checkValue = 1;
        
        int scoreFloor = lowestScore;
        
        while (checkValue < highestScore) {
            checkValue *= 2;
            powersOf2++;
        }
        
        if (powersOf2 > 2) {
            if (powersOf2 > rect.size.height/22.0f) powersOf2 = rect.size.height/22.0f;
            if (powersOf2 > 10) powersOf2 = 10;
            
            
            int multiplesOf5 = 0;
            int intervals = 5;
            int intervalicDistance = 5;
            
            while (intervals * powersOf2 < highestScore) {
                intervals += intervalicDistance;
                multiplesOf5++;
                
                if (intervals == 25) {
                    intervalicDistance = 25;
                }
                
                else if (intervals == 50) {
                    intervalicDistance = 50;
                }
                
                else if (intervals == 100) {
                    intervalicDistance = 100;
                }
                
                else if (intervals == 1000) {
                    intervalicDistance = 1000;
                }
                
                else if (intervals == 5000) {
                    intervalicDistance = 5000;
                }
                
                else if (intervals == 25000) {
                    intervalicDistance = 25000;
                }
                
                else if (intervals == 100000) {
                    intervalicDistance = 100000;
                }
                
                else if (intervals == 1000000) {
                    intervalicDistance = 1000000;
                }
            }
            
            scoreFloor = scoreFloor - scoreFloor % intervals;
            
            for (int i = -10; i < 20; i++) {
                float y = rect.size.height - (i * intervals) * rect.size.height / scoreRange;
                CGPoint starting0Point = CGPointMake(0.0f, y);
                CGPoint ending0Point = CGPointMake(rect.size.width, y);
                UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(1.0f, (y < 0) ? -200.0f : y, rect.size.width, 20.0f)];
                if (i*intervals+scoreFloor == 0) {
                    draw1PxStroke(context, starting0Point, ending0Point, [UIColor blackColor].CGColor);
                    [valueLabel setTextColor:[UIColor blackColor]];
                }
                
                else {
                    draw1PxStroke(context, starting0Point, ending0Point, [UIColor colorWithWhite:0.8f alpha:0.5f].CGColor);
                    [valueLabel setTextColor:[UIColor lightGrayColor]];
                    [valueLabel setAlpha:0.5f];
                }
                
                [valueLabel setText:[NSString stringWithFormat:@"%d", i * intervals + scoreFloor]];
                [self addSubview:valueLabel];
            }
            
            for (int i = 1; i < 10; i++) {
                float y = rect.size.height - ((-lowestScore) * rect.size.height / scoreRange) + (i * intervals * rect.size.height / highestScore);
                CGPoint starting0Point = CGPointMake(0.0f, y);
                CGPoint ending0Point = CGPointMake(rect.size.width, y);
                draw1PxStroke(context, starting0Point, ending0Point, [UIColor colorWithWhite:0.8f alpha:0.5f].CGColor);
                UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(1.0f, y, rect.size.width, 20.0f)];
                [valueLabel setText:[NSString stringWithFormat:@"-%d", i * intervals + scoreFloor]];
                [valueLabel setTextColor:[UIColor lightGrayColor]];
                [valueLabel setAlpha:0.5f];
                [self addSubview:valueLabel];
            }
        }
        
        numberOfRounds--;
        for (int j = 0; j < [players count]; j++) {
            GTPlayer *player = [players objectAtIndex:j];
            
            int pointPosition = (float)numberOfRounds / (float)([players count]) * (float)([players count] - (float)j - 0.5f);
            
            int currentScore = 0;
            CGPoint lastPoint = CGPointMake(-2.0f, rect.size.height);
            CGPoint currentPoint = CGPointMake(0.0f, rect.size.height);
            
            int iteration = 0;
            float x = 0.0f;
            float y = 0.0f;
            for (int i = 0; i < [[player scoreHistory] count]; i++) {
                NSNumber *score = [[player scoreHistory] objectAtIndex:i];
                currentScore += [score intValue];
                
                x = iteration * rect.size.width / numberOfRounds - 1.0f;
                y = rect.size.height - (currentScore - lowestScore) * rect.size.height / scoreRange ;
                currentPoint = CGPointMake(x,y);
                if (i > 0) draw2PxStroke(context, lastPoint, currentPoint, [player color].CGColor);
                
                lastPoint = currentPoint;
                iteration++;
                
                if (numberOfRounds < [players count]) {
                    if (i == numberOfRounds/2) {
                        player.point = CGPointMake((lastPoint.x + currentPoint.x)/2.0f, (lastPoint.y + currentPoint.y)/2.0);
                    }
                }
                
                else if (i == pointPosition) {
                    player.point = CGPointMake((lastPoint.x + currentPoint.x)/2.0f, (lastPoint.y + currentPoint.y)/2.0);
                }
            }
            
            if (numberOfRounds > [players count] * 2 && rect.size.height > 250.0f) {
                for (int i = 0; i < [players count]; i++) {
                    GTPlayer *player = [players objectAtIndex:i];
                    
                    UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f - i,
                                                                                   10 + [players count] * 20 + ([players count] - i) * -20.0f,
                                                                                   (kScreenWidth / 4.0f) - i * 2,
                                                                                   20.0f)];
                    [nameLabel setTextAlignment:NSTextAlignmentRight];
                    
                    CGPoint endPoint = CGPointMake(nameLabel.center.x + nameLabel.frame.size.width/2.0f, nameLabel.center.y);
                    if (i + 1 == [players count]) endPoint = CGPointMake(nameLabel.center.x + nameLabel.frame.size.width/3.0f, nameLabel.frame.size.height/2.0f + nameLabel.center.y);
                    
                    
                    if (scoreCorrelation < 0) {
                        [nameLabel setFrame:CGRectMake(10.0f + i,
                                                       rect.size.height - (20 + [players count] * 20 + ([players count] - i) * -20.0f),
                                                       (kScreenWidth / 4.0f) - i * 4,
                                                       20.0f)];
                        [nameLabel setTextAlignment:NSTextAlignmentRight];
                        
                        endPoint = CGPointMake(nameLabel.center.x + nameLabel.frame.size.width/2.0f, nameLabel.center.y);
                        if (i + 1 == [players count]) endPoint = CGPointMake(nameLabel.center.x + nameLabel.frame.size.width/3.0f, nameLabel.center.y - nameLabel.frame.size.height/2.0f);
                    }
                    
                    [nameLabel setTextColor:[player color]];
                    [nameLabel setText:[player name]];
                    [self addSubview:nameLabel];
                    draw1PxStroke(context, player.point, endPoint, [[player color] colorWithAlphaComponent:0.5f].CGColor);
                }
            }
        }
    }
    
    CGContextSaveGState(context);
    CGContextDrawPath(context, kCGPathStroke);
    
}

void draw2PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color) {
    drawStroke(context, startPoint, endPoint, color, 2.0f);
}

void draw1PxStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color) {
    drawStroke(context, startPoint, endPoint, color, 1.0f);
}

void drawStroke(CGContextRef context, CGPoint startPoint, CGPoint endPoint, CGColorRef color, float strokeWidth) {
    CGContextSaveGState(context);
    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetStrokeColorWithColor(context, color);
    CGContextSetLineWidth(context, strokeWidth);
    CGContextMoveToPoint(context, startPoint.x + 0.5, startPoint.y + 0.5);
    CGContextAddLineToPoint(context, endPoint.x + 0.5, endPoint.y + 0.5);
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

@end
