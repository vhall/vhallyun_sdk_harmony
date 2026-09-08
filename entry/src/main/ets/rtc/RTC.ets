
import { promptAction, router, window } from '@kit.ArkUI';
import { getVHRTCShareInstance, VHRTCInteractive, VHRTCCallback,
  VHPushConfigProfile,
  VHResolutionMode,
  VHStreamType,
  VHStream,
  VHRTCVideoFillMode,
  VHMediaType,
  VHXComponentView,
  VHCaptureFrame,
  VHCodeNum} from '@vhall/vhallyun-rtc'
import { abilityAccessCtrl, common, PermissionRequestResult } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import StyleConstants from '../common/constants/StyleConstants';
import { VHInternal } from '@vhall/vhallyun-ims';
import { JSON } from '@kit.ArkTS';
import { AVSessionManager } from '../common/utils/AVSessionManager';
import { VHDocument } from '@vhall/vhallyun-doc';
import { image } from '@kit.ImageKit';
import { audio } from '@kit.AudioKit';


@Builder
export function RTCBuilder(name: string, param: object) {
  RTC({ lss_id: param['lss_id'], access_token: param['access_token'], user_id: param['userid'], channel_id: param['channel_id'],inav_id: param['inav_id']})
}



@Observed
export class UserListItemModel {
  constructor(userId: string,rtc:VHRTCInteractive|null, isRemote: boolean) {
    this.userId = userId;
    this.isRemote = isRemote;
    this.rtc = rtc;
  }
  rtc:VHRTCInteractive | null = null;
  userId: string = "";
  isRemote: boolean = false;
  // quality: TRTCQuality = TRTCQuality.TRTCQuality_Unknown;
  voiceVolume: number = 0;

  isAudioMute: boolean = true;
  isVideoMuteMain: boolean = true;

  streamId:string = "";
  streamType:number = 0;
  streamAttr:string = "";
  nickName:string = "";
  controller:object | null = null;

  get mainVideoViewID(): string {
    return this.userId + "#MainStream" + this.streamType;
  }

  updateRenderParams(controller:object): void {
    this.controller = controller;
    if (this.isRemote) {
      if(this.streamAttr.length > 0){
        let obj = JSON.parse(this.streamAttr) as object;
        if(JSON.has(obj,"nickname")){
          this.nickName = obj["nickname"];
        }
      }
      this.rtc?.subScribeRemoteView(this.streamId,this.streamType,this.mainVideoViewID,controller);
    }else{
      this.rtc?.updateLocalView(this.mainVideoViewID,controller);
    }
  }
}

@Component
struct UserVideoItemView {
  @ObjectLink userItem: UserListItemModel;
  public rtc : VHRTCInteractive | null =  null;
  public rtcType : number = 0;
  onVHXComponentLoad(xComponentId:string,controller:object){
    this.userItem.updateRenderParams(controller);
  }

  build() {
    Column() {
      RelativeContainer() {
        VHXComponentView({xComponentId: this.userItem.mainVideoViewID , type: this.rtcType,componentListener:this})
          .backgroundColor(Color.Black)
          .alignRules({
            'top': { 'anchor': '__container__', 'align': VerticalAlign.Top },
            'left': { 'anchor': '__container__', 'align': HorizontalAlign.Start },
            'bottom': { 'anchor': '__container__', 'align': VerticalAlign.Bottom },
            'right' : { 'anchor': '__container__', 'align': HorizontalAlign.End },
          })

        Text(this.userItem.userId)
          .alignRules({
            'top': { 'anchor': '__container__', 'align': VerticalAlign.Top },
            'left': { 'anchor': '__container__', 'align': HorizontalAlign.Start },
          }).backgroundColor(Color.Black).fontColor(Color.White).margin(2)


        Text(this.userItem.nickName)
          .alignRules({
            'left': { 'anchor': '__container__', 'align': HorizontalAlign.Start },
            'bottom': { 'anchor': '__container__', 'align': VerticalAlign.Bottom },
          }).backgroundColor(Color.Black).fontColor(Color.White).margin(2)


        Progress({ value: this.userItem.voiceVolume, total: 100, type: ProgressType.Linear })
          .value(this.userItem.voiceVolume)
          .color(Color.Green).backgroundColor(Color.Transparent).height(4)
          .alignRules({
            'bottom': { 'anchor': '__container__', 'align': VerticalAlign.Bottom },
            'left': { 'anchor': '__container__', 'align': HorizontalAlign.Start },
            'right': { 'anchor': '__container__', 'align': HorizontalAlign.End },
          }).id('volume')

        Image($r('app.media.mic_close'))
          .alignRules({
            'right': { 'anchor': '__container__', 'align': HorizontalAlign.End},
            'bottom': { 'anchor': '__container__', 'align': VerticalAlign.Bottom },
          }).width('16vp')
          .height('16vp')
          .visibility(this.userItem.isAudioMute ? Visibility.Visible : Visibility.Hidden)

        Image($r('app.media.camera_close'))
          .alignRules({
            'top': { 'anchor': '__container__', 'align': VerticalAlign.Top },
            'right': { 'anchor': '__container__', 'align': HorizontalAlign.End},
          }).width('16vp')
          .height('16vp')
          .visibility(this.userItem.isVideoMuteMain ? Visibility.Visible : Visibility.Hidden)

      }.width('100%').height('50%')
    }
  }
}


@Entry
@Component
struct RTC {
  public lss_id: string = '';//this.params['lss_id'];
  public access_token: string = '';//this.params['access_token'];
  public channel_id: string ='';// this.params['channel_id'];
  public user_id:string = '';//this.params['userid'];
  public inav_id:string = '';//this.params['userid'];
  pageInfos: NavPathStack = new NavPathStack() // 导航
  public rtc : VHRTCInteractive | null =  null;
  public rtcType:number = 0;

  private avSessionManager: AVSessionManager = new AVSessionManager();
  @State scalingArray: Array<SelectOption> = [];
  @State scalingText: string = StyleConstants.PLAY_AspectFit;
  @State  scalingIndex:number = 0;

  @State resolutionArray: Array<SelectOption> = [];
  @State resolutionText: string =  StyleConstants.PUSH_STREAM_HIGH;
  @State resolutionIndex:number = 0;

  @State isPublishStream:boolean = false;
  @State isPublishDesktopStream:boolean = false;
  @State isPushPixmap:boolean = false;
  @State isMuteMic:boolean = false;
  @State isMuteCamera:boolean = false;
  private scroller: Scroller = new Scroller();

  @State switchAudioRender:boolean = false;
  @State changeView:boolean = true;

  isFrontCamera:boolean = true;
  @StorageLink('userList') userList: UserListItemModel[] = [];
  @StorageLink('subUserList') subUserList: UserListItemModel[] = [];
  private  document: VHDocument = new VHDocument();
  async aboutToAppear(): Promise<void> {

    this.document.getDocInfo(this.channel_id,this.access_token,{
      // 成功
      onSuccess: (data: string | object) => {

      },
      // 失败
      onFailure: (errorCode: number, errorMsg: string) => {

      }
    });

    this.avSessionManager.start();
    const context: Context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    getVHRTCShareInstance().getInteractive(context,this.lss_id,this.channel_id,this.access_token,this.user_id,this.inav_id,{
      onFailure: (errorCode: number, errorMsg: string) => {

      }
    }).then((value:VHRTCInteractive)=>{
      this.rtc = value;
      this.rtcType = this.rtc.getRTCType();
      //  角色类型 1 主持人，2 观众，3 助理，4 嘉宾
      // {"roleName":1,"accountId":"18461681","nickname":"邱宇","nickName":"邱宇","role":1}
      // 将数据请求参数转换为 Record
      let paramsJson: Record<string, string | object> = {};
      paramsJson["role"] = "2";
      paramsJson["roleName"] = "2";
      paramsJson["nickname"] = this.user_id;
      paramsJson["nickName"] = this.user_id;
      paramsJson["accountId"] = this.user_id;
      const jsonParams = JSON.stringify(paramsJson);
      this.rtc.setAttribute(jsonParams);
      this.rtc.addCallback(this.onCallback);
      this.rtc.enterRoom();
      this.rtc?.setVideoEncode(VHPushConfigProfile.VHPushConfigProfile_Resolution_1920_1080,VHResolutionMode.TRTCVideoResolutionModePortrait);
      this.rtc.enableCustomVideoProcess(true);
    }).catch((err: BusinessError) => {

    })

    this.initScalingMode();
  }

  aboutToDisappear(): void {
    this.avSessionManager.stop();
    if(this.rtc){
      //退出房间
      this.rtc.exitRoom();
      setTimeout(()=>{
        if(this.rtc){
          this.rtc.destroy();
        }
      },200);
      this.userList = [];
      this.subUserList = [];
    }
  }


  initScalingMode() {

    this.scalingArray.push({ value: StyleConstants.PLAY_AspectFit });
    this.scalingArray.push({ value: StyleConstants.PLAY_Fill });

    this.resolutionArray.push({ value:  StyleConstants.PUSH_STREAM_HIGH});
    this.resolutionArray.push({ value:  StyleConstants.PUSH_STREAM_LOW });
  }

  private onCallback: VHRTCCallback = {
    onConnectRoom: (errorCode: number, errorMsg: string): void => {
      let selfItem = new UserListItemModel(this.user_id, this.rtc, false);
      selfItem.isAudioMute = false;
      selfItem.isVideoMuteMain = false;
      selfItem.streamType = VHStreamType.VHStreamType_AudioAndVideo;
      this.userList.push(selfItem);

      let selfScreenItem = new UserListItemModel(this.user_id, this.rtc, false);
      selfScreenItem.isAudioMute = false;
      selfScreenItem.isVideoMuteMain = false;
      selfScreenItem.streamType = VHStreamType.VHStreamType_Desktop;
      this.userList.push(selfScreenItem);

      promptAction.showToast({ message: "进入房间成功", duration: 1000 });
    },
    onConnectionRoomLost: (): void => {
    },
    onReconnectRoom: (): void => {
    },
    onConnectionRecovery: (): void => {
    },
    onError: (errCode: number, errMsg: string): void => {
    },
    onWarning: (warningCode: number, warningMsg: string): void => {
    },
    onPublishStreamSuccess: (stream: VHStream): void => {
      if (stream.streamType == VHStreamType.VHStreamType_Desktop) {
        promptAction.showToast({ message: "桌面推流成功", duration: 1000 });
        this.isPublishDesktopStream = true;
      } else {
        promptAction.showToast({ message: "推流成功", duration: 1000 });
        this.isPublishStream = true;
      }
    },
    onUnPublishStreamSuccess: (stream: VHStream): void => {
      if (stream.streamType == VHStreamType.VHStreamType_Desktop) {
        promptAction.showToast({ message: "桌面推流结束", duration: 1000 });
        this.isPublishDesktopStream = false;
      } else {
        promptAction.showToast({ message: "已停止推流", duration: 1000 });
        this.isPublishStream = false;
      }
    },
    onRemoteStreamAdd: (stream: VHStream): void => {

      const foundUser = this.subUserList.find(item => stream.streamId === item.streamId);
      if(foundUser == undefined){
        let selfItem = new UserListItemModel(stream.userId, this.rtc, true);
        selfItem.streamId = stream.streamId;
        selfItem.streamType = stream.streamType;
        selfItem.streamAttr = stream.attribute;
        this.subUserList.push(selfItem);
      }else{
        if(foundUser.controller){
          foundUser.updateRenderParams(foundUser.controller);
        }
      }
      promptAction.showToast({ message: "远端流加入" + stream.userId, duration: 1000 });
    },
    onRemoteStreamRemoved: (stream: VHStream): void => {
      for (let i = this.subUserList.length - 1; i >= 0; i--) {
        try {
          if (stream.streamId == this.subUserList[i].streamId) {
            this.subUserList.splice(i, 1); // 从后往前删除元素
            break;
          }
        } catch (err) {
          console.error('request CAMERA error=' + JSON.stringify(err));
        }
      }
      promptAction.showToast({ message: "远端流移除" + stream.streamId, duration: 1000 });
    },
    onSubScribeStreamSuccess: (stream: VHStream, type: VHMediaType): void => {
      promptAction.showToast({ message: "订阅流" + stream.userId, duration: 1000 });
    },
    onSubScribeStreamFailed: (code: number, msg: string, stream_id: string): void => {
      promptAction.showToast({ message: "订阅流失败" + stream_id, duration: 1000 });
      //订阅失败重新拉流订阅
      setTimeout(()=>{
        if(code == VHCodeNum.ERR_MEDIA_CONNECT_CONNECT_ERROR || code == VHCodeNum.ERR_ICE_CONNECT_CONNECT_ERROR || code == VHCodeNum.ERR_DISCONNECTED){
          for (let i = this.subUserList.length - 1; i >= 0; i--) {
            try {
              if (stream_id == this.subUserList[i].streamId) {
                let controller = this.subUserList[i].controller;
                if(controller != null){
                  this.subUserList[i].updateRenderParams(controller!);
                }
                break;
              }
            } catch (err) {
              console.error('request CAMERA error=' + JSON.stringify(err));
            }
          }
        }
      },500)
    },
    onUnSubScribeStreamSuccess: (stream: VHStream): void => {
      promptAction.showToast({ message: "取消订阅流" + stream.userId, duration: 1000 });
    },
    onUserVideoAvailable: (stream: VHStream, available: number): void => {
      setTimeout(()=>{
        if (stream.userId == this.user_id) {
          for (let i = 0; i < this.userList.length; i++) {
            try {
              if (stream.streamType == this.userList[i].streamType) {
                this.userList[i].isVideoMuteMain = available == 1 ? false : true;
                break;
              }
            } catch (err) {
              console.error('request CAMERA error=' + JSON.stringify(err));
            }
          }
        } else {
          for (let i = 0; i < this.subUserList.length; i++) {
            try {
              if (stream.streamId == this.subUserList[i].streamId) {
                this.subUserList[i].isVideoMuteMain = available == 1 ? false : true;
                break;
              }
            } catch (err) {
              console.error('request CAMERA error=' + JSON.stringify(err));
            }
          }
        }
      },1000)
    },
    onUserAudioAvailable: (stream: VHStream, available: number): void => {
      setTimeout(()=>{
        if (stream.userId == this.user_id) {
          for (let i = 0; i < this.userList.length; i++) {
            try {
              if (stream.streamType == this.userList[i].streamType) {
                this.userList[i].isAudioMute = available == 1 ? false : true;
                break;
              }
            } catch (err) {
              console.error('request CAMERA error=' + JSON.stringify(err));
            }
          }
        } else {
          for (let i = 0; i < this.subUserList.length; i++) {
            try {
              if (stream.streamId == this.subUserList[i].streamId) {
                this.subUserList[i].isAudioMute = available == 1 ? false : true;
                break;
              }
            } catch (err) {
              console.error('request CAMERA error=' + JSON.stringify(err));
            }
          }
        }
      },1000)

    },
    onUserStatistics: (stream: VHStream, lost: number): void => {
    },
    onUserAudioVolume: (stream: VHStream, value: number): void => {
      if (stream.userId == this.user_id) {
        for (let i = 0; i < this.userList.length; i++) {
          try {
            this.userList[i].voiceVolume = value;
          } catch (err) {
            console.error('request CAMERA error=' + JSON.stringify(err));
          }
        }
      } else {
        for (let i = 0; i < this.subUserList.length; i++) {
          try {
            if (stream.streamId == this.subUserList[i].streamId) {
              this.subUserList[i].voiceVolume = value;
              break;
            }
          } catch (err) {
            console.error('request CAMERA error=' + JSON.stringify(err));
          }
        }
      }
    },
    onPublishStreamFailed: (code: number, msg: string, stream_id: string): void => {
      promptAction.showToast({ message: "推流失败", duration: 1000 });
    },

    onUnPublishStreamFailed: (code: number, msg: string, stream_id: string): void => {
      promptAction.showToast({ message: "取消推流失败", duration: 1000 });
    },
    onUnSubScribeStreamFailed: (code: number, msg: string, stream_id: string): void => {
      throw new Error('Function not implemented.');
    },
    onCaptureFrame: (src:VHCaptureFrame,dst:VHCaptureFrame): void => {
      dst.data = src.data;
    }
  }

  @Builder
  componentBuilder() {
    Image($r('app.media.icon'))
      .width('40vp')
      .height('40vp')
  }


  build() {
    NavDestination(){
      Row(){
        if(this.changeView){
          Grid(this.scroller) {
            ForEach(this.userList, (userItem: UserListItemModel, index: number) => {
              GridItem() {
                UserVideoItemView({rtc:this.rtc,userItem: userItem,rtcType:this.rtcType})
              }
            }, (userItem: UserListItemModel, index: number): string =>  {
              return userItem.userId + "_" + userItem.isRemote.toString() + "_Main"+ userItem.streamId + userItem.streamType;
            })
            ForEach(this.subUserList, (userItem: UserListItemModel, index: number) => {
              GridItem() {
                UserVideoItemView({rtc:this.rtc,userItem: userItem,rtcType:this.rtcType})
              }
            }, (userItem: UserListItemModel, index: number): string =>  {
              return userItem.userId + "_" + userItem.isRemote.toString() + "_Sub" + userItem.streamId + userItem.streamType;
            })
          }
          .layoutDirection(GridDirection.Row)
          .columnsTemplate('1fr 1fr')
          .columnsGap(1).rowsGap(1)
          .edgeEffect(EdgeEffect.Spring)
          .scrollBar(BarState.Auto).scrollBarColor(Color.Red)
        }

      }
      .height('50%')
      .width('100%')


      Row(){
        Button("开启摄像头").onClick(()=>{
          let index = this.userList.findIndex(item => item.userId === this.user_id);
          if (index !== -1) {
            let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
            try {
              atManager.requestPermissionsFromUser(getContext(), ['ohos.permission.CAMERA'], (err: BusinessError, data: PermissionRequestResult) => {
                console.info('request CAMERA result=' + JSON.stringify(data)); // AuthResult: -1(被拒绝，包括用户当次点的拒绝和曾经点过拒绝) 0(已授权) 2(非法调用)
                if (data.authResults[0] == 0) {
                  atManager.requestPermissionsFromUser(getContext(), ['ohos.permission.MICROPHONE'], (err: BusinessError, data: PermissionRequestResult) => {
                    console.info('request CAMERA result=' + JSON.stringify(data)); // AuthResult: -1(被拒绝，包括用户当次点的拒绝和曾经点过拒绝) 0(已授权) 2(非法调用)
                    if (data.authResults[0] == 0) {
                      this.rtc?.createLocalStream(true, this.userList[index].mainVideoViewID,this.userList[index].controller!);
                      this.userList[index].nickName = "qiuyu";
                    } else {
                      try {
                        promptAction.showToast({message: "申请摄像头权限失败", duration: 1000});
                      } catch (error) {}
                    }
                  });

                } else {
                  try {
                    promptAction.showToast({message: "申请摄像头权限失败", duration: 1000});
                  } catch (error) {}
                }
              });
            } catch (err) {
              let errorMsg = "";
              if (err != null) {
                // 先转字符串，避免空对象 JSON.stringify 成 "{}"
                if (typeof err === 'object' && Object.keys(err).length === 0) {
                  errorMsg = "";
                } else if (typeof err === 'string' && err.trim() === "") {
                  errorMsg = "";
                } else {
                  errorMsg = JSON.stringify(err);
                }
              }
              console.error('request CAMERA error=' + errorMsg);
            }
          }
        })

        Button("桌面共享").onClick(()=>{
            if(this.isPublishDesktopStream){
              this.rtc?.stopScreenCapture();
              this.isPublishDesktopStream = false;
            }else{
              this.isPublishDesktopStream = true;
              this.userList.forEach((value: UserListItemModel, index: number, array: UserListItemModel[])=>{
                if(value.streamType == VHStreamType.VHStreamType_Desktop){
                  this.rtc?.startScreenCapture(VHResolutionMode.TRTCVideoResolutionModePortrait,value.controller!);
                }
              })

            }
        })

        Button(this.isPushPixmap == false ? "图片推流" : "停止图片推流").onClick(async ()=>{
          if(this.isPushPixmap){
            this.rtc?.setVideoMuteImage(null,5);
            this.isPushPixmap = false;
          }else{
            this.isPushPixmap = true;
            let videoMuteImageFd = getContext(this).resourceManager.getMediaContentSync($r('app.media.videomuteimage'));
            let imageSource : image.ImageSource = image.createImageSource(videoMuteImageFd.buffer);
            let pixelMap = imageSource.createPixelMapSync({ desiredPixelFormat: image.PixelMapFormat.BGRA_8888 });
            this.rtc?.setVideoMuteImage(pixelMap,5);
          }
        })
      }

      Row(){
        Button(this.isPublishStream ? "停止推流":"开始推流").onClick(()=>{
          if(this.isPublishStream){
            this.rtc?.unPublish();
            this.isPublishStream = false;
          }else{
            this.rtc?.publish();
            this.isPublishStream = true;
          }
        })

        Button(this.isMuteMic ? "麦克风开启":"麦克风关闭").onClick(()=>{
          this.rtc?.muteLocalAudio(!this.isMuteMic);
          this.isMuteMic = !this.isMuteMic;
          let index = this.userList.findIndex(item => item.userId === this.user_id);
          if (index !== -1) {
            this.userList[index].isAudioMute = this.isMuteMic;
          }
        })

        Button(this.isMuteCamera ? "摄像头开启":"摄像头关闭").onClick(()=>{
          this.rtc?.muteLocalVideo(!this.isMuteCamera);
          this.isMuteCamera = !this.isMuteCamera;
        })

      }

      Row(){
        Button("停自采集").onClick(()=>{
          this.rtc?.enableCustomVideoProcess(false);
        })
        Button("开自采集").onClick(()=>{
          this.rtc?.enableCustomVideoProcess(true);
        })

        Button("退出房间").onClick(()=>{
          this.rtc?.enableCustomVideoProcess(false);
          this.rtc?.stopLocalPreview()
          this.rtc?.exitRoom()
        })
        Button("进入房间").onClick(()=>{
          this.rtc?.enterRoom();
          this.rtc?.setVideoEncode(VHPushConfigProfile.VHPushConfigProfile_Resolution_1920_1080,VHResolutionMode.TRTCVideoResolutionModePortrait);
          this.rtc?.enableCustomVideoProcess(false);
          setTimeout(()=>{
            this.rtc?.enableCustomVideoProcess(true);
          },3000)
        })
      }


      Row(){
        Select(this.scalingArray)
          .onSelect((index: number, text?: string | undefined) => {
            console.info('Select:' + index)
            this.scalingText = text as string;
            this.scalingIndex = index;
            if (index == 0) {
              this.rtc?.setVideoFillMode(VHRTCVideoFillMode.VHRTCVideoFillMode_Fit);
            } else if (index == 1) {
              this.rtc?.setVideoFillMode(VHRTCVideoFillMode.VHRTCVideoFillMode_Fill);
            }
          }).value(this.scalingText).selected(this.scalingIndex)


        Select(this.resolutionArray)
          .onSelect((index: number, text?: string | undefined) => {
            console.info('Select:' + index)
            this.resolutionText = text as string;
            this.resolutionIndex = index;
            if (index == 0) {
              this.rtc?.setVideoEncode(VHPushConfigProfile.VHPushConfigProfile_Resolution_1280_720,VHResolutionMode.TRTCVideoResolutionModePortrait);
            } else if (index == 1) {
              this.rtc?.setVideoEncode(VHPushConfigProfile.VHPushConfigProfile_Resolution_320_180,VHResolutionMode.TRTCVideoResolutionModePortrait);
            }
          }).value(this.resolutionText).selected(this.resolutionIndex)
        }
        Row(){
          Row(){
            Text("镜像")
            Toggle({ type: ToggleType.Switch, isOn:  false })
              .onChange((isOn: boolean) => {
                this.rtc?.setMirrorType(isOn ? true : false);
              })
          }
          Row(){
            Text("切换摄像头")
            Toggle({ type: ToggleType.Switch, isOn:  false })
              .onChange((isOn: boolean) => {
                this.rtc?.switchCamera(isOn ? false : true);
              })
          }
        }

    }.onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    }).hideBackButton(true)
    .id('RTC')

  }
}