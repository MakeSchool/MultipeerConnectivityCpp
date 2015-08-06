//
//  GameCenterWrapper.mm
//  Leukocyte
//
//  Created by Mitsushige Komiya on 2015/07/18.
//
//

#include "GameCenterWrapper.h"
#include "GameCenterManager.h"
#include "NetworkingWrapper.h"

#pragma mark - Lifecycle

GameCenterWrapper::GameCenterWrapper()
{
    this->gameCenterManager = [[GameCenterManager alloc] init];
    [gameCenterManager setDelegates:this gameCenterDelegate:this];
    [gameCenterManager retain];
}

GameCenterWrapper::~GameCenterWrapper()
{
    [gameCenterManager release];
    gameCenterManager = nil;
}

void GameCenterWrapper::setDelegates(NetworkingDelegate *delegate1, GameCenterDelegate *delegate2)
{
    this->networkingDelegate = delegate1;
    this->gameCenterDelegate = delegate2;
}

bool GameCenterWrapper::isLoggedIn()
{
    return [gameCenterManager isLoggedIn];
}

void GameCenterWrapper::loginGameCenter()
{
    [gameCenterManager loginGameCenter];
}

void GameCenterWrapper::startRequestMatching()
{
    [gameCenterManager startRequestMatching];
}

void GameCenterWrapper::sendData(const void *data, unsigned long length, SendDataMode mode)
{
    GKMatchSendDataMode mcSessionMode = GKMatchSendDataReliable;
    switch (mode) {
        case SendDataMode::Reliable  : mcSessionMode = GKMatchSendDataReliable;   break;
        case SendDataMode::Unreliable: mcSessionMode = GKMatchSendDataUnreliable; break;
    }
    
    NSData* dataToSend = [NSData dataWithBytes:data length:length];
    [this->gameCenterManager sendData:dataToSend];
}

#pragma mark - NetworkManagerDelegate Methods

void GameCenterWrapper::receivedData(const void *data, unsigned long length)
{
    if (this->networkingDelegate) {
        this->networkingDelegate->receivedData(data, length);
    }
}

void GameCenterWrapper::stateChanged(ConnectionState state)
{
    if (this->networkingDelegate) {
        this->networkingDelegate->stateChanged(state);
    }
}

void GameCenterWrapper::startOnlineGame()
{
    if (this->gameCenterDelegate) {
        this->gameCenterDelegate->startOnlineGame();
    }
}

void GameCenterWrapper::didLoggedIn()
{
    if (this->gameCenterDelegate) {
        this->gameCenterDelegate->didLoggedIn();
    }
}