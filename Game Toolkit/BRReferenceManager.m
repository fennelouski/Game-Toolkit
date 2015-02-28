//
//  BRReferenceManager.m
//  Bachelor Reference
//
//  Created by Developer Nathan on 1/8/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "BRReferenceManager.h"
#import "UIFont+AppFonts.h"
#import "UIColor+AppColors.h"
#import "BRMapView.h"
#import <AddressBook/AddressBook.h>

@implementation BRReferenceManager {
    NSMutableArray *_bachelors;
    BRBachelorette *_star;
}

+ (instancetype)sharedReferenceManager {
    static BRReferenceManager *sharedReferenceManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedReferenceManager = [[BRReferenceManager alloc] init];
    });
    
    return sharedReferenceManager;
}

- (id)init {
    self = [super init];
    if (self) {
        _bachelors = [[NSMutableArray alloc] init];
        
        [self setUpSeason19];
        [self getStarAddress];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        for (BRBachelorette *bachelorette in _bachelors) {
            [bachelorette.question1 appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [bachelorette.question2 appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [bachelorette.question3 appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [bachelorette.question4 appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [bachelorette.question5 appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            [bachelorette.question6 appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            
            int position = 0;
            NSString *note = [defaults objectForKey:[NSString stringWithFormat:@"%@note%d", bachelorette.name, position]];
            while (note) {
                [bachelorette.notes setObject:note atIndexedSubscript:position];
                position++;
                note = [defaults objectForKey:[NSString stringWithFormat:@"%@note%d", bachelorette.name, position]];
            }

        }
    }
    
    return self;
}

- (BRBachelorette *)star {
    return _star;
}

- (void)getStarAddress {
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    
    NSString *addressString =
    [NSString stringWithFormat:
     @"%@, %@",
     _star.hometownCity,
     _star.hometownState];

    [geocoder
     geocodeAddressString:addressString
     completionHandler:^(NSArray *placemarks,
                         NSError *error) {
         
         if (error) {
             NSLog(@"Geocode failed with error: %@", error);
             return;
         }
         
         if (placemarks && placemarks.count > 0) {
             CLPlacemark *placemark = placemarks[0];
             
             CLLocation *location = placemark.location;
             _star.coordinate = location.coordinate;
         }
     }];
}

- (BRReferenceManager *)bachelorForRow:(int)row {
    if (row < _bachelors.count) {
        return [_bachelors objectAtIndex:row];
    }
    
    return nil;
}

- (NSArray *)bachelors {
    return _bachelors;
}

- (NSArray *)myTeam {
    NSMutableArray *myTeam = [[NSMutableArray alloc] init];
    for (BRBachelorette *bachelorette in _bachelors) {
        if (bachelorette.myTeam) {
            [myTeam addObject:bachelorette];
        }
    }
    
    if (myTeam.count < 1) {
        return _bachelors;
    }
    
    return myTeam;
}

- (NSArray *)stillIn {
    NSMutableArray *stillIn = [[NSMutableArray alloc] init];
    for (BRBachelorette *bachelorette in _bachelors) {
        if (!bachelorette.noRose) {
            [stillIn addObject:bachelorette];
        }
    }
    
    if (stillIn.count < 2) {
        return _bachelors;
    }
    
    return stillIn;
}

- (void)setUpSeason19 {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    _star = [[BRBachelorette alloc] init];
    _star.name = @"Chris Soules";
    _star.hometownCity = @"Arlington";
    _star.hometownState = @"Iowa";

    BRBachelorette *alissa = [[BRBachelorette alloc] init];
    [_bachelors addObject:alissa];
    alissa.name = @"Alissa";
    alissa.occupation = @"Flight Attendant";
    alissa.age = 24;
    alissa.hometownCity = @"Hamilton";
    alissa.hometownState = @"New Jersey";
    alissa.heightFeet = 5;
    alissa.heightInch = 4;
    alissa.heightInInches = 64;
    alissa.tattooCount = 0;
    alissa.cannotLiveWithout = @"Family, friends, laughter, hope, faith";
    alissa.biggestDateFear = @"Running into recent exes";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", alissa.name]]) {
        alissa.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", alissa.name]]) {
        alissa.myTeam = YES;
    }
    
    // Declare the fonts
    UIFont *myStringFont1 = [UIFont systemFontOfSize:16.0f];
    UIFont *myStringFont2 = [UIFont boldSystemFontOfSize:16.0];
    UIFont *myStringFont3 = [UIFont italicSystemFontOfSize:16.0f];
    
    // Declare the paragraph styles
    NSMutableParagraphStyle *myStringParaStyle1 = [[NSMutableParagraphStyle alloc]init];
    myStringParaStyle1.alignment = 4;
    
    // Declare the colors
    UIColor *myStringColor1 = [UIColor darkTextColor];
    UIColor *myStringColor2 = [UIColor clearColor];
    
    
    alissa.question1 = [[NSMutableAttributedString alloc]initWithString:
                        @"If I never had to upset others, I would be very happy."];

    // Create the attributes and add them to the string
    [alissa.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [alissa.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [alissa.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [alissa.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [alissa.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,12)];
    [alissa.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,12)];
    [alissa.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,12)];
    [alissa.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,12)];
    [alissa.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(30,22)];
    [alissa.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(30,22)];
    [alissa.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(30,22)];
    [alissa.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(30,22)];
    
    
    // Create the attributed string
    alissa.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to play with puppies, I would be very sad."];
    
    // Create the attributes and add them to the string
    [alissa.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [alissa.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [alissa.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [alissa.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [alissa.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,17)];
    [alissa.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,17)];
    [alissa.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,17)];
    [alissa.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,17)];
    [alissa.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(35,21)];
    [alissa.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(35,21)];
    [alissa.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(35,21)];
    [alissa.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(35,21)];
    
    
    // Create the attributed string
    alissa.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be any animal, what would you be?\nA wild mustang. Free to run and explore, they're unpredictable and beautiful, and are loyal to their herd."];
    
    // Create the attributes and add them to the string
    [alissa.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [alissa.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,46)];
    [alissa.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,46)];
    [alissa.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [alissa.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,106)];
    [alissa.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(46,106)];
    [alissa.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(46,106)];
    [alissa.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,106)];
    
    
    // Create the attributed string
    alissa.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you won the lottery, what would you do with your winnings?\nAdopt dogs and charter a jet for my friends anf fmaily to fly around Europe, with unlimited champagne and a hot air balloon ride over Greece."];
    
    // Create the attributes and add them to the string
    [alissa.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [alissa.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [alissa.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [alissa.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [alissa.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,141)];
    [alissa.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,141)];
    [alissa.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,141)];
    [alissa.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,141)];
    
    // Create the attributed string
    alissa.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's your most embarrassing moment?\nI was in-depth stalking a guy's Facebook page and sent my friend a long, detailed text about my findings...except I sent it to him. Oops."];
    
    // Create the attributes and add them to the string
    [alissa.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,37)];
    [alissa.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,37)];
    [alissa.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,37)];
    [alissa.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,37)];
    [alissa.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,137)];
    [alissa.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(37,137)];
    [alissa.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(37,137)];
    [alissa.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,137)];
    
    
    // Create the attributed string
    alissa.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your greatest achievement to date?\nGetting my yoga certification because I've been able to inspire others to do yoga and become instructors!"];
    
    // Create the attributes and add them to the string
    [alissa.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [alissa.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,42)];
    [alissa.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,42)];
    [alissa.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [alissa.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,105)];
    [alissa.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(42,105)];
    [alissa.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(42,105)];
    [alissa.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,105)];
    
    // alissa end
    
    
    // amanda begin
    
    BRBachelorette *amanda = [[BRBachelorette alloc] init];
    [_bachelors addObject:amanda];
    amanda.name = @"Amanda";
    amanda.age = 24;
    amanda.occupation = @"Ballet Teacher";
    amanda.hometownCity = @"Lake in the Hills";
    amanda.hometownState = @"Illinois";
    amanda.heightFeet = 5;
    amanda.heightInch = 4;
    amanda.heightInInches = 64;
    amanda.tattooCount = 2;
    amanda.cannotLiveWithout = @"Family, a good book";
    amanda.biggestDateFear = @"Not having chemistry with someone";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", amanda.name]]) {
        amanda.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", amanda.name]]) {
        amanda.myTeam = YES;
    }

    
    // Create the attributed string
    amanda.question1 = [[NSMutableAttributedString alloc]initWithString:@"If I never had to clean, I would be very happy."];
    
    // Create the attributes and add them to the string
    [amanda.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [amanda.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [amanda.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [amanda.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [amanda.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [amanda.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [amanda.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [amanda.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [amanda.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [amanda.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [amanda.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,5)];
    [amanda.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,5)];
    [amanda.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,5)];
    [amanda.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [amanda.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,24)];
    [amanda.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,24)];
    [amanda.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,24)];
    [amanda.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,24)];
    [amanda.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,24)];
    [amanda.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(23,24)];
    [amanda.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,24)];
    
    
    // Create the attributed string
    amanda.question2 = [[NSMutableAttributedString alloc]initWithString:@"If I never got to shop, I would be very sad."];
    
    
    // Create the attributes and add them to the string
    [amanda.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [amanda.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [amanda.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [amanda.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [amanda.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [amanda.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [amanda.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [amanda.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,4)];
    [amanda.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,4)];
    [amanda.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,4)];
    [amanda.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,4)];
    [amanda.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,4)];
    [amanda.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,4)];
    [amanda.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,4)];
    [amanda.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(22,22)];
    [amanda.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(22,22)];
    [amanda.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(22,22)];
    [amanda.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(22,22)];
    [amanda.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(22,22)];
    [amanda.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(22,22)];
    [amanda.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(22,22)];
    
    
    // Create the attributed string
    amanda.question3 = [[NSMutableAttributedString alloc]initWithString:@"What's the most romantic present you have ever received?\nA guy once wrote me a beautiful letter expressing his feelings for me. I still have it. He was a creep, but a great writer."];
    
    // Create the attributes and add them to the string
    [amanda.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [amanda.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [amanda.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [amanda.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [amanda.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [amanda.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [amanda.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [amanda.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,124)];
    [amanda.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,124)];
    [amanda.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,124)];
    [amanda.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,124)];
    [amanda.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,124)];
    [amanda.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,124)];
    [amanda.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,124)];
    
    
    // Create the attributed string
    amanda.question4 = [[NSMutableAttributedString alloc]initWithString:@"If you could be a fictional character, who would you be?\nAllie from The Notebook. Noah loves her so much, and to find that and have it last a lifetime is a rare thing."];
    
    // Create the attributes and add them to the string
    [amanda.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [amanda.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [amanda.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [amanda.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [amanda.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [amanda.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [amanda.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [amanda.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,12)];
    [amanda.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,12)];
    [amanda.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,12)];
    [amanda.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,12)];
    [amanda.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,12)];
    [amanda.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,12)];
    [amanda.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,12)];
    [amanda.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(68,12)];
    [amanda.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(68,12)];
    [amanda.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(68,12)];
    [amanda.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(68,12)];
    [amanda.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(68,12)];
    [amanda.question4 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(68,12)];
    [amanda.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(68,12)];
    [amanda.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(80,87)];
    [amanda.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(80,87)];
    [amanda.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(80,87)];
    [amanda.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(80,87)];
    [amanda.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(80,87)];
    [amanda.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(80,87)];
    [amanda.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(80,87)];
    
    // Create the attributed string
    amanda.question5 = [[NSMutableAttributedString alloc]initWithString:@"If you won the lottery, what would you do with your winnings?\nI would first pay off my student loans, and then buy a house while the market is still good. The rest would go into savings."];
    
    // Create the attributes and add them to the string
    [amanda.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [amanda.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [amanda.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [amanda.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [amanda.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,61)];
    [amanda.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [amanda.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [amanda.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,125)];
    [amanda.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,125)];
    [amanda.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,125)];
    [amanda.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,125)];
    [amanda.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,125)];
    [amanda.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,125)];
    [amanda.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,125)];
    
    // Create the attributed string
    amanda.question6 = [[NSMutableAttributedString alloc]initWithString:@"Where do you see yourself in five years?\nI'd love to be married, and hopefully running my own ballet studio."];
    
    // Create the attributes and add them to the string
    [amanda.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,40)];
    [amanda.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,40)];
    [amanda.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,40)];
    [amanda.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,40)];
    [amanda.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,40)];
    [amanda.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,40)];
    [amanda.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,40)];
    [amanda.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(40,68)];
    [amanda.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(40,68)];
    [amanda.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(40,68)];
    [amanda.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(40,68)];
    [amanda.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(40,68)];
    [amanda.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(40,68)];
    [amanda.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(40,68)];
    // amanda end
    
    
    // amber begin
    
    BRBachelorette *amber = [[BRBachelorette alloc] init];
    [_bachelors addObject:amber];
    amber.name = @"Amber";
    amber.age = 29;
    amber.occupation = @"Bartender";
    amber.hometownCity = @"Chicago";
    amber.hometownState = @"Illinois";
    amber.heightFeet = 5;
    amber.heightInch = 3;
    amber.heightInInches = 63;
    amber.tattooCount = 0;
    amber.cannotLiveWithout = @"Teddy bear, Mom, best friends, brother";
    amber.biggestDateFear = @"Loving someone and them not feeling the same way";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", amber.name]]) {
        amber.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", amber.name]]) {
        amber.myTeam = YES;
    }
    
    // Create the attributed string
    amber.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to pay bills, I would be very happy."];
    
    // Create the attributes and add them to the string
    [amber.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,17)];
    [amber.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,17)];
    [amber.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,17)];
    [amber.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,17)];
    [amber.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,17)];
    [amber.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,17)];
    [amber.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,17)];
    [amber.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(17,10)];
    [amber.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(17,10)];
    [amber.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(17,10)];
    [amber.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(17,10)];
    [amber.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(17,10)];
    [amber.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(17,10)];
    [amber.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(17,10)];
    [amber.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(27,24)];
    [amber.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(27,24)];
    [amber.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(27,24)];
    [amber.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(27,24)];
    [amber.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(27,24)];
    [amber.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(27,24)];
    [amber.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(27,24)];
    
    // Create the attributed string
    amber.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to see my friends/family, I would be very sad."];
    
    // Create the attributes and add them to the string
    [amber.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [amber.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [amber.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [amber.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [amber.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [amber.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [amber.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [amber.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,21)];
    [amber.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,21)];
    [amber.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,21)];
    [amber.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,21)];
    [amber.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,21)];
    [amber.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,21)];
    [amber.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,21)];
    [amber.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(39,22)];
    [amber.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(39,22)];
    [amber.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(39,22)];
    [amber.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(39,22)];
    [amber.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(39,22)];
    [amber.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(39,22)];
    [amber.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(39,22)];
    
    
    // Create the attributed string
    amber.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be someone else for just one day, who would it be?\nA zookeeper. I would love to be around the different animals and watch how they live."];
    
    // Create the attributes and add them to the string
    [amber.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,63)];
    [amber.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,63)];
    [amber.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,63)];
    [amber.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,63)];
    [amber.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,63)];
    [amber.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,63)];
    [amber.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,63)];
    [amber.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(63,85)];
    [amber.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(63,85)];
    [amber.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(63,85)];
    [amber.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(63,85)];
    [amber.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(63,85)];
    [amber.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(63,85)];
    [amber.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(63,85)];
    
    // Create the attributed string
    amber.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you won the lottery, what would you do with your winnings?\nTravel -- there is so much to see in this world. Also so many families in different countries that can use help."];
    
    // Create the attributes and add them to the string
    [amber.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [amber.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [amber.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [amber.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [amber.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,61)];
    [amber.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [amber.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [amber.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,113)];
    [amber.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,113)];
    [amber.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,113)];
    [amber.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,113)];
    [amber.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,113)];
    [amber.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,113)];
    [amber.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,113)];
    
    // Create the attributed string
    amber.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Top 3 all-time favorite movies?\nThe Lion King, Reservoir Dogs, and A Bronx Tale."];
    
    // Create the attributes and add them to the string
    [amber.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [amber.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [amber.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [amber.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,31)];
    [amber.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,31)];
    [amber.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,31)];
    [amber.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [amber.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [amber.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [amber.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [amber.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(31,1)];
    [amber.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(31,1)];
    [amber.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(31,1)];
    [amber.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [amber.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(32,31)];
    [amber.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,31)];
    [amber.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(32,31)];
    [amber.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(32,31)];
    [amber.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(32,31)];
    [amber.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(32,31)];
    [amber.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,31)];
    [amber.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(63,3)];
    [amber.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(63,3)];
    [amber.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(63,3)];
    [amber.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(63,3)];
    [amber.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(63,3)];
    [amber.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(63,3)];
    [amber.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(63,3)];
    [amber.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(66,14)];
    [amber.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(66,14)];
    [amber.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(66,14)];
    [amber.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(66,14)];
    [amber.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(66,14)];
    [amber.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(66,14)];
    [amber.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(66,14)];
    
    // Create the attributed string
    amber.question6 = [[NSMutableAttributedString alloc]initWithString:@"What does being married mean to you?\nCommitting to be with each other no matter how tough it can be. Having a life-long friendship and being there for one another."];
    
    // Create the attributes and add them to the string
    [amber.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [amber.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [amber.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [amber.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [amber.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [amber.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [amber.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [amber.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,1)];
    [amber.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,1)];
    [amber.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,1)];
    [amber.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,1)];
    [amber.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,1)];
    [amber.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,1)];
    [amber.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(37,126)];
    [amber.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,126)];
    [amber.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(37,126)];
    [amber.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(37,126)];
    [amber.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(37,126)];
    [amber.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(37,126)];
    [amber.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,126)];
    // amber end
    
    // ashley I begin
    
    BRBachelorette *ashleyI = [[BRBachelorette alloc] init];
    [_bachelors addObject:ashleyI];
    ashleyI.name = @"Ashley I.";
    ashleyI.age = 26;
    ashleyI.occupation = @"Freelance Journalist";
    ashleyI.hometownCity = @"Wayne";
    ashleyI.hometownState = @"New Jersey";
    ashleyI.heightFeet = 5;
    ashleyI.heightInch = 6;
    ashleyI.heightInInches = 66;
    ashleyI.tattooCount = 0;
    ashleyI.cannotLiveWithout = @"Sister and parents, best friend, foundation and mascara";
    ashleyI.biggestDateFear = @"Awkward silence, which is different from silence";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", ashleyI.name]]) {
        NSLog(@"");
        ashleyI.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", ashleyI.name]]) {
        ashleyI.myTeam = YES;
    }

    
    // Create the attributed string
    ashleyI.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to wake up before 10am, I would be very happy."];
    
    // Create the attributes and add them to the string
    [ashleyI.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [ashleyI.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [ashleyI.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [ashleyI.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [ashleyI.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [ashleyI.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [ashleyI.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [ashleyI.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,19)];
    [ashleyI.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,19)];
    [ashleyI.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,19)];
    [ashleyI.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,19)];
    [ashleyI.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,19)];
    [ashleyI.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,19)];
    [ashleyI.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,19)];
    [ashleyI.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(37,23)];
    [ashleyI.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,23)];
    [ashleyI.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(37,23)];
    [ashleyI.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(37,23)];
    [ashleyI.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(37,23)];
    [ashleyI.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(37,23)];
    [ashleyI.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,23)];
    
    
    // Create the attributed string
    ashleyI.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to cook/eat, I would be very sad."];
    
    // Create the attributes and add them to the string
    [ashleyI.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [ashleyI.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [ashleyI.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [ashleyI.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [ashleyI.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [ashleyI.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [ashleyI.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [ashleyI.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,8)];
    [ashleyI.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,8)];
    [ashleyI.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,8)];
    [ashleyI.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,8)];
    [ashleyI.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,8)];
    [ashleyI.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,8)];
    [ashleyI.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,8)];
    [ashleyI.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(26,22)];
    [ashleyI.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(26,22)];
    [ashleyI.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(26,22)];
    [ashleyI.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(26,22)];
    [ashleyI.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(26,22)];
    [ashleyI.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(26,22)];
    [ashleyI.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(26,22)];
    
    
    // Create the attributed string
    ashleyI.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you won the lottery, what would you do with your winnings?\nBuy a room on a cruise ship that I could use any time. A place in Southern California on the beach, a penthouse in New York. Buy Sephora's inventory. Most of all, give a TON to my parents for payback."];
    
    // Create the attributes and add them to the string
    [ashleyI.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [ashleyI.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [ashleyI.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [ashleyI.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [ashleyI.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,61)];
    [ashleyI.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [ashleyI.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [ashleyI.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,201)];
    [ashleyI.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,201)];
    [ashleyI.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,201)];
    [ashleyI.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,201)];
    [ashleyI.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,201)];
    [ashleyI.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,201)];
    [ashleyI.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,201)];
    
    
    // Create the attributed string
    ashleyI.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you really wanted to impress a man, what would you do?\nMake him amazing cheeseburgers and watch football with him because that would be fun for me and him. Plus, my football knowledge is impressive."];
    
    // Create the attributes and add them to the string
    [ashleyI.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [ashleyI.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [ashleyI.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [ashleyI.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,57)];
    [ashleyI.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,57)];
    [ashleyI.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,57)];
    [ashleyI.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [ashleyI.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(57,144)];
    [ashleyI.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,144)];
    [ashleyI.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(57,144)];
    [ashleyI.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(57,144)];
    [ashleyI.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(57,144)];
    [ashleyI.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(57,144)];
    [ashleyI.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,144)];
    
    
    // Create the attributed string
    ashleyI.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Describe the worst first date you've ever been on.\nI decided to try out being a cougar, but he was sooo immature and had me pay for everything. He was too intimidated to hold a conversation."];
    
    // Create the attributes and add them to the string
    [ashleyI.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,50)];
    [ashleyI.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,50)];
    [ashleyI.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,50)];
    [ashleyI.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,50)];
    [ashleyI.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,50)];
    [ashleyI.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,50)];
    [ashleyI.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,50)];
    [ashleyI.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(50,49)];
    [ashleyI.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(50,49)];
    [ashleyI.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(50,49)];
    [ashleyI.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(50,49)];
    [ashleyI.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(50,49)];
    [ashleyI.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(50,49)];
    [ashleyI.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(50,49)];
    [ashleyI.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(99,4)];
    [ashleyI.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(99,4)];
    [ashleyI.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(99,4)];
    [ashleyI.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(99,4)];
    [ashleyI.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(99,4)];
    [ashleyI.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(99,4)];
    [ashleyI.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(99,4)];
    [ashleyI.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(103,87)];
    [ashleyI.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(103,87)];
    [ashleyI.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(103,87)];
    [ashleyI.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(103,87)];
    [ashleyI.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(103,87)];
    [ashleyI.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(103,87)];
    [ashleyI.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(103,87)];
    
    
    // Create the attributed string
    ashleyI.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What does being married mean to you?\nHaving a best friend to do everything with for life. A constant support and source of comfort, happiness and love."];
    
    // Create the attributes and add them to the string
    [ashleyI.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [ashleyI.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [ashleyI.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [ashleyI.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [ashleyI.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [ashleyI.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [ashleyI.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [ashleyI.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,1)];
    [ashleyI.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,1)];
    [ashleyI.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,1)];
    [ashleyI.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,1)];
    [ashleyI.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,1)];
    [ashleyI.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,1)];
    [ashleyI.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(37,114)];
    [ashleyI.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,114)];
    [ashleyI.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(37,114)];
    [ashleyI.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(37,114)];
    [ashleyI.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(37,114)];
    [ashleyI.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(37,114)];
    [ashleyI.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,114)];
    // ashely I end
    
    
    // ashley S begin
    
    BRBachelorette *ashleyS = [[BRBachelorette alloc] init];
    [_bachelors addObject:ashleyS];
    ashleyS.name = @"Ashley S.";
    ashleyS.age = 24;
    ashleyS.occupation = @"Hair Stylist";
    ashleyS.hometownCity = @"Brooklyn";
    ashleyS.hometownState = @"New York";
    ashleyS.heightFeet = 5;
    ashleyS.heightInch = 7;
    ashleyS.heightInInches = 67;
    ashleyS.tattooCount = 0;
    ashleyS.cannotLiveWithout = @"Lip gloss, coffee, my journal, people I love, sunshine";
    ashleyS.biggestDateFear = @"Having nothing to talk about";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", ashleyS.name]]) {
        ashleyS.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", ashleyS.name]]) {
        ashleyS.myTeam = YES;
    }
    
    
    // Create the attributed string
    ashleyS.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date shares intimate conversation."];
    
    // Create the attributes and add them to the string
    [ashleyS.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [ashleyS.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [ashleyS.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [ashleyS.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [ashleyS.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [ashleyS.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [ashleyS.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [ashleyS.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,29)];
    [ashleyS.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,29)];
    [ashleyS.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,29)];
    [ashleyS.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,29)];
    [ashleyS.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,29)];
    [ashleyS.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,29)];
    [ashleyS.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,29)];
    
    
    // Create the attributed string
    ashleyS.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date is constantly on the phone."];
    
    // Create the attributes and add them to the string
    [ashleyS.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [ashleyS.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [ashleyS.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [ashleyS.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [ashleyS.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [ashleyS.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [ashleyS.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [ashleyS.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,27)];
    [ashleyS.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,27)];
    [ashleyS.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,27)];
    [ashleyS.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,27)];
    [ashleyS.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,27)];
    [ashleyS.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,27)];
    [ashleyS.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,27)];
    
    
    // Create the attributed string
    ashleyS.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you won the lottery, what would you do with your winnings?\nHelp my uncle and my grandmother...and of course buy some amazing Italian shoes."];
    
    // Create the attributes and add them to the string
    [ashleyS.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [ashleyS.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [ashleyS.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [ashleyS.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [ashleyS.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,61)];
    [ashleyS.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [ashleyS.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [ashleyS.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,81)];
    [ashleyS.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,81)];
    [ashleyS.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,81)];
    [ashleyS.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,81)];
    [ashleyS.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,81)];
    [ashleyS.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,81)];
    [ashleyS.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,81)];
    
    
    // Create the attributed string
    ashleyS.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be a fictional character, who would you be?\nThumbelina, because she's persuaded by so many families to become a part of theirs, but in the end of the fairy tale she follows her heart. My favorite childhood story."];
    
    // Create the attributes and add them to the string
    [ashleyS.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [ashleyS.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [ashleyS.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [ashleyS.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [ashleyS.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [ashleyS.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [ashleyS.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [ashleyS.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,169)];
    [ashleyS.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,169)];
    [ashleyS.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,169)];
    [ashleyS.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,169)];
    [ashleyS.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,169)];
    [ashleyS.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,169)];
    [ashleyS.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,169)];
    
    
    // Create the attributed string
    ashleyS.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Top 3 all-time favorite movies?\nBreakfast at Tiffany's, Sex and the City, and Seven Pounds."];
    
    // Create the attributes and add them to the string
    [ashleyS.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [ashleyS.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [ashleyS.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [ashleyS.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,31)];
    [ashleyS.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,31)];
    [ashleyS.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,31)];
    [ashleyS.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [ashleyS.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [ashleyS.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [ashleyS.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [ashleyS.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(31,1)];
    [ashleyS.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(31,1)];
    [ashleyS.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(31,1)];
    [ashleyS.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [ashleyS.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(32,42)];
    [ashleyS.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,42)];
    [ashleyS.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(32,42)];
    [ashleyS.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(32,42)];
    [ashleyS.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(32,42)];
    [ashleyS.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(32,42)];
    [ashleyS.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,42)];
    [ashleyS.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(74,3)];
    [ashleyS.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(74,3)];
    [ashleyS.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(74,3)];
    [ashleyS.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(74,3)];
    [ashleyS.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(74,3)];
    [ashleyS.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(74,3)];
    [ashleyS.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(74,3)];
    [ashleyS.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(77,14)];
    [ashleyS.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(77,14)];
    [ashleyS.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(77,14)];
    [ashleyS.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(77,14)];
    [ashleyS.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(77,14)];
    [ashleyS.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(77,14)];
    [ashleyS.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(77,14)];
    
    
    // Create the attributed string
    ashleyS.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What does being married mean to you?\nIt is the highest honor to a relationship and 100% commitment."];
    
    // Create the attributes and add them to the string
    [ashleyS.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [ashleyS.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [ashleyS.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [ashleyS.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [ashleyS.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [ashleyS.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [ashleyS.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [ashleyS.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,63)];
    [ashleyS.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,63)];
    [ashleyS.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,63)];
    [ashleyS.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,63)];
    [ashleyS.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,63)];
    [ashleyS.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,63)];
    [ashleyS.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,63)];
    // ashley S end
    
    
    // becca begin
    
    BRBachelorette *becca = [[BRBachelorette alloc] init];
    [_bachelors addObject:becca];
    becca.name = @"Becca";
    becca.age = 25;
    becca.occupation = @"Chiropractic Assistant";
    becca.hometownCity = @"San Diego";
    becca.hometownState = @"California";
    becca.heightFeet = 5;
    becca.heightInch = 5;
    becca.heightInInches = 65;
    becca.tattooCount = 2;
    becca.cannotLiveWithout = @"Food, family, friends, Wi-Fi, Netflix";
    becca.biggestDateFear = @"Having stomach issues and clogging up a toilet, a la Dumb and Dumber";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", becca.name]]) {
        becca.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", becca.name]]) {
        becca.myTeam = YES;
    }

    
    // Create the attributed string
    becca.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to go back to school, I would be very happy."];
    
    // Create the attributes and add them to the string
    [becca.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [becca.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [becca.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [becca.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [becca.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [becca.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [becca.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [becca.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,17)];
    [becca.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,17)];
    [becca.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,17)];
    [becca.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,17)];
    [becca.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,17)];
    [becca.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,17)];
    [becca.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,17)];
    [becca.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(35,24)];
    [becca.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(35,24)];
    [becca.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(35,24)];
    [becca.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(35,24)];
    [becca.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(35,24)];
    [becca.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(35,24)];
    [becca.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(35,24)];
    
    
    // Create the attributed string
    becca.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to see my family, I would be very sad."];
    
    // Create the attributes and add them to the string
    [becca.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [becca.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [becca.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [becca.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [becca.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [becca.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [becca.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [becca.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,13)];
    [becca.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,13)];
    [becca.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,13)];
    [becca.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,13)];
    [becca.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,13)];
    [becca.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,13)];
    [becca.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,13)];
    [becca.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(31,22)];
    [becca.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,22)];
    [becca.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(31,22)];
    [becca.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(31,22)];
    [becca.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(31,22)];
    [becca.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(31,22)];
    [becca.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,22)];
    
    
    // Create the attributed string
    becca.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be any animal, what would you be?\nA dolphin. They're beautiful and supposedly use 20% of their brains -- brilliant!"];
    
    // Create the attributes and add them to the string
    [becca.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [becca.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [becca.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [becca.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,46)];
    [becca.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,46)];
    [becca.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,46)];
    [becca.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [becca.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(46,82)];
    [becca.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,82)];
    [becca.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(46,82)];
    [becca.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(46,82)];
    [becca.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(46,82)];
    [becca.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(46,82)];
    [becca.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,82)];
    
    
    // Create the attributed string
    becca.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you won the lottery, what would you do with your winnings?\nI would give a large portion to my family, and then travel!"];
    
    // Create the attributes and add them to the string
    [becca.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [becca.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [becca.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [becca.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [becca.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,61)];
    [becca.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [becca.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [becca.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,60)];
    [becca.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,60)];
    [becca.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,60)];
    [becca.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,60)];
    [becca.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,60)];
    [becca.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,60)];
    [becca.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,60)];
    
    
    // Create the attributed string
    becca.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's your most embarrassing moment?\nI have several -- once I was getting gas and the guy asked, \"What kind of gas do you like?\" and I thought he asked \"What kind of guys do you like?\" I responded, \"Tall, dark, and handsome.\" He just stared at me and repeated the question."];
    
    // Create the attributes and add them to the string
    [becca.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,37)];
    [becca.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,37)];
    [becca.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,37)];
    [becca.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,37)];
    [becca.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,37)];
    [becca.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,37)];
    [becca.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,37)];
    [becca.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(37,237)];
    [becca.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,237)];
    [becca.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(37,237)];
    [becca.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(37,237)];
    [becca.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(37,237)];
    [becca.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(37,237)];
    [becca.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,237)];
    
    
    // Create the attributed string
    becca.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your greatest achievement to date?\nStaying and living alone in California when my sister and brother-in-law went back home to Louisiana."];
    
    // Create the attributes and add them to the string
    [becca.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [becca.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [becca.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [becca.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,42)];
    [becca.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,42)];
    [becca.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,42)];
    [becca.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [becca.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(42,102)];
    [becca.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,102)];
    [becca.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(42,102)];
    [becca.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(42,102)];
    [becca.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(42,102)];
    [becca.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(42,102)];
    [becca.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,102)];
    // becca end
    
    
    // bo begin
    
    BRBachelorette *bo = [[BRBachelorette alloc] init];
    [_bachelors addObject:bo];
    bo.name = @"Bo";
    bo.age = 25;
    bo.occupation = @"Plus-Size Model";
    bo.hometownCity = @"Carpinteria";
    bo.hometownState = @"California";
    bo.heightFeet = 5;
    bo.heightInch = 9;
    bo.heightInInches = 69;
    bo.tattooCount = 2;
    bo.cannotLiveWithout = @"Food, exercise, water (i.e., the ocean), family, friends";
    bo.biggestDateFear = @"No fears. I love being open to new experiences.";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", bo.name]]) {
        bo.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", bo.name]]) {
        bo.myTeam = YES;
    }

    
    // Create the attributed string
    bo.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to sky dive, I would be very happy."];
    
    // Create the attributes and add them to the string
    [bo.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [bo.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [bo.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [bo.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [bo.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [bo.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [bo.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [bo.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,8)];
    [bo.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,8)];
    [bo.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,8)];
    [bo.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,8)];
    [bo.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,8)];
    [bo.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,8)];
    [bo.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,8)];
    [bo.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(26,24)];
    [bo.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(26,24)];
    [bo.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(26,24)];
    [bo.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(26,24)];
    [bo.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(26,24)];
    [bo.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(26,24)];
    [bo.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(26,24)];
    
    
    // Create the attributed string
    bo.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to have kids, I would be very sad."];
    
    // Create the attributes and add them to the string
    [bo.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [bo.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [bo.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [bo.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [bo.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [bo.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [bo.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [bo.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,9)];
    [bo.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,9)];
    [bo.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,9)];
    [bo.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,9)];
    [bo.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,9)];
    [bo.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,9)];
    [bo.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,9)];
    [bo.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(27,22)];
    [bo.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(27,22)];
    [bo.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(27,22)];
    [bo.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(27,22)];
    [bo.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(27,22)];
    [bo.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(27,22)];
    [bo.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(27,22)];
    
    
    // Create the attributed string
    bo.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your greatest achievement to date?\nBeing in the top 12 on the Women's World Qualifying for surfing."];
    
    // Create the attributes and add them to the string
    [bo.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [bo.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [bo.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [bo.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,42)];
    [bo.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,42)];
    [bo.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,42)];
    [bo.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [bo.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(42,65)];
    [bo.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,65)];
    [bo.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(42,65)];
    [bo.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(42,65)];
    [bo.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(42,65)];
    [bo.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(42,65)];
    [bo.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,65)];
    
    
    // Create the attributed string
    bo.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could have lunch with three people, living or dead, who would it be?\nBeyonce, Rihanna, and Mother Theresa. A feast so we could all get down. Food is bonding, and every woman loves food!"];
    
    // Create the attributes and add them to the string
    [bo.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,75)];
    [bo.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,75)];
    [bo.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,75)];
    [bo.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,75)];
    [bo.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,75)];
    [bo.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,75)];
    [bo.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,75)];
    [bo.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(75,117)];
    [bo.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(75,117)];
    [bo.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(75,117)];
    [bo.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(75,117)];
    [bo.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(75,117)];
    [bo.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(75,117)];
    [bo.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(75,117)];
    
    
    // Create the attributed string
    bo.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be any animal, what would you be?\nA dolphin, because then I would be in the ocean all day! A dolphin in Hawaii."];
    
    // Create the attributes and add them to the string
    [bo.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [bo.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [bo.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [bo.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,46)];
    [bo.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,46)];
    [bo.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,46)];
    [bo.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [bo.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(46,78)];
    [bo.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,78)];
    [bo.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(46,78)];
    [bo.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(46,78)];
    [bo.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(46,78)];
    [bo.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(46,78)];
    [bo.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,78)];
    
    
    // Create the attributed string
    bo.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you wanted to approach a man you'd never met before, how would you go about it?\nJust walk up and start talking to him like a human being...just get to know him, no creepy pick-up lines."];
    
    // Create the attributes and add them to the string
    [bo.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,82)];
    [bo.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,82)];
    [bo.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,82)];
    [bo.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,82)];
    [bo.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,82)];
    [bo.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,82)];
    [bo.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,82)];
    [bo.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(82,106)];
    [bo.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(82,106)];
    [bo.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(82,106)];
    [bo.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(82,106)];
    [bo.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(82,106)];
    [bo.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(82,106)];
    [bo.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(82,106)];
    // bo end
    
    
    // britt begin
    
    BRBachelorette *britt = [[BRBachelorette alloc] init];
    [_bachelors addObject:britt];
    britt.name = @"Britt";
    britt.age = 27;
    britt.occupation = @"Waitress";
    britt.hometownCity = @"Hollywood";
    britt.hometownState = @"California";
    britt.heightFeet = 5;
    britt.heightInch = 5;
    britt.heightInInches = 65;
    britt.tattooCount = 0;
    britt.cannotLiveWithout = @"Bible, journal, makeup, snacks, cell phone";
    britt.biggestDateFear = @"Being into someone who isn't into me";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", britt.name]]) {
        britt.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", britt.name]]) {
        britt.myTeam = YES;
    }

    
    // Create the attributed string
    britt.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to worry, I would be very happy."];
    
    // Create the attributes and add them to the string
    [britt.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [britt.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [britt.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [britt.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [britt.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [britt.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [britt.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [britt.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [britt.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [britt.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [britt.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,5)];
    [britt.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,5)];
    [britt.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,5)];
    [britt.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [britt.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,24)];
    [britt.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,24)];
    [britt.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,24)];
    [britt.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,24)];
    [britt.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,24)];
    [britt.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(23,24)];
    [britt.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,24)];
    
    
    // Create the attributed string
    britt.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to step out of my comfort zone, I would be very sad."];
    
    // Create the attributes and add them to the string
    [britt.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [britt.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [britt.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [britt.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [britt.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [britt.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [britt.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [britt.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,27)];
    [britt.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,27)];
    [britt.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,27)];
    [britt.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,27)];
    [britt.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,27)];
    [britt.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,27)];
    [britt.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,27)];
    [britt.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(45,22)];
    [britt.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(45,22)];
    [britt.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(45,22)];
    [britt.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(45,22)];
    [britt.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(45,22)];
    [britt.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(45,22)];
    [britt.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(45,22)];
    
    
    // Create the attributed string
    britt.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you won the lottery, what would you do with your winnings?\nPay off my college loans. Buy my parents whatever they need most, plus a vacation! Save half of the difference and give the other half to charity."];
    
    // Create the attributes and add them to the string
    [britt.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [britt.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [britt.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [britt.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [britt.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,61)];
    [britt.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [britt.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [britt.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,147)];
    [britt.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,147)];
    [britt.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,147)];
    [britt.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,147)];
    [britt.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,147)];
    [britt.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,147)];
    [britt.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,147)];
    
    
    // Create the attributed string
    britt.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Who is your favorite author?\nDavid Foster Wallace or Dave Eggers. Both men have (or had) such a grasp of the human experience and the English language. Great wordsmiths, highly eccentric."];
    
    // Create the attributes and add them to the string
    [britt.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,28)];
    [britt.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,28)];
    [britt.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,28)];
    [britt.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,28)];
    [britt.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,28)];
    [britt.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,28)];
    [britt.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,28)];
    [britt.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(28,159)];
    [britt.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(28,159)];
    [britt.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(28,159)];
    [britt.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(28,159)];
    [britt.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(28,159)];
    [britt.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(28,159)];
    [britt.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(28,159)];
    
    
    // Create the attributed string
    britt.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Who do you admire most in the world?\nPeople who face danger to promote or defend the things they believe in. That's really living what you talk about."];
    
    // Create the attributes and add them to the string
    [britt.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [britt.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [britt.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [britt.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [britt.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [britt.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [britt.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [britt.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,114)];
    [britt.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,114)];
    [britt.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,114)];
    [britt.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,114)];
    [britt.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,114)];
    [britt.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,114)];
    [britt.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,114)];
    
    
    // Create the attributed string
    britt.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your greatest achievement to date?\nThe children I sponsor are my most proud achievement. I am happy to put my money toward giving them a better life."];
    
    // Create the attributes and add them to the string
    [britt.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [britt.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [britt.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [britt.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,42)];
    [britt.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,42)];
    [britt.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,42)];
    [britt.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [britt.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(42,115)];
    [britt.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,115)];
    [britt.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(42,115)];
    [britt.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(42,115)];
    [britt.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(42,115)];
    [britt.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(42,115)];
    [britt.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,115)];
    // britt end
    
    
    // brittany begin
    
    BRBachelorette *brittany = [[BRBachelorette alloc] init];
    [_bachelors addObject:brittany];
    brittany.name = @"Brittany";
    brittany.age = 26;
    brittany.occupation = @"WWE Diva-in-Training";
    brittany.hometownCity = @"Orlando";
    brittany.hometownState = @"Florida";
    brittany.heightFeet = 5;
    brittany.heightInch = 4;
    brittany.heightInInches = 64;
    brittany.tattooCount = 2;
    brittany.cannotLiveWithout = @"Family, laughter, the ocean, chocolate, reading material";
    brittany.biggestDateFear = @"Gas or violent diarrhea";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", brittany.name]]) {
        brittany.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", brittany.name]]) {
        brittany.myTeam = YES;
    }

    
    // Create the attributed string
    brittany.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to say goodbye, I would be very happy."];
    
    // Create the attributes and add them to the string
    [brittany.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [brittany.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [brittany.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [brittany.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [brittany.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [brittany.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [brittany.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [brittany.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,11)];
    [brittany.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,11)];
    [brittany.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,11)];
    [brittany.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,11)];
    [brittany.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,11)];
    [brittany.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,11)];
    [brittany.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,11)];
    [brittany.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(29,24)];
    [brittany.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(29,24)];
    [brittany.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(29,24)];
    [brittany.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(29,24)];
    [brittany.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(29,24)];
    [brittany.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(29,24)];
    [brittany.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(29,24)];
    
    
    // Create the attributed string
    brittany.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to see the sunset, I would be very sad."];
    
    // Create the attributes and add them to the string
    [brittany.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [brittany.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [brittany.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [brittany.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [brittany.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [brittany.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [brittany.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [brittany.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,14)];
    [brittany.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,14)];
    [brittany.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,14)];
    [brittany.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,14)];
    [brittany.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,14)];
    [brittany.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,14)];
    [brittany.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,14)];
    [brittany.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(32,22)];
    [brittany.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,22)];
    [brittany.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(32,22)];
    [brittany.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(32,22)];
    [brittany.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(32,22)];
    [brittany.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(32,22)];
    [brittany.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,22)];
    
    
    // Create the attributed string
    brittany.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your greatest achievement to date?\nBecoming a WWE Diva and learning to wrestle! So crazy but amazing at the same time."];
    
    // Create the attributes and add them to the string
    [brittany.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [brittany.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [brittany.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [brittany.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,42)];
    [brittany.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,42)];
    [brittany.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,42)];
    [brittany.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [brittany.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(42,84)];
    [brittany.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,84)];
    [brittany.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(42,84)];
    [brittany.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(42,84)];
    [brittany.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(42,84)];
    [brittany.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(42,84)];
    [brittany.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,84)];
    
    
    // Create the attributed string
    brittany.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be a fictional character, who would you be?\nBelle from Beauty and the Beast. I loved her as a child and now as an adult I admire her ability to see beauty from the inside first."];
    
    // Create the attributes and add them to the string
    [brittany.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [brittany.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [brittany.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [brittany.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [brittany.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [brittany.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [brittany.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [brittany.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,12)];
    [brittany.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,12)];
    [brittany.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,12)];
    [brittany.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,12)];
    [brittany.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,12)];
    [brittany.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,12)];
    [brittany.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,12)];
    [brittany.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(68,20)];
    [brittany.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(68,20)];
    [brittany.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(68,20)];
    [brittany.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(68,20)];
    [brittany.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(68,20)];
    [brittany.question4 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(68,20)];
    [brittany.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(68,20)];
    [brittany.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(88,102)];
    [brittany.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(88,102)];
    [brittany.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(88,102)];
    [brittany.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(88,102)];
    [brittany.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(88,102)];
    [brittany.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(88,102)];
    [brittany.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(88,102)];
    
    
    // Create the attributed string
    brittany.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Describe your idea of the ultimate date.\nThe ultimate date is when you're absolutely in love with a person -- it doesn't even matter where you go or if you stay home on the couch. I've been on amazing dates, but if I felt nothing, none of it mattered."];
    
    // Create the attributes and add them to the string
    [brittany.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,40)];
    [brittany.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,40)];
    [brittany.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,40)];
    [brittany.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,40)];
    [brittany.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,40)];
    [brittany.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,40)];
    [brittany.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,40)];
    [brittany.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(40,211)];
    [brittany.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(40,211)];
    [brittany.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(40,211)];
    [brittany.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(40,211)];
    [brittany.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(40,211)];
    [brittany.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(40,211)];
    [brittany.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(40,211)];
    
    
    // Create the attributed string
    brittany.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's your most embarrassing moment?\nPeeing while still being attached to a microphone, or my shorts coming off in my very first wrestling match."];
    
    // Create the attributes and add them to the string
    [brittany.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,37)];
    [brittany.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,37)];
    [brittany.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,37)];
    [brittany.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,37)];
    [brittany.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,37)];
    [brittany.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,37)];
    [brittany.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,37)];
    [brittany.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(37,109)];
    [brittany.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,109)];
    [brittany.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(37,109)];
    [brittany.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(37,109)];
    [brittany.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(37,109)];
    [brittany.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(37,109)];
    [brittany.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,109)];
    // brittany end
    
    
    // carly begin
    
    BRBachelorette *carly = [[BRBachelorette alloc] init];
    [_bachelors addObject:carly];
    carly.name = @"Carly";
    carly.age = 29;
    carly.occupation = @"Cruise Ship Singer";
    carly.hometownCity = @"Arlington";
    carly.hometownState = @"Texas";
    carly.heightFeet = 5;
    carly.heightInch = 4;
    carly.heightInInches = 64;
    carly.tattooCount = 0;
    carly.cannotLiveWithout = @"God, family, mascara, curling iron, cut-off denim shorts";
    carly.biggestDateFear = @"Silence";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", carly.name]]) {
        carly.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", carly.name]]) {
        carly.myTeam = YES;
    }

    
    // Create the attributed string
    carly.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date is invested, opens the door, asks questions, looks me in the eyes, compliments me, smiles, laughs, holds my hand."];
    
    // Create the attributes and add them to the string
    [carly.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [carly.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [carly.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [carly.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [carly.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [carly.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [carly.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [carly.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,113)];
    [carly.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,113)];
    [carly.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,113)];
    [carly.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,113)];
    [carly.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,113)];
    [carly.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,113)];
    [carly.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,113)];
    
    
    // Create the attributed string
    carly.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date looks at his phone the whole time, is absent mentally, is too handsy (at first), eats less than me, is rude to other people."];
    
    // Create the attributes and add them to the string
    [carly.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [carly.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [carly.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [carly.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [carly.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [carly.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [carly.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [carly.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,124)];
    [carly.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,124)];
    [carly.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,124)];
    [carly.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,124)];
    [carly.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,124)];
    [carly.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,124)];
    [carly.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,124)];
    
    
    // Create the attributed string
    carly.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is the most outrageous thing you've ever done?\nI had to be a pirate watcher from midnight to 4am in the Red Sea on my last ship. (Yes, you read that correct...actual pirates, not Captain Hook.)"];
    
    // Create the attributes and add them to the string
    [carly.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,51)];
    [carly.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,51)];
    [carly.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,51)];
    [carly.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,51)];
    [carly.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,51)];
    [carly.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,51)];
    [carly.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,51)];
    [carly.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(51,147)];
    [carly.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(51,147)];
    [carly.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(51,147)];
    [carly.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(51,147)];
    [carly.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(51,147)];
    [carly.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(51,147)];
    [carly.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(51,147)];
    
    
    // Create the attributed string
    carly.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Who is your favorite actor?\nRachel McAdams -- she's brilliant while being adorable at the same time. Perfect balance."];
    
    // Create the attributes and add them to the string
    [carly.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,27)];
    [carly.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,27)];
    [carly.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,27)];
    [carly.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,27)];
    [carly.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,27)];
    [carly.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,27)];
    [carly.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,27)];
    [carly.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(27,90)];
    [carly.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(27,90)];
    [carly.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(27,90)];
    [carly.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(27,90)];
    [carly.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(27,90)];
    [carly.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(27,90)];
    [carly.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(27,90)];
    
    
    // Create the attributed string
    carly.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's the most romantic present you have ever received?\nA handpicked flower from his walk to pick me up. Something about a man twirling a flower in his fingers...so sweet and thoughtful."];
    
    // Create the attributes and add them to the string
    [carly.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [carly.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [carly.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [carly.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [carly.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [carly.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [carly.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [carly.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,131)];
    [carly.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,131)];
    [carly.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,131)];
    [carly.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,131)];
    [carly.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,131)];
    [carly.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,131)];
    [carly.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,131)];
    
    
    // Create the attributed string
    carly.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What does being married mean to you?\nTwo souls growing independently and intertwined at the same time. Unconditional love, trust, companionship and compassion."];
    
    // Create the attributes and add them to the string
    [carly.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [carly.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [carly.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [carly.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [carly.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [carly.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [carly.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [carly.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,123)];
    [carly.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,123)];
    [carly.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,123)];
    [carly.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,123)];
    [carly.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,123)];
    [carly.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,123)];
    [carly.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,123)];
    // carly end
    
    // jade begin
    
    BRBachelorette *jade = [[BRBachelorette alloc] init];
    [_bachelors addObject:jade];
    jade.name = @"Jade";
    jade.age = 28;
    jade.occupation = @"Cosmetics Developer";
    jade.hometownCity = @"Los Angeles";
    jade.hometownState = @"California";
    jade.heightFeet = 5;
    jade.heightInch = 4;
    jade.heightInInches = 64;
    jade.tattooCount = 2;
    jade.cannotLiveWithout = @"My dog, my car, my family, avocados, books";
    jade.biggestDateFear = @"Having to tell someone there's no chemistry";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", jade.name]]) {
        jade.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", jade.name]]) {
        jade.myTeam = YES;
    }

    
    // Create the attributed string
    jade.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to worry about debt, I would be very happy."];
    
    // Create the attributes and add them to the string
    [jade.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [jade.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [jade.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [jade.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [jade.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [jade.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [jade.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [jade.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,16)];
    [jade.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,16)];
    [jade.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,16)];
    [jade.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,16)];
    [jade.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,16)];
    [jade.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,16)];
    [jade.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,16)];
    [jade.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(34,24)];
    [jade.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(34,24)];
    [jade.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(34,24)];
    [jade.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(34,24)];
    [jade.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(34,24)];
    [jade.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(34,24)];
    [jade.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(34,24)];
    
    
    // Create the attributed string
    jade.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to go outside, I would be very sad."];
    
    // Create the attributes and add them to the string
    [jade.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [jade.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [jade.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [jade.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [jade.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [jade.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [jade.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [jade.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,10)];
    [jade.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,10)];
    [jade.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,10)];
    [jade.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,10)];
    [jade.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,10)];
    [jade.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,10)];
    [jade.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,10)];
    [jade.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(28,22)];
    [jade.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(28,22)];
    [jade.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(28,22)];
    [jade.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(28,22)];
    [jade.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(28,22)];
    [jade.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(28,22)];
    [jade.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(28,22)];
    
    
    // Create the attributed string
    jade.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your greatest achievement to date?\nMoving to Los Angeles on my own and starting the launch of my business."];
    
    // Create the attributes and add them to the string
    [jade.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [jade.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [jade.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [jade.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,42)];
    [jade.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,42)];
    [jade.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,42)];
    [jade.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [jade.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(42,72)];
    [jade.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,72)];
    [jade.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(42,72)];
    [jade.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(42,72)];
    [jade.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(42,72)];
    [jade.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(42,72)];
    [jade.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,72)];
    
    
    // Create the attributed string
    jade.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be any animal, what would you be?\nAn elephant. They are associated with wisdom and altruism. They are large in scale yet graceful. I love the matriarchy as well."];
    
    // Create the attributes and add them to the string
    [jade.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [jade.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [jade.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [jade.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,46)];
    [jade.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,46)];
    [jade.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,46)];
    [jade.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [jade.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(46,128)];
    [jade.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,128)];
    [jade.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(46,128)];
    [jade.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(46,128)];
    [jade.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(46,128)];
    [jade.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(46,128)];
    [jade.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,128)];
    
    
    // Create the attributed string
    jade.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be a fictional character, who would you be?\nJane Eyre. She's admirable, a heroine that relies on herself to get back on her feet. She's complex and passionate."];
    
    // Create the attributes and add them to the string
    [jade.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [jade.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [jade.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [jade.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [jade.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [jade.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [jade.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [jade.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,116)];
    [jade.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,116)];
    [jade.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,116)];
    [jade.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,116)];
    [jade.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,116)];
    [jade.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,116)];
    [jade.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,116)];
    
    
    // Create the attributed string
    jade.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you won the lottery, what would you do with your winnings?\nLaunch my business, pay off my debt, set my parents up for retirement, invest, and give back."];
    
    // Create the attributes and add them to the string
    [jade.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [jade.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [jade.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [jade.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [jade.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,61)];
    [jade.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [jade.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [jade.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,94)];
    [jade.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,94)];
    [jade.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,94)];
    [jade.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,94)];
    [jade.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,94)];
    [jade.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,94)];
    [jade.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,94)];
    // jade end
    
    // jillian begin
    
    BRBachelorette *jillian = [[BRBachelorette alloc] init];
    [_bachelors addObject:jillian];
    jillian.name = @"Jillian";
    jillian.age = 25;
    jillian.occupation = @"News Producer";
    jillian.hometownCity = @"Washington";
    jillian.hometownState = @"District of Columbia";
    jillian.heightFeet = 5;
    jillian.heightInch = 2;
    jillian.heightInInches = 62;
    jillian.tattooCount = 0;
    jillian.cannotLiveWithout = @"My phone, chocolate, my bunny rabbit, Netflix, Mexican food";
    jillian.biggestDateFear = @"A guy with bad intentions";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", jillian.name]]) {
        jillian.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", jillian.name]]) {
        jillian.myTeam = YES;
    }

    
    // Create the attributed string
    jillian.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to mow the lawn, I would be very happy."];
    
    // Create the attributes and add them to the string
    [jillian.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [jillian.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [jillian.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [jillian.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [jillian.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [jillian.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [jillian.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [jillian.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,12)];
    [jillian.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,12)];
    [jillian.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,12)];
    [jillian.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,12)];
    [jillian.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,12)];
    [jillian.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,12)];
    [jillian.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,12)];
    [jillian.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(30,24)];
    [jillian.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(30,24)];
    [jillian.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(30,24)];
    [jillian.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(30,24)];
    [jillian.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(30,24)];
    [jillian.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(30,24)];
    [jillian.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(30,24)];
    
    
    // Create the attributed string
    jillian.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to eat, I would be very sad."];
    
    // Create the attributes and add them to the string
    [jillian.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [jillian.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [jillian.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [jillian.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [jillian.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [jillian.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [jillian.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [jillian.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,3)];
    [jillian.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,3)];
    [jillian.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,3)];
    [jillian.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,3)];
    [jillian.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,3)];
    [jillian.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,3)];
    [jillian.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,3)];
    [jillian.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(21,22)];
    [jillian.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(21,22)];
    [jillian.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(21,22)];
    [jillian.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(21,22)];
    [jillian.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(21,22)];
    [jillian.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(21,22)];
    [jillian.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(21,22)];
    
    
    // Create the attributed string
    jillian.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you really wanted to impress a man, what would you do?\nBe myself. If he's not impressed he's not the right one. I like intellectual conversations."];
    
    // Create the attributes and add them to the string
    [jillian.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [jillian.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [jillian.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [jillian.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,57)];
    [jillian.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,57)];
    [jillian.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,57)];
    [jillian.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [jillian.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(57,92)];
    [jillian.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,92)];
    [jillian.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(57,92)];
    [jillian.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(57,92)];
    [jillian.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(57,92)];
    [jillian.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(57,92)];
    [jillian.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,92)];
    
    
    // Create the attributed string
    jillian.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's the most outrageous thing you have ever done?\nI let Mike Tyson feel my bicep and I let him dangerously close to my ear...but I still have both."];
    
    // Create the attributes and add them to the string
    [jillian.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,52)];
    [jillian.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,52)];
    [jillian.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,52)];
    [jillian.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,52)];
    [jillian.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,52)];
    [jillian.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,52)];
    [jillian.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,52)];
    [jillian.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(52,98)];
    [jillian.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(52,98)];
    [jillian.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(52,98)];
    [jillian.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(52,98)];
    [jillian.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(52,98)];
    [jillian.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(52,98)];
    [jillian.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(52,98)];
    
    
    // Create the attributed string
    jillian.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be a fictional character, who would you be?\nIron Man -- because he's Iron Man! I want the suit and to be able to save people and fly around."];
    
    // Create the attributes and add them to the string
    [jillian.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [jillian.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [jillian.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [jillian.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [jillian.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [jillian.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [jillian.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [jillian.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,97)];
    [jillian.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,97)];
    [jillian.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,97)];
    [jillian.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,97)];
    [jillian.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,97)];
    [jillian.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,97)];
    [jillian.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,97)];
    
    
    // Create the attributed string
    jillian.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's your most embarrassing moment?\nPossibly this process...getting asked about my life in front of tons of people. Eek!"];
    
    // Create the attributes and add them to the string
    [jillian.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,37)];
    [jillian.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,37)];
    [jillian.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,37)];
    [jillian.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,37)];
    [jillian.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,37)];
    [jillian.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,37)];
    [jillian.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,37)];
    [jillian.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(37,85)];
    [jillian.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,85)];
    [jillian.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(37,85)];
    [jillian.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(37,85)];
    [jillian.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(37,85)];
    [jillian.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(37,85)];
    [jillian.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,85)];
    // jillian end
    
    // jordan begin
    
    BRBachelorette *jordan = [[BRBachelorette alloc] init];
    [_bachelors addObject:jordan];
    jordan.name = @"Jordan";
    jordan.age = 24;
    jordan.occupation = @"Student";
    jordan.hometownCity = @"Windsor";
    jordan.hometownState = @"Colorado";
    jordan.heightFeet = 5;
    jordan.heightInch = 5;
    jordan.heightInInches = 65;
    jordan.tattooCount = 2;
    jordan.cannotLiveWithout = @"Blush, toothbrush, phone, water, food";
    jordan.biggestDateFear = @"Getting stomach cramps";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", jordan.name]]) {
        jordan.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", jordan.name]]) {
        jordan.myTeam = YES;
    }

    
    // Create the attributed string
    jordan.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date opens my door and brings me flowers."];
    
    // Create the attributes and add them to the string
    [jordan.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [jordan.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [jordan.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [jordan.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [jordan.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [jordan.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [jordan.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [jordan.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,36)];
    [jordan.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,36)];
    [jordan.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,36)];
    [jordan.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,36)];
    [jordan.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,36)];
    [jordan.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,36)];
    [jordan.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,36)];
    
    
    // Create the attributed string
    jordan.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date smacks his food!"];
    
    // Create the attributes and add them to the string
    [jordan.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [jordan.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [jordan.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [jordan.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [jordan.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [jordan.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [jordan.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [jordan.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,16)];
    [jordan.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,16)];
    [jordan.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,16)];
    [jordan.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,16)];
    [jordan.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,16)];
    [jordan.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,16)];
    [jordan.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,16)];
    
    
    // Create the attributed string
    jordan.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's the most outrageous thing you've ever done?\nI jumped off the back of a boat bar naked in the British Virgin Islands and then was the bartender while the real one took a nap."];
    
    // Create the attributes and add them to the string
    [jordan.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,50)];
    [jordan.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,50)];
    [jordan.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,50)];
    [jordan.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,50)];
    [jordan.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,50)];
    [jordan.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,50)];
    [jordan.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,50)];
    [jordan.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(50,130)];
    [jordan.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(50,130)];
    [jordan.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(50,130)];
    [jordan.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(50,130)];
    [jordan.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(50,130)];
    [jordan.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(50,130)];
    [jordan.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(50,130)];
    
    
    // Create the attributed string
    jordan.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be someone else for just one day, who would it be?\nBritney Spears because she's awesome!"];
    
    // Create the attributes and add them to the string
    [jordan.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,63)];
    [jordan.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,63)];
    [jordan.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,63)];
    [jordan.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,63)];
    [jordan.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,63)];
    [jordan.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,63)];
    [jordan.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,63)];
    [jordan.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(63,38)];
    [jordan.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(63,38)];
    [jordan.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(63,38)];
    [jordan.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(63,38)];
    [jordan.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(63,38)];
    [jordan.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(63,38)];
    [jordan.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(63,38)];
    
    
    // Create the attributed string
    jordan.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you really wanted to impress a man, what would you do?\nGive him a sexy dance because it would turn him on and hopefully lead to more."];
    
    // Create the attributes and add them to the string
    [jordan.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [jordan.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [jordan.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [jordan.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,57)];
    [jordan.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,57)];
    [jordan.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,57)];
    [jordan.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [jordan.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(57,79)];
    [jordan.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,79)];
    [jordan.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(57,79)];
    [jordan.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(57,79)];
    [jordan.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(57,79)];
    [jordan.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(57,79)];
    [jordan.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,79)];
    
    
    // Create the attributed string
    jordan.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Who do you admire most in the world?\nMy mama. She always knows best, she's always been there when I need her -- or even if I don't. She's beautiful, successful, and I think she's amazing."];
    
    // Create the attributes and add them to the string
    [jordan.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [jordan.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [jordan.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [jordan.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [jordan.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [jordan.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [jordan.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [jordan.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,151)];
    [jordan.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,151)];
    [jordan.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,151)];
    [jordan.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,151)];
    [jordan.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,151)];
    [jordan.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,151)];
    [jordan.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,151)];
    // jordan end
    
    // juelia begin
    
    BRBachelorette *juelia = [[BRBachelorette alloc] init];
    [_bachelors addObject:juelia];
    juelia.name = @"Juelia";
    juelia.age = 30;
    juelia.occupation = @"Esthetician";
    juelia.hometownCity = @"Portland";
    juelia.hometownState = @"Oregon";
    juelia.heightFeet = 5;
    juelia.heightInch = 5;
    juelia.heightInInches = 65;
    juelia.tattooCount = 1;
    juelia.cannotLiveWithout = @"My tinted mineral sunscreen, adventure, faith, drive, sense of humor";
    juelia.biggestDateFear = @"Long periods of silence";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", juelia.name]]) {
        juelia.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", juelia.name]]) {
        juelia.myTeam = YES;
    }

    
    // Create the attributed string
    juelia.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to sleep, I would be very happy."];
    
    // Create the attributes and add them to the string
    [juelia.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [juelia.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [juelia.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [juelia.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [juelia.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [juelia.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [juelia.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [juelia.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [juelia.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [juelia.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [juelia.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,5)];
    [juelia.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,5)];
    [juelia.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,5)];
    [juelia.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [juelia.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,24)];
    [juelia.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,24)];
    [juelia.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,24)];
    [juelia.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,24)];
    [juelia.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,24)];
    [juelia.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(23,24)];
    [juelia.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,24)];
    
    
    // Create the attributed string
    juelia.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to eat, I would be very sad."];
    
    // Create the attributes and add them to the string
    [juelia.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [juelia.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [juelia.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [juelia.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [juelia.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [juelia.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [juelia.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [juelia.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,3)];
    [juelia.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,3)];
    [juelia.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,3)];
    [juelia.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,3)];
    [juelia.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,3)];
    [juelia.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,3)];
    [juelia.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,3)];
    [juelia.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(21,22)];
    [juelia.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(21,22)];
    [juelia.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(21,22)];
    [juelia.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(21,22)];
    [juelia.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(21,22)];
    [juelia.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(21,22)];
    [juelia.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(21,22)];
    
    
    // Create the attributed string
    juelia.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you won the lottery, what would you do with your winnings?\nBuy property and travel the world! And shop of course...I am a woman. :)"];
    
    // Create the attributes and add them to the string
    [juelia.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [juelia.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [juelia.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [juelia.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [juelia.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,61)];
    [juelia.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [juelia.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [juelia.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,73)];
    [juelia.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,73)];
    [juelia.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,73)];
    [juelia.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,73)];
    [juelia.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,73)];
    [juelia.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,73)];
    [juelia.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,73)];
    
    
    // Create the attributed string
    juelia.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Top 3 all-time favorite movies?\nDumb and Dumber, Titanic, and Bridesmaids."];
    
    // Create the attributes and add them to the string
    [juelia.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [juelia.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [juelia.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [juelia.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,31)];
    [juelia.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,31)];
    [juelia.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,31)];
    [juelia.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [juelia.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [juelia.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [juelia.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [juelia.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(31,1)];
    [juelia.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(31,1)];
    [juelia.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(31,1)];
    [juelia.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [juelia.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(32,26)];
    [juelia.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,26)];
    [juelia.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(32,26)];
    [juelia.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(32,26)];
    [juelia.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(32,26)];
    [juelia.question4 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(32,26)];
    [juelia.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,26)];
    [juelia.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(58,3)];
    [juelia.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(58,3)];
    [juelia.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(58,3)];
    [juelia.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(58,3)];
    [juelia.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(58,3)];
    [juelia.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(58,3)];
    [juelia.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(58,3)];
    [juelia.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,13)];
    [juelia.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,13)];
    [juelia.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,13)];
    [juelia.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,13)];
    [juelia.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,13)];
    [juelia.question4 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(61,13)];
    [juelia.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,13)];
    
    
    // Create the attributed string
    juelia.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's your worst date memory?\nThe guy took me to dinner, then refused to eat dinner, and then told me he couldn't believe I ate my whole dinner."];
    
    // Create the attributes and add them to the string
    [juelia.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,30)];
    [juelia.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,30)];
    [juelia.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,30)];
    [juelia.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,30)];
    [juelia.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,30)];
    [juelia.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,30)];
    [juelia.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,30)];
    [juelia.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(30,115)];
    [juelia.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(30,115)];
    [juelia.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(30,115)];
    [juelia.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(30,115)];
    [juelia.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(30,115)];
    [juelia.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(30,115)];
    [juelia.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(30,115)];
    
    
    // Create the attributed string
    juelia.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you consider yourself a romantic?\nI do! I know there's an amazing man out there for me, I just have to find him -- or hopefully he finds me on The Bachelor!"];
    
    // Create the attributes and add them to the string
    [juelia.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [juelia.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [juelia.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [juelia.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [juelia.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [juelia.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [juelia.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [juelia.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,110)];
    [juelia.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,110)];
    [juelia.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,110)];
    [juelia.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,110)];
    [juelia.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,110)];
    [juelia.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,110)];
    [juelia.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,110)];
    [juelia.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(146,12)];
    [juelia.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(146,12)];
    [juelia.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(146,12)];
    [juelia.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(146,12)];
    [juelia.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(146,12)];
    [juelia.question6 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(146,12)];
    [juelia.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(146,12)];
    [juelia.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(158,1)];
    [juelia.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(158,1)];
    [juelia.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(158,1)];
    [juelia.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(158,1)];
    [juelia.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(158,1)];
    [juelia.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(158,1)];
    [juelia.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(158,1)];
    // juelia end
    
    // kaitlyn begin
    
    BRBachelorette *kaitlyn = [[BRBachelorette alloc] init];
    [_bachelors addObject:kaitlyn];
    kaitlyn.name = @"Kaitlyn";
    kaitlyn.age = 29;
    kaitlyn.occupation = @"Dance Instructor";
    kaitlyn.hometownCity = @"Vancouver";
    kaitlyn.hometownState = @"British Columbia";
    kaitlyn.heightFeet = 5;
    kaitlyn.heightInch = 4;
    kaitlyn.heightInInches = 64;
    kaitlyn.tattooCount = 5;
    kaitlyn.cannotLiveWithout = @"Moisturizer, family, eyelash curler, sushi, music";
    kaitlyn.biggestDateFear = @"That we won't feel the same";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", kaitlyn.name]]) {
        kaitlyn.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", kaitlyn.name]]) {
        kaitlyn.myTeam = YES;
    }

    
    // Create the attributed string
    kaitlyn.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to worry, I would be very happy."];
    
    // Create the attributes and add them to the string
    [kaitlyn.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kaitlyn.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kaitlyn.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kaitlyn.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [kaitlyn.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [kaitlyn.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [kaitlyn.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kaitlyn.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [kaitlyn.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [kaitlyn.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [kaitlyn.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,5)];
    [kaitlyn.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,5)];
    [kaitlyn.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,5)];
    [kaitlyn.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [kaitlyn.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,24)];
    [kaitlyn.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,24)];
    [kaitlyn.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,24)];
    [kaitlyn.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,24)];
    [kaitlyn.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,24)];
    [kaitlyn.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(23,24)];
    [kaitlyn.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,24)];
    
    
    // Create the attributed string
    kaitlyn.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to love, I would be very sad."];
    
    // Create the attributes and add them to the string
    [kaitlyn.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kaitlyn.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kaitlyn.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kaitlyn.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [kaitlyn.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [kaitlyn.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [kaitlyn.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kaitlyn.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,4)];
    [kaitlyn.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,4)];
    [kaitlyn.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,4)];
    [kaitlyn.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,4)];
    [kaitlyn.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,4)];
    [kaitlyn.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,4)];
    [kaitlyn.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,4)];
    [kaitlyn.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(22,22)];
    [kaitlyn.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(22,22)];
    [kaitlyn.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(22,22)];
    [kaitlyn.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(22,22)];
    [kaitlyn.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(22,22)];
    [kaitlyn.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(22,22)];
    [kaitlyn.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(22,22)];
    
    
    // Create the attributed string
    kaitlyn.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you won the lottery, what would you do with your winnings?\nPay back my parents for all my dance lessons, buy an island and make it into a land of pirates. It would be called Yarrrland."];
    
    // Create the attributes and add them to the string
    [kaitlyn.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [kaitlyn.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [kaitlyn.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [kaitlyn.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [kaitlyn.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,61)];
    [kaitlyn.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [kaitlyn.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [kaitlyn.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,126)];
    [kaitlyn.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,126)];
    [kaitlyn.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,126)];
    [kaitlyn.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,126)];
    [kaitlyn.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,126)];
    [kaitlyn.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,126)];
    [kaitlyn.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,126)];
    
    
    // Create the attributed string
    kaitlyn.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your greatest achievement to date?\nGetting a dance scholarship and moving out of my small town for it."];
    
    // Create the attributes and add them to the string
    [kaitlyn.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [kaitlyn.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [kaitlyn.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [kaitlyn.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,42)];
    [kaitlyn.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,42)];
    [kaitlyn.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,42)];
    [kaitlyn.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [kaitlyn.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(42,68)];
    [kaitlyn.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,68)];
    [kaitlyn.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(42,68)];
    [kaitlyn.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(42,68)];
    [kaitlyn.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(42,68)];
    [kaitlyn.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(42,68)];
    [kaitlyn.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,68)];
    
    
    // Create the attributed string
    kaitlyn.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be a fictional character, who would you be?\nApril O'Neil because she gets to hang out with the Ninja Turtles and she's a babe."];
    
    // Create the attributes and add them to the string
    [kaitlyn.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [kaitlyn.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [kaitlyn.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [kaitlyn.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [kaitlyn.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [kaitlyn.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [kaitlyn.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [kaitlyn.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,83)];
    [kaitlyn.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,83)];
    [kaitlyn.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,83)];
    [kaitlyn.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,83)];
    [kaitlyn.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,83)];
    [kaitlyn.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,83)];
    [kaitlyn.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,83)];
    
    
    // Create the attributed string
    kaitlyn.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you wanted to approach a man you'd never met before, how would you go about it?\nI'd walk right up to him and just say, \"Good, and you?\""];
    
    // Create the attributes and add them to the string
    [kaitlyn.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,82)];
    [kaitlyn.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,82)];
    [kaitlyn.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,82)];
    [kaitlyn.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,82)];
    [kaitlyn.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,82)];
    [kaitlyn.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,82)];
    [kaitlyn.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,82)];
    [kaitlyn.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(82,56)];
    [kaitlyn.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(82,56)];
    [kaitlyn.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(82,56)];
    [kaitlyn.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(82,56)];
    [kaitlyn.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(82,56)];
    [kaitlyn.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(82,56)];
    [kaitlyn.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(82,56)];
    // kaitlyn end
    
    // kara begin
    
    BRBachelorette *kara = [[BRBachelorette alloc] init];
    [_bachelors addObject:kara];
    kara.name = @"Kara";
    kara.age = 25;
    kara.occupation = @"High School Soccer Coach";
    kara.hometownCity = @"Brownsville";
    kara.hometownState = @"Kentucky";
    kara.heightFeet = 5;
    kara.heightInch = 7;
    kara.heightInInches = 67;
    kara.tattooCount = 0;
    kara.cannotLiveWithout = @"Mountain Dew, cookies, my family, writing, Jesus";
    kara.biggestDateFear = @"Sweating";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", kara.name]]) {
        kara.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", kara.name]]) {
        kara.myTeam = YES;
    }

    
    // Create the attributed string
    kara.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to go to grad school, I would be very happy."];
    
    // Create the attributes and add them to the string
    [kara.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kara.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kara.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kara.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [kara.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [kara.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [kara.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kara.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,17)];
    [kara.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,17)];
    [kara.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,17)];
    [kara.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,17)];
    [kara.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,17)];
    [kara.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,17)];
    [kara.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,17)];
    [kara.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(35,24)];
    [kara.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(35,24)];
    [kara.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(35,24)];
    [kara.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(35,24)];
    [kara.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(35,24)];
    [kara.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(35,24)];
    [kara.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(35,24)];
    
    
    // Create the attributed string
    kara.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to teach, I would be very sad."];
    
    // Create the attributes and add them to the string
    [kara.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kara.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kara.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kara.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [kara.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [kara.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [kara.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kara.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [kara.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [kara.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [kara.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,5)];
    [kara.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,5)];
    [kara.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,5)];
    [kara.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [kara.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,22)];
    [kara.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,22)];
    [kara.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,22)];
    [kara.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,22)];
    [kara.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,22)];
    [kara.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(23,22)];
    [kara.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,22)];
    
    
    // Create the attributed string
    kara.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be someone else for just one day, who would you be?\nMy future husband, so I'd know who he is, what he's like, and what goes on in his head."];
    
    // Create the attributes and add them to the string
    [kara.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,64)];
    [kara.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,64)];
    [kara.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,64)];
    [kara.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,64)];
    [kara.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,64)];
    [kara.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,64)];
    [kara.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,64)];
    [kara.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(64,88)];
    [kara.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(64,88)];
    [kara.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(64,88)];
    [kara.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(64,88)];
    [kara.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(64,88)];
    [kara.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(64,88)];
    [kara.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(64,88)];
    
    
    // Create the attributed string
    kara.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's your most embarrassing moment?\nA trainer had to massage my shins (splints) and my legs were really hairy. He was handsome, so... yeah."];
    
    // Create the attributes and add them to the string
    [kara.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,37)];
    [kara.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,37)];
    [kara.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,37)];
    [kara.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,37)];
    [kara.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,37)];
    [kara.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,37)];
    [kara.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,37)];
    [kara.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(37,104)];
    [kara.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,104)];
    [kara.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(37,104)];
    [kara.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(37,104)];
    [kara.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(37,104)];
    [kara.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(37,104)];
    [kara.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(37,104)];
    
    
    // Create the attributed string
    kara.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be any animal, what would you be?\nA housecat -- they're loved and petted, but their owners respect their independence."];
    
    // Create the attributes and add them to the string
    [kara.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [kara.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [kara.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [kara.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,46)];
    [kara.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,46)];
    [kara.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,46)];
    [kara.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [kara.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(46,85)];
    [kara.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,85)];
    [kara.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(46,85)];
    [kara.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(46,85)];
    [kara.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(46,85)];
    [kara.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(46,85)];
    [kara.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,85)];
    
    
    // Create the attributed string
    kara.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you really wanted to impress a man, what would you do?\nBe myself. And wear a sexy yet tasteful outfit. I think it's attractive to be yourself, and not easy when you're nervous."];
    
    // Create the attributes and add them to the string
    [kara.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [kara.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [kara.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [kara.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,57)];
    [kara.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,57)];
    [kara.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,57)];
    [kara.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [kara.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(57,122)];
    [kara.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,122)];
    [kara.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(57,122)];
    [kara.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(57,122)];
    [kara.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(57,122)];
    [kara.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(57,122)];
    [kara.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,122)];
    // kara end
    
    // kelsey begin
    
    BRBachelorette *kelsey = [[BRBachelorette alloc] init];
    [_bachelors addObject:kelsey];
    kelsey.name = @"Kelsey";
    kelsey.age = 28;
    kelsey.occupation = @"Guidance Counselor";
    kelsey.hometownCity = @"Austin";
    kelsey.hometownState = @"Texas";
    kelsey.heightFeet = 5;
    kelsey.heightInch = 5;
    kelsey.heightInInches = 65;
    kelsey.tattooCount = 0;
    kelsey.cannotLiveWithout = @"Hope, love, optimism, creativity, chapstick";
    kelsey.biggestDateFear = @"Diarrhea";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", kelsey.name]]) {
        kelsey.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", kelsey.name]]) {
        kelsey.myTeam = YES;
    }

    
    // Create the attributed string
    kelsey.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to experience the death of a loved one, I would be very happy."];
    
    // Create the attributes and add them to the string
    [kelsey.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kelsey.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kelsey.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kelsey.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [kelsey.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [kelsey.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [kelsey.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kelsey.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,35)];
    [kelsey.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,35)];
    [kelsey.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,35)];
    [kelsey.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,35)];
    [kelsey.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,35)];
    [kelsey.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,35)];
    [kelsey.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,35)];
    [kelsey.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(53,24)];
    [kelsey.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(53,24)];
    [kelsey.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(53,24)];
    [kelsey.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(53,24)];
    [kelsey.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(53,24)];
    [kelsey.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(53,24)];
    [kelsey.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(53,24)];
    
    
    // Create the attributed string
    kelsey.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to be challenged, I would be very sad."];
    
    // Create the attributes and add them to the string
    [kelsey.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kelsey.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kelsey.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kelsey.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [kelsey.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [kelsey.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [kelsey.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kelsey.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,13)];
    [kelsey.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,13)];
    [kelsey.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,13)];
    [kelsey.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,13)];
    [kelsey.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,13)];
    [kelsey.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,13)];
    [kelsey.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,13)];
    [kelsey.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(31,22)];
    [kelsey.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,22)];
    [kelsey.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(31,22)];
    [kelsey.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(31,22)];
    [kelsey.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(31,22)];
    [kelsey.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(31,22)];
    [kelsey.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,22)];
    
    
    // Create the attributed string
    kelsey.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Who do you admire most in the world?\nMy grandma Helen because she is full of grace, wisdom, style, and strength."];
    
    // Create the attributes and add them to the string
    [kelsey.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [kelsey.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [kelsey.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [kelsey.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [kelsey.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [kelsey.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [kelsey.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [kelsey.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,76)];
    [kelsey.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,76)];
    [kelsey.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,76)];
    [kelsey.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,76)];
    [kelsey.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,76)];
    [kelsey.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,76)];
    [kelsey.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,76)];
    
    
    // Create the attributed string
    kelsey.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be someone else for just one day, who would you be?\nI'd be my future spouse so I could truly know the person and his experience in life. Then when I ask, \"Honey, how was your day?\" I'd have a better idea."];
    
    // Create the attributes and add them to the string
    [kelsey.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,64)];
    [kelsey.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,64)];
    [kelsey.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,64)];
    [kelsey.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,64)];
    [kelsey.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,64)];
    [kelsey.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,64)];
    [kelsey.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,64)];
    [kelsey.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(64,153)];
    [kelsey.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(64,153)];
    [kelsey.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(64,153)];
    [kelsey.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(64,153)];
    [kelsey.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(64,153)];
    [kelsey.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(64,153)];
    [kelsey.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(64,153)];
    
    
    // Create the attributed string
    kelsey.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Top 3 all-time favorite movies?\nGood Will Hunting, What About Bob?, and Mean Girls. They're great to psychoanalyze."];
    
    // Create the attributes and add them to the string
    [kelsey.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [kelsey.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [kelsey.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [kelsey.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,31)];
    [kelsey.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,31)];
    [kelsey.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,31)];
    [kelsey.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [kelsey.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [kelsey.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [kelsey.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [kelsey.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(31,1)];
    [kelsey.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(31,1)];
    [kelsey.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(31,1)];
    [kelsey.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [kelsey.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(32,17)];
    [kelsey.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,17)];
    [kelsey.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(32,17)];
    [kelsey.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(32,17)];
    [kelsey.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(32,17)];
    [kelsey.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(32,17)];
    [kelsey.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,17)];
    [kelsey.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(49,2)];
    [kelsey.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(49,2)];
    [kelsey.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(49,2)];
    [kelsey.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(49,2)];
    [kelsey.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(49,2)];
    [kelsey.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(49,2)];
    [kelsey.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(49,2)];
    [kelsey.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(51,15)];
    [kelsey.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(51,15)];
    [kelsey.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(51,15)];
    [kelsey.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(51,15)];
    [kelsey.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(51,15)];
    [kelsey.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(51,15)];
    [kelsey.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(51,15)];
    [kelsey.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(66,6)];
    [kelsey.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(66,6)];
    [kelsey.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(66,6)];
    [kelsey.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(66,6)];
    [kelsey.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(66,6)];
    [kelsey.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(66,6)];
    [kelsey.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(66,6)];
    [kelsey.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(72,10)];
    [kelsey.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(72,10)];
    [kelsey.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(72,10)];
    [kelsey.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(72,10)];
    [kelsey.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(72,10)];
    [kelsey.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(72,10)];
    [kelsey.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(72,10)];
    [kelsey.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(82,33)];
    [kelsey.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(82,33)];
    [kelsey.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(82,33)];
    [kelsey.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(82,33)];
    [kelsey.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(82,33)];
    [kelsey.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(82,33)];
    [kelsey.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(82,33)];
    
    
    // Create the attributed string
    kelsey.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Describe your idea of the ultimate date.\nSomething neither of us has done -- outdoors, active, and in a new environment."];
    
    // Create the attributes and add them to the string
    [kelsey.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,40)];
    [kelsey.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,40)];
    [kelsey.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,40)];
    [kelsey.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,40)];
    [kelsey.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,40)];
    [kelsey.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,40)];
    [kelsey.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,40)];
    [kelsey.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(40,80)];
    [kelsey.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(40,80)];
    [kelsey.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(40,80)];
    [kelsey.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(40,80)];
    [kelsey.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(40,80)];
    [kelsey.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(40,80)];
    [kelsey.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(40,80)];
    // kelsey end
    
    // kimberly begin
    
    BRBachelorette *kimberly = [[BRBachelorette alloc] init];
    [_bachelors addObject:kimberly];
    kimberly.name = @"Kimberly";
    kimberly.age = 28;
    kimberly.occupation = @"Yoga Instructor";
    kimberly.hometownCity = @"Long Island";
    kimberly.hometownState = @"New York";
    kimberly.heightFeet = 5;
    kimberly.heightInch = 7;
    kimberly.heightInInches = 67;
    kimberly.tattooCount = 0;
    kimberly.cannotLiveWithout = @"Yoga, family, popcorn, my niece, makeup";
    kimberly.biggestDateFear = @"Not liking the guy and not being able to escape the date";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", kimberly.name]]) {
        kimberly.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", kimberly.name]]) {
        kimberly.myTeam = YES;
    }
    
    
    // Create the attributed string
    kimberly.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to think about money, I would be very happy."];
    
    // Create the attributes and add them to the string
    [kimberly.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kimberly.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kimberly.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kimberly.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [kimberly.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [kimberly.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [kimberly.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kimberly.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,17)];
    [kimberly.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,17)];
    [kimberly.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,17)];
    [kimberly.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,17)];
    [kimberly.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,17)];
    [kimberly.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,17)];
    [kimberly.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,17)];
    [kimberly.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(35,24)];
    [kimberly.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(35,24)];
    [kimberly.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(35,24)];
    [kimberly.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(35,24)];
    [kimberly.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(35,24)];
    [kimberly.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(35,24)];
    [kimberly.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(35,24)];
    
    
    // Create the attributed string
    kimberly.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to get dressed up, I would be very sad."];
    
    // Create the attributes and add them to the string
    [kimberly.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kimberly.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kimberly.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [kimberly.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [kimberly.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [kimberly.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [kimberly.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [kimberly.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,14)];
    [kimberly.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,14)];
    [kimberly.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,14)];
    [kimberly.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,14)];
    [kimberly.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,14)];
    [kimberly.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,14)];
    [kimberly.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,14)];
    [kimberly.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(32,22)];
    [kimberly.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,22)];
    [kimberly.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(32,22)];
    [kimberly.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(32,22)];
    [kimberly.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(32,22)];
    [kimberly.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(32,22)];
    [kimberly.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,22)];
    
    
    // Create the attributed string
    kimberly.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your greatest achievement to date?\nGraduating from college with honors."];
    
    // Create the attributes and add them to the string
    [kimberly.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [kimberly.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [kimberly.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [kimberly.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,42)];
    [kimberly.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,42)];
    [kimberly.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,42)];
    [kimberly.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [kimberly.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(42,37)];
    [kimberly.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,37)];
    [kimberly.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(42,37)];
    [kimberly.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(42,37)];
    [kimberly.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(42,37)];
    [kimberly.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(42,37)];
    [kimberly.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,37)];
    
    
    // Create the attributed string
    kimberly.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be a fictional character, who would you be?\nMabe a fairy godmother. It would be fun granting wishes!"];
    
    // Create the attributes and add them to the string
    [kimberly.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [kimberly.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [kimberly.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [kimberly.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [kimberly.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [kimberly.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [kimberly.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [kimberly.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,57)];
    [kimberly.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,57)];
    [kimberly.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,57)];
    [kimberly.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,57)];
    [kimberly.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,57)];
    [kimberly.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,57)];
    [kimberly.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,57)];
    
    
    // Create the attributed string
    kimberly.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Top 3 all-time favorite movies?\nShawshank Redemption (I cry every time), Another Earth, and Stepmom."];
    
    // Create the attributes and add them to the string
    [kimberly.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [kimberly.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [kimberly.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [kimberly.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,31)];
    [kimberly.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,31)];
    [kimberly.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,31)];
    [kimberly.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [kimberly.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [kimberly.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [kimberly.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [kimberly.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(31,1)];
    [kimberly.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(31,1)];
    [kimberly.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(31,1)];
    [kimberly.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [kimberly.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(32,20)];
    [kimberly.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,20)];
    [kimberly.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(32,20)];
    [kimberly.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(32,20)];
    [kimberly.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(32,20)];
    [kimberly.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(32,20)];
    [kimberly.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,20)];
    [kimberly.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(52,21)];
    [kimberly.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(52,21)];
    [kimberly.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(52,21)];
    [kimberly.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(52,21)];
    [kimberly.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(52,21)];
    [kimberly.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(52,21)];
    [kimberly.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(52,21)];
    [kimberly.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(73,13)];
    [kimberly.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(73,13)];
    [kimberly.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(73,13)];
    [kimberly.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(73,13)];
    [kimberly.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(73,13)];
    [kimberly.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(73,13)];
    [kimberly.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(73,13)];
    [kimberly.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(86,6)];
    [kimberly.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(86,6)];
    [kimberly.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(86,6)];
    [kimberly.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(86,6)];
    [kimberly.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(86,6)];
    [kimberly.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(86,6)];
    [kimberly.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(86,6)];
    [kimberly.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(92,7)];
    [kimberly.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(92,7)];
    [kimberly.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(92,7)];
    [kimberly.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(92,7)];
    [kimberly.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(92,7)];
    [kimberly.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(92,7)];
    [kimberly.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(92,7)];
    [kimberly.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(99,1)];
    [kimberly.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(99,1)];
    [kimberly.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(99,1)];
    [kimberly.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(99,1)];
    [kimberly.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(99,1)];
    [kimberly.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(99,1)];
    [kimberly.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(99,1)];
    
    
    // Create the attributed string
    kimberly.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you consider yourself a romantic?\nHopeless (or hopeful) romantic. I will always believe in love. Always."];
    
    // Create the attributes and add them to the string
    [kimberly.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [kimberly.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [kimberly.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [kimberly.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [kimberly.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [kimberly.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [kimberly.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [kimberly.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,71)];
    [kimberly.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,71)];
    [kimberly.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,71)];
    [kimberly.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,71)];
    [kimberly.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,71)];
    [kimberly.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,71)];
    [kimberly.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,71)];
    // kimberly end
    
    // mackenzie begin
    
    BRBachelorette *mackenzie = [[BRBachelorette alloc] init];
    [_bachelors addObject:mackenzie];
    mackenzie.name = @"Mackenzie";
    mackenzie.age = 21;
    mackenzie.occupation = @"Dental Assistant";
    mackenzie.hometownCity = @"Maple Valley";
    mackenzie.hometownState = @"Washington";
    mackenzie.heightFeet = 5;
    mackenzie.heightInch = 4;
    mackenzie.heightInInches = 64;
    mackenzie.tattooCount = 0;
    mackenzie.cannotLiveWithout = @"My family, my dog, friends, food/water";
    mackenzie.biggestDateFear = @"That they'll smell bad";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", mackenzie.name]]) {
        mackenzie.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", mackenzie.name]]) {
        mackenzie.myTeam = YES;
    }

    
    // Create the attributed string
    mackenzie.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to get shots, I would be very happy."];
    
    // Create the attributes and add them to the string
    [mackenzie.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [mackenzie.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [mackenzie.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [mackenzie.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [mackenzie.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [mackenzie.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [mackenzie.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [mackenzie.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,9)];
    [mackenzie.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,9)];
    [mackenzie.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,9)];
    [mackenzie.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,9)];
    [mackenzie.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,9)];
    [mackenzie.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,9)];
    [mackenzie.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,9)];
    [mackenzie.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(27,24)];
    [mackenzie.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(27,24)];
    [mackenzie.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(27,24)];
    [mackenzie.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(27,24)];
    [mackenzie.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(27,24)];
    [mackenzie.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(27,24)];
    [mackenzie.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(27,24)];
    
    
    // Create the attributed string
    mackenzie.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to drive, I would be very sad."];
    
    // Create the attributes and add them to the string
    [mackenzie.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [mackenzie.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [mackenzie.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [mackenzie.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [mackenzie.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [mackenzie.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [mackenzie.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [mackenzie.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [mackenzie.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [mackenzie.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,5)];
    [mackenzie.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,5)];
    [mackenzie.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,5)];
    [mackenzie.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,5)];
    [mackenzie.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,5)];
    [mackenzie.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,22)];
    [mackenzie.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,22)];
    [mackenzie.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,22)];
    [mackenzie.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,22)];
    [mackenzie.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,22)];
    [mackenzie.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(23,22)];
    [mackenzie.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,22)];
    
    
    // Create the attributed string
    mackenzie.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be someone else for just one day, who would you be?\nMila Kunis, because she is perfect."];
    
    // Create the attributes and add them to the string
    [mackenzie.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,64)];
    [mackenzie.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,64)];
    [mackenzie.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,64)];
    [mackenzie.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,64)];
    [mackenzie.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,64)];
    [mackenzie.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,64)];
    [mackenzie.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,64)];
    [mackenzie.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(64,36)];
    [mackenzie.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(64,36)];
    [mackenzie.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(64,36)];
    [mackenzie.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(64,36)];
    [mackenzie.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(64,36)];
    [mackenzie.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(64,36)];
    [mackenzie.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(64,36)];
    
    
    // Create the attributed string
    mackenzie.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Top 3 all-time favorite movies?\nPineapple Express, The Book of Eli, and Mean Girls."];
    
    // Create the attributes and add them to the string
    [mackenzie.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [mackenzie.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [mackenzie.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [mackenzie.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,31)];
    [mackenzie.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,31)];
    [mackenzie.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,31)];
    [mackenzie.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [mackenzie.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [mackenzie.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [mackenzie.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [mackenzie.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(31,1)];
    [mackenzie.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(31,1)];
    [mackenzie.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(31,1)];
    [mackenzie.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [mackenzie.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(32,36)];
    [mackenzie.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,36)];
    [mackenzie.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(32,36)];
    [mackenzie.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(32,36)];
    [mackenzie.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(32,36)];
    [mackenzie.question4 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(32,36)];
    [mackenzie.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,36)];
    [mackenzie.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(68,3)];
    [mackenzie.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(68,3)];
    [mackenzie.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(68,3)];
    [mackenzie.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(68,3)];
    [mackenzie.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(68,3)];
    [mackenzie.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(68,3)];
    [mackenzie.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(68,3)];
    [mackenzie.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(71,12)];
    [mackenzie.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(71,12)];
    [mackenzie.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(71,12)];
    [mackenzie.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(71,12)];
    [mackenzie.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(71,12)];
    [mackenzie.question4 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(71,12)];
    [mackenzie.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(71,12)];
    
    
    // Create the attributed string
    mackenzie.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be any animal, what would you be?\nA dog -- they never have to worry and get pampered all the time. (At least mine do.)"];
    
    // Create the attributes and add them to the string
    [mackenzie.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [mackenzie.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [mackenzie.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [mackenzie.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,46)];
    [mackenzie.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,46)];
    [mackenzie.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,46)];
    [mackenzie.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [mackenzie.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(46,85)];
    [mackenzie.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,85)];
    [mackenzie.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(46,85)];
    [mackenzie.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(46,85)];
    [mackenzie.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(46,85)];
    [mackenzie.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(46,85)];
    [mackenzie.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,85)];
    
    
    // Create the attributed string
    mackenzie.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What does being married mean to you?\nSettling down together and starting a family. Be a team, loyal and honest."];
    
    // Create the attributes and add them to the string
    [mackenzie.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [mackenzie.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [mackenzie.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [mackenzie.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [mackenzie.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [mackenzie.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [mackenzie.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [mackenzie.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,75)];
    [mackenzie.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,75)];
    [mackenzie.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,75)];
    [mackenzie.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,75)];
    [mackenzie.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,75)];
    [mackenzie.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,75)];
    [mackenzie.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,75)];
    // mackenzie end
    
    // megan begin
    
    BRBachelorette *megan = [[BRBachelorette alloc] init];
    [_bachelors addObject:megan];
    megan.name = @"Megan";
    megan.age = 24;
    megan.occupation = @"Make-Up Artist";
    megan.hometownCity = @"Nashville";
    megan.hometownState = @"Tennessee";
    megan.heightFeet = 5;
    megan.heightInch = 4;
    megan.heightInInches = 64;
    megan.tattooCount = 2;
    megan.cannotLiveWithout = @"The gym, my family, water, love, and my phone";
    megan.biggestDateFear = @"Not having anything in common";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", megan.name]]) {
        megan.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", megan.name]]) {
        megan.myTeam = YES;
    }

    
    // Create the attributed string
    megan.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date looks me in the eyes or tells me stories."];
    
    // Create the attributes and add them to the string
    [megan.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [megan.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [megan.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [megan.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [megan.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [megan.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [megan.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [megan.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,41)];
    [megan.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,41)];
    [megan.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,41)];
    [megan.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,41)];
    [megan.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,41)];
    [megan.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,41)];
    [megan.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,41)];
    
    
    // Create the attributed string
    megan.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date texts while talking to me."];
    
    // Create the attributes and add them to the string
    [megan.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [megan.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [megan.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [megan.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [megan.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [megan.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [megan.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [megan.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,26)];
    [megan.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,26)];
    [megan.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,26)];
    [megan.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,26)];
    [megan.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,26)];
    [megan.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,26)];
    [megan.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,26)];
    
    
    // Create the attributed string
    megan.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you really wanted to impress a man, what would you do?\nI think it's important to be yourself and not put up a front. Men are impressed with a down-to-earth girl who can make them feel comfortable. And then they can be themselves too."];
    
    // Create the attributes and add them to the string
    [megan.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [megan.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [megan.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [megan.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,57)];
    [megan.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,57)];
    [megan.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,57)];
    [megan.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [megan.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(57,179)];
    [megan.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,179)];
    [megan.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(57,179)];
    [megan.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(57,179)];
    [megan.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(57,179)];
    [megan.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(57,179)];
    [megan.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,179)];
    
    
    // Create the attributed string
    megan.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be any animal, what would you be?\nA lion, because they are leaders."];
    
    // Create the attributes and add them to the string
    [megan.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [megan.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [megan.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [megan.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,46)];
    [megan.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,46)];
    [megan.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,46)];
    [megan.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [megan.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(46,34)];
    [megan.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,34)];
    [megan.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(46,34)];
    [megan.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(46,34)];
    [megan.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(46,34)];
    [megan.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(46,34)];
    [megan.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,34)];
    
    
    // Create the attributed string
    megan.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Top 3 all-time favorite movies?\nThe Notebook, Step Brothers, and Gone with the Wind."];
    
    // Create the attributes and add them to the string
    [megan.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [megan.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [megan.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [megan.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,31)];
    [megan.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,31)];
    [megan.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,31)];
    [megan.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [megan.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [megan.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [megan.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [megan.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(31,1)];
    [megan.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(31,1)];
    [megan.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(31,1)];
    [megan.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [megan.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(32,29)];
    [megan.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,29)];
    [megan.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(32,29)];
    [megan.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(32,29)];
    [megan.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(32,29)];
    [megan.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(32,29)];
    [megan.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,29)];
    [megan.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,3)];
    [megan.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,3)];
    [megan.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,3)];
    [megan.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,3)];
    [megan.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,3)];
    [megan.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,3)];
    [megan.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,3)];
    [megan.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(64,20)];
    [megan.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(64,20)];
    [megan.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(64,20)];
    [megan.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(64,20)];
    [megan.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(64,20)];
    [megan.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(64,20)];
    [megan.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(64,20)];
    
    
    // Create the attributed string
    megan.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's your worst date memory?\nLast minute, a guy from my class asked me to be with him on New Year's in Memphis, TN. Well, my adventurous self went and got way too drunk. He watched me throw up in my purse! Haha, it was awful!"];
    
    // Create the attributes and add them to the string
    [megan.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,30)];
    [megan.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,30)];
    [megan.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,30)];
    [megan.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,30)];
    [megan.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,30)];
    [megan.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,30)];
    [megan.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,30)];
    [megan.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(30,197)];
    [megan.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(30,197)];
    [megan.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(30,197)];
    [megan.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(30,197)];
    [megan.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(30,197)];
    [megan.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(30,197)];
    [megan.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(30,197)];
    // megan end
    
    // michelle begin
    
    BRBachelorette *michelle = [[BRBachelorette alloc] init];
    [_bachelors addObject:michelle];
    michelle.name = @"Michelle";
    michelle.age = 25;
    michelle.occupation = @"Wedding Cake Decorator";
    michelle.hometownCity = @"Provo";
    michelle.hometownState = @"Utah";
    michelle.heightFeet = 5;
    michelle.heightInch = 3;
    michelle.heightInInches = 63;
    michelle.tattooCount = 0;
    michelle.cannotLiveWithout = @"Family, church/religion, food";
    michelle.biggestDateFear = @"A guy who doesn't talk or is rude";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", michelle.name]]) {
        michelle.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", michelle.name]]) {
        michelle.myTeam = YES;
    }

    
    // Create the attributed string
    michelle.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never had to see another spider or snake, I would be very happy."];
    
    // Create the attributes and add them to the string
    [michelle.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [michelle.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [michelle.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,18)];
    [michelle.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,18)];
    [michelle.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,18)];
    [michelle.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,18)];
    [michelle.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,18)];
    [michelle.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(18,27)];
    [michelle.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,27)];
    [michelle.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(18,27)];
    [michelle.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(18,27)];
    [michelle.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(18,27)];
    [michelle.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(18,27)];
    [michelle.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(18,27)];
    [michelle.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(45,24)];
    [michelle.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(45,24)];
    [michelle.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(45,24)];
    [michelle.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(45,24)];
    [michelle.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(45,24)];
    [michelle.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(45,24)];
    [michelle.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(45,24)];
    
    
    // Create the attributed string
    michelle.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If I never got to laugh again, I would be very sad."];
    
    // Create the attributes and add them to the string
    [michelle.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,17)];
    [michelle.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,17)];
    [michelle.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,17)];
    [michelle.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,17)];
    [michelle.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,17)];
    [michelle.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,17)];
    [michelle.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,17)];
    [michelle.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(17,12)];
    [michelle.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(17,12)];
    [michelle.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(17,12)];
    [michelle.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(17,12)];
    [michelle.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(17,12)];
    [michelle.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(17,12)];
    [michelle.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(17,12)];
    [michelle.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(29,22)];
    [michelle.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(29,22)];
    [michelle.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(29,22)];
    [michelle.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(29,22)];
    [michelle.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(29,22)];
    [michelle.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(29,22)];
    [michelle.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(29,22)];
    
    
    // Create the attributed string
    michelle.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be a fictional character, who would you be?\nGiselle from Enchanted because she's always happy, she makes cute clothes, animals clean her house for her, and she has a good singing voice."];
    
    // Create the attributes and add them to the string
    [michelle.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [michelle.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [michelle.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [michelle.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [michelle.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [michelle.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [michelle.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [michelle.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,142)];
    [michelle.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,142)];
    [michelle.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,142)];
    [michelle.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,142)];
    [michelle.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,142)];
    [michelle.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,142)];
    [michelle.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,142)];
    
    
    // Create the attributed string
    michelle.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Describe your idea of the ultimate date.\nA surprise trip to Waikoloa (Hawaii), a luau, a helicopter ride over volcanoes, and watch the sunset on the beach."];
    
    // Create the attributes and add them to the string
    [michelle.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,40)];
    [michelle.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,40)];
    [michelle.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,40)];
    [michelle.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,40)];
    [michelle.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,40)];
    [michelle.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,40)];
    [michelle.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,40)];
    [michelle.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(40,115)];
    [michelle.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(40,115)];
    [michelle.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(40,115)];
    [michelle.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(40,115)];
    [michelle.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(40,115)];
    [michelle.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(40,115)];
    [michelle.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(40,115)];
    
    
    // Create the attributed string
    michelle.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Top 3 all-time favorite movies?\nThe Wedding Singer, Pirates of the Caribbean, and Yes Man."];
    
    // Create the attributes and add them to the string
    [michelle.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [michelle.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [michelle.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,31)];
    [michelle.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,31)];
    [michelle.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,31)];
    [michelle.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,31)];
    [michelle.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,31)];
    [michelle.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [michelle.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [michelle.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(31,1)];
    [michelle.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(31,1)];
    [michelle.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(31,1)];
    [michelle.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(31,1)];
    [michelle.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(31,1)];
    [michelle.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(32,18)];
    [michelle.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,18)];
    [michelle.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(32,18)];
    [michelle.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(32,18)];
    [michelle.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(32,18)];
    [michelle.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(32,18)];
    [michelle.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(32,18)];
    [michelle.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(50,2)];
    [michelle.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(50,2)];
    [michelle.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(50,2)];
    [michelle.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(50,2)];
    [michelle.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(50,2)];
    [michelle.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(50,2)];
    [michelle.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(50,2)];
    [michelle.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(52,24)];
    [michelle.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(52,24)];
    [michelle.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(52,24)];
    [michelle.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(52,24)];
    [michelle.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(52,24)];
    [michelle.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(52,24)];
    [michelle.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(52,24)];
    [michelle.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(76,6)];
    [michelle.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(76,6)];
    [michelle.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(76,6)];
    [michelle.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(76,6)];
    [michelle.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(76,6)];
    [michelle.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(76,6)];
    [michelle.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(76,6)];
    [michelle.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(82,7)];
    [michelle.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(82,7)];
    [michelle.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(82,7)];
    [michelle.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(82,7)];
    [michelle.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(82,7)];
    [michelle.question5 addAttribute:NSFontAttributeName value:myStringFont3 range:NSMakeRange(82,7)];
    [michelle.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(82,7)];
    [michelle.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(89,1)];
    [michelle.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(89,1)];
    [michelle.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(89,1)];
    [michelle.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(89,1)];
    [michelle.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(89,1)];
    [michelle.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(89,1)];
    [michelle.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(89,1)];
    
    
    // Create the attributed string
    michelle.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you really wanted to impress a man, what would you do?\nLaugh at his jokes to make him feel funny, and ask him questions about himself to make him feel special and show I'm interested. I also make cakes for guys on special occasions."];
    
    // Create the attributes and add them to the string
    [michelle.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [michelle.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [michelle.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [michelle.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,57)];
    [michelle.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,57)];
    [michelle.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,57)];
    [michelle.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [michelle.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(57,178)];
    [michelle.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,178)];
    [michelle.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(57,178)];
    [michelle.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(57,178)];
    [michelle.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(57,178)];
    [michelle.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(57,178)];
    [michelle.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,178)];
    // michelle end
    
    // nicole begin
    
    BRBachelorette *nicole = [[BRBachelorette alloc] init];
    [_bachelors addObject:nicole];
    nicole.name = @"Nicole";
    nicole.age = 31;
    nicole.occupation = @"Real Estate Agent";
    nicole.hometownCity = @"Scottsdale";
    nicole.hometownState = @"Arizona";
    nicole.heightFeet = 5;
    nicole.heightInch = 8;
    nicole.heightInInches = 68;
    nicole.tattooCount = 0;
    nicole.cannotLiveWithout = @"My dogs, sunblock, dessert, passport, hiking shoes";
    nicole.biggestDateFear = @"Having nothing to talk about";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", nicole.name]]) {
        nicole.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", nicole.name]]) {
        nicole.myTeam = YES;
    }

    
    // Create the attributed string
    nicole.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date is chivalrous, compliments me and is truly interested in getting to know me, and asks questions."];
    
    // Create the attributes and add them to the string
    [nicole.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [nicole.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [nicole.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [nicole.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [nicole.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [nicole.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [nicole.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [nicole.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,96)];
    [nicole.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,96)];
    [nicole.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,96)];
    [nicole.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,96)];
    [nicole.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,96)];
    [nicole.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,96)];
    [nicole.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,96)];
    
    
    // Create the attributed string
    nicole.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date talks about himself non-stop, doesn't buy dinner (when he asked me out!), has bad manners, is rude to the staff, has bad breath."];
    
    // Create the attributes and add them to the string
    [nicole.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [nicole.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [nicole.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [nicole.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [nicole.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [nicole.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [nicole.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [nicole.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,128)];
    [nicole.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,128)];
    [nicole.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,128)];
    [nicole.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,128)];
    [nicole.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,128)];
    [nicole.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,128)];
    [nicole.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,128)];
    
    
    // Create the attributed string
    nicole.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your greatest achievement to date?\nBeing successful enough to have the means and ability to travel wherever I want. I'm also proud of myself for graduating summa cum laude."];
    
    // Create the attributes and add them to the string
    [nicole.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [nicole.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [nicole.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,42)];
    [nicole.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,42)];
    [nicole.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,42)];
    [nicole.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,42)];
    [nicole.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,42)];
    [nicole.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(42,138)];
    [nicole.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,138)];
    [nicole.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(42,138)];
    [nicole.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(42,138)];
    [nicole.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(42,138)];
    [nicole.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(42,138)];
    [nicole.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(42,138)];
    
    
    // Create the attributed string
    nicole.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be a fictional character, who would you be?\nJessica Rabbit because she is so unapologetically sexy with natural sex appeal. Would be fun to be someone so different! "];
    
    // Create the attributes and add them to the string
    [nicole.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [nicole.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [nicole.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [nicole.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [nicole.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [nicole.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [nicole.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [nicole.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,122)];
    [nicole.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,122)];
    [nicole.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,122)];
    [nicole.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,122)];
    [nicole.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,122)];
    [nicole.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,122)];
    [nicole.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,122)];
    
    
    // Create the attributed string
    nicole.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be any animal, what would you be?\nA wolf. They are magical and bad-ass creatures."];
    
    // Create the attributes and add them to the string
    [nicole.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [nicole.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [nicole.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [nicole.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,46)];
    [nicole.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,46)];
    [nicole.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,46)];
    [nicole.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [nicole.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(46,48)];
    [nicole.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,48)];
    [nicole.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(46,48)];
    [nicole.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(46,48)];
    [nicole.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(46,48)];
    [nicole.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(46,48)];
    [nicole.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,48)];
    
    
    // Create the attributed string
    nicole.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What does being married mean to you?\nA partnership, to have each other's back in everything, and to have a best friend you want to jump in the sack with."];
    
    // Create the attributes and add them to the string
    [nicole.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [nicole.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [nicole.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [nicole.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [nicole.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [nicole.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [nicole.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [nicole.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,117)];
    [nicole.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,117)];
    [nicole.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,117)];
    [nicole.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,117)];
    [nicole.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,117)];
    [nicole.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,117)];
    [nicole.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,117)];
    // nicole end
    
    // nikki begin
    
    BRBachelorette *nikki = [[BRBachelorette alloc] init];
    [_bachelors addObject:nikki];
    nikki.name = @"Nikki";
    nikki.age = 26;
    nikki.occupation = @"Former NFL Cheerleader";
    nikki.hometownCity = @"New York City";
    nikki.hometownState = @"New York";
    nikki.heightFeet = 5;
    nikki.heightInch = 8;
    nikki.heightInInches = 68;
    nikki.tattooCount = 0;
    nikki.cannotLiveWithout = @"Carrots, coffee, exercise, friends, family";
    nikki.biggestDateFear = @"Awkward silence";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", nikki.name]]) {
        nikki.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", nikki.name]]) {
        nikki.myTeam = YES;
    }

    
    // Create the attributed string
    nikki.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date is a gentleman with that old-school mentality/manners, is outgoing, fun, funny, witty, playful, engaging, charming."];
    
    // Create the attributes and add them to the string
    [nikki.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [nikki.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [nikki.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [nikki.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [nikki.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [nikki.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [nikki.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [nikki.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,115)];
    [nikki.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,115)];
    [nikki.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,115)];
    [nikki.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,115)];
    [nikki.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,115)];
    [nikki.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,115)];
    [nikki.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,115)];
    
    
    // Create the attributed string
    nikki.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date is late!"];
    
    // Create the attributes and add them to the string
    [nikki.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [nikki.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [nikki.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [nikki.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [nikki.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [nikki.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [nikki.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [nikki.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,8)];
    [nikki.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,8)];
    [nikki.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,8)];
    [nikki.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,8)];
    [nikki.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,8)];
    [nikki.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,8)];
    [nikki.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,8)];
    
    
    // Create the attributed string
    nikki.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's your greatest achievement to date?\nI have a few. First was working at Sally Hershberger, next was making the NY Jets Flight Crew, then it was signing with Wilhelmina Models."];
    
    // Create the attributes and add them to the string
    [nikki.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,41)];
    [nikki.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,41)];
    [nikki.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,41)];
    [nikki.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,41)];
    [nikki.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,41)];
    [nikki.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,41)];
    [nikki.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,41)];
    [nikki.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(41,139)];
    [nikki.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(41,139)];
    [nikki.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(41,139)];
    [nikki.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(41,139)];
    [nikki.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(41,139)];
    [nikki.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(41,139)];
    [nikki.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(41,139)];
    
    
    // Create the attributed string
    nikki.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could have lunch with three people, living or dead, who would it be?\nJoan Rivers, Will Farrell, and Cleopatra."];
    
    // Create the attributes and add them to the string
    [nikki.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,75)];
    [nikki.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,75)];
    [nikki.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,75)];
    [nikki.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,75)];
    [nikki.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,75)];
    [nikki.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,75)];
    [nikki.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,75)];
    [nikki.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(75,42)];
    [nikki.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(75,42)];
    [nikki.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(75,42)];
    [nikki.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(75,42)];
    [nikki.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(75,42)];
    [nikki.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(75,42)];
    [nikki.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(75,42)];
    
    
    // Create the attributed string
    nikki.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you prefer a man who wants to be pursued or a man who pursues you?\nI like someone who knows what he wants. A challenge is fun, but there's a certain attractiveness to a man who's after me but knows when to pull back to allow room for my pursuit. Balance. :)"];
    
    // Create the attributes and add them to the string
    [nikki.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,69)];
    [nikki.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,69)];
    [nikki.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,69)];
    [nikki.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,69)];
    [nikki.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,69)];
    [nikki.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,69)];
    [nikki.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,69)];
    [nikki.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(69,191)];
    [nikki.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(69,191)];
    [nikki.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(69,191)];
    [nikki.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(69,191)];
    [nikki.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(69,191)];
    [nikki.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(69,191)];
    [nikki.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(69,191)];
    
    
    // Create the attributed string
    nikki.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What does being married mean to you?\nLifetime, life partner, other half. You complement each other, go about life two developed successful people who do it together. Best friends."];
    
    // Create the attributes and add them to the string
    [nikki.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [nikki.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [nikki.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [nikki.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [nikki.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [nikki.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [nikki.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [nikki.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,143)];
    [nikki.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,143)];
    [nikki.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,143)];
    [nikki.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,143)];
    [nikki.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,143)];
    [nikki.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,143)];
    [nikki.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,143)];
    // nikki end
    
    // reegan begin
    
    BRBachelorette *reegan = [[BRBachelorette alloc] init];
    [_bachelors addObject:reegan];
    reegan.name = @"Reegan";
    reegan.age = 28;
    reegan.occupation = @"Donated Tissue Specialist";
    reegan.hometownCity = @"Manhattan Beach";
    reegan.hometownState = @"California";
    reegan.heightFeet = 5;
    reegan.heightInch = 6;
    reegan.heightInInches = 66;
    reegan.tattooCount = 0;
    reegan.cannotLiveWithout = @"Eye makeup remover, salted caramel ice cream, cherry chapstick, butter popcorn, mascara";
    reegan.biggestDateFear = @"Guys who name drop and lie to impress";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", reegan.name]]) {
        reegan.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", reegan.name]]) {
        reegan.myTeam = YES;
    }

    
    // Create the attributed string
    reegan.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date opens the car door and tells you that you look nice -- right away."];
    
    // Create the attributes and add them to the string
    [reegan.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [reegan.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [reegan.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [reegan.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [reegan.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [reegan.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [reegan.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [reegan.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,66)];
    [reegan.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,66)];
    [reegan.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,66)];
    [reegan.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,66)];
    [reegan.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,66)];
    [reegan.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,66)];
    [reegan.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,66)];
    
    
    // Create the attributed string
    reegan.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date gets too touchy-feely too soon."];
    
    // Create the attributes and add them to the string
    [reegan.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [reegan.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [reegan.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [reegan.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [reegan.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [reegan.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [reegan.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [reegan.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,31)];
    [reegan.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,31)];
    [reegan.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,31)];
    [reegan.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,31)];
    [reegan.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,31)];
    [reegan.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,31)];
    [reegan.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,31)];
    
    
    // Create the attributed string
    reegan.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be any animal, what would you be?\nAn eagle -- they mate for life, they fly and see the world above, they are strong and beautiful and represent the greatest country."];
    
    // Create the attributes and add them to the string
    [reegan.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [reegan.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [reegan.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,46)];
    [reegan.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,46)];
    [reegan.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,46)];
    [reegan.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,46)];
    [reegan.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,46)];
    [reegan.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(46,132)];
    [reegan.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,132)];
    [reegan.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(46,132)];
    [reegan.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(46,132)];
    [reegan.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(46,132)];
    [reegan.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(46,132)];
    [reegan.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(46,132)];
    
    
    // Create the attributed string
    reegan.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you won the lottery, what would you do with your winnings?\nI would take my closest friends on a big multi-country vacation. Save half and donate the other half to schools for kids with learning disabilities like dyslexia."];
    
    // Create the attributes and add them to the string
    [reegan.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [reegan.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [reegan.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,61)];
    [reegan.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,61)];
    [reegan.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,61)];
    [reegan.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,61)];
    [reegan.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,61)];
    [reegan.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(61,163)];
    [reegan.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,163)];
    [reegan.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(61,163)];
    [reegan.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(61,163)];
    [reegan.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(61,163)];
    [reegan.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(61,163)];
    [reegan.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(61,163)];
    
    
    // Create the attributed string
    reegan.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you prefer a man who wants to be pursued or a man who pursues you?\nI'm a little old fashioned...I know times are changing but I still believe pursuing is part of being a man. Manly men approach women -- it shows confidence."];
    
    // Create the attributes and add them to the string
    [reegan.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,69)];
    [reegan.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,69)];
    [reegan.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,69)];
    [reegan.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,69)];
    [reegan.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,69)];
    [reegan.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,69)];
    [reegan.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,69)];
    [reegan.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(69,157)];
    [reegan.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(69,157)];
    [reegan.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(69,157)];
    [reegan.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(69,157)];
    [reegan.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(69,157)];
    [reegan.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(69,157)];
    [reegan.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(69,157)];
    
    
    // Create the attributed string
    reegan.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you really wanted to impress a man, what would you do?\nI'd keep my mouth shut. :) Seriously, I think just being supportive and listening to what they have to say works best."];
    
    // Create the attributes and add them to the string
    [reegan.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [reegan.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [reegan.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,57)];
    [reegan.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,57)];
    [reegan.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,57)];
    [reegan.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,57)];
    [reegan.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,57)];
    [reegan.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(57,119)];
    [reegan.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,119)];
    [reegan.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(57,119)];
    [reegan.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(57,119)];
    [reegan.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(57,119)];
    [reegan.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(57,119)];
    [reegan.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(57,119)];
    // reegan end
    
    // samantha begin
    
    BRBachelorette *samantha = [[BRBachelorette alloc] init];
    [_bachelors addObject:samantha];
    samantha.name = @"Samantha";
    samantha.age = 27;
    samantha.occupation = @"Fashion Designer";
    samantha.hometownCity = @"Los Angeles";
    samantha.hometownState = @"California";
    samantha.heightFeet = 5;
    samantha.heightInch = 5;
    samantha.heightInInches = 65;
    samantha.tattooCount = 0;
    samantha.cannotLiveWithout = @"My family, Kallie (my 3.5 pound Teacup Maltese), friends, lip gloss, chocolate";
    samantha.biggestDateFear = @"Dating someone who is selfish and arrogant";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", samantha.name]]) {
        samantha.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", samantha.name]]) {
        samantha.myTeam = YES;
    }

    
    
    // Create the attributed string
    samantha.question1 = [[NSMutableAttributedString alloc]initWithString:
                @"I love it when my date acts like a gentleman."];
    
    // Create the attributes and add them to the string
    [samantha.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [samantha.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [samantha.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [samantha.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [samantha.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [samantha.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [samantha.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [samantha.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,22)];
    [samantha.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,22)];
    [samantha.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,22)];
    [samantha.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,22)];
    [samantha.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,22)];
    [samantha.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,22)];
    [samantha.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,22)];
    

    // Create the attributed string
    samantha.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date does nothing but talk about himself."];
    
    // Create the attributes and add them to the string
    [samantha.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [samantha.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [samantha.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [samantha.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [samantha.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [samantha.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [samantha.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [samantha.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,36)];
    [samantha.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,36)];
    [samantha.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,36)];
    [samantha.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,36)];
    [samantha.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,36)];
    [samantha.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,36)];
    [samantha.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,36)];
    
    
    // Create the attributed string
    samantha.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you consider yourself neat or messy?\nNeat to a fault -- drives me crazy if my house isn't neat."];
    
    // Create the attributes and add them to the string
    [samantha.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,39)];
    [samantha.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,39)];
    [samantha.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,39)];
    [samantha.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,39)];
    [samantha.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,39)];
    [samantha.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,39)];
    [samantha.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,39)];
    [samantha.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(39,59)];
    [samantha.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(39,59)];
    [samantha.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(39,59)];
    [samantha.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(39,59)];
    [samantha.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(39,59)];
    [samantha.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(39,59)];
    [samantha.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(39,59)];
    
    
    // Create the attributed string
    samantha.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Are you a little bit country or more of a city person?\nBoth! I grew up more in the country, but have lived in New York City and Los Angeles for the past 4.5 years. Eventually the country might be better as it may be a better environment to raise a family."];
    
    // Create the attributes and add them to the string
    [samantha.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,54)];
    [samantha.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,54)];
    [samantha.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,54)];
    [samantha.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,54)];
    [samantha.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,54)];
    [samantha.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,54)];
    [samantha.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,54)];
    [samantha.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(54,201)];
    [samantha.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(54,201)];
    [samantha.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(54,201)];
    [samantha.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(54,201)];
    [samantha.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(54,201)];
    [samantha.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(54,201)];
    [samantha.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(54,201)];
    
    
    // Create the attributed string
    samantha.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you consider yourself a romantic? If so why, or why not?\nYes because I enjoy romantic situations like candlelit dinners, sunsets, being cozy, holding hands, etc."];
    
    // Create the attributes and add them to the string
    [samantha.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,59)];
    [samantha.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,59)];
    [samantha.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,59)];
    [samantha.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,59)];
    [samantha.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,59)];
    [samantha.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,59)];
    [samantha.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,59)];
    [samantha.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(59,105)];
    [samantha.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(59,105)];
    [samantha.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(59,105)];
    [samantha.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(59,105)];
    [samantha.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(59,105)];
    [samantha.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(59,105)];
    [samantha.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(59,105)];
    
    
    // Create the attributed string
    samantha.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"How important is your family's approval to you when it concerns dating a certain someone, and why?\nMy family's approval means everything to me because they are the most important people in my life and they are smart about what's good for me and we value each other's opinions. I believe when you marry someone, you are also marrying their family."];
    
    // Create the attributes and add them to the string
    [samantha.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,98)];
    [samantha.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,98)];
    [samantha.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,98)];
    [samantha.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,98)];
    [samantha.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,98)];
    [samantha.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,98)];
    [samantha.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,98)];
    [samantha.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(98,248)];
    [samantha.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(98,248)];
    [samantha.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(98,248)];
    [samantha.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(98,248)];
    [samantha.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(98,248)];
    [samantha.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(98,248)];
    [samantha.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(98,248)];
    // samantha end
    
    // tandra begin
    
    BRBachelorette *tandra = [[BRBachelorette alloc] init];
    [_bachelors addObject:tandra];
    tandra.name = @"Tandra";
    tandra.age = 30;
    tandra.occupation = @"Executive Assistant";
    tandra.hometownCity = @"Sandy";
    tandra.hometownState = @"Utah";
    tandra.heightFeet = 5;
    tandra.heightInch = 11;
    tandra.heightInInches = 71;
    tandra.tattooCount = 0;
    tandra.cannotLiveWithout = @"Music, family, friends, animals, my contact lenses";
    tandra.biggestDateFear = @"I've never really thought about that before. Maybe peeing my pants from laughing so hard or something.";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", tandra.name]]) {
        tandra.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", tandra.name]]) {
        tandra.myTeam = YES;
    }

    
    // Create the attributed string
    tandra.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date can hold a conversation, is genuine and has taken the time to plan something."];
    
    // Create the attributes and add them to the string
    [tandra.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tandra.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tandra.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tandra.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [tandra.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [tandra.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [tandra.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tandra.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,77)];
    [tandra.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,77)];
    [tandra.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,77)];
    [tandra.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,77)];
    [tandra.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,77)];
    [tandra.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,77)];
    [tandra.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,77)];
    
    
    // Create the attributed string
    tandra.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date talks only about himself and is arrogant."];
    
    // Create the attributes and add them to the string
    [tandra.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tandra.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tandra.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tandra.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [tandra.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [tandra.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [tandra.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tandra.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,41)];
    [tandra.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,41)];
    [tandra.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,41)];
    [tandra.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,41)];
    [tandra.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,41)];
    [tandra.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,41)];
    [tandra.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,41)];
    
    
    // Create the attributed string
    tandra.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Describe the worst first date you've ever been on.\nNo joke, a guy took me to a wedding reception as a first date once. It was so awkward."];
    
    // Create the attributes and add them to the string
    [tandra.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,50)];
    [tandra.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,50)];
    [tandra.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,50)];
    [tandra.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,50)];
    [tandra.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,50)];
    [tandra.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,50)];
    [tandra.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,50)];
    [tandra.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(50,87)];
    [tandra.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(50,87)];
    [tandra.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(50,87)];
    [tandra.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(50,87)];
    [tandra.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(50,87)];
    [tandra.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(50,87)];
    [tandra.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(50,87)];
    
    
    // Create the attributed string
    tandra.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What kinds of music do you listen to most often?\nAll kinds. I love blues, rock, pop, oldies, country and jazz! I even listen to some French rock. The song just has to build. I love moments in music -- it needs to have a climax!"];
    
    // Create the attributes and add them to the string
    [tandra.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,48)];
    [tandra.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,48)];
    [tandra.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,48)];
    [tandra.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,48)];
    [tandra.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,48)];
    [tandra.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,48)];
    [tandra.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,48)];
    [tandra.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(48,179)];
    [tandra.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(48,179)];
    [tandra.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(48,179)];
    [tandra.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(48,179)];
    [tandra.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(48,179)];
    [tandra.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(48,179)];
    [tandra.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(48,179)];
    
    
    // Create the attributed string
    tandra.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What does being married mean to you?\nIt's sacred. You are promising your life and heart to another. It's choosing every day to love one person, commit to them and build a life together."];
    
    // Create the attributes and add them to the string
    [tandra.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [tandra.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [tandra.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [tandra.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [tandra.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [tandra.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [tandra.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [tandra.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,149)];
    [tandra.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,149)];
    [tandra.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,149)];
    [tandra.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,149)];
    [tandra.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,149)];
    [tandra.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,149)];
    [tandra.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,149)];
    
    
    // Create the attributed string
    tandra.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your ideal mate's personality like?\nHe is honest and genuine. He makes me laugh and cares about others. He likes animals."];
    
    // Create the attributes and add them to the string
    [tandra.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,43)];
    [tandra.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,43)];
    [tandra.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,43)];
    [tandra.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,43)];
    [tandra.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,43)];
    [tandra.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,43)];
    [tandra.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,43)];
    [tandra.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(43,86)];
    [tandra.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(43,86)];
    [tandra.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(43,86)];
    [tandra.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(43,86)];
    [tandra.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(43,86)];
    [tandra.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(43,86)];
    [tandra.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(43,86)];
    // tandra end
    
    // tara begin
    
    BRBachelorette *tara = [[BRBachelorette alloc] init];
    [_bachelors addObject:tara];
    tara.name = @"Tara";
    tara.age = 26;
    tara.occupation = @"Sport Fishing Enthusiast";
    tara.hometownCity = @"Ft. Lauterdale";
    tara.hometownState = @"Florida";
    tara.heightFeet = 5;
    tara.heightInch = 10;
    tara.heightInInches = 70;
    tara.tattooCount = 0;
    tara.cannotLiveWithout = @"Chocolate, nail file, whiskey, Beave (my stuffed animal beaver I've had since birth), the ocean";
    tara.biggestDateFear = @"A man who nervous talks or won't shut up. Or me having bad gas during the date and he catches on to me.";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", tara.name]]) {
        tara.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", tara.name]]) {
        tara.myTeam = YES;
    }
    
    
    // Create the attributed string
    tara.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date opens the truck door for me, is kind to everyone around (servers), shows others that he's with me and wants to show me off to the world, and makes me laugh until I can't breathe."];
    
    // Create the attributes and add them to the string
    [tara.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tara.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tara.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tara.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [tara.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [tara.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [tara.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tara.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,178)];
    [tara.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,178)];
    [tara.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,178)];
    [tara.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,178)];
    [tara.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,178)];
    [tara.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,178)];
    [tara.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,178)];
    
    
    // Create the attributed string
    tara.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date talks too much (nervous talk) or has no personality, chews with his mouth open, is rude to people, or makes me pay for anything."];
    
    // Create the attributes and add them to the string
    [tara.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tara.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tara.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tara.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [tara.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [tara.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [tara.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tara.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,128)];
    [tara.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,128)];
    [tara.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,128)];
    [tara.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,128)];
    [tara.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,128)];
    [tara.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,128)];
    [tara.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,128)];
    
    
    // Create the attributed string
    tara.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is the most outrageous thing you have ever done?\nI went to a different country using my identical twins' I.D. and passport. Obviously it worked just fine."];
    
    // Create the attributes and add them to the string
    [tara.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,53)];
    [tara.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,53)];
    [tara.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,53)];
    [tara.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,53)];
    [tara.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,53)];
    [tara.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,53)];
    [tara.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,53)];
    [tara.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(53,106)];
    [tara.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(53,106)];
    [tara.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(53,106)];
    [tara.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(53,106)];
    [tara.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(53,106)];
    [tara.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(53,106)];
    [tara.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(53,106)];
    
    
    // Create the attributed string
    tara.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you consider yourself a romantic? If so why, or why not?\nNot too romantic. Because I have not been in a relationship for so long, or dated anyone, I have no one to be romantic towards."];
    
    // Create the attributes and add them to the string
    [tara.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,59)];
    [tara.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,59)];
    [tara.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,59)];
    [tara.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,59)];
    [tara.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,59)];
    [tara.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,59)];
    [tara.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,59)];
    [tara.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(59,128)];
    [tara.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(59,128)];
    [tara.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(59,128)];
    [tara.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(59,128)];
    [tara.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(59,128)];
    [tara.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(59,128)];
    [tara.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(59,128)];
    
    
    // Create the attributed string
    tara.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you prefer a man who wants to be pursued or a man who pusues you and why?\nBoth. Both of us females and males like the feeling of being pursued. So let's make it interesting and both sexes give it a try."];
    
    // Create the attributes and add them to the string
    [tara.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,76)];
    [tara.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,76)];
    [tara.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,76)];
    [tara.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,76)];
    [tara.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,76)];
    [tara.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,76)];
    [tara.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,76)];
    [tara.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(76,129)];
    [tara.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(76,129)];
    [tara.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(76,129)];
    [tara.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(76,129)];
    [tara.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(76,129)];
    [tara.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(76,129)];
    [tara.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(76,129)];
    
    
    // Create the attributed string
    tara.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What does being married mean to you?\nIt means legal documentation that you are forever committed and loyal to your best friend."];
    
    // Create the attributes and add them to the string
    [tara.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [tara.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [tara.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [tara.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [tara.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [tara.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [tara.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [tara.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,91)];
    [tara.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,91)];
    [tara.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,91)];
    [tara.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,91)];
    [tara.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,91)];
    [tara.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,91)];
    [tara.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,91)];
    // tara end
    
    // tracy begin
    
    BRBachelorette *tracy = [[BRBachelorette alloc] init];
    [_bachelors addObject:tracy];
    tracy.name = @"Tracy";
    tracy.age = 29;
    tracy.occupation = @"Fourth Grade Teacher";
    tracy.hometownCity = @"Wellington";
    tracy.hometownState = @"Florida";
    tracy.heightFeet = 5;
    tracy.heightInch = 4;
    tracy.heightInInches = 64;
    tracy.tattooCount = 1;
    tracy.cannotLiveWithout = @"Chocolate, mascara, face wash, gum, phone";
    tracy.biggestDateFear = @"Having food in my teeth!";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", tracy.name]]) {
        tracy.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", tracy.name]]) {
        tracy.myTeam = YES;
    }

    
    // Create the attributed string
    tracy.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date makes eye contact, asks questions, adds to conversation and makes me laugh."];
    
    // Create the attributes and add them to the string
    [tracy.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tracy.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tracy.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tracy.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [tracy.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [tracy.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [tracy.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tracy.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,75)];
    [tracy.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,75)];
    [tracy.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,75)];
    [tracy.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,75)];
    [tracy.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,75)];
    [tracy.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,75)];
    [tracy.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,75)];
    
    
    // Create the attributed string
    tracy.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date talks about himself the whole time or just asks questions like an interview and gives nothing back."];
    
    // Create the attributes and add them to the string
    [tracy.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tracy.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tracy.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [tracy.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [tracy.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [tracy.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [tracy.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [tracy.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,99)];
    [tracy.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,99)];
    [tracy.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,99)];
    [tracy.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,99)];
    [tracy.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,99)];
    [tracy.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,99)];
    [tracy.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,99)];
    
    
    // Create the attributed string
    tracy.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What is your ideal mate's personality like?\nFunny, confident, smart, motivated, thoughtful and caring."];
    
    // Create the attributes and add them to the string
    [tracy.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,43)];
    [tracy.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,43)];
    [tracy.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,43)];
    [tracy.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,43)];
    [tracy.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,43)];
    [tracy.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,43)];
    [tracy.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,43)];
    [tracy.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(43,59)];
    [tracy.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(43,59)];
    [tracy.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(43,59)];
    [tracy.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(43,59)];
    [tracy.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(43,59)];
    [tracy.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(43,59)];
    [tracy.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(43,59)];
    
    
    // Create the attributed string
    tracy.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you consider yourself a romantic? If so why, or why not?\nI'd like to be a romantic but I haven't found a guy who'd be into that! I think I am one at heart though."];
    
    // Create the attributes and add them to the string
    [tracy.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,59)];
    [tracy.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,59)];
    [tracy.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,59)];
    [tracy.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,59)];
    [tracy.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,59)];
    [tracy.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,59)];
    [tracy.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,59)];
    [tracy.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(59,106)];
    [tracy.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(59,106)];
    [tracy.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(59,106)];
    [tracy.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(59,106)];
    [tracy.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(59,106)];
    [tracy.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(59,106)];
    [tracy.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(59,106)];
    
    
    // Create the attributed string
    tracy.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's your worst date memory?\nAt lunch I just threw my hair up real quick because it was hot or something and he said \"keep your hair down.\" It was weird."];
    
    // Create the attributes and add them to the string
    [tracy.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,30)];
    [tracy.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,30)];
    [tracy.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,30)];
    [tracy.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,30)];
    [tracy.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,30)];
    [tracy.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,30)];
    [tracy.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,30)];
    [tracy.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(30,125)];
    [tracy.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(30,125)];
    [tracy.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(30,125)];
    [tracy.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(30,125)];
    [tracy.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(30,125)];
    [tracy.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(30,125)];
    [tracy.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(30,125)];
    
    
    // Create the attributed string
    tracy.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What does being married mean to you?\nHaving a sidekick and a teammate. Someone who's there for you and loves you no matter what."];
    
    // Create the attributes and add them to the string
    [tracy.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [tracy.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [tracy.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [tracy.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [tracy.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [tracy.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [tracy.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [tracy.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,92)];
    [tracy.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,92)];
    [tracy.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,92)];
    [tracy.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,92)];
    [tracy.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,92)];
    [tracy.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,92)];
    [tracy.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,92)];
    // tracy end
    
    // trina begin
    
    BRBachelorette *trina = [[BRBachelorette alloc] init];
    [_bachelors addObject:trina];
    trina.name = @"Trina";
    trina.age = 33;
    trina.occupation = @"Special Education Teacher";
    trina.hometownCity = @"San Clemente";
    trina.hometownState = @"California";
    trina.heightFeet = 5;
    trina.heightInch = 5;
    trina.heightInInches = 65;
    trina.tattooCount = 1;
    trina.cannotLiveWithout = @"My dog, pizza, my girlfriends, my mom, random adventures";
    trina.biggestDateFear = @"Eating something that gives me \"di-di\"";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", trina.name]]) {
        trina.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", trina.name]]) {
        trina.myTeam = YES;
    }

    
    // Create the attributed string
    trina.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date makes an effort to get to know me and asks me questions."];
    
    // Create the attributes and add them to the string
    [trina.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [trina.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [trina.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [trina.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [trina.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [trina.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [trina.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [trina.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,56)];
    [trina.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,56)];
    [trina.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,56)];
    [trina.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,56)];
    [trina.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,56)];
    [trina.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,56)];
    [trina.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,56)];
    
    
    // Create the attributed string
    trina.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date doesn't ask me questions."];
    
    // Create the attributes and add them to the string
    [trina.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [trina.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [trina.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [trina.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [trina.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [trina.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [trina.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [trina.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,25)];
    [trina.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,25)];
    [trina.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,25)];
    [trina.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,25)];
    [trina.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,25)];
    [trina.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,25)];
    [trina.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,25)];
    
    
    // Create the attributed string
    trina.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What's your greatest achievement to date?\nI'm most proud of going to graduate school -- twice! Both times, I earned a 4.0 GPA."];
    
    // Create the attributes and add them to the string
    [trina.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,41)];
    [trina.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,41)];
    [trina.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,41)];
    [trina.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,41)];
    [trina.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,41)];
    [trina.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,41)];
    [trina.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,41)];
    [trina.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(41,85)];
    [trina.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(41,85)];
    [trina.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(41,85)];
    [trina.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(41,85)];
    [trina.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(41,85)];
    [trina.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(41,85)];
    [trina.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(41,85)];
    
    
    // Create the attributed string
    trina.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be any fruit or vegetable, which one would you be?\nI would be a coconut. I love how they grow in such beautiful, exotic yet uninhabited places. No one would ever eat me! I would smell and taste delicious too! And I'd have lots of health benefits to offer."];
    
    // Create the attributes and add them to the string
    [trina.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,63)];
    [trina.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,63)];
    [trina.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,63)];
    [trina.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,63)];
    [trina.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,63)];
    [trina.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,63)];
    [trina.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,63)];
    [trina.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(63,205)];
    [trina.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(63,205)];
    [trina.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(63,205)];
    [trina.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(63,205)];
    [trina.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(63,205)];
    [trina.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(63,205)];
    [trina.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(63,205)];
    
    
    // Create the attributed string
    trina.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What does being married mean to you?\nYou are officially signifying that you are a team. You now have a lifetime partner through this journey called life -- the good parts, bad parts, and everything in between."];
    
    // Create the attributes and add them to the string
    [trina.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [trina.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [trina.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,36)];
    [trina.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,36)];
    [trina.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,36)];
    [trina.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,36)];
    [trina.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,36)];
    [trina.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(36,173)];
    [trina.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,173)];
    [trina.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(36,173)];
    [trina.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(36,173)];
    [trina.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(36,173)];
    [trina.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(36,173)];
    [trina.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(36,173)];
    
    
    // Create the attributed string
    trina.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"If you could be someone else for just one day, who would you be?\nI would love to be a guy for one day. No one in particular, just a guy. I'd love to know how they think!"];
    
    // Create the attributes and add them to the string
    [trina.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,64)];
    [trina.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,64)];
    [trina.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,64)];
    [trina.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,64)];
    [trina.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,64)];
    [trina.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,64)];
    [trina.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,64)];
    [trina.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(64,105)];
    [trina.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(64,105)];
    [trina.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(64,105)];
    [trina.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(64,105)];
    [trina.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(64,105)];
    [trina.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(64,105)];
    [trina.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(64,105)];
    // trina end
    
    // whitney begin
    
    BRBachelorette *whitney = [[BRBachelorette alloc] init];
    [_bachelors addObject:whitney];
    whitney.name = @"Whitney";
    whitney.age = 29;
    whitney.occupation = @"Fertility Nurse";
    whitney.hometownCity = @"Chicago";
    whitney.hometownState = @"Illinois";
    whitney.heightFeet = 5;
    whitney.heightInch = 7;
    whitney.heightInInches = 67;
    whitney.tattooCount = 1;
    whitney.cannotLiveWithout = @"My planner (totally old school), money, my job (have to pay the bills), razor (can't stand hair), friends and family";
    whitney.biggestDateFear = @"Falling or spilling my drink.";
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@noRose", whitney.name]]) {
        whitney.noRose = YES;
    }
    if ([defaults objectForKey:[NSString stringWithFormat:@"%@myTeam", whitney.name]]) {
        whitney.myTeam = YES;
    }

    
    // Create the attributed string
    whitney.question1 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I love it when my date makes me laugh and is a gentleman and opens the door."];
    
    // Create the attributes and add them to the string
    [whitney.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [whitney.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [whitney.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [whitney.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [whitney.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [whitney.question1 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [whitney.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [whitney.question1 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,53)];
    [whitney.question1 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,53)];
    [whitney.question1 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,53)];
    [whitney.question1 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,53)];
    [whitney.question1 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,53)];
    [whitney.question1 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,53)];
    [whitney.question1 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,53)];
    
    
    // Create the attributed string
    whitney.question2 = [[NSMutableAttributedString alloc]initWithString:
                                           @"I hate it when my date checks his cell phone during a date."];
    
    // Create the attributes and add them to the string
    [whitney.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [whitney.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [whitney.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,23)];
    [whitney.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,23)];
    [whitney.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,23)];
    [whitney.question2 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,23)];
    [whitney.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,23)];
    [whitney.question2 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(23,36)];
    [whitney.question2 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,36)];
    [whitney.question2 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(23,36)];
    [whitney.question2 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(23,36)];
    [whitney.question2 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(23,36)];
    [whitney.question2 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(23,36)];
    [whitney.question2 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(23,36)];
    
    
    // Create the attributed string
    whitney.question3 = [[NSMutableAttributedString alloc]initWithString:
                                           @"What are you most afraid of?\nBeing alone. Never finding love or getting to have a family."];
    
    // Create the attributes and add them to the string
    [whitney.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,28)];
    [whitney.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,28)];
    [whitney.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,28)];
    [whitney.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,28)];
    [whitney.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,28)];
    [whitney.question3 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,28)];
    [whitney.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,28)];
    [whitney.question3 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(28,61)];
    [whitney.question3 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(28,61)];
    [whitney.question3 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(28,61)];
    [whitney.question3 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(28,61)];
    [whitney.question3 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(28,61)];
    [whitney.question3 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(28,61)];
    [whitney.question3 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(28,61)];
    
    
    // Create the attributed string
    whitney.question4 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Would you consider yourself adventurous or conservative?\nMore conservative, but I will try anything once."];
    
    // Create the attributes and add them to the string
    [whitney.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [whitney.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [whitney.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,56)];
    [whitney.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,56)];
    [whitney.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,56)];
    [whitney.question4 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,56)];
    [whitney.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,56)];
    [whitney.question4 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(56,49)];
    [whitney.question4 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,49)];
    [whitney.question4 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(56,49)];
    [whitney.question4 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(56,49)];
    [whitney.question4 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(56,49)];
    [whitney.question4 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(56,49)];
    [whitney.question4 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(56,49)];
    
    
    // Create the attributed string
    whitney.question5 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you consider yourself a romantic? If so why, or why not?\nYes! I'm a complete hopeless romantic."];
    
    // Create the attributes and add them to the string
    [whitney.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,59)];
    [whitney.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,59)];
    [whitney.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,59)];
    [whitney.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,59)];
    [whitney.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,59)];
    [whitney.question5 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,59)];
    [whitney.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,59)];
    [whitney.question5 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(59,39)];
    [whitney.question5 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(59,39)];
    [whitney.question5 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(59,39)];
    [whitney.question5 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(59,39)];
    [whitney.question5 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(59,39)];
    [whitney.question5 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(59,39)];
    [whitney.question5 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(59,39)];
    
    
    // Create the attributed string
    whitney.question6 = [[NSMutableAttributedString alloc]initWithString:
                                           @"Do you prefer a man who wants to be pursued or a man who pursues you and why?\nA man who wants to be pursued. To me that means he is a little on the shy side and enjoys an outgoing girl like myself."];
    
    // Create the attributes and add them to the string
    [whitney.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(0,77)];
    [whitney.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,77)];
    [whitney.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(0,77)];
    [whitney.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(0,77)];
    [whitney.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(0,77)];
    [whitney.question6 addAttribute:NSFontAttributeName value:myStringFont1 range:NSMakeRange(0,77)];
    [whitney.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(0,77)];
    [whitney.question6 addAttribute:NSForegroundColorAttributeName value:myStringColor1 range:NSMakeRange(77,120)];
    [whitney.question6 addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(77,120)];
    [whitney.question6 addAttribute:NSStrokeColorAttributeName value:myStringColor1 range:NSMakeRange(77,120)];
    [whitney.question6 addAttribute:NSParagraphStyleAttributeName value:myStringParaStyle1 range:NSMakeRange(77,120)];
    [whitney.question6 addAttribute:NSBackgroundColorAttributeName value:myStringColor2 range:NSMakeRange(77,120)];
    [whitney.question6 addAttribute:NSFontAttributeName value:myStringFont2 range:NSMakeRange(77,120)];
    [whitney.question6 addAttribute:NSKernAttributeName value:[NSNumber numberWithInteger:0] range:NSMakeRange(77,120)];
    // whitney end
    
    
    [defaults synchronize];
}

@end
