//
//  GTTimerViewController.h
//  Game Toolkit
//
//  Created by Developer Nathan on 2/10/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GTPlayerManager.h"

@interface GTTimerViewController : UIViewController <GTPlayerManagerDelegate, GTPlayerManagerTimerDelegate>

@property (nonatomic, strong) NSMutableDictionary *playerButtons;
@property (nonatomic, strong) UIToolbar *headerToolbar;

@end
