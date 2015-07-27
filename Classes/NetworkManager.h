//
//  NetworkManager.h
//  Doodler
//
//  Created by Daniel Haaser on 5/25/15.
//
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

class NetworkManagerDelegate;

@interface NetworkManager : NSObject <MCBrowserViewControllerDelegate, MCSessionDelegate>

@property (nonatomic, copy) NSString* serviceName;
@property (nonatomic, assign) NSUInteger minPeers;
@property (nonatomic, assign) NSUInteger maxPeers;

- (instancetype)initWithServiceName:(NSString*)serviceName minumumNumberOfPeers:(NSUInteger)minimum andMaximumNumberOfPeers:(NSUInteger)maximum;

- (void)setDelegate:(NetworkManagerDelegate*)delegate;

- (void)startAdvertisingAvailability;

- (void)stopAdvertisingAvailability;

- (void)showPeerList;

- (void)sendData:(NSData*)data;

- (void)disconnect;

- (NSArray*)getPeerList;

@end
