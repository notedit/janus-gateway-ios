//
//  WebRTCClient.h
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <WebRTC/WebRTC.h>



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

-(void)client:(WebRTCClient *)client didJoin:(uint64_t)userid withHandleID:(uint64_t)handleid;

-(void)client:(WebRTCClient *)client didLeave:(uint64_t)userid withHandleID:(uint64_t)handleid;

-(void)client:(WebRTCClient *)client didReceiveLocalVideoTrack:(RTCVideoTrack *)track;

-(void)client:(WebRTCClient *)client didReceiveLocalAudioTrack:(RTCAudioTrack *)track;

-(void)client:(WebRTCClient *)client didReceiveRemoteVideoTrack:(RTCVideoTrack *)track;

-(void)client:(WebRTCClient *)client didReceiveRemoteAudioTrack:(RTCAudioTrack *)track;

-(void)client:(WebRTCClient *)client didRemoveLocalVideoTrack:(RTCVideoTrack *)track;

-(void)client:(WebRTCClient *)client didRemoveLocalAudioTrack:(RTCAudioTrack *)track;

-(void)client:(WebRTCClient *)client didRemoveRemoteVideoTrack:(RTCVideoTrack*)track;

-(void)client:(WebRTCClient *)client didRemoveRemoreAudioTrack:(RTCAudioTrack *)track;

@end




@interface WebRTCClient : NSObject


@property(nonatomic, readonly) WebRTCClientState state;
@property(nonatomic, weak) id<WebRTCClientDelegate> delegate;
@property(nonatomic, strong) NSMutableDictionary* handleMap;
@property(nonatomic, strong) RTCMediaStream *localMediaStream;

-(instancetype)initWithDelegate:(id<WebRTCClientDelegate>)delegate;

- (void)setCameraConstraints:(RTCMediaConstraints *)mediaConstraints;

- (void)startLocalMedia;

- (void)stopLocalMedia;

- (void)joinRoomWith:(uint64_t)room
             userid:(uint64_t)user;


- (void)leaveRoom;


@end
