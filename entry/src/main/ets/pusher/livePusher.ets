
import { promptAction, router, window } from '@kit.ArkUI';
import { abilityAccessCtrl, common, PermissionRequestResult } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import StyleConstants, { logData } from '../common/constants/StyleConstants';
import { JSON } from '@kit.ArkTS';
import { AVSessionManager } from '../common/utils/AVSessionManager';
import { image } from '@kit.ImageKit';
import { getVHPusherShareInstance, VHLivePusher,
  VHLivePusherCallback,
  VHLivePusherXComponentView ,VHPusherInitCallback,
  VHPusherResolutionMode,
  VHPusherFillMode,
  VHMediaCaptureFrame,
  VHMediaPusherCode} from '@vhall/vhallyun-live-pusher';
import { VHAppInfo } from '@vhall/vhallyun-framework';

@Builder
export function LivePusherBuilder(name: string, param: object) {
  LivePusher({ lss_id: param['lss_id'], access_token: param['access_token'], user_id: param['userid'], channel_id: param['channel_id'],inav_id: param['inav_id']})
}

@Observed
export class UserListItemModel {
  constructor(userId: string,pusher:VHLivePusher|null) {
    this.userId = userId;
    this.pusher = pusher;
  }
  pusher:VHLivePusher | null = null;
  userId: string = "";
  voiceVolume: number = 0;
  isAudioMute: boolean = false;
  isVideoMute: boolean = false;
  nickName:string = "";
  streamType:number = 0;
  controller:object | null = null;

  get mainVideoViewID(): string {
    return this.userId + "#MainStream" + this.streamType;
  }

  updateRenderParams(controller:object): void {
    this.controller = controller;
    this.pusher?.setRenderView(this.mainVideoViewID,controller);
  }
}

@Component
struct UserVideoItemView {
  @ObjectLink userItem: UserListItemModel;
  public pusher : VHLivePusher | null =  null;

  onVHXComponentLoad(xComponentId:string,controller:object){
    this.userItem.updateRenderParams(controller);
  }

  build() {
    Column() {
      RelativeContainer() {
        VHLivePusherXComponentView({xComponentId: this.userItem.mainVideoViewID , type: this.pusher?.pusherType(), componentListener:this})
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
          .visibility(this.userItem.isVideoMute ? Visibility.Visible : Visibility.Hidden)

      }.width('100%').height('50%')
    }
  }
}


@Entry
@Component
struct LivePusher {
  public lss_id: string = '';//this.params['lss_id'];
  public access_token: string = '';//this.params['access_token'];
  public channel_id: string ='';// this.params['channel_id'];
  public user_id:string = '';//this.params['userid'];
  public inav_id:string = '';//this.params['userid'];
  pageInfos: NavPathStack = new NavPathStack() // 导航

  pusher:VHLivePusher | null = null;
  private avSessionManager: AVSessionManager = new AVSessionManager();
  @State scalingArray: Array<SelectOption> = [];
  @State scalingText: string = StyleConstants.PLAY_AspectFit;
  @State scalingIndex:number = 0;

  @State resolutionArray: Array<SelectOption> = [];
  @State resolutionText: string =  StyleConstants.PUSH_STREAM_HIGH;
  @State resolutionIndex:number = 0;
  @State bitRate:string = "";
  @State isPublishStream:boolean = false;
  @State isPublishDesktopStream:boolean = false;
  @State isPushPixmap:boolean = false;
  @State isMuteMic:boolean = false;
  @State isMuteCamera:boolean = false;
  private scroller: Scroller = new Scroller();
  @State switchAudioRender:boolean = false;

  isFrontCamera:boolean = true;
  @StorageLink('userList') userList: UserListItemModel[] = [];

  async aboutToAppear(): Promise<void> {

    // let windowStage: window.WindowStage = AppStorage.get('windowStage') as window.WindowStage;
    // windowStage.getMainWindowSync().setPreferredOrientation(window.Orientation.LANDSCAPE);

    let data = new logData;
    data.join_id = 876768888;
    data.is_filter = 0;
    data.visitor_id = this.user_id;
    // 将对象转换为 JSON 字符串
    let jsonString = JSON.stringify(data);
    VHAppInfo.getInstance().report_extra = jsonString;

    this.avSessionManager.start();
    const context: Context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    getVHPusherShareInstance().getLivePusher(context,2,this.lss_id,this.access_token, null,null).then((value:VHLivePusher)=>{
      this.pusher = value;
      let paramsJson: Record<string, string | object> = {};
      paramsJson["role"] = "2";
      paramsJson["roleName"] = "2";
      paramsJson["nickname"] = this.user_id;
      paramsJson["nickName"] = this.user_id;
      paramsJson["accountId"] = this.user_id;
      const jsonParams = JSON.stringify(paramsJson);
      this.pusher.setAttribute(jsonParams);
      this.pusher.setObserver(this.onCallback);
      this.pusher?.initResolutionMode(VHPusherResolutionMode.VHPusherResolutionMode_Portrait);

      let selfItem = new UserListItemModel(this.user_id, this.pusher);
      selfItem.isAudioMute = false;
      selfItem.isVideoMute = false;
      selfItem.streamType = 0;
      selfItem.nickName = this.user_id;
      this.userList.push(selfItem);
      this.pusher.enableCustomDataProcess(true);
    }).catch((err: BusinessError) => {

    })
    this.initScalingMode();
  }

  aboutToDisappear(): void {
    this.avSessionManager.stop();
    this.userList = [];
    this.pusher?.release();
  }

  initScalingMode() {
    this.scalingArray.push({ value: StyleConstants.PLAY_AspectFit });
    this.scalingArray.push({ value: StyleConstants.PLAY_Fill });
    this.resolutionArray.push({ value:  StyleConstants.PUSH_STREAM_HIGH});
    this.resolutionArray.push({ value:  StyleConstants.PUSH_STREAM_LOW });
  }

  private onCallback: VHLivePusherCallback = {
    onPushConnectSuccess: (): void => {
      promptAction.showToast({ message: "推流成功", duration: 1000 });
    },
    onPushDisconnect: (): void => {
      promptAction.showToast({ message: "推流已断开", duration: 1000 });
      setTimeout(()=>{
        this.pusher?.stopPush();
        this.pusher?.startPush(this.lss_id,this.access_token);
      },2000)
    },
    onReConnecting: (): void => {
      promptAction.showToast({ message: "正在重新推流", duration: 1000 });
    },
    onError: (errCode: number, errMsg: string): void => {
      if(errCode == VHMediaPusherCode.ERROR_PUBLISH_CONNECT || errCode == VHMediaPusherCode.ERROR_MUXER_EMPTY){
        setTimeout(()=>{
          this.pusher?.stopPush();
          this.pusher?.startPush(this.lss_id,this.access_token);
        },2000)
      }
      promptAction.showToast({ message: errMsg, duration: 1000 });
    },
    onWarning: (warningCode: number, warningMsg: string): void => {
    },
    onMicrophoneVolumeUpdate: (volume: number): void => {
      for (let i = 0; i < this.userList.length; i++) {
        try {
          this.userList[i].voiceVolume = volume;
        } catch (err) {
          console.error('request CAMERA error=' + JSON.stringify(err));
        }
      }
    },
    onPushStreamBitrate: (bitrate: number): void => {
      console.debug('onPushStreamBitrate',bitrate.toString());
      // this.bitRate = bitrate.toString();
    },
    onCaptureFrame:(src:ArrayBuffer,width:number,height:number,dst:VHMediaCaptureFrame)=> {
      dst.data = src;
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
        Grid(this.scroller) {
          ForEach(this.userList, (userItem: UserListItemModel, index: number) => {
            GridItem() {
              UserVideoItemView({pusher:this.pusher,userItem: userItem})
            }
          }, (userItem: UserListItemModel, index: number): string =>  {
            return userItem.userId + "_" + "_Main"+ userItem.streamType;
          })

        }
        .layoutDirection(GridDirection.Row)
        .columnsTemplate('1fr 1fr')
        .columnsGap(1).rowsGap(1)
        .edgeEffect(EdgeEffect.Spring)
        .scrollBar(BarState.Auto).scrollBarColor(Color.Red)
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
                      this.pusher?.setVideoQuality(1280,720,20,2000,1500);
                      // this.pusher?.setVideoQuality(640,360,15,2000,1500);
                      this.userList[index].updateRenderParams(this.userList[index].controller!);
                      this.pusher?.startCamera(true);
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
              console.error('request CAMERA error=' + JSON.stringify(err));
            }
          }
        })

        Button("桌面共享").onClick(()=>{
          if(this.isPublishDesktopStream){
            //this.rtc?.stopScreenCapture();
            this.isPublishDesktopStream = false;
          }else{
            this.isPublishDesktopStream = true;
            this.userList.forEach((value: UserListItemModel, index: number, array: UserListItemModel[])=>{
              if(value.streamType == 1){
               // this.pusher?.startScreenCapture(VHResolutionMode.TRTCVideoResolutionModePortrait,value.controller!);
              }
            })

          }
        })

        Button(this.isPushPixmap == false ? "图片推流" : "停止图片推流").onClick(async ()=>{
          if(this.isPushPixmap){
           this.pusher?.setVideoImage(null);
            this.isPushPixmap = false;
          }else{
            this.isPushPixmap = true;
            let videoMuteImageFd = getContext(this).resourceManager.getMediaContentSync($r('app.media.videomuteimage'));
            let imageSource : image.ImageSource = image.createImageSource(videoMuteImageFd.buffer);
            let pixelMap = imageSource.createPixelMapSync({ desiredPixelFormat: image.PixelMapFormat.BGRA_8888 });
            this.pusher?.setVideoImage(pixelMap);
          }
        })
      }

      Row(){
        Button(this.isPublishStream ? "停止推流":"开始推流").onClick(()=>{
          if(this.isPublishStream){
            this.pusher?.stopPush();
            this.isPublishStream = false;
          }else{
            this.pusher?.startPush(this.lss_id,this.access_token);
            this.isPublishStream = true;
          }
        })

        Button(this.isMuteMic ? "麦克风开启":"麦克风关闭").onClick(()=>{
         this.pusher?.muteAudio(!this.isMuteMic);
          this.isMuteMic = !this.isMuteMic;
          let index = this.userList.findIndex(item => item.userId === this.user_id);
          if (index !== -1) {
            this.userList[index].isAudioMute = this.isMuteMic;
          }
        })

        Button(this.isMuteCamera ? "摄像头开启":"摄像头关闭").onClick(()=>{
          this.isMuteCamera = !this.isMuteCamera;
          if(this.isMuteCamera){
            let videoMuteImageFd = getContext(this).resourceManager.getMediaContentSync($r('app.media.videomuteimage'));
            let imageSource : image.ImageSource = image.createImageSource(videoMuteImageFd.buffer);
            let pixelMap = imageSource.createPixelMapSync({ desiredPixelFormat: image.PixelMapFormat.BGRA_8888 });
            this.pusher?.setVideoImage(pixelMap);
          }else {
            this.pusher?.setVideoImage(null);
          }
        })
      }

      Row(){
        Select(this.scalingArray)
          .onSelect((index: number, text?: string | undefined) => {
            console.info('Select:' + index)
            this.scalingText = text as string;
            this.scalingIndex = index;
            if (index == 0) {
             this.pusher?.setVideoFillMode(VHPusherFillMode.VHPushFillMode_Fit);
            } else if (index == 1) {
             this.pusher?.setVideoFillMode(VHPusherFillMode.VHPushFillMode_Fill);
            }
          }).value(this.scalingText).selected(this.scalingIndex)


        Select(this.resolutionArray)
          .onSelect((index: number, text?: string | undefined) => {
            console.info('Select:' + index)
            this.resolutionText = text as string;
            this.resolutionIndex = index;
            if (index == 0) {
             this.pusher?.setVideoQuality(1920,1080,15,2000,1500);
            } else if (index == 1) {
              this.pusher?.setVideoQuality(640,360,25,1000,500);
            }
          }).value(this.resolutionText).selected(this.resolutionIndex)


      }
      Row(){
        Text(this.bitRate)
        Row(){
          Text("镜像")
          Toggle({ type: ToggleType.Switch, isOn:  false })
            .onChange((isOn: boolean) => {
             this.pusher?.setRenderMirror(isOn ? true : false);
            })
        }
        Row(){
          Text("切换摄像头")
          Toggle({ type: ToggleType.Switch, isOn:  false })
            .onChange((isOn: boolean) => {
             this.pusher?.switchCamera(isOn ? false : true);
            })
        }
        Row(){
          Text("自定义")
          Toggle({ type: ToggleType.Switch, isOn:  false })
            .onChange((isOn: boolean) => {
              this.pusher?.enableCustomDataProcess(isOn)
            })
        }
      }

    }.onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    }).hideBackButton(true)
    .id('LivePusher')

  }
}