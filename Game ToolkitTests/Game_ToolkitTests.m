//
//  Game_ToolkitTests.m
//  Game ToolkitTests
//
//  Created by Developer Nathan on 2/2/15.
//  Copyright (c) 2015 Nathan Fennel. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "GTPlayer.h"
#import "GTPlayerManager.h"

@interface Game_ToolkitTests : XCTestCase
@property (nonatomic, strong) GTPlayerManager *playerManager;
@end

@implementation Game_ToolkitTests

- (void)setUp {
    [super setUp];
    // Create a fresh player manager for each test
    self.playerManager = [[GTPlayerManager alloc] init];
}

- (void)tearDown {
    // Clean up after each test
    self.playerManager = nil;
    [super tearDown];
}

#pragma mark - GTPlayer Tests

- (void)testPlayerInitialization {
    // Test that a player can be initialized with a name
    GTPlayer *player = [[GTPlayer alloc] initWithName:@"Alice"];

    XCTAssertNotNil(player, @"Player should be initialized");
    XCTAssertEqualObjects(player.name, @"Alice", @"Player name should be set correctly");
    XCTAssertNotNil(player.moveTimes, @"Move times array should be initialized");
    XCTAssertNotNil(player.scoreHistory, @"Score history array should be initialized");
    XCTAssertEqual(player.currentScore, 0, @"Initial score should be 0");
    XCTAssertEqual(player.pendingScore, 0, @"Initial pending score should be 0");
}

- (void)testPlayerScoreCommit {
    // Test committing a pending score
    GTPlayer *player = [[GTPlayer alloc] initWithName:@"Bob"];

    player.pendingScore = 5;
    player.isPendingNegative = NO;
    [player commitPendingScore];

    XCTAssertEqual(player.currentScore, 5, @"Score should be updated after commit");
    XCTAssertEqual(player.pendingScore, 0, @"Pending score should be reset after commit");
    XCTAssertEqual(player.scoreHistory.count, 1, @"Score history should have one entry");
}

- (void)testPlayerNegativeScoreCommit {
    // Test committing a negative pending score
    GTPlayer *player = [[GTPlayer alloc] initWithName:@"Charlie"];

    player.currentScore = 10;
    player.pendingScore = 3;
    player.isPendingNegative = YES;
    [player commitPendingScore];

    XCTAssertEqual(player.currentScore, 7, @"Score should be decreased for negative pending score");
}

- (void)testPlayerTimeRemaining {
    // Test time remaining property
    GTPlayer *player = [[GTPlayer alloc] initWithName:@"Diana"];

    player.timeRemaining = 60.0;
    XCTAssertEqual(player.timeRemaining, 60.0, @"Time remaining should be set correctly");
}

#pragma mark - GTPlayerManager Tests

- (void)testPlayerManagerSharedInstance {
    // Test that shared instance is a singleton
    GTPlayerManager *manager1 = [GTPlayerManager sharedReferenceManager];
    GTPlayerManager *manager2 = [GTPlayerManager sharedReferenceManager];

    XCTAssertNotNil(manager1, @"Shared instance should not be nil");
    XCTAssertEqual(manager1, manager2, @"Shared instance should be singleton");
}

- (void)testAddPlayer {
    // Test adding a single player
    GTPlayer *player = [[GTPlayer alloc] initWithName:@"Eve"];
    [self.playerManager addPlayer:player];

    XCTAssertEqual([self.playerManager players].count, 1, @"Player count should be 1");
    XCTAssertEqual([self.playerManager playerAtIndex:0], player, @"Player should be retrievable by index");
}

- (void)testAddMultiplePlayers {
    // Test adding multiple players
    GTPlayer *player1 = [[GTPlayer alloc] initWithName:@"Frank"];
    GTPlayer *player2 = [[GTPlayer alloc] initWithName:@"Grace"];
    GTPlayer *player3 = [[GTPlayer alloc] initWithName:@"Henry"];

    NSArray *players = @[player1, player2, player3];
    [self.playerManager addPlayers:players];

    XCTAssertEqual([self.playerManager players].count, 3, @"Player count should be 3");
}

- (void)testAddPlayerAtIndex {
    // Test adding a player at a specific index
    GTPlayer *player1 = [[GTPlayer alloc] initWithName:@"Irene"];
    GTPlayer *player2 = [[GTPlayer alloc] initWithName:@"Jack"];
    GTPlayer *player3 = [[GTPlayer alloc] initWithName:@"Kelly"];

    [self.playerManager addPlayer:player1];
    [self.playerManager addPlayer:player3];
    [self.playerManager addPlayer:player2 atIndex:1];

    XCTAssertEqual([self.playerManager playerAtIndex:1], player2, @"Player should be inserted at correct index");
}

- (void)testRemovePlayer {
    // Test removing a player
    GTPlayer *player1 = [[GTPlayer alloc] initWithName:@"Leo"];
    GTPlayer *player2 = [[GTPlayer alloc] initWithName:@"Mia"];

    [self.playerManager addPlayer:player1];
    [self.playerManager addPlayer:player2];

    BOOL removed = [self.playerManager removePlayer:player1];

    XCTAssertTrue(removed, @"Player should be successfully removed");
    XCTAssertEqual([self.playerManager players].count, 1, @"Player count should be 1 after removal");
    XCTAssertEqual([self.playerManager playerAtIndex:0], player2, @"Remaining player should be player2");
}

- (void)testRemovePlayers {
    // Test removing multiple players
    GTPlayer *player1 = [[GTPlayer alloc] initWithName:@"Noah"];
    GTPlayer *player2 = [[GTPlayer alloc] initWithName:@"Olivia"];
    GTPlayer *player3 = [[GTPlayer alloc] initWithName:@"Peter"];

    [self.playerManager addPlayers:@[player1, player2, player3]];
    [self.playerManager removePlayers:@[player1, player3]];

    XCTAssertEqual([self.playerManager players].count, 1, @"Player count should be 1 after removing 2 players");
    XCTAssertEqual([self.playerManager playerAtIndex:0], player2, @"Remaining player should be player2");
}

- (void)testMakeCurrentPlayer {
    // Test setting the current player
    GTPlayer *player = [[GTPlayer alloc] initWithName:@"Quinn"];
    [self.playerManager addPlayer:player];

    [self.playerManager makeCurrentPlayer:player];

    XCTAssertEqual(self.playerManager.currentPlayer, player, @"Current player should be set correctly");
}

- (void)testResetScores {
    // Test resetting all player scores
    GTPlayer *player1 = [[GTPlayer alloc] initWithName:@"Rachel"];
    GTPlayer *player2 = [[GTPlayer alloc] initWithName:@"Sam"];

    player1.currentScore = 10;
    player2.currentScore = 20;

    [self.playerManager addPlayers:@[player1, player2]];
    [self.playerManager resetScores];

    XCTAssertEqual(player1.currentScore, 0, @"Player 1 score should be reset to 0");
    XCTAssertEqual(player2.currentScore, 0, @"Player 2 score should be reset to 0");
}

- (void)testDiceConfiguration {
    // Test dice configuration methods
    [self.playerManager setNumberOfDice:5];
    XCTAssertEqual([self.playerManager numberOfDice], 5, @"Number of dice should be 5");

    [self.playerManager setNumberOfDiceSides:12];
    XCTAssertEqual([self.playerManager numberOfDiceSides], 12, @"Number of dice sides should be 12");
}

- (void)testDiceColorConfiguration {
    // Test dice color configuration
    NSArray *colorNames = [self.playerManager diceColorNames];
    XCTAssertNotNil(colorNames, @"Dice color names should not be nil");
    XCTAssertTrue(colorNames.count > 0, @"Should have at least one dice color option");

    if (colorNames.count > 0) {
        NSString *firstColorName = colorNames[0];
        [self.playerManager setDiceColor:firstColorName];

        NSString *currentColorName = [self.playerManager diceColorName];
        XCTAssertEqualObjects(currentColorName, firstColorName, @"Dice color should be set correctly");
    }
}

#pragma mark - Performance Tests

- (void)testPlayerCreationPerformance {
    // Test the performance of creating multiple players
    [self measureBlock:^{
        for (int i = 0; i < 100; i++) {
            GTPlayer *player = [[GTPlayer alloc] initWithName:[NSString stringWithFormat:@"Player %d", i]];
            (void)player; // Suppress unused variable warning
        }
    }];
}

- (void)testPlayerManagerAddPerformance {
    // Test the performance of adding many players to the manager
    NSMutableArray *players = [NSMutableArray array];
    for (int i = 0; i < 100; i++) {
        [players addObject:[[GTPlayer alloc] initWithName:[NSString stringWithFormat:@"Player %d", i]]];
    }

    [self measureBlock:^{
        GTPlayerManager *testManager = [[GTPlayerManager alloc] init];
        [testManager addPlayers:players];
    }];
}

@end
