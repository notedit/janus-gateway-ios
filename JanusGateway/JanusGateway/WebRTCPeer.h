//
//  WebRTCStream.h
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WebRTC/WebRTC.h>

@class WebRTCPeer;

@protocol WebRTCPeerDelegate <NSObject>

-(void)peer:(WebRTCPeer*)peer didReceiveRemoteVideo:(RTCVideoTrack*)track;

-(void)peer:(WebRTCPeer*)peer didRemoveRemoteVideo:(RTCVideoTrack*)track;

-(void)peer:(WebRTCPeer*)peer didOccurError:(NSInteger*)errorCode;

-(void)peer:(WebRTCPeer*)peer didGotCandidate:(RTCIceCandidate*)candidate;

-(void)sendMessage:(NSDictionary*)message;

@end


@interface WebRTCPeer : NSObject

@property(nonatomic)  uint64_t userID;
@property(nonatomic)  uint64_t handleID;
@property(nonatomic)  uint64_t sessionID;
@property(nonatomic)  NSString* role;
@property(nonatomic,strong) RTCPeerConnection *peerconnection;
@property(nonatomic,strong) RTCEAGLVideoView  *view;
@property(nonatomic,weak)id<WebRTCPeerDelegate> delegate;
@property(nonatomic,strong) RTCRtpSender* audioRender;
@property(nonatomic,strong) RTCRtpSender* videoRender;
@property(nonatomic,strong) RTCMediaStream* localStream;
@property(nonatomic,readonly) RTCMediaStream* remoteStream;


-(instancetype)initWithDelegate:(id<WebRTCPeerDelegate>)delegate;


- (void)setMaxBitrate:(NSNumber *)maxBitrate;

-(void)offerWithConstraints:(RTCMediaConstraints*)constraints Block:(void (^)(RTCSessionDescription* sdp, NSError* error))block;

-(void)answerWithConstraints:(RTCMediaConstraints*)constraints Block:(void (^)(RTCSessionDescription* sdp, NSError* error))block;

-(void)setRemoteSDP:(RTCSessionDescription*)sdp block:(void (^)(NSError* error))block;

-(void)addCandidate:(RTCIceCandidate*)candidate;

-(void)leave;

@end






