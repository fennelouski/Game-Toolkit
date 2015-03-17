//
//  GTGraphView.h
//  Game Toolkit
//
//  Created by Developer Nathan on 3/16/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTPlayer.h"

@interface GTGraphView : UIView

@property (nonatomic, strong) GTPlayer *player;

@property (nonatomic) BOOL shouldShowIndividualScores;

@end
