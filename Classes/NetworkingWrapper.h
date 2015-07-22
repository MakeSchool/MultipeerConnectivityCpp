//
//  NetworkingWrapper.h
//  Doodler
//
//  Created by Daniel Haaser on 5/25/15.
//
//

#ifndef __Doodler__NetworkingWrapper__
#define __Doodler__NetworkingWrapper__

#include "NetworkManagerDelegate.h"

#ifdef __OBJC__
@class NetworkManager;
#else
typedef struct objc_object NetworkManager;
#endif

// Classes that want to be notified by networking activity should inherit from this class
// and set themselves as the delegate
class NetworkingDelegate
{
public:
    virtual void receivedData(const void* data, unsigned long length) = 0;
    virtual void stateChanged(ConnectionState state) = 0;
};

class NetworkingWrapper : public NetworkManagerDelegate
{
public:
    NetworkingWrapper();
    ~NetworkingWrapper();
    
    /**
     *  Set the delegate class that will be informed of connection state changes, and will be given the data recieved from the network
     */
    void setDelegate(NetworkingDelegate* delegate);
    
    /**
     *   Allow this device to be discovered and invited to connect by other devices
     */
    void startAdvertisingAvailability();
    
    /**
     *  Displays a built-in modal view that displays peers and allows this device to invite them to connect
     */
    void showPeerList();
    
    /**
     *  Sends the data in the specified address in memory with a given length over the network to the connected peers
     */
    void sendData(const void* data, unsigned long length);
    
    /**
     *  Retrieves the name of the this device
     */
    static const char * getDeviceName();
    
    /**
     *  Disconnect from the current session
     */
    void disconnect();
    
    /**
     *  Retrieves a list of the device names of any currently connected peers
     */
    std::vector<std::string> getPeerList();
    
private:
    NetworkManager* networkManager;
    NetworkingDelegate* delegate;
    
    void receivedData(const void* data, unsigned long length);
    void stateChanged(ConnectionState state);
};

#endif /* defined(__Doodler__NetworkingWrapper__) */
