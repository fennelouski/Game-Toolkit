//
//  GTScoreCardViewController.m
//  Game Timer
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import "GTScoreCardViewController.h"
#import "GTPlayer.h"
#import "UIColor+AppColors.h"
#import "GTPlayerManager.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kStatusBarHeight (([[UIApplication sharedApplication] statusBarFrame].size.height == 20.0f) ? 20.0f : (([[UIApplication sharedApplication] statusBarFrame].size.height == 40.0f) ? 20.0f : 0.0f))
#define kScreenHeight (([[UIApplication sharedApplication] statusBarFrame].size.height > 20.0f) ? [UIScreen mainScreen].bounds.size.height - 20.0f : [UIScreen mainScreen].bounds.size.height)
#define ANIMATION_DURATION 0.05f
#define CELL_HEIGHT 44.0f
#define HEADER_HEIGHT CELL_HEIGHT + kStatusBarHeight
#define CELL_BUFFER 20.0f
#define STARTING_CELL_WIDTH 80.0f
#define FOOTER_HEIGHT 49.0f

@implementation GTScoreCardViewController

- (void)viewDidLoad {
//    [self.view setBackgroundColor:[UIColor white]];
//    [self.view addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Green Background"]]];
    
    self.keyboardIsShowing = NO;
    
    self.allowForPiDay = YES;
    
    UIToolbar *headerBackground = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f,
                                                                              0.0f,
                                                                              kScreenWidth + kScreenHeight,
                                                                              kStatusBarHeight + kScreenHeight + kScreenWidth)];
    [self.view addSubview:headerBackground];
    [self.view addSubview:self.tableScrollView];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self  selector:@selector(updateViews)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    [nc addObserver:self selector:@selector(updateViews) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    self.textFields = [[NSMutableArray alloc] initWithCapacity:1000];
    for (int i = 0; i < 1000; i++) {
        UITextField *scoreTextField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.cellWidth - CELL_BUFFER, CELL_HEIGHT)];
        [scoreTextField setPlaceholder:@"####"];
        [scoreTextField setTextColor:[UIColor darkTextColor]];
        [scoreTextField setKeyboardType:UIKeyboardTypePhonePad];
        [scoreTextField setDelegate:self];
        [scoreTextField setTextAlignment:NSTextAlignmentRight];
        [scoreTextField setTag:i];
        [scoreTextField setInputAccessoryView:self.accessoryView];
        [self.textFields addObject:scoreTextField];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.headerSubviews) {
        for (UIView *subview in self.headerSubviews) {
            [subview removeFromSuperview];
        }
    }
    self.headerSubviews = [[NSMutableArray alloc] init];
    self.playerTables = [[NSMutableArray alloc] init];
    
    float tableXPosition = 0.0f;
    self.cellWidth = STARTING_CELL_WIDTH;
    while ([[[GTPlayerManager sharedReferenceManager] players] count] * self.cellWidth < kScreenWidth) {
        self.cellWidth++;
    }
    for (int i = 0 ; i < [[[GTPlayerManager sharedReferenceManager] players] count]; i++) {
        UITableView *playerTable = [[UITableView alloc] initWithFrame:CGRectMake(tableXPosition, self.headerToolbar.frame.size.height, self.cellWidth, kScreenHeight)];
        [playerTable setBackgroundColor:[UIColor clearColor]];
        [playerTable setDelegate:self];
        [playerTable setDataSource:self];
        [playerTable setTag:i];
        [playerTable setBounces:YES];
        [self.playerTables addObject:playerTable];
        if (i + 1 < [[[GTPlayerManager sharedReferenceManager] players] count]) [playerTable setShowsVerticalScrollIndicator:NO];
        
        
        GTPlayer *player = [[[GTPlayerManager sharedReferenceManager] players] objectAtIndex:i];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(tableXPosition, kStatusBarHeight, self.cellWidth, CELL_HEIGHT)];
        [nameLabel setTextAlignment:NSTextAlignmentCenter];
        [nameLabel setTextColor:[UIColor randomDarkColorFromString:player.name]];
        [nameLabel setText:player.name];
        
        NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *dateComps = [gregorianCal components: (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour)
                                                      fromDate: [NSDate date]];
        
        if ([dateComps month] == 3 && [dateComps day] == 14 && self.allowForPiDay) {
            [nameLabel setText:[nameLabel.text piIfy]];
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePiDayAlert)];
            [tap setNumberOfTapsRequired:1];
            [nameLabel addGestureRecognizer:tap];
        }
        
        [self.headerSubviews addObject:nameLabel];
        
        tableXPosition += self.cellWidth;
    }
    
    [self layoutTables];
    
    [self.tableScrollView setContentSize:CGSizeMake(tableXPosition, kScreenHeight)];
    
    [self updateViews];
}

- (void)layoutTables {
    for (UITableView *tableView in self.playerTables) {
        [self.tableScrollView addSubview:tableView];
    }

    [self.tableScrollView addSubview:self.headerToolbar];
}

- (void)updateViews {
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.tableScrollView setFrame:CGRectMake(0.0,
                                                  0.0f,
                                                  kScreenWidth,
                                                  kScreenHeight)];
        float tableXPosition = 0.0f;
        self.cellWidth = STARTING_CELL_WIDTH;
        while ([[[GTPlayerManager sharedReferenceManager] players] count] * self.cellWidth < kScreenWidth) self.cellWidth++;
        [self.tableScrollView setContentSize:CGSizeMake([[[GTPlayerManager sharedReferenceManager] players] count] * self.cellWidth,
                                                        kScreenHeight)];
        for (UITableView *tableView in self.playerTables) {
            if (kScreenHeight > kScreenWidth) {
                [tableView setContentInset:UIEdgeInsetsMake(CELL_HEIGHT + kStatusBarHeight,
                                                            0.0f,
                                                            self.keyboardHeight,
                                                            0.0f)];
            }
            
            else {
                [tableView setContentInset:UIEdgeInsetsMake(CELL_HEIGHT + kStatusBarHeight,
                                                            0.0f,
                                                            FOOTER_HEIGHT,
                                                            0.0f)];
                [self.currentFirstResponder resignFirstResponder];
            }
            
            [tableView setFrame:CGRectMake(tableXPosition,
                                           0.0f,
                                           self.cellWidth,
                                           kScreenHeight)];
            if (!self.keyboardIsShowing) {
                [tableView reloadData];
            }
            
            tableXPosition += self.cellWidth;
        }
        
        for (int i = 0; i < self.headerSubviews.count; i++) {
            UILabel *headerLabel = [self.headerSubviews objectAtIndex:i];
            [headerLabel setFrame:CGRectMake(self.cellWidth * i,
                                             kStatusBarHeight,
                                             self.cellWidth,
                                             CELL_HEIGHT)];
            [self.headerToolbar addSubview:headerLabel];
        }
        
        [self.headerToolbar setFrame:CGRectMake(0.0f,
                                                0.0f,
                                                (self.tableScrollView.contentSize.width > kScreenWidth) ? self.tableScrollView.contentSize.width : kScreenWidth,
                                                HEADER_HEIGHT)];
        [self.saveButton setCenter:CGPointMake(kScreenWidth - self.saveButton.frame.size.width/2.0f,
                                               CELL_HEIGHT/2.0f)];
    }];
}

#pragma mark - Subviews

- (UIScrollView *)tableScrollView {
    if (!_tableScrollView) {
        _tableScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, kScreenHeight)];
        [_tableScrollView setShowsVerticalScrollIndicator:NO];
        [_tableScrollView setBounces:YES];
        [_tableScrollView setScrollsToTop:YES];
        [_tableScrollView setBackgroundColor:[UIColor clearColor]];
    }
    
    return _tableScrollView;
}

- (UIToolbar *)accessoryView {
    if (!_accessoryView) {
        _accessoryView = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, kScreenHeight, kScreenWidth, CELL_HEIGHT)];
        [_accessoryView addSubview:self.negativeButton];
        [_accessoryView addSubview:self.saveButton];
    }
    
    return _accessoryView;
}

- (UIButton *)negativeButton {
    if (!_negativeButton) {
        _negativeButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kScreenWidth/2.0f, CELL_HEIGHT)];
        [_negativeButton setTitle:@"Negative" forState:UIControlStateSelected];
        [_negativeButton setTitleColor:[UIColor red] forState:UIControlStateSelected];
        [_negativeButton setTitle:@"Positive" forState:UIControlStateNormal];
        [_negativeButton setTitleColor:[UIColor black] forState:UIControlStateNormal];
        [_negativeButton addTarget:self action:@selector(negativeButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _negativeButton;
}

- (UIButton *)saveButton {
    if (!_saveButton) {
        _saveButton = [[UIButton alloc] initWithFrame:CGRectMake(kScreenWidth/2.0f, 0.0f, kScreenWidth/2.0f, CELL_HEIGHT)];
        [_saveButton setTitle:@"End Round" forState:UIControlStateNormal];
        [_saveButton setTitleColor:[UIColor blue] forState:UIControlStateNormal];
        [_saveButton addTarget:self action:@selector(saveButtonTouched) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _saveButton;
}

- (UIToolbar *)headerToolbar {
    if (!_headerToolbar) {
        _headerToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, HEADER_HEIGHT)];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePiDayAlert)];
        [tap setNumberOfTapsRequired:1];
        [_headerToolbar addGestureRecognizer:tap];
    }
    
    return _headerToolbar;
}

#pragma mark - Button Actions

- (void)negativeButtonTouched {
    [self.negativeButton setSelected:!self.negativeButton.selected];
    if (self.negativeButton.selected) {
        [self.currentFirstResponder setTextColor:[UIColor red]];
    }
    else {
        [self.currentFirstResponder setTextColor:[UIColor darkTextColor]];
    }
}

- (void)saveButtonTouched {
    BOOL shouldCommit = NO;
    for (GTPlayer *player in [[GTPlayerManager sharedReferenceManager] players]) {
        if (abs(player.pendingScore) > 0) {
            shouldCommit = YES;
        }
    }
    
    if (!shouldCommit) {
        for (UITableView *tableView in self.playerTables) {
            [tableView performSelector:@selector(reloadData) withObject:tableView afterDelay:0.03f];
//            [tableView reloadData];
        }
        
        return;
    }
    
    [self.currentFirstResponder resignFirstResponder];
    
    for (GTPlayer *player in [[GTPlayerManager sharedReferenceManager] players]) {
        [player commitPendingScore];
    }
    
    int keepingTrack = 0;
    for (UITextField *textField in self.textFields) {
        [textField setText:@""];
        keepingTrack++;
    }
    
    for (UITableView *tableView in self.playerTables) {
        [tableView performSelector:@selector(reloadData) withObject:tableView afterDelay:0.03f];
    }
    
    [self.negativeButton setSelected:NO];
}

#pragma mark - Table View Delegate and Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    
    for (int i = 0; i < self.playerTables.count && i < [[[GTPlayerManager sharedReferenceManager] players] count]; i++) {
        if ([tableView isEqual:[self.playerTables objectAtIndex:i]]) {
            GTPlayer *player = [[[GTPlayerManager sharedReferenceManager] players] objectAtIndex:i];
            
            if ([[player scoreHistory] count] == 1) {
                numberOfRows = 1;
            }
            
            else {
                numberOfRows = [[player scoreHistory] count] + [[player scoreHistory] count] - 1;
            }
            
            if (numberOfRows < 1) {
                numberOfRows = 1;
            }
        }
    }
    
    return numberOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.cellWidth, CELL_HEIGHT)];
    
    for (int i = 0; i < self.playerTables.count && i < [[[GTPlayerManager sharedReferenceManager] players] count]; i++) {
        if ([tableView isEqual:[self.playerTables objectAtIndex:i]]) {
            GTPlayer *player = [[[GTPlayerManager sharedReferenceManager] players] objectAtIndex:i];
            UILabel *lineLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.cellWidth - CELL_BUFFER, CELL_HEIGHT)];
            [lineLabel setTextAlignment:NSTextAlignmentRight];
            [lineLabel setTextColor:[UIColor darkTextColor]];
            
            // first row
            if ([player.scoreHistory count] > 0 && [indexPath row] == 0) {
                [lineLabel setText:[NSString stringWithFormat:@"%d", [[[player scoreHistory] objectAtIndex:0] intValue]]];
                [lineLabel setTextColor:[UIColor darkGrayColor]];
                [cell addSubview:lineLabel];
            }
            
            // total row
            else if ([indexPath row] % 2 == 0) {
                
                int totalScore = 0;
                
                for (int currentScoreIndex = 0; currentScoreIndex < player.scoreHistory.count && currentScoreIndex <= [indexPath row]/2; currentScoreIndex++) {
                    totalScore += [[[player scoreHistory] objectAtIndex:currentScoreIndex] intValue];
                }
                
                [lineLabel setText:[NSString stringWithFormat:@"%d", totalScore]];
                if (totalScore > 0) [lineLabel setTextColor:[UIColor black]];
                [cell addSubview:lineLabel];
                [cell setBackgroundColor:[[UIColor red] makeBrightnessOf:0.95f]];
            }
            
            // scoring row
            else if ([indexPath row] % 2 == 1) {
                int scoreIndex = (int)(([indexPath row] + 1)/2);
                int score = 0;
                if (scoreIndex < [[player scoreHistory] count]) {
                    score = [[[player scoreHistory] objectAtIndex:scoreIndex] intValue];
                }
                
                else {
                    NSLog(@"scoreIndex: %d\t\t%ld", scoreIndex, (unsigned long)[[player scoreHistory] count]);
                }
                
                [lineLabel setText:[NSString stringWithFormat:@"%d", score]];
                [lineLabel setTextColor:[UIColor darkGrayColor]];
                [cell addSubview:lineLabel];
            }
            
        }
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.cellWidth, HEADER_HEIGHT)];
    
    for (int i = 0; i < self.playerTables.count && i < [[[GTPlayerManager sharedReferenceManager] players] count]; i++) {
        if ([tableView isEqual:[self.playerTables objectAtIndex:i]]) {
            GTPlayer *player = [[[GTPlayerManager sharedReferenceManager] players] objectAtIndex:i];
            
            UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, kStatusBarHeight, self.cellWidth, CELL_HEIGHT)];
            [nameLabel setTextAlignment:NSTextAlignmentCenter];
            [nameLabel setTextColor:[UIColor randomDarkColor]];
            [nameLabel setText:player.name];
            [headerView addSubview:nameLabel];
            
            NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
            NSDateComponents *dateComps = [gregorianCal components: (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour)
                                                          fromDate: [NSDate date]];

            if ([dateComps month] == 3 && [dateComps day] == 14 && self.allowForPiDay) {
                [nameLabel setText:[nameLabel.text piIfy]];
                
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePiDayAlert)];
                [tap setNumberOfTapsRequired:1];
                [headerView addGestureRecognizer:tap];
            }
        }
    }
    
    [headerView setBackgroundColor:[UIColor cream]];
    
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.cellWidth, CELL_HEIGHT)];
    GTPlayer *player;
    for (int i = 0; i < self.playerTables.count && i < [[[GTPlayerManager sharedReferenceManager] players] count]; i++) {
        if ([tableView isEqual:[self.playerTables objectAtIndex:i]]) {
            player = [[[GTPlayerManager sharedReferenceManager] players] objectAtIndex:i];
        }
    }
    
    UITextField *scoreTextField = [self.textFields objectAtIndex:tableView.tag];
    [scoreTextField setFrame:CGRectMake(0.0f, 0.0f, self.cellWidth - CELL_BUFFER, CELL_HEIGHT)];
    if (abs(player.pendingScore) > 0) [scoreTextField setText:[NSString stringWithFormat:@"%d", player.pendingScore]];

    [footerView addSubview:scoreTextField];
    [footerView setBackgroundColor:[UIColor colorWithRed:0.95f green:0.95f blue:0.95f alpha:1.0f]];
    
    return footerView;
}

#pragma mark - Scroll View Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    BOOL isTableView = NO;
    for (UITableView *tableView in self.playerTables) {
        if ([scrollView isEqual:tableView]) {
            isTableView = YES;
        }
    }
    
    if (isTableView) {
        for (UITableView *tableView in self.playerTables) {
            [tableView setContentOffset:scrollView.contentOffset];
        }
    }
}

#pragma mark - Keyboard Notifications

- (void)keyboardDidShow:(NSNotification *)notification {
    self.keyboardHeight = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    [self updateViews];
}

- (void)keyboardDidHide:(NSNotification *)notification {
    self.keyboardHeight = FOOTER_HEIGHT;
    
    [self updateViews];
}

#pragma mark - Text Field Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.currentFirstResponder = textField;
    [self performSelector:@selector(letsJustTryThis) withObject:self afterDelay:0.18f];
    [textField setDelegate:self];
    if (self.negativeButton.selected) {
        [textField setTextColor:[UIColor red]];
    }
    
    else {
        [textField setTextColor:[UIColor darkTextColor]];
    }
    
    for (UITableView *tableView in self.playerTables) {
        float tableContentHeight = tableView.contentSize.height;
        float tableHeight = tableView.frame.size.height - tableView.contentInset.top - tableView.contentInset.bottom;
        float offsetAmount = tableHeight - tableContentHeight;
        
        if (offsetAmount > 0.0f) {
            offsetAmount = 0.0f;
        }
        
//        [tableView setContentOffset:CGPointMake(0.0f, tableView.contentOffset.y - offsetAmount) animated:YES];
    }
    
    [self scrollToLastRow];
    
//    NSLog(@"%f", self.keyboardHeight);
}

- (void)scrollToLastRow {
    if (self.playerTables.count > 0) {
        UITableView *tableView = [self.playerTables firstObject];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self tableView:tableView numberOfRowsInSection:0] - 1 inSection:0];
        [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        if ([indexPath row] * CELL_HEIGHT > self.tableScrollView.contentSize.height) {
//            [tableView setContentOffset:CGPointMake(tableView.contentOffset.x, tableView.contentOffset.y - CELL_HEIGHT) animated:YES];
        }
    }
}

// when a text field begins editing, it's set as the currentFirstResponder so there's a strong reference to it
// I couldn't figure out why it wasn't allowing me to type, so I came up with the idea of re-setting it as the first responder a moment after it's already the first responder
// apparently, this works and does NOT create an inifinite loop
- (void)letsJustTryThis {
    [self.currentFirstResponder becomeFirstResponder];
}

- (void)checkForFirstResponder {
    [self.currentFirstResponder becomeFirstResponder];
    
    [self performSelector:@selector(flipFirstResponderLoopCheck) withObject:self afterDelay:0.2f];
}

- (void)flipFirstResponderLoopCheck {
    [self.currentFirstResponder becomeFirstResponder];
    self.firstResponderLoopCheck = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.tag < [[[GTPlayerManager sharedReferenceManager] players] count]) {
        GTPlayer *player = [[[GTPlayerManager sharedReferenceManager] players] objectAtIndex:textField.tag];
        [player setPendingScore:[textField.text intValue]];
        [player setIsPendingNegative:self.negativeButton.selected];
    }
    
    else {
        NSLog(@"Add %@ to Player %ld...which is not in [[GTPlayerManager sharedReferenceManager] players]", textField.text, (long)textField.tag);
    }
    
    [self.negativeButton setSelected:NO];
    [self scrollToLastRow];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *decimalCharacterSet = [NSCharacterSet decimalDigitCharacterSet];
    if (string.length < 1 || ([decimalCharacterSet characterIsMember:[string characterAtIndex:0]] && string.length == 1)) {
        [self performSelector:@selector(updatePending) withObject:self afterDelay:0.1f];
        return YES;
    }
    
    return NO;
}

- (void)updatePending {
    for (int i = 0; i < [[[GTPlayerManager sharedReferenceManager] players] count]; i++) {
        GTPlayer *player = [[[GTPlayerManager sharedReferenceManager] players] objectAtIndex:i];
        UITextField *scoreTextField = [self.textFields objectAtIndex:i];
        [player setPendingScore:[scoreTextField.text intValue]];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"Selected: %@", indexPath);
    
    return NO;
}

#pragma mark Motion Gesture Methods

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    if (motion == UIEventSubtypeMotionShake ) {
        NSMutableArray *players = [NSMutableArray arrayWithArray:[[GTPlayerManager sharedReferenceManager] players]];;
        NSMutableString *playerString = [[NSMutableString alloc] init];
        int currentPlayerCount = 1;
        while (players.count > 0) {
            GTPlayer *currentPlayer = [players objectAtIndex:arc4random()%players.count];
            [playerString appendFormat:@"%d. %@\n", currentPlayerCount, currentPlayer.name];
            [players removeObject:currentPlayer];
            currentPlayerCount++;
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Random order of players" message:[playerString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            
        }];
        [alertController addAction:okAction];
        
        UIAlertAction *newOrderAction = [UIAlertAction actionWithTitle:@"New Order" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [self motionBegan:motion withEvent:event];
        }];
        [alertController addAction:newOrderAction];
        
        [self presentViewController:alertController animated:YES completion:^{
            
        }];
    }
}

#pragma mark - Alert For Pi Day

- (void)handlePiDayAlert {
    UIAlertController *piDayAlertController = [UIAlertController alertControllerWithTitle:@"Happy π Day!" message:@"For π Day, all P's have been replaced with π! This is for one day only, and will change back tomorrow.\n\nWould you like to change it back now?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *revertAction = [UIAlertAction actionWithTitle:@"Change it back" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self setAllowForPiDay:NO];
        [self viewWillAppear:YES];
    }];
    UIAlertAction *coolAction = [UIAlertAction actionWithTitle:@"Keep it!" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setAllowForPiDay:YES];
        [self viewWillAppear:YES];
    }];
    [piDayAlertController addAction:revertAction];
    [piDayAlertController addAction:coolAction];
    
    [self presentViewController:piDayAlertController animated:YES completion:^{
        
    }];
}


@end
