//
//  NetworkManager.m
//  Doodler
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

@end

@implementation NetworkManager
{
    NetworkManagerDelegate* _delegate;
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

    _advertiserAssistant = [[MCAdvertiserAssistant alloc] initWithServiceType:@"doodler-game" discoveryInfo:nil session:_session];
    [_advertiserAssistant start];
}

- (void)stopAdvertisingAvailability
{
    [_advertiserAssistant stop];
}

- (void)showPeerList
{
    // Display view listing nearby peers
    MCBrowserViewController *browserViewController = [[MCBrowserViewController alloc] initWithServiceType:@"doodler-game" session:_session];
    
    browserViewController.delegate = self;
    browserViewController.minimumNumberOfPeers = 1;
    browserViewController.maximumNumberOfPeers = 1;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootViewController = window.rootViewController;
    
    [rootViewController presentViewController:browserViewController animated:YES completion:nil];
}

- (void)disconnect
{
    [self.session disconnect];
    
    self.session.delegate = nil;
    
    self.peerID = nil;
    self.session = nil;
}

- (void)sendData:(NSData*)data
{
    NSError* error;
    [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
}

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
    ConnectionState changedState;
    NSString* stateString = @"";
    
    switch (state)
    {
        case MCSessionStateConnected:
            changedState = ConnectionState::CONNECTED;
            stateString = @"connected to";
            
            [[UIApplication sharedApplication].keyWindow.rootViewController dismissModalViewControllerAnimated:true];
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

@end
