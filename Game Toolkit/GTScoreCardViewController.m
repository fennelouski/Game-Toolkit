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

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kStatusBarHeight (([[UIApplication sharedApplication] statusBarFrame].size.height == 20.0f) ? 20.0f : (([[UIApplication sharedApplication] statusBarFrame].size.height == 40.0f) ? 20.0f : 0.0f))
#define kScreenHeight (([[UIApplication sharedApplication] statusBarFrame].size.height > 20.0f) ? [UIScreen mainScreen].bounds.size.height - 20.0f : [UIScreen mainScreen].bounds.size.height)
#define CELL_HEIGHT 44.0f
#define HEADER_HEIGHT CELL_HEIGHT + kStatusBarHeight
#define CELL_BUFFER 20.0f
#define STARTING_CELL_WIDTH 80.0f

@implementation GTScoreCardViewController

- (void)viewDidLoad {
    self.headerSubviews = [[NSMutableArray alloc] init];
    [self.view setBackgroundColor:[UIColor white]];
    
    GTPlayer *player1 = [[GTPlayer alloc] init];
    player1.name = @"Nathan";
    
    GTPlayer *player2 = [[GTPlayer alloc] init];
    player2.name = @"Katie";
    
    GTPlayer *player3 = [[GTPlayer alloc] init];
    player3.name = @"Player 3";
    
    GTPlayer *player4 = [[GTPlayer alloc] init];
    player4.name = @"Player 4";
    
    self.players = [[NSMutableArray alloc] initWithArray:@[player1, player2, player3, player4]];
    
    for (int i = 0; i < 0; i++) {
        for (GTPlayer *player in self.players) {
            NSNumber *score = [NSNumber numberWithInt:arc4random()%15 - 2];
            if (arc4random()%4 != 10) {
                [[player scoreHistory] addObject:score];
            }
        }
    }
    
    self.playerTables = [[NSMutableArray alloc] init];
    
    float tableXPosition = 0.0f;
    self.cellWidth = STARTING_CELL_WIDTH;
    while (self.players.count * self.cellWidth < kScreenWidth) {
        self.cellWidth++;
    }
    for (int i = 0 ; i < self.players.count ; i++) {
        UITableView *playerTable = [[UITableView alloc] initWithFrame:CGRectMake(tableXPosition, 0.0f, self.cellWidth, kScreenHeight)];
        [playerTable setDelegate:self];
        [playerTable setDataSource:self];
        [playerTable setTag:i];
        [playerTable setBounces:YES];
        [self.playerTables addObject:playerTable];
        if (i + 1 < self.players.count) [playerTable setShowsVerticalScrollIndicator:NO];
        tableXPosition += self.cellWidth;
        
        GTPlayer *player = [self.players objectAtIndex:i];
        
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, kStatusBarHeight, self.cellWidth, CELL_HEIGHT)];
        [nameLabel setTextAlignment:NSTextAlignmentCenter];
        [nameLabel setTextColor:[UIColor randomDarkColor]];
        [nameLabel setText:player.name];
        
        [self.headerSubviews addObject:nameLabel];
    }
    
    [self layoutTables];
    
    [self.tableScrollView setContentSize:CGSizeMake(tableXPosition, kScreenHeight)];
    
    [self.view addSubview:self.tableScrollView];
    [self.view addSubview:self.headerToolbar];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self  selector:@selector(updateViews)    name:UIDeviceOrientationDidChangeNotification  object:nil];
    [nc addObserver:self selector:@selector(updateViews) name:UIApplicationWillChangeStatusBarFrameNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self updateViews];
}

- (void)layoutTables {
    for (UITableView *tableView in self.playerTables) {
        [self.tableScrollView addSubview:tableView];
    }
}

- (void)updateViews {
    [UIView animateWithDuration:0.35f animations:^{
        [self.tableScrollView setFrame:CGRectMake(0.0, 0.0f, kScreenWidth, kScreenHeight)];
        
        float tableXPosition = 0.0f;
        self.cellWidth = STARTING_CELL_WIDTH;
        while (self.players.count * self.cellWidth < kScreenWidth) self.cellWidth++;
        for (UITableView *tableView in self.playerTables) {
            [tableView setContentInset:UIEdgeInsetsMake(CELL_HEIGHT + kStatusBarHeight, 0.0f, self.keyboardHeight, 0.0f)];
            [tableView setFrame:CGRectMake(tableXPosition, 0.0f, self.cellWidth, kScreenHeight)];
            [tableView reloadData];
            tableXPosition += self.cellWidth;
        }
        
        for (int i = 0; i < self.headerSubviews.count; i++) {
            UILabel *headerLabel = [self.headerSubviews objectAtIndex:i];
            [headerLabel setFrame:CGRectMake(self.cellWidth * i, kStatusBarHeight, self.cellWidth, CELL_HEIGHT)];
            [self.headerToolbar addSubview:headerLabel];
        }
        
        [self.headerToolbar setFrame:CGRectMake(0.0f, 0.0f, kScreenWidth, HEADER_HEIGHT)];
        [self.saveButton setCenter:CGPointMake(kScreenWidth - self.saveButton.frame.size.width/2.0f, CELL_HEIGHT/2.0f)];
    }];
}

#pragma mark - Subviews

- (UIScrollView *)tableScrollView {
    if (!_tableScrollView) {
        _tableScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        [_tableScrollView setShowsVerticalScrollIndicator:NO];
        [_tableScrollView setBounces:NO];
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
    }
    
    return _headerToolbar;
}

#pragma mark - Button Actions

- (void)negativeButtonTouched {
    [self.negativeButton setSelected:!self.negativeButton.selected];
}

- (void)saveButtonTouched {
    [self.currentFirstResponder resignFirstResponder];
    
    BOOL shouldCommit = NO;
    for (GTPlayer *player in self.players) {
        if (player.pendingScore > 0) {
            shouldCommit = YES;
        }
    }
    
    if (!shouldCommit) {
        return;
    }
    
    for (GTPlayer *player in self.players) {
        [player commitPendingScore];
    }
    
    for (UITableView *tableView in self.playerTables) {
        [tableView reloadData];
    }
}

#pragma mark - Table View Delegate and Data Source Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    
    for (int i = 0; i < self.playerTables.count && i < self.players.count; i++) {
        if ([tableView isEqual:[self.playerTables objectAtIndex:i]]) {
            GTPlayer *player = [self.players objectAtIndex:i];
            
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
    
    for (int i = 0; i < self.playerTables.count && i < self.players.count; i++) {
        if ([tableView isEqual:[self.playerTables objectAtIndex:i]]) {
            GTPlayer *player = [self.players objectAtIndex:i];
            UILabel *lineLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.cellWidth - CELL_BUFFER, CELL_HEIGHT)];
            [lineLabel setTextAlignment:NSTextAlignmentRight];
            [lineLabel setTextColor:[UIColor darkTextColor]];
            
            if ([player.scoreHistory count] > 0 && [indexPath row] == 0) {
                [lineLabel setText:[NSString stringWithFormat:@"%d", [[[player scoreHistory] objectAtIndex:0] intValue]]];
                [cell addSubview:lineLabel];
            }
            
            // check if it's a total row
            else if ([indexPath row] % 2 == 0) {
                
                int totalScore = 0;
                
                for (int currentScoreIndex = 0; currentScoreIndex < player.scoreHistory.count && currentScoreIndex <= [indexPath row]/2; currentScoreIndex++) {
                    totalScore += [[[player scoreHistory] objectAtIndex:currentScoreIndex] intValue];
                }
                
                [lineLabel setText:[NSString stringWithFormat:@"%d", totalScore]];
                [cell addSubview:lineLabel];
                [cell setBackgroundColor:[[UIColor red] makeBrightnessOf:0.95f]];
            }
            
            else if ([indexPath row] % 2 == 1) {
                int scoreIndex = (int)(([indexPath row] + 1)/2);
                int score = 0;
                if (scoreIndex < [[player scoreHistory] count]) {
                    score = [[[player scoreHistory] objectAtIndex:scoreIndex] intValue];
                }
                
                else {
                    NSLog(@"scoreIndex: %d\t\t%ld", scoreIndex, [[player scoreHistory] count]);
                }
                
                [lineLabel setText:[NSString stringWithFormat:@"%d", score]];
                [cell addSubview:lineLabel];
            }
            
        }
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.cellWidth, HEADER_HEIGHT)];
    
    for (int i = 0; i < self.playerTables.count && i < self.players.count; i++) {
        if ([tableView isEqual:[self.playerTables objectAtIndex:i]]) {
            GTPlayer *player = [self.players objectAtIndex:i];
            
            UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, kStatusBarHeight, self.cellWidth, CELL_HEIGHT)];
            [nameLabel setTextAlignment:NSTextAlignmentCenter];
            [nameLabel setTextColor:[UIColor randomDarkColor]];
            [nameLabel setText:player.name];
            [headerView addSubview:nameLabel];
        }
    }
    
    [headerView setBackgroundColor:[UIColor cream]];
    
    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.cellWidth, CELL_HEIGHT)];
    GTPlayer *player;
    for (int i = 0; i < self.playerTables.count && i < self.players.count; i++) {
        if ([tableView isEqual:[self.playerTables objectAtIndex:i]]) {
            player = [self.players objectAtIndex:i];
        }
    }
    
    UITextField *scoreTextField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.cellWidth - CELL_BUFFER, CELL_HEIGHT)];
    [scoreTextField setPlaceholder:@"##"];
    [scoreTextField setTextColor:[UIColor darkTextColor]];
    [scoreTextField setKeyboardType:UIKeyboardTypePhonePad];
    [scoreTextField setDelegate:self];
    [scoreTextField setTextAlignment:NSTextAlignmentRight];
    [scoreTextField setTag:tableView.tag];
    [scoreTextField setInputAccessoryView:self.accessoryView];
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
    self.keyboardHeight = 0.0f;
    [self updateViews];
}

#pragma mark - Text Field Delegate Methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (kScreenWidth < kScreenHeight) {
        return YES;
    }
    
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.currentFirstResponder = textField;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField.tag < self.players.count) {
        GTPlayer *player = [self.players objectAtIndex:textField.tag];
        if (self.negativeButton.selected) {
            [player setPendingScore:[textField.text intValue] * -1];
        }
        
        else {
            [player setPendingScore:[textField.text intValue]];
        }
    }
    
    else {
        NSLog(@"Add %@ to Player %ld...which is not in self.players", textField.text, (long)textField.tag);
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *decimalCharacterSet = [NSCharacterSet decimalDigitCharacterSet];
    if (string.length < 1 || ([decimalCharacterSet characterIsMember:[string characterAtIndex:0]] && string.length == 1)) {
        return YES;
    }
    
    return NO;
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
//        for (GTPlayer *player in self.players) {
//            NSNumber *lastScore = [[player scoreHistory] lastObject];
//            if (abs([lastScore intValue]) > 0) {
//                [[player scoreHistory] removeObject:lastScore];
//            }
//            
//            [player setPendingScore:[lastScore intValue]];
//        }
//        
//        for (UITableView *tableView in self.playerTables) {
//            [tableView reloadData];
//        }
    }
}

@end
