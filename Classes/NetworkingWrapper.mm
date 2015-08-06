//
//  NetworkingWrapper.cpp
//  Doodler
//
//  Created by Daniel Haaser on 5/25/15.
//
//

#include "NetworkingWrapper.h"
#include "NetworkManager.h"
#pragma mark -
#pragma mark Lifecycle

NetworkingWrapper::NetworkingWrapper()
{
    NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    
    this->networkManager = [[NetworkManager alloc] initWithServiceName:appName minumumNumberOfPeers:1 andMaximumNumberOfPeers:1];
    [this->networkManager setDelegate:this];
    [networkManager retain];
}

NetworkingWrapper::~NetworkingWrapper()
{
    [networkManager release];
    networkManager = nil;
}

#pragma mark -
#pragma mark Public Methods

void NetworkingWrapper::setServiceName(const std::string &serviceName)
{
    this->networkManager.serviceName = [NSString stringWithUTF8String:serviceName.c_str()];
}

void NetworkingWrapper::setMinimumPeers(unsigned int minimumPeers)
{
    this->networkManager.minPeers = minimumPeers;
}

void NetworkingWrapper::setMaximumPeers(unsigned int maximumPeers)
{
    this->networkManager.maxPeers = maximumPeers;
}

void NetworkingWrapper::setDelegate(NetworkingDelegate* delegate)
{
    this->delegate = delegate;
}

void NetworkingWrapper::startAdvertisingAvailability()
{
    [this->networkManager startAdvertisingAvailability];
}

void NetworkingWrapper::stopAdvertisingAvailability()
{
    [this->networkManager stopAdvertisingAvailability];
}

void NetworkingWrapper::showPeerList()
{
    [this->networkManager showPeerList];
}

void NetworkingWrapper::sendData(const void *data, unsigned long length, SendDataMode mode)
{
    MCSessionSendDataMode mcSessionMode = MCSessionSendDataReliable;
    
    switch (mode)
    {
        case SendDataMode::Reliable: mcSessionMode = MCSessionSendDataReliable; break;
        case SendDataMode::Unreliable: mcSessionMode = MCSessionSendDataUnreliable; break;
    }
    
    NSData* dataToSend = [NSData dataWithBytes:data length:length];
    [this->networkManager sendData:dataToSend withMode:mcSessionMode];
}

void NetworkingWrapper::disconnect()
{
    [this->networkManager disconnect];
}

const char * NetworkingWrapper::getDeviceName()
{
    NSString* deviceName = [UIDevice currentDevice].name;
    return [deviceName UTF8String];
}

std::vector<std::string> NetworkingWrapper::getPeerList()
{
    NSArray* peerList = [this->networkManager getPeerList];
    
    std::vector<std::string> returnVector;
    
    for (NSString* peerName in peerList)
    {
        std::string peerString = std::string([peerName UTF8String]);
        returnVector.push_back(peerString);
    }
    
    return returnVector;
}

#pragma mark -
#pragma mark NetworkManager Delegate Methods

void NetworkingWrapper::receivedData(const void *data, unsigned long length)
{
    if (this->delegate)
    {
        this->delegate->receivedData(data, length);
    }
}

void NetworkingWrapper::stateChanged(ConnectionState state)
{
    if (this->delegate)
    {
        this->delegate->stateChanged(state);
    }
}