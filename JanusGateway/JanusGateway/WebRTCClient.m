//
//  WebRTCClient.m
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import "WebRTCClient.h"


#import "WebRTCSignaling.h"


@interface WebRTCClient () <WebRTCSignalingDelegate>
{
    RTCMediaConstraints*  _mediaConstraints;
    RTCPeerConnectionFactory *_peerConnectionFactory;
}

@end


@implementation WebRTCClient


-(instancetype)initWithDelegate:(id<WebRTCClientDelegate>)delegate
{
    
   
    self = [super init];
    _delegate = delegate;
    _handleMap = [[NSMutableDictionary alloc] init];
    _state = kClientStateDisconnected;
    return self;
}


-(void)setCameraConstraints:(RTCMediaConstraints *)constraints
{
    _mediaConstraints = constraints;
}

-(void)startLocalMedia
{
    
    if (!self.localMediaStream) {
        
    }
}


-(void)stopLocalMedia
{
    if (self.localMediaStream) {
        
    }
}


-(void)joinRoomWith:(uint64_t)room userid:(uint64_t)user
{

}


-(void)leaveRoom
{
    
}

#pragma delegate 


-(void)channel:(WebRTCSignaling *)channel didReceiveMessage:(NSDictionary *)data
{

}


-(void)channel:(WebRTCSignaling *)channel didChangeState:(WebRTCSignalingState)state
{

}

@end
