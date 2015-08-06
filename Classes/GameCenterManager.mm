//
//  GameCenterManager.mm
//  Leukocyte
//
//  Created by Mitsushige Komiya on 2015/07/18.
//
//

#import "GameCenterManager.h"
#include "NetworkManagerDelegate.h"

#ifdef COCOS2D_DEBUG
#define NMLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
#define NMLog(...) do {} while (0)
#endif

#define BATTLE_PLAYER_NUM 2

@interface GameCenterManager ()

@property (nonatomic, strong) GKMatch* match;
@property (nonatomic, getter = isMatchStarted) BOOL matchStarted;

@end

@implementation GameCenterManager {
    NetworkManagerDelegate* _networkManagerDelegate;
    GameCenterManagerDelegate* _gameCenterDelegate;
}

- (void)setDelegates:(NetworkManagerDelegate*)delegate1 gameCenterDelegate:(GameCenterManagerDelegate*)delegate2
{
    _networkManagerDelegate = delegate1;
    _gameCenterDelegate     = delegate2;
}

- (void)loginGameCenter
{
    // for iOS6+
    if (floor(NSFoundationVersionNumber) >= NSFoundationVersionNumber_iOS_6_0) {
        GKLocalPlayer* player = [GKLocalPlayer localPlayer];
        UIViewController* rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
        player.authenticateHandler = ^(UIViewController *viewController, NSError* error)
        {
            if (viewController != nil) {
                NMLog(@"Need to login");
                [rootController presentViewController:viewController animated:YES completion:nil];
            }
            else if (player.isAuthenticated) {
                NMLog(@"Authenticated");
                [self loggedIn];
            }
            else {
                NMLog(@"Failed");
            }
        };
    }
    else {
        GKLocalPlayer* localPlayer = [GKLocalPlayer localPlayer];
        
        [localPlayer authenticateWithCompletionHandler:^(NSError* error)
        {
            if (localPlayer.authenticated) {
                NMLog(@"Authenticated");
                [self loggedIn];
            }
            else {
                NMLog(@"Not authenticated");
            }
        }];
    }
}

- (void)loggedIn
{
    [[GKLocalPlayer localPlayer] registerListener:self];
    
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error)
    {
        if (error != nil)
        {
            // エラーを処理する。
        }
        if (achievements != nil)
        {
            // アチーブメントの配列を処理する
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_gameCenterDelegate)
        {
            _gameCenterDelegate->didLoggedIn();
        }
    });
}

- (BOOL)isLoggedIn
{
    return [GKLocalPlayer localPlayer].isAuthenticated;
}

- (void)startRequestMatching
{
    GKMatchRequest* request = [[GKMatchRequest alloc] init];
    request.minPlayers = BATTLE_PLAYER_NUM;
    request.maxPlayers = BATTLE_PLAYER_NUM;
    request.defaultNumberOfPlayers = BATTLE_PLAYER_NUM;
    
    GKMatchmakerViewController* mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.matchmakerDelegate = self;
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:mmvc animated:YES completion:nil];
}

- (void)startOnlineGame
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_gameCenterDelegate)
        {
            _gameCenterDelegate->startOnlineGame();
        }
    });
}

- (void)sendData:(NSData *)data withMode:(GKMatchSendDataMode)mode
{
    NSError* error;
    [self.match sendDataToAllPlayers: data withDataMode:mode error:&error];
}

- (void)disconnect
{
    [self.match disconnect];
}

#pragma mark - GKLocalPlayerListener Methods

- (void)player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite
{
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithInvite:invite];
    
    mmvc.matchmakerDelegate = self;
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:mmvc animated:YES completion:nil];
}

- (void)player:(GKPlayer *)player didRequestMatchWithPlayers:(NSArray *)playerIDsToInvite
{
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = BATTLE_PLAYER_NUM;
    request.maxPlayers = BATTLE_PLAYER_NUM;
    request.playersToInvite = playerIDsToInvite;
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    mmvc.matchmakerDelegate = self;
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:mmvc animated:YES completion:nil];
}

#pragma mark - GKMatchmakerViewControllerDelegate Methods

- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController
{
    UIViewController* rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootController dismissViewControllerAnimated:YES completion:nil];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error
{
    UIViewController* rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootController dismissViewControllerAnimated:YES completion:nil];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)match
{
    UIViewController* rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootController dismissViewControllerAnimated:YES completion:nil];
    
    NMLog(@"find match");
    
    self.match = match;
    self.match.delegate = self;
    
    if (!self.matchStarted && match.expectedPlayerCount == 0)
    {
        self.matchStarted = YES;
        
        NMLog(@"Game start");
        
        [self startOnlineGame];
    }
    
}

#pragma mark - GKMatchDelegate Methods

- (void)match:(GKMatch *)match player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state
{
    ConnectionState changedState;
    NSString* stateString = @"";
    
    switch (state)
    {
        case GKPlayerStateConnected:
            // 新規のプレーヤー接続を処理する
            changedState = ConnectionState::CONNECTED;
            stateString = @"connected to";
            break;
        case GKPlayerStateDisconnected:
            // プレーヤーが切断した場合
            changedState = ConnectionState::NOT_CONNECTED;
            stateString = @"not connected to";
            break;
        case GKPlayerStateUnknown:
            changedState = ConnectionState::NOT_CONNECTED;
            stateString = @"unknown to";
            break;
    }
    
    NMLog(@"%@ changed state: %@ %@", [UIDevice currentDevice].name, stateString, playerID);
    
    if (!self.matchStarted && match.expectedPlayerCount == 0)
    {
        self.matchStarted = YES;
        [self startOnlineGame];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_networkManagerDelegate)
        {
            _networkManagerDelegate->stateChanged(changedState);
        }
    });
}

- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_networkManagerDelegate)
        {
            _networkManagerDelegate->receivedData(data.bytes, data.length);
        }
    });
}

@end

