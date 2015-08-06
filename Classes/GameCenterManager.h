//
//  GameCenterManager.h
//  Leukocyte
//
//  Created by Mitsushige Komiya on 2015/07/18.
//
//

#ifndef Leukocyte_GameCenterManager_h
#define Leukocyte_GameCenterManager_h

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

class NetworkManagerDelegate;
class GameCenterManagerDelegate;

@interface GameCenterManager : NSObject<GKMatchmakerViewControllerDelegate, GKMatchDelegate, GKLocalPlayerListener>

- (void)setDelegates:(NetworkManagerDelegate*)delegate1 gameCenterDelegate:(GameCenterManagerDelegate*)delegate2;

- (void)loginGameCenter;

- (BOOL)isLoggedIn;

- (void)startRequestMatching;

- (void)startOnlineGame;

- (void)sendData:(NSData*)data withMode:(GKMatchSendDataMode)mode;

- (void)disconnect;

@end

#endif
