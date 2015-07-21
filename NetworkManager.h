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

- (void)setDelegate:(NetworkManagerDelegate*)delegate;

- (void)startAdvertisingAvailability;

- (void)stopAdvertisingAvailability;

- (void)showPeerList;

- (void)sendData:(NSData*)data;

- (void)disconnect;

@end
