//
//  ViewController.m
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import "ViewController.h"

#import <stdlib.h>

#import <CRToast/CRToast.h>

#import "WebRTCClient.h"

#import <WebRTC/WebRTC.h>






static uint64_t  ROOM = 1234;

@interface ViewController ()<WebRTCClientDelegate>
{
    WebRTCClient* webrtcClient;
    UIView*  localVideoView;
    uint64_t userid;
}

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [_joinButton addTarget:self action:@selector(joinClick:) forControlEvents:UIControlEventTouchUpInside];
    
    _joinButton.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    
    webrtcClient = [[WebRTCClient alloc] initWithDelegate:self];
    
    RTCSetMinDebugLogLevel(RTCLoggingSeverityVerbose);
}


-(void) joinClick:(UIButton*)button
{
    
    [self requestAudioAcess:^(BOOL granted) {
        BOOL audioGranted = granted;
        [self requestVideoAcess:^(BOOL granted) {
            BOOL videoGranted = granted;
            if (audioGranted && videoGranted) {
                _joinButton.hidden = YES;
                [webrtcClient startLocalMedia];
                userid = (uint64_t)(arc4random_uniform(100000));
                [webrtcClient joinRoomWith:ROOM userid:userid];
            } else {
                [self toast:@"can not get media access"];
            }
        }];
    }];
    

    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void)toast:(NSString*)text
{
    
    NSDictionary *options = @{
                              kCRToastTextKey : text,
                              kCRToastTextAlignmentKey : @(NSTextAlignmentCenter),
                              kCRToastBackgroundColorKey : [UIColor redColor],
                              kCRToastAnimationInTypeKey : @(CRToastAnimationTypeGravity),
                              kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeGravity),
                              kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionLeft),
                              kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionRight)
                              };
    [CRToastManager showNotificationWithOptions:options
                                completionBlock:^{
                                    NSLog(@"Completed");
                                }];
}



-(void)requestAudioAcess:(void (^)(BOOL granted))block
{
    AVAudioSessionRecordPermission permissionStatus = [[AVAudioSession sharedInstance] recordPermission];
    
    if (permissionStatus == AVAudioSessionRecordPermissionUndetermined) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL grante) {
            // CALL YOUR METHOD HERE - as this assumes being called only once from user interacting with permission alert!
            if (grante) {
                block(TRUE);
                // Microphone enabled code
            }
            else {
                block(FALSE);
                // Microphone disabled code
            }
        }];
    } else if(permissionStatus == AVAudioSessionRecordPermissionDenied){
        
        block(FALSE);
        
    } else if(permissionStatus == AVAudioSessionRecordPermissionGranted){
        block(TRUE);
        
    } else {
        block(FALSE);
    }
    
}


-(void)requestVideoAcess:(void (^)(BOOL granted))block
{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        
        block(TRUE);
        
    } else if(authStatus == AVAuthorizationStatusDenied){
        // denied
        block(FALSE);
    } else if(authStatus == AVAuthorizationStatusRestricted){
        // restricted, normally won't happen
        block(FALSE);
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        // not determined?!
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL grante) {
            if(grante){
                block(TRUE);
            } else {
                block(FALSE);
            }
        }];
    } else {
        // impossible, unknown authorization status
    }
}


-(CGRect)videoViewFrame:(int)index
{
    
    float width = self.view.frame.size.width/2;
    float height = width;
    float x = (index%2) * width;
    float y = (index/2) * width;
    
    return CGRectMake(x, y, width, height);
}

#pragma delegate  



-(void)client:(WebRTCClient *)client didJoin:(uint64_t)userid
{
    NSLog(@"didJoin %llu",userid);
}

-(void)client:(WebRTCClient *)client didLeave:(uint64_t)userid
{
    NSLog(@"didLeave %llu",userid);
}


-(void)client:(WebRTCClient *)client didOccourError:(NSInteger)errorCode
{
    NSLog(@"didOccourError");
}




-(void)client:(WebRTCClient *)client didReceiveLocalVideo:(WebRTCPeer *)peer
{
    NSLog(@"didReceiveLocalVideo ");
    NSMutableArray*  users  = [NSMutableArray arrayWithArray:[client.peers.allValues copy]];
    [users insertObject:peer atIndex:0];
    
    localVideoView = peer.view;
    CGRect frame = [self videoViewFrame:0];
    [peer.view  setSize:frame.size];
    peer.view.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:peer.view];
    
    int i = 0;
    for (WebRTCPeer* peer in users) {
        CGRect frame = [self videoViewFrame:i];
        peer.view.frame = frame;
        i++;
    }
    
    [peer setMaxBitrate:@100];
    
}

-(void)client:(WebRTCClient *)client didReceiveRemoteVideo:(WebRTCPeer *)peer
{
    
    NSLog(@"didReceiveRemoteVideo ");
    NSMutableArray*  users  = [NSMutableArray arrayWithArray:[client.peers.allValues copy]];
    [users insertObject:client.localPeer atIndex:0];
    
    CGRect frame = [self videoViewFrame:0];
    [peer.view  setSize:frame.size];
    peer.view.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:peer.view];
    peer.view.backgroundColor = [UIColor blackColor];
    
    int i = 0;
    for (WebRTCPeer* peer in users) {
        CGRect frame = [self videoViewFrame:i];
        peer.view.frame = frame;
        i++;
    }
    
    [peer setMaxBitrate:@100];
    
}

-(void)client:(WebRTCClient *)client didRemoveLocalVideo:(WebRTCPeer *)peer
{
    NSLog(@"didRemoveLocalVideo ");
    [peer.view removeFromSuperview];
    
    NSMutableArray* users = [NSMutableArray arrayWithArray:[client.peers.allValues copy]];
    
    int i = 0;
    for(WebRTCPeer* peer in users){
        CGRect frame = [self videoViewFrame:i];
        peer.view.frame = frame;
        i++;
    }
    
}

-(void)client:(WebRTCClient *)client didRemoveRemoteVideo:(WebRTCPeer *)peer
{
    NSLog(@"didRemoveRemoteVideo");
    [peer.view removeFromSuperview];
    
    NSMutableArray* users = [NSMutableArray arrayWithArray:[client.peers.allValues copy]];
    
    [users insertObject:client.localPeer atIndex:0];
    
    int i = 0;
    for(WebRTCPeer* peer in users){
        CGRect frame = [self videoViewFrame:i];
        peer.view.frame = frame;
        i++;
    }
}



@end
