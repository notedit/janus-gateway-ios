//
//  WebRTCStream.m
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import "WebRTCPeer.h"

#import <WebRTC/RTCEAGLVideoView.h>

@interface WebRTCPeer ()<RTCPeerConnectionDelegate,RTCEAGLVideoViewDelegate>
{
    
    NSNumber* _maxBitrate;
    
    BOOL  _hasVideo;
    
    RTCVideoTrack* _removeVideoTrack;
    
}

@end

@implementation WebRTCPeer

-(instancetype)initWithDelegate:(id<WebRTCPeerDelegate>)delegate
{
    self = [super init];
    _delegate = delegate;
    _view = [[RTCEAGLVideoView alloc] init];
    _view.delegate = self;
    return self;
}

-(void)setMaxBitrate:(NSNumber *)maxBitrate
{
    _maxBitrate = maxBitrate;
    if (_peerconnection) {
        [self setMaxBitrateForPeerConnectionVideoSender];
    }
}

-(void)offerWithConstraints:(RTCMediaConstraints *)constraints Block:(void (^)(RTCSessionDescription *, NSError *))block
{
    
    [_peerconnection offerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        
        //we can handle more sdp info here
        
        block(sdp,error);
    }];
    
    [self setMaxBitrateForPeerConnectionVideoSender];
}

-(void)answerWithConstraints:(RTCMediaConstraints *)constraints Block:(void (^)(RTCSessionDescription *, NSError *))block
{
    
    [_peerconnection answerForConstraints:constraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        
        // we can handle more sdp info here
        block(sdp,error);
    }];
    
    [self setMaxBitrateForPeerConnectionVideoSender];
}

-(void)setRemoteSDP:(RTCSessionDescription *)sdp block:(void (^)(NSError *))block
{
    // we can handle sdp info here
    [_peerconnection setRemoteDescription:sdp completionHandler:^(NSError * _Nullable error) {
        
        block(error);
    }];
}

-(void)addCandidate:(RTCIceCandidate *)candidate
{
    // need add  queue todo ?
    [_peerconnection addIceCandidate:candidate];
}

-(void)leave
{
    [_peerconnection close];
}


- (void)setMaxBitrateForPeerConnectionVideoSender {
    RTCRtpSender* videoSender;
    for (RTCRtpSender *sender in _peerconnection.senders) {
        if (sender.track != nil) {
            if ([sender.track.kind isEqualToString:@"video"]) {
                videoSender = sender;
            }
        }
    }
    
    if(videoSender == nil){
        return;
    }
    
    if (_maxBitrate.intValue <= 0) {
        return;
    }
    
    RTCRtpParameters *parametersToModify = videoSender.parameters;
    for (RTCRtpEncodingParameters *encoding in parametersToModify.encodings) {
        encoding.maxBitrateBps = @(_maxBitrate.intValue * 1000);
    }
    [videoSender setParameters:parametersToModify];
    
}

#pragma


-(void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size
{
    
    if (!_hasVideo) {
        _hasVideo = true;
        
    }
    NSLog(@"didChangeVideoSize height %f  width %f", size.height,size.width);
    
}


/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged
{
    NSLog(@"didChangeSignalingState ");
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
          didAddStream:(RTCMediaStream *)stream
{
    NSLog(@"didAddStream ");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        RTCLog(@"Received %lu video tracks and %lu audio tracks",
               (unsigned long)stream.videoTracks.count,
               (unsigned long)stream.audioTracks.count);
        if (stream.videoTracks.count) {
            _removeVideoTrack = stream.videoTracks[0];
            [_delegate peer:self didReceiveRemoteVideo:_removeVideoTrack];

        }
    });
    
}

/** Called when a remote peer closes a stream. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream
{
    NSLog(@"didRemoveStream");
    if ([_delegate respondsToSelector:@selector(peer:didRemoveRemoteVideo:)]) {
        
        if ([stream.videoTracks count] > 0) {
            [_delegate peer:self didRemoveRemoteVideo:stream.videoTracks[0]];
        }

    }
    
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection
{
    NSLog(@"peerConnectionShouldNegotiate");
    
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState
{
    NSLog(@"didChangeIceConnectionState");
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState
{
    NSLog(@"didChangeIceGatheringState");
    
    switch (newState) {
        case RTCIceGatheringStateNew:
            break;
        case RTCIceGatheringStateGathering:
            break;
        case RTCIceGatheringStateComplete:
            [_delegate peer:self didGotCandidate:nil];
        default:
            break;
    }
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate
{
    NSLog(@"didGenerateIceCandidate %@",candidate);
    
    [_delegate peer:self didGotCandidate:candidate];
    
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates
{
    NSLog(@"didRemoveIceCandidates");
}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel
{
    // will not happen
    NSLog(@"didOpenDataChannel");
    
}

@end
