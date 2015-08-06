//
//  NetworkManager.m
//  MultipeerConnectivityCpp
//
//  Created by Daniel Haaser on 5/25/15.
//
//

#import "NetworkManager.h"
#include "NetworkManagerDelegate.h"

#ifdef COCOS2D_DEBUG
    #define NMLog(format, ...) NSLog(format, ##__VA_ARGS__)
#else
    #define NMLog(...) do {} while (0)
#endif

@interface NetworkManager ()

@property (nonatomic, strong) MCSession* session;
@property (nonatomic, strong) MCPeerID* peerID;
@property (retain, nonatomic) MCAdvertiserAssistant *advertiserAssistant;

@property (atomic, strong) NSMutableArray* connectedPeers;

@end

@implementation NetworkManager
{
    NetworkManagerDelegate* _delegate;
}

- (instancetype)initWithServiceName:(NSString *)serviceName minumumNumberOfPeers:(NSUInteger)minimum andMaximumNumberOfPeers:(NSUInteger)maximum
{
    if (self = [super init])
    {
        self.connectedPeers = [NSMutableArray array];
        self.serviceName = serviceName;
        self.minPeers = minimum;
        self.maxPeers = maximum;
    }
    
    return self;
}

- (void)setDelegate:(NetworkManagerDelegate*)p_delegate
{
    _delegate = p_delegate;
}

- (void)startAdvertisingAvailability
{
    self.peerID = [[MCPeerID alloc] initWithDisplayName:[UIDevice currentDevice].name];

    _session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];
    _session.delegate = self;
    
    _advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:self.serviceName discoveryInfo:nil session:_session];
    [_advertiserAssistant start];
}

- (void)stopAdvertisingAvailability
{
    [_advertiserAssistant stop];
}

- (void)showPeerList
{    
    // Display view listing nearby peers
    MCBrowserViewController *browserViewController = [[MCBrowserViewController alloc] initWithServiceType:self.serviceName session:_session];
    
    browserViewController.delegate = self;
    browserViewController.minimumNumberOfPeers = self.minPeers;
    browserViewController.maximumNumberOfPeers = self.maxPeers;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootViewController = window.rootViewController;
    
    [rootViewController presentViewController:browserViewController animated:YES completion:nil];
}

- (void)disconnect
{
    [self.session disconnect];
    [self.connectedPeers removeAllObjects];
    
    self.session.delegate = nil;
    
    self.peerID = nil;
    self.session = nil;
}

- (void)sendData:(NSData*)data withMode:(MCSessionSendDataMode)mode
{
    NSError* error;
    [self.session sendData:data toPeers:self.session.connectedPeers withMode:mode error:&error];
}

- (NSArray*)getPeerList
{
    NSMutableArray* peerDisplayNames = [@[] mutableCopy];
    
    if (self.session && self.connectedPeers)
    {
        for (MCPeerID* otherPeerID in self.connectedPeers)
        {
            [peerDisplayNames addObject:[NSString stringWithString:otherPeerID.displayName]];
        }
    }
    
    return [NSArray arrayWithArray:peerDisplayNames];
}

#pragma mark -
#pragma mark - MCBrowserViewControllerDelegate methods

// Override this method to filter out peers based on application specific needs
- (BOOL)browserViewController:(MCBrowserViewController *)browserViewController shouldPresentNearbyPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    return YES;
}

// Override this to know when the user has pressed the "done" button in the MCBrowserViewController
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

// Override this to know when the user has pressed the "cancel" button in the MCBrowserViewController
- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController
{
    [browserViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark MCSession Delegate Methods

// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    if (state == MCSessionStateConnected)
    {
        [self.connectedPeers addObject:peerID];
        
        [[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:true];
    }
    else
    {
        MCPeerID* existingPeerObject = [self peerIDInConnectedPeersWithDisplayName:peerID.displayName];
        if (existingPeerObject)
        {
            [self.connectedPeers removeObject:existingPeerObject];
        }
    }
    
    ConnectionState changedState;
    NSString* stateString = @"";
    
    switch (state)
    {
        case MCSessionStateConnected:
            changedState = ConnectionState::CONNECTED;
            stateString = @"connected to";
            break;
            
        case MCSessionStateConnecting:
            changedState = ConnectionState::CONNECTING;
            stateString = @"connecting to";
            break;
            
        case MCSessionStateNotConnected:
            changedState = ConnectionState::NOT_CONNECTED;
            stateString = @"not connected to";
            break;
    }
    
    NMLog(@"%@ changed state: %@ %@", [UIDevice currentDevice].name, stateString, peerID.displayName);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate)
        {
            _delegate->stateChanged(changedState);
        }
    });
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NMLog(@"%@ received data from %@", [UIDevice currentDevice].name, peerID.displayName);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate)
        {
            _delegate->receivedData(data.bytes, data.length);
        }
    });
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    
}

#pragma mark -
#pragma mark Getters / Setters

- (void)setServiceName:(NSString *)serviceName
{
    if (![_serviceName isEqualToString:serviceName])
    {
        _serviceName = [[self stringFilteredForBonjourDiscoveryServiceName:serviceName] copy];
    }
}

#pragma mark -
#pragma mark Private Methods

- (MCPeerID*)peerIDInConnectedPeersWithDisplayName:(NSString*)displayName
{
    for (MCPeerID* peerID in self.connectedPeers)
    {
        if ([peerID.displayName isEqualToString:displayName])
        {
            return peerID;
        }
    }
    
    return nil;
}

- (NSString*)stringFilteredForBonjourDiscoveryServiceName:(NSString*)inputString
{
    // Bonjour discovery service names must contain only
    // lowercase ascii letters or numbers and hyphens
    // of maximum length 15 characters
    
    NSString* lowercase = [inputString lowercaseString];
    NSString* withoutSpaces = [lowercase stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    
    NSCharacterSet* characterSet = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyz1234567890-"] invertedSet];
    NSString* filtered = [[withoutSpaces componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];
    
    if (filtered.length > 15)
    {
        filtered = [withoutSpaces substringToIndex:15];
    }
    else if (filtered.length == 0)
    {
        filtered = @"oops";
    }
    
    return filtered;
}

@end
