import { VHVodPlayer, VHVodPlayerView, VHPlayerStatus, VHDefinition, VHCastPlayState,
  VHCastPlayMediaSource,VHCastPlayDevice,  VHPlayerScalingMode,
  WaiterMaskPostion,
  VHPlayerPipStatus,
  VHPlayStreamType,
  VHErrorCode,
  VHPlayerError,
  VHVodPlayerSpeed,
  VHWaterMarkLocation,
  VHPlayerPipControlPanelStatus} from '@vhall/vhallyun-lss-vod'
import { promptAction, router, window } from '@kit.ArkUI';
import StyleConstants from '../common/constants/StyleConstants';
import {logData} from '../common/constants/StyleConstants';
import { BusinessError } from '@ohos.base';
import { common, wantAgent } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import fs from '@ohos.file.fs';

import image from '@ohos.multimedia.image';
import {
  VHDocFilType,
  VHDocument,
  VHDocumentView,
  VHDocumentViewModel,
  VHDocumentWaterMark
} from '@vhall/vhallyun-doc';

import { AVCastPicker, AVCastPickerState } from '@kit.AVSessionKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { TaskManager } from '../common/utils/TaskUitl';
import { emitter } from '@kit.BasicServicesKit';


@Entry
@Component
struct Vod {
  private vodPlayerModel: VHVodPlayer = new VHVodPlayer(getContext(this) as common.UIAbilityContext);
  @State photoAccessHelper: photoAccessHelper.PhotoAccessHelper | undefined = undefined; // 相册模块管理实例
  @State livePlayCreate: boolean = false;
  // 获取上个界面传递过来的房间号
  params: object = router.getParams() as object;
  public record_id: string = this.params['record_id'];
  public access_token: string = this.params['access_token'];
  public user_id:string = this.params['userid'];
  private channel_id: string = this.params['channel_id'];
  private isFirstShow: boolean = true;
  /**
   * 页面退到后台前获取播放状态，用于回到前台进行播放判断。
   * **/
  private playState: VHPlayerStatus = VHPlayerStatus.INIT;
  //如果为文件操作方
  private isDocController:boolean = false;
  //是否显示文档
  @State showDoc: boolean = true;
  @State hasAudio: boolean = false;
  @State scalingArray: Array<SelectOption> = [];
  @State scalingText: string = StyleConstants.PLAY_AspectFit;
  @State scalingIndex: number = 0;
  @State totalTime: string = '00:00:00';
  @State currentTime: string = '00:00:00';
  @State totalDuration: number = 0;
  @State currentDuration: number = 0;
  @State vhLiveDefText: string = '原画';
  @State vhLiveDefIndex: number = 0;
  @State isCasting :boolean = false;
  /**
   * 清晰度列表
   */
  @State vhLiveDefinition: Array<SelectOption> = [{ value: '原画' }];
  @State userWaterMarkUrl: string =
    'https://cnstatic01.e.vhall.com/upload/common/static-imgs/c0/e7/c0e7569408de296971eb4b98945c240b.png';
  private rePullStreamTimerId: number = 0;
  private exitVodPage: boolean = false;
  @State waterPos: Array<SelectOption> = [{ value: '左上' }, { value: '右上' }, { value: '左下' }, { value: '右下' }];
  @State waterPText: string = '左上';
  @State waterPIndex: number = 0;
  @State selectCid: string = '';
  private selectDocument: number = 0;
  @State documentViews: Array<VHDocument> = new Array();
  private document: VHDocument = new VHDocument(new VHDocumentViewModel(VHDocFilType.DOC));
  private controller: TabsController = new TabsController()
  private docWaterMark: VHDocumentWaterMark = new VHDocumentWaterMark('hello world', 20);
  private source: VHCastPlayMediaSource |undefined = undefined;
  @State waterMarkLocation: VHWaterMarkLocation = new VHWaterMarkLocation();
  @State speedSelect: Array<SelectOption> = [];
  @State speedText: string = '1.00倍';
  @State speedIndex: number = 1;
  @State playLandSpaceMode: boolean = false;
  @State isMute: boolean = false;
  @State muteText: string = StyleConstants.PLAY_MUTE;
  @State volume: number = 1.0;
  @State currentDocumentIndex: number = 0;
  private logReport:object = [];
  aboutToAppear(): void {
    this.source = {
      title:'我的回放',
      name:'微吼直播',
      description:'当前播放为回放视频',
      headImage:"https://q3.itc.cn/q_70/images03/20250328/eb685be206974653af5acbff051bd9f3.jpeg"
    };
    //初始化投屏后，会创建媒体会话绑定播控服务。如果不使用投屏功能不要进行初始化。
    this.vodPlayerModel.initCastPlay(this.source);
    this.vodPlayerModel.setVHLivePlayerInterface(this, this);
    this.initSpeed();
    this.initScalingMode();
    this.document.initVodDoc(this.record_id, this.access_token,this);
    let context = getContext(this);
    window.getLastWindow(context)
      .then((window) => {
        window.setWindowKeepScreenOn(true) //设置窗口常亮避免息屏
      })
      .catch((err: BusinessError)=>{
        console.error('Error occurred:', err);
      })

    let data = new logData;
    data.join_id = 876768888;
    data.is_filter = 0;
    data.visitor_id = this.user_id;
    data.is_filter = 0;
    // 将对象转换为 JSON 字符串
    let jsonString = JSON.stringify(data);
    this.logReport['report_extra'] = jsonString;
    this.logReport['sz_t'] = 1;
  }

  aboutToDisappear(): void {
    this.vodPlayerModel.destroyPlayer();
    clearInterval(this.rePullStreamTimerId);
  }

  // 页面初次加载的时候
  onPageShow(): void {
    if (this.isFirstShow) {
      this.isFirstShow = false;
    } else {
      //退到后台时如果播放器处于播放状态，将变为pause状态。重新进入进行恢复
      if (this.playState == VHPlayerStatus.PLAYING) {
        this.vodPlayerModel.resumePlay();
      }
    }
  }

  onPageHide(): void {
    this.playState = this.vodPlayerModel.getPlayerState();
    //判断是否需要继续进行播放。如果没有投屏则暂停播放
    if(!this.isCasting){
      this.vodPlayerModel.pausePlay();
    }
  }

  /**
   * 文档初始化、创建失败回调
   * @param errorCode 错误码
   * @param errorMsg  错误信息
   * @param cid 文档白板标识。
   */
  docError(errorCode: number, errorMsg: string, cid?: string) {
    promptAction.showToast({
      duration: 2000,
      message: errorMsg
    });
  }

  /**
   *  直播文档同步
   * @param channelID 文档channelID
   * @return number 延迟执行时间(秒)
   */
  dolayChannelID(channelID: string): number {
    return 0;
  }

  /**
   * 是否显示文档
   * @param switchStatus 状态
   */
  docSwitchStatus(switchStatus: boolean): void {
    this.showDoc = switchStatus;
  }

  /**
   * 翻页消息
   * @param documentView   文档id 为空时没有 文档
   */
  docChangePage(docViewModel: VHDocumentViewModel): void {

  }

  /**
   * 选择文档
   * @param documentView 文档视图
   */
  docSelect(cid: string): void {
    this.selectCid = cid;
  }

  /**
   * 添加文档
   * @param documentView 文档视图
   */
  docAdd(docViewModel: VHDocumentViewModel): void {
    if (!this.isExistDocument(docViewModel.cid)) {
      let document: VHDocument = new VHDocument(docViewModel);
      this.insertDocumentItem(document);
    }
  }

  /**
   * 删除文档
   * @param cid 容器id
   */
  docRemove(cid: string): void {
    this.removeDocumentItem(cid);
  }

  isExistDocument(cid: string): boolean {
    for (let index = 0; index < this.documentViews.length; index++) {
      const element = this.documentViews[index].documentViewModel
      if (element?.cid == cid) {
        return true;
      }
    }
    return false;
  }

  insertDocumentItem(doc: VHDocument) {
    this.documentViews.push(doc);
  }

  removeDocumentItem(cid: string) {
    for (let index = 0; index < this.documentViews.length; index++) {
      const element = this.documentViews[index];
      if (element.documentViewModel.cid == cid) {
        this.documentViews.splice(index, 1);
        element.deleteDoc();
      }
    }
  }

  /**
   * 组件加载成功
   */
  onVHPlayerViewLoaded() {
    // 初次进入调用播放
    this.vodPlayerModel.startPlay(this.record_id, this.access_token,this.logReport);
  }

  /**
   * 画中画状态
   */
  onPipStatusChange(state: VHPlayerPipStatus) {

  }


  onPipControlPanelStatusChange(state:VHPlayerPipControlPanelStatus){
    switch (state){
      case VHPlayerPipControlPanelStatus.CONTROL_PAUSE:
        this.vodPlayerModel.pausePlay();
        break;
      case VHPlayerPipControlPanelStatus.CONTROL_PLAY:
        this.vodPlayerModel.resumePlay();
        break;
    }
  }

  initScalingMode() {
    let modes: Array<VHPlayerScalingMode> = this.vodPlayerModel.getPlayerScalingMode()
    for (let i = 0; i < modes.length; i++) {
      let mode = modes[i];
      if (mode == VHPlayerScalingMode.FILL) {
        this.scalingArray.push({ value: StyleConstants.PLAY_Fill });
      }
      if (mode == VHPlayerScalingMode.ASPECT_FIT) {
        this.scalingArray.push({ value: StyleConstants.PLAY_AspectFit });
      }
      if (mode == VHPlayerScalingMode.ASPECT_FILL) {
        this.scalingArray.push({ value: StyleConstants.PLAY_AspectFill });
      }
      if (this.vodPlayerModel.getCurrentScalingMode() == VHPlayerScalingMode.FILL) {
        this.scalingIndex = 0;
        this.scalingText = StyleConstants.PLAY_Fill;
      }
      if (this.vodPlayerModel.getCurrentScalingMode() == VHPlayerScalingMode.ASPECT_FIT) {
        this.scalingIndex = 1;
        this.scalingText = StyleConstants.PLAY_AspectFit;
      }
      if (this.vodPlayerModel.getCurrentScalingMode() == VHPlayerScalingMode.ASPECT_FILL) {
        this.scalingIndex = 2;
        this.scalingText = StyleConstants.PLAY_AspectFill;
      }
    }
  }

  initSpeed() {
    let speeds: Array<VHVodPlayerSpeed> = this.vodPlayerModel.getSpeed();
    let currentSpeed = this.vodPlayerModel.getCurrentSpeed();
    for (let i = 0; i < speeds.length; i++) {
      if (speeds[i] == VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_0_75_X) {
        this.speedSelect.push({ value: StyleConstants.PLAY_SPEED_0_75 });
        if (currentSpeed == VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_0_75_X) {
          this.speedText = StyleConstants.PLAY_SPEED_0_75;
          this.speedIndex = 0;
        }
      } else if (speeds[i] == VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_1_00_X) {
        this.speedSelect.push({ value: StyleConstants.PLAY_SPEED_1_00 });
        if (currentSpeed == VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_1_00_X) {
          this.speedText = StyleConstants.PLAY_SPEED_1_00;
          this.speedIndex = 1;
        }
      } else if (speeds[i] == VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_1_25_X) {
        this.speedSelect.push({ value: StyleConstants.PLAY_SPEED_1_25 });
        if (currentSpeed == VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_1_25_X) {
          this.speedText = StyleConstants.PLAY_SPEED_1_25;
          this.speedIndex = 2;
        }
      } else if (speeds[i] == VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_1_75_X) {
        this.speedSelect.push({ value: StyleConstants.PLAY_SPEED_1_75 });
        if (currentSpeed == VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_1_75_X) {
          this.speedText = StyleConstants.PLAY_SPEED_1_75;
          this.speedIndex = 3;
        }
      } else if (speeds[i] == VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_2_00_X) {
        this.speedSelect.push({ value: StyleConstants.PLAY_SPEED_2_00 });
        if (currentSpeed == VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_2_00_X) {
          this.speedText = StyleConstants.PLAY_SPEED_2_00;
          this.speedIndex = 4;
        }
      }
    }
  }

  // 封装NavigationTitle
  @Builder
  NavigationTitle() {
    Text('点播界面')
      .fontColor($r('app.color.title_text_color'))
      .fontSize($r('app.float.title_font_size'))
      .lineHeight($r('app.float.nav_size_height'))
  }

  /**
   * 监听资源播放资源的时长，单位为毫秒（ms），用于刷新进度条长度
   * @param duration  回放时长，单位为毫秒（ms）。
   */
  onVodTotalDuration(duration: number) {
    if (duration != 0) {
      this.totalTime = this.msToTime(duration);
      this.totalDuration = duration;
    }
  }

  /**
   * 当前播放时长，单位为毫秒（ms），用于刷新进度条长度
   * @param currentDuration  当前播放时长，单位为毫秒（ms）。
   */
  onVodCurrentDuration(currentDuration: number) {
    this.currentTime = this.msToTime(currentDuration);
    let nowSeconds = Math.floor(currentDuration / 1000);
    let totalSeconds = Math.floor(this.totalDuration / 1000);
    this.currentDuration = Math.floor(nowSeconds * 100 / totalSeconds);
  }

  /**
   * 监听SeekTime，用于刷新进度条长度
   * @param duration  当前时长，单位为毫秒（ms）。
   */
  onVodSeekDuration(duration: number) {

  }

  /**
   * 监听setSpeed，表示切换倍速成功。
   * @param speed  当前倍速
   */
  onVodSpeedDone(speed: VHVodPlayerSpeed) {
    promptAction.showToast({
      duration: StyleConstants.PLAY_ERROR_TIME,
      message: '切换倍速成功'
    });
  }

  msToTime(duration: number): string {
    let seconds = Math.floor((duration / 1000) % 60);
    let minutes = Math.floor((duration / (1000 * 60)) % 60);
    let hours = Math.floor((duration / (1000 * 60 * 60)) % 24);

    let hoursStr = (hours < 10) ? "0" + hours : hours.toString();
    let minutesStr = (minutes < 10) ? "0" + minutes : minutes.toString();
    let secondsStr = (seconds < 10) ? "0" + seconds : seconds.toString();

    if (hours > 0) {
      return hoursStr + ":" + minutesStr + ":" + secondsStr;
    } else {
      return minutesStr + ":" + secondsStr;
    }
  }

  /**
   * 监听水印图片加载成功回调
   * @param width   组件宽
   */
  onVHWaterMaskLoadedSucceed() {
    promptAction.showToast({
      duration: StyleConstants.PLAY_ERROR_TIME,
      message: '水印加载成功'
    });
  }

  /**
   * 监听水印图片加载失败回调
   * @param error 失败原因
   */
  onVHWaterMaskLoadedError(error: string) {
    this.vodPlayerModel.setWaterMarkUrl(false);
    promptAction.showToast({
      duration: StyleConstants.PLAY_ERROR_TIME,
      message: '水印加载失败' + error
    });
  }

  onPlayerVolume(volume: number) {
    if (volume === 0) {
      this.isMute = true;
      this.muteText = StyleConstants.PLAY_UN_MUTE;
    } else {
      this.muteText = StyleConstants.PLAY_MUTE;
      this.isMute = false;
      this.volume = volume;
    }
  }

  onPlayerError(error: VHPlayerError) {
    let msg = '[code:' + error.code + ']:' + error.name + ' ';
    switch (error.code) {
      case VHErrorCode.PLAY_STREAM_FAILED:{
        if(this.rePullStreamTimerId){
          clearInterval(this.rePullStreamTimerId);
          this.rePullStreamTimerId = 0;
        }
        this.rePullStreamTimerId = setInterval(() => {
          this.vodPlayerModel.startPlay(this.record_id, this.access_token,this.logReport);
          clearInterval(this.rePullStreamTimerId);
          this.rePullStreamTimerId = 0;
        }, 2000);
        let id = $r('app.string.play_url_error').id;
        let context = getContext(this) as common.UIAbilityContext;
        let str = context.resourceManager.getStringSync(id);
        msg = msg + str;
        break;
      }
      case VHErrorCode.PLAY_TIMEOUT:{
        if(this.rePullStreamTimerId != 0){
          clearInterval(this.rePullStreamTimerId);
          this.rePullStreamTimerId = 0;
        }

        this.rePullStreamTimerId = setInterval(() => {
          clearInterval(this.rePullStreamTimerId);
          this.rePullStreamTimerId = 0;
          this.vodPlayerModel.startPlay(this.record_id, this.access_token,this.logReport);
        }, 2000);
        break;
      }
      case VHErrorCode.PLAY_CURRENT_DEF_FAILED:{
        //如果没有当前清晰度调度，重新播放当前选中的清晰度
        let def = this.getPlayDefinition(this.vhLiveDefText);
        this.vodPlayerModel.changeDefinition(def);
        break;
      }
      case VHErrorCode.DISPATCH_URL_EMPTY:
      case VHErrorCode.PLAY_FORMAT_ERROR:
      case VHErrorCode.NETWORK_ERROR:{
        //如果没有播放调度地址或播放失败，需要应用层根据业务需求判断是否重新拉流。
        if(true){
          if(this.rePullStreamTimerId != 0){
            clearInterval(this.rePullStreamTimerId);
            this.rePullStreamTimerId = 0;
          }

          this.rePullStreamTimerId = setInterval(() => {
            clearInterval(this.rePullStreamTimerId);
            this.rePullStreamTimerId = 0;
            this.vodPlayerModel.startPlay(this.record_id, this.access_token,this.logReport);
          }, 2000);
        }
        break;
      }
      default:
        msg = msg + error.message;
        break;
    }
    promptAction.showToast({
      duration: StyleConstants.PLAY_ERROR_TIME,
      message: msg
    });
  }

  onStatusDidChange(state: VHPlayerStatus) {
    if (state == VHPlayerStatus.PLAYING) {
      promptAction.showToast({
        duration: StyleConstants.PLAY_ERROR_TIME,
        message: '开始播放'
      });
    } else if (state == VHPlayerStatus.PAUSE) {
      promptAction.showToast({
        duration: StyleConstants.PLAY_ERROR_TIME,
        message: '已暂停播放'
      });
    } else if (state == VHPlayerStatus.STOP) {
      promptAction.showToast({
        duration: StyleConstants.PLAY_ERROR_TIME,
        message: '已停止播放'
      });
    } else if (state == VHPlayerStatus.RELEASE) {
      promptAction.showToast({
        duration: StyleConstants.PLAY_ERROR_TIME,
        message: '播放器已释放'
      });
    } else if (state == VHPlayerStatus.COMPLETE) {
      promptAction.showToast({
        duration: StyleConstants.PLAY_ERROR_TIME,
        message: '视频播放完毕'
      });
    } else if (state == VHPlayerStatus.LOADING) {
      promptAction.showToast({
        duration: StyleConstants.PLAY_ERROR_TIME,
        message: '视频加载中'
      });
    }else if(state == VHPlayerStatus.PREPARED){
      this.vodPlayerModel.initPipController(true,'');
    }
  }

  getPlaySpeed(text: string): VHVodPlayerSpeed {
    let def: VHVodPlayerSpeed = VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_1_00_X;
    if (text == StyleConstants.PLAY_SPEED_0_75) {
      def = VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_0_75_X;
    } else if (text == StyleConstants.PLAY_SPEED_1_00) {
      def = VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_1_00_X;
    } else if (text == StyleConstants.PLAY_SPEED_1_25) {
      def = VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_1_25_X;
    } else if (text == StyleConstants.PLAY_SPEED_1_75) {
      def = VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_1_75_X;
    } else if (text == StyleConstants.PLAY_SPEED_2_00) {
      def = VHVodPlayerSpeed.VH_VOD_PLAYER_SPEED_2_00_X;
    }
    return def;
  }

  getPlayDefinition(text: string): VHDefinition {
    let def: VHDefinition = VHDefinition.ORIGIN;
    if (text == '原画') {
      def = VHDefinition.ORIGIN;
    } else if (text == '超高清') {
      def = VHDefinition.UHD;
    } else if (text == '高清') {
      def = VHDefinition.HD;
    } else if (text == '标清') {
      def = VHDefinition.SD;
    } else if (text == '纯音频') {
      def = VHDefinition.AUDIO;
    } else if (text == '裁剪分辨率') {
      def = VHDefinition.CROP_MODE;
    } else if (text == '1080P') {
      def = VHDefinition.FULL_HD;
    }
    return def;
  }

  onValidDefinitions(definitions: VHDefinition[]) {
    this.vhLiveDefinition.splice(0, this.vhLiveDefinition.length);
    for (let index = 0; index < definitions.length; index++) {
      const element: VHDefinition = definitions[index];
      if (element == VHDefinition.ORIGIN) {
        if (this.vodPlayerModel.getCurDefinition() == VHDefinition.ORIGIN) {
          this.vhLiveDefText = '原画';
        }
        this.vhLiveDefinition.push({ value: '原画' });
      } else if (element == VHDefinition.UHD) {
        if (this.vodPlayerModel.getCurDefinition() == VHDefinition.UHD) {
          this.vhLiveDefText = '超高清';
        }
        this.vhLiveDefinition.push({ value: '超高清' });
      } else if (element == VHDefinition.HD) {
        if (this.vodPlayerModel.getCurDefinition() == VHDefinition.HD) {
          this.vhLiveDefText = '高清';
        }
        this.vhLiveDefinition.push({ value: '高清' });
      } else if (element == VHDefinition.SD) {
        if (this.vodPlayerModel.getCurDefinition() == VHDefinition.SD) {
          this.vhLiveDefText = '标清';
        }
        this.vhLiveDefinition.push({ value: '标清' });
      } else if (element == VHDefinition.AUDIO) {
        if (this.vodPlayerModel.getCurDefinition() == VHDefinition.AUDIO) {
          this.vhLiveDefText = '纯音频';
        }
        this.vhLiveDefinition.push({ value: '纯音频' });
      } else if (element == VHDefinition.FULL_HD) {
        if (this.vodPlayerModel.getCurDefinition() == VHDefinition.FULL_HD) {
          this.vhLiveDefText = '1080P';
        }
        this.vhLiveDefinition.push({ value: '1080P' });
      }
    }
  }

  onStreamType(streamType: VHPlayStreamType) {
    if (streamType == VHPlayStreamType.AV_STREAM_TYPE || streamType == VHPlayStreamType.AUDIO_STREAM_TYPE) {
      this.hasAudio = true;
    }
  }

  onVideoFrameSize(width: number, height: number) {

  }

  /**
   * 投屏设备状体事件回调。
   * @param state. 0 设备已准备好可以播放。1：设备已断开
   */
  onCastPlayDeviceState(state: number) {
    this.isCasting = state == 0? true :false;
    if(state == 0) {
     // TaskManager.startContinuousTask(getContext(this) as common.UIAbilityContext);
    }else{
      //TaskManager.stopContinuousTask(getContext(this) as common.UIAbilityContext);

    }
  }
  /**
   * 投屏事件回调。
   * @param state:VHCastPlayState
   */
  onCastPlayState(state: VHCastPlayState) {


  }

  onCastPlayDeviceConnected(device: VHCastPlayDevice){

  }

  /**
   * 投屏播放时长。
   * @param duration:number  播放总时长 ，单位ms
   */
  onCastPlayDuration(duration: number){

  }
  /**
   * 投屏播放当前位置。
   * @param position:number  播放当前进度 ，单位ms
   */
  onCastPlayPosition(position: number) {
    this.onVodCurrentDuration(position);

  }

  /**
   * 投屏操作失败。
   * @param state:VHCastPlayState。执行相关操作失败。包括开播、暂停、设置进度
   */
  onCastPlayError(state: VHCastPlayState) {

  }

  onStateChange(state: AVCastPickerState) {
    if (state == AVCastPickerState.STATE_APPEARING) {
      console.log('The picker starts showing.');
      // 定义一个eventId为1的事件。
      let event: emitter.InnerEvent = {
        eventId: 1
      };
      emitter.emit(event);
    } else if (state == AVCastPickerState.STATE_DISAPPEARING) {
      console.log('The picker finishes presenting.');
    }
  }

  getDownLoadSpeed(speed: number): string {
    let strSpeed = '0 bp/s';
    if (speed < StyleConstants.PLAY_SPEED_BPS) { //
      strSpeed = speed.toString() + 'bp/s';
    } else if (speed >= StyleConstants.PLAY_SPEED_BPS && speed < StyleConstants.PLAY_SPEED_KBPS) {
      speed = speed / StyleConstants.PLAY_SPEED_BPS;
      strSpeed = speed.toFixed(2) + 'kbp/s';
    } else if (speed >= StyleConstants.PLAY_SPEED_KBPS && speed < StyleConstants.PLAY_SPEED_MBPS) {
      speed = speed / StyleConstants.PLAY_SPEED_KBPS;
      strSpeed = speed.toFixed(2) + 'mbp/s';
    } else if (speed >= StyleConstants.PLAY_SPEED_MBPS && speed < StyleConstants.PLAY_SPEED_GBPS) {
      speed = speed / StyleConstants.PLAY_SPEED_MBPS;
      strSpeed = speed.toFixed(2) + 'gbp/s';
    }
    return strSpeed;
  }

  async copyPixelMap(pm: PixelMap): Promise<PixelMap> {
    const imageInfo: image.ImageInfo = await pm.getImageInfo();
    const buffer: ArrayBuffer = new ArrayBuffer(pm.getPixelBytesNumber());
    // TODO 知识点：通过readPixelsToBuffer实现PixelMap的深拷贝，其中readPixelsToBuffer输出为BGRA_8888
    await pm.readPixelsToBuffer(buffer);
    // TODO 知识点：readPixelsToBuffer输出为BGRA_8888,此处createPixelMap需转为RGBA_8888
    const opts: image.InitializationOptions = {
      editable: true,
      pixelFormat: image.PixelMapFormat.RGBA_8888,
      size: { height: imageInfo.size.height, width: imageInfo.size.width }
    };
    return await image.createPixelMap(buffer, opts);
  }

  @Builder
  VHLivePlayCtl() {
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start }) {
      Button($r('app.string.pause')).onClick(() => {
        this.vodPlayerModel.pausePlay();
        this.vodPlayerModel.updatePipControlStatus(VHPlayerPipControlPanelStatus.CONTROL_PAUSE);
      })
      Button($r('app.string.resume')).onClick(() => {
        this.vodPlayerModel.resumePlay();
        this.vodPlayerModel.updatePipControlStatus(VHPlayerPipControlPanelStatus.CONTROL_PLAY);
      })

      Button($r('app.string.stop')).onClick(() => {
        this.vodPlayerModel.stopPlay();
      })
      Button($r('app.string.start_play')).onClick(() => {
        this.documentViews.splice(0, this.documentViews.length);
        this.document.initVodDoc(this.record_id, this.access_token,this);
        this.vodPlayerModel.startPlay(this.record_id, this.access_token,this.logReport);
      })
      AVCastPicker({
        customPicker: (): void => this.componentBuilder(),
        normalColor: Color.Black,
        onStateChange: this.onStateChange
      })
        .width('40vp')
        .height('40vp')
    }

    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start }) {
      Button($r('app.string.destory')).onClick(() => {
        try {
          router.back({
            url: 'pages/Index',
          })
        } catch (err) {
          console.error(`pushUrl failed, code is ${(err as BusinessError).code}, message is ${(err as BusinessError).message}`);
        }
      })
      Row() {
        Select(this.scalingArray)
          .onSelect((index: number, text?: string | undefined) => {
            console.info('Select:' + index)
            this.scalingText = text as string;
            this.scalingIndex = index;
            if (index == 0) {
              this.vodPlayerModel.setPlayerScalingMode(VHPlayerScalingMode.FILL);
            } else if (index == 1) {
              this.vodPlayerModel.setPlayerScalingMode(VHPlayerScalingMode.ASPECT_FIT);
            } else if (index == 2) {
              this.vodPlayerModel.setPlayerScalingMode(VHPlayerScalingMode.ASPECT_FILL);
            }
          }).value(this.scalingText).selected(this.scalingIndex)

        Select(this.vhLiveDefinition)
          .onSelect((index: number, text?: string | undefined) => {
            console.info('Select:' + index)
            this.vhLiveDefText = text as string;
            this.vhLiveDefIndex = index;
            let def = this.getPlayDefinition(this.vhLiveDefText);
            this.vodPlayerModel.changeDefinition(def);
          }).value(this.vhLiveDefText).selected(this.vhLiveDefIndex)
      }
    }

    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start }) {
      Button($r('app.string.enable_water_mask')).onClick(() => {
        this.vodPlayerModel.setWaterMarkUrl(true, this.userWaterMarkUrl);
      })
      Button($r('app.string.disable_water_mask')).onClick(() => {
        this.vodPlayerModel.setWaterMarkUrl(false);
      })
      Select(this.waterPos)
        .onSelect((index: number, text?: string | undefined) => {
          console.info('Select:' + index)
          this.waterPText = text as string;
          this.waterPIndex = index;
          if (index == 0) {
            this.waterMarkLocation.position = WaiterMaskPostion.LEFT_TOP;
          } else if (index == 1) {
            this.waterMarkLocation.position = WaiterMaskPostion.RIGHT_TOP;
          } else if (index == 2) {
            this.waterMarkLocation.position = WaiterMaskPostion.LET_BOTTOM;
          } else if (index == 3) {
            this.waterMarkLocation.position = WaiterMaskPostion.RIGHT_BOTTOM;
          }
          this.vodPlayerModel.setWaterMarkLocation(this.waterMarkLocation);
        })
        .value(this.waterPText)
        .selected(this.vhLiveDefIndex)
        .alignSelf(ItemAlign.End)
        .align(Alignment.End)

      TextInput({ placeholder: $r("app.string.water_url"), text: this.userWaterMarkUrl })
        .onChange((value: string) => {
          this.userWaterMarkUrl = value;
        }).width(StyleConstants.WATERMARK_InputWidth)

    }

    if (this.hasAudio) {
      Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceEvenly }) {
        Slider({
          min: 0.0,
          max: 1.0,
          step: 0.01,
          value: this.isMute ? 0 : this.volume
        })
          .onChange((value: number, mode: SliderChangeMode) => {
            this.vodPlayerModel.setPlayerVolume(value);

          })

        Button(this.muteText).onClick(() => {
          if (this.isMute) {
            if (this.vodPlayerModel.setMute(false) == VHErrorCode.OK) {
              this.isMute = false;
            }
          } else {
            if (this.vodPlayerModel.setMute(true) == VHErrorCode.OK) {
              this.isMute = true;
            }
          }
        })

      }
    }

    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
      Select(this.speedSelect)
        .onSelect((index: number, text?: string | undefined) => {
          console.info('Select:' + index)
          this.speedText = text as string;
          this.speedIndex = index;
          let def = this.getPlaySpeed(this.speedText);
          this.vodPlayerModel.setPlayerSpeed(def);

        }).value(this.speedText).selected(this.speedIndex).alignSelf(ItemAlign.End)

      SaveButton({ text: SaveDescription.SAVE_IMAGE })
        .onClick(async () => {
          try {
            let pixmap = await this.vodPlayerModel.getVideoFrame();
            try {
              const imagePackerApi = image.createImagePacker();
              let packOpts: image.PackingOption = { format: "image/jpeg", quality: 98 };
              let data = await imagePackerApi.packing(pixmap, packOpts);
              let context = getContext();
              let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
              let uri = await phAccessHelper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg');
              const file = await fs.open(uri, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
              let len = await fs.write(file.fd, data);
              await fs.close(file.fd);
            } catch (error) {
              this.onPlayerError(error);
            }
          } catch (error) {
            this.onPlayerError(error);
          }
        })

      Button($r('app.string.start_pip')).onClick(() => {
        this.vodPlayerModel.startPiP();
      })
      Button($r('app.string.stop_pip')).onClick(() => {
        this.vodPlayerModel.stopPip();
      })
    }


    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Center }) {
      Text(this.currentTime).width(StyleConstants.PLAY_TIME);
      Slider({ step: 1, value: this.currentDuration })
        .onChange((value: number, mode: SliderChangeMode) => {
          if( this.isCasting){
            let seekTime = value * this.totalDuration / 100;
            this.vodPlayerModel.SeekCastPlay(seekTime);
          }
          else{
            let seekTime = value * this.totalDuration / 100;
            this.vodPlayerModel.setPlayerSeek(seekTime);
          }
        })
      Text(this.totalTime).width(StyleConstants.PLAY_TIME);
      Text('循环').width(StyleConstants.PLAY_LOOP_TEXT_WIDHT);
      Checkbox({ name: '循环' }).onChange(value => {
        this.vodPlayerModel.setPlayLoop(value);
      })
    }
  }

  @Builder
  componentBuilder() {
    Image($r('app.media.icon'))
      .width('40vp')
      .height('40vp')
  }


  @Builder
  documentViewBuilder() {
    Tabs({ barPosition: BarPosition.Start, controller: this.controller }) {
      //documentViews 数组为顺序添加到队列中的，通过@State修饰后，如果队列发生改变(添加或移除)，会重新刷新tab。因此tab中的index和documentViews中的index为对应的关系。
      ForEach(this.documentViews, (doc: VHDocument, index: number) => {
        TabContent() {
          VHDocumentView({ vhDocInterface: this, vhDocument: doc, demonstrateProgress: true })
            .width('100%')
            .height('100%')
            .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
              //添加到控件内，根据控件大小重置文档的渲染大小
              doc.setDocumentViewSize(newValue.width as number, newValue.height as number);
            })
        }
        .tabBar(this.tabBuilder(doc, index))
      }, (doc: VHDocument, index: number) => {
        //this.selectCid 发生改变时刷新文档当前页。
        if (this.selectCid == doc.documentViewModel.cid) {
          if(this.selectDocument != 0){
            clearInterval(this.selectDocument);
            this.selectDocument = 0;
          }
          this.selectDocument = setInterval(() => {
            this.controller.changeIndex(index);
            if(this.selectDocument != 0){
              clearInterval(this.selectDocument);
              this.selectDocument = 0;
            }
          }, 100);
        }
        return doc.documentViewModel.cid;
      })
    }
    .barHeight(0) //可通过设置此参数隐藏tab
    .animationDuration(0)
    .backgroundColor('#ffd7ecb3')
    .height('30%')
    .opacity(this.showDoc == true ? 100 : 0)
    .scrollable(false)
  }

  build() {
    Column({ space: StyleConstants.COLUMN_SPACE }) {
      Navigation().title(this.NavigationTitle).width(StyleConstants.FULL_HEIGHT).height('5%')
      Column() {
        Stack({ alignContent: Alignment.TopEnd }) {
          // 播放器容器
          VHVodPlayerView({ componentListener: this, vodPlayer: this.vodPlayerModel })
            .width(StyleConstants.FULL_WIDTH)
            .height(this.playLandSpaceMode ? StyleConstants.FULL_HEIGHT : StyleConstants.VH_PLAYER_NORMAL_HEIGHT)
            .backgroundColor(Color.Black)
            .align(Alignment.Center)
            .zIndex(1)
          Row(){
            Button($r('app.string.player_landspace')).onClick(() => {
              let windowStage: window.WindowStage = AppStorage.get('windowStage') as window.WindowStage;
              windowStage.getMainWindowSync().setPreferredOrientation(window.Orientation.LANDSCAPE);
              this.playLandSpaceMode = true;
            })
            Button($r('app.string.play_portrait')).onClick(() => {
              let windowStage: window.WindowStage = AppStorage.get('windowStage') as window.WindowStage;
              windowStage.getMainWindowSync().setPreferredOrientation(window.Orientation.PORTRAIT);
              this.playLandSpaceMode = false;
            })

          }.zIndex(2)

          Column() {
            Row() {
              Button("停止投屏")
                .fontColor(Color.White)
                .backgroundColor('#333333')
                .onClick(() => {
                  this.vodPlayerModel.StopCastPlay();
                })
                .margin({
                  left: '12vp',
                  right: '12vp'
                })
            }
            .justifyContent(FlexAlign.Center)
            .width('100%')
          }
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Color.Black)
          .width(StyleConstants.FULL_WIDTH)
          .height(this.playLandSpaceMode ? StyleConstants.FULL_HEIGHT : StyleConstants.VH_PLAYER_NORMAL_HEIGHT)
          .zIndex(this.isCasting ? 3 : 0)
        }
        this.documentViewBuilder();
        this.VHLivePlayCtl();
      }
    }
    .alignItems(HorizontalAlign.Center)
    .height(StyleConstants.FULL_HEIGHT)
    .padding({
      top: 0,
      left: 8,
      bottom: 0,
      right: 8
    })
  }

  @Builder
  tabBuilder(model: VHDocument, targetIndex: number) {
    Column() {
      Text(model.documentViewModel.cid)
        .fontColor(Color.White)
        .margin({ top: 17, bottom: 7 })
    }.backgroundColor(this.currentDocumentIndex === targetIndex ? '#ff3ece16' : '#ffcbd9d9')
  }
}