//
//  WebRTCClient.h
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <WebRTC/WebRTC.h>

#import "WebRTCPeer.h"

typedef NS_ENUM(NSInteger, WebRTCClientState) {
    // Disconnected from servers.
    kClientStateDisconnected,
    // Connecting to servers.
    kClientStateConnecting,
    // Connected to servers.
    kClientStateConnected,
};


@class WebRTCClient;

@protocol WebRTCClientDelegate <NSObject>

-(void)client:(WebRTCClient *)client didJoin:(uint64_t)userid;

-(void)client:(WebRTCClient *)client didLeave:(uint64_t)userid;

-(void)client:(WebRTCClient *)client didOccourError:(NSInteger)errorCode;

-(void)client:(WebRTCClient *)client didReceiveLocalVideo:(WebRTCPeer *)peer;

-(void)client:(WebRTCClient *)client didReceiveRemoteVideo:(WebRTCPeer *)peer;

-(void)client:(WebRTCClient *)client didRemoveLocalVideo:(WebRTCPeer *)peer;

-(void)client:(WebRTCClient *)client didRemoveRemoteVideo:(WebRTCPeer *)peer;


@end


@interface WebRTCClient : NSObject


@property(nonatomic, readonly) WebRTCClientState state;
@property(nonatomic, weak) id<WebRTCClientDelegate> delegate;
@property(nonatomic, strong) RTCMediaStream *localMediaStream;
@property(nonatomic, strong) WebRTCPeer* localPeer;
@property(nonatomic, strong) NSMutableDictionary* peers;


-(instancetype)initWithDelegate:(id<WebRTCClientDelegate>)delegate;

- (void)startLocalMedia;

- (void)stopLocalMedia;

- (void)joinRoomWith:(uint64_t)room
             userid:(uint64_t)user;

- (void)leaveRoom;

- (void)sendMessage:(NSDictionary*)message;

@end
