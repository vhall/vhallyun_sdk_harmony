import { VHLivePlayer, VHLivePlayerView, VHPlayerStatus, VHDefinition, VHWaterMarkLocation,
  VHCastPlayState ,  VHPlayerScalingMode,
  WaiterMaskPostion,
  VHPlayStreamType,
  VHErrorCode,
  VHPlayerError,
  VHPlayerPipStatus,
  VHPlayerPipControlPanelStatus,
  VHCastPlayMediaSource,
  VHCastPlayDevice
} from '@vhall/vhallyun-lss-vod'
import { promptAction, router, window } from '@kit.ArkUI';
import StyleConstants from '../common/constants/StyleConstants';
import {logData} from '../common/constants/StyleConstants';
import { BusinessError } from '@ohos.base';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import {
  VHDocFilType,
  VHDocument,
  VHDocumentPageModel,
  VHDocumentView,
  VHDocumentViewModel,
  VHDocumentWaterMark
} from '@vhall/vhallyun-doc';
import { AVCastPicker, AVCastPickerState } from '@kit.AVSessionKit';
import { TaskManager } from '../common/utils/TaskUitl';
import { VHIM, VHIMInterface } from '@vhall/vhallyun-ims';

import bundleManager from '@ohos.bundle.bundleManager';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer } from '@kit.ArkTS';
import { VHAppInfo, VHMessage } from '@vhall/vhallyun-framework';

@Builder
export function LiveBuilder(name: string, param: object) {
  Live({ lss_id: param['lss_id'], access_token: param['access_token'], user_id: param['userid'], channel_id: param['channel_id']})
}
@Entry
@Component
struct Live {
  imConnectTimer: number = -1;
  livePlayerModel: VHLivePlayer = new VHLivePlayer(getContext(this));
  @State photoAccessHelper: photoAccessHelper.PhotoAccessHelper | undefined = undefined; // 相册模块管理实例
  @State livePlayCreate: boolean = false;
  // 获取上个界面传递过来的房间号
  params: object = router.getParams() as object;
  public lss_id: string = '';//this.params['lss_id'];
  public access_token: string = '';//this.params['access_token'];
  public channel_id: string ='';// this.params['channel_id'];
  public user_id:string = '';//this.params['userid'];
  private isFirstShow: boolean = true;
  @State isCasting :boolean = false;
  /**
   * 页面退到后台前获取播放状态，用于回到前台进行播放判断。
   * **/
  private playState: VHPlayerStatus = VHPlayerStatus.INIT;
  pageInfos: NavPathStack = new NavPathStack() // 导航
  //文档水印参数
  private docWaterMark: VHDocumentWaterMark = new VHDocumentWaterMark('hello world', 20);
  //判断视频显示音频控件
  @State hasAudio: boolean = false;
  //视频缩放模式
  @State scalingArray: Array<SelectOption> = [];
  @State scalingText: string = StyleConstants.PLAY_AspectFit;
  @State scalingIndex: number = 0;
  @State userWaterMarkUrl: string = 'https://cnstatic01.e.vhall.com/upload/common/static-imgs/c0/e7/c0e7569408de296971eb4b98945c240b.png';
  @State vhLiveDefText: string = '原画';
  @State vhLiveDef: Array<VHDefinition> = [];
  @State vhLiveDefIndex: number = 0;
  private imBase: VHIM = new VHIM();
  //播放清晰度
  @State vhLiveDefinition: Array<SelectOption> = [{ value: '原画' }];
  @State waterMarkLocation: VHWaterMarkLocation = new VHWaterMarkLocation();
  private rePullStreamTimerId: number = 0;
  private selectDocument: number = 0;
  @State waterPos: Array<SelectOption> = [{ value: '左上' }, { value: '右上' }, { value: '左下' }, { value: '右下' }];
  @State waterPText: string = '左上';
  @State waterPIndex: number = 0;
  @State playLandSpaceMode: boolean = false;
  @State isMute: boolean = false;
  @State muteText: string = StyleConstants.PLAY_MUTE;
  @State volume: number = 1.0;
  @State documentViews: Array<VHDocument> = new Array();
  private document: VHDocument = new VHDocument(new VHDocumentViewModel(VHDocFilType.DOC));
  private controller: TabsController = new TabsController()
  @State selectCid: string = '';
  @State showDoc: boolean = true;
  private logReport:object = [];
  private source: VHCastPlayMediaSource |undefined = undefined;


  public static uint8ArrayToHexStr(data: Uint8Array): string {
    let hexString = '';
    let i: number;
    for (i = 0; i < data.length; i++) {
      let char = ('00' + data[i].toString(16)).slice(-2);
      hexString += char;
    }
    console.info('Uint8Array转十六进制:' + hexString);
    return hexString;
  }


  public static async getVersionName(): Promise<string> {
    try {
      let bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION| bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_SIGNATURE_INFO);
      let sign = bundleInfo.signatureInfo;
      let cer = sign.certificate?.toString();
      let certBody = cer?.replace('-----BEGIN CERTIFICATE-----', '').replace('-----END CERTIFICATE-----', '').replace(/\s+/g, ''); // 移除所有空白字符
      let md = cryptoFramework.createMd('MD5');
      // 数据量较少时，可以只做一次update，将数据全部传入，接口未对入参长度做限制。
      await md?.update({ data: new Uint8Array(buffer.from(sign.fingerprint, 'utf-8').buffer) });
      let mdResult = await md.digest();
      let hexString = '';
      let i: number = 0;
      for (i = 0; i < mdResult.data.length; i++) {
        let char = ('00' + mdResult.data[i].toString(16)).slice(-2);
        hexString += char;
      }
      return hexString;
    } catch (error) {

    }
    return "";
  }

  aboutToAppear(): void {
    this.source = {
      title:'我的回放',
      name:'微吼直播',
      description:'当前播放为回放视频',
      headImage:"https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fsafe-img.xhscdn.com%2Fbw1%2F2eb3e4c4-d619-4657-90c6-a535c40f8096%3FimageView2%2F2%2Fw%2F1080%2Fformat%2Fjpg&refer=http%3A%2F%2Fsafe-img.xhscdn.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1755311692&t=f5126cbadc7bae9845f367c33ea72fa2"
    };
    this.livePlayerModel.initCastPlay(this.source);
    this.livePlayerModel.setVHLivePlayerInterface(this);
    this.initScalingMode();
    // this.document.setVHDocInterface(this);
    //初始化直播文档，进行消息监听
    this.imBase.init(this.channel_id, this.access_token);
    this.imBase.setVHIMInterface(this)
    this.document.initLiveDoc(this.lss_id, this.channel_id, this.access_token, true,this)
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
    // 将对象转换为 JSON 字符串
    let jsonString = JSON.stringify(data);
    this.logReport['report_extra'] = jsonString;
    this.logReport['sz_t'] = 1;
    VHAppInfo.getInstance().report_extra = jsonString;
    let t = Live.getVersionName();
  }



  aboutToDisappear(): void {
    this.imBase.closeMsg();
    this.livePlayerModel.destroyPlayer();
    //释放文档
    this.document.destroyDoc();
    if(this.rePullStreamTimerId != 0){
      clearInterval(this.rePullStreamTimerId);
      this.rePullStreamTimerId = 0;
    }

  }

    imSDKReceiveChatMessage (im: VHIM, message: VHMessage): void {
      throw new Error('Function not implemented.');
    }
    imSDKReceiveOnlineMessage (im: VHIM, message: VHMessage): void {
      throw new Error('Function not implemented.');
    }
    imSDKReceiveCustomMessage (im: VHIM, message: VHMessage): void  {
      throw new Error('Function not implemented.');
    }
    imSDKReceiveRoomMessage (im: VHIM, message: VHMessage): void  {
      throw new Error('Function not implemented.');
    }
    imSDKError (im: VHIM, code: number, errorMsg: string): void {
      throw new Error('Function not implemented.');
    }
    onNetworkConnect (): void  {
      console.log("onNetworkConnect","onNetworkConnect")
    }
    onNetworkDisconnect (code: number, message: string): void  {
      if (this.imConnectTimer != -1) {
        return;
      }
      //启用定时器进行重连。
      this.imConnectTimer = setTimeout(() => {
        //重连只需要重新调用join方法
        this.imBase.init(this.channel_id, this.access_token);
        this.imConnectTimer = -1;
      }, 3000);
    }
    onNetworkConnecting (): void {
      throw new Error('Function not implemented.');
    }
    imSDKForbidden (im: VHIM, forbidden: boolean): void  {
      throw new Error('Function not implemented.');
    }
    imSDKForbiddenAll (im: VHIM, forbiddenAll: boolean): void {
      throw new Error('Function not implemented.');
    }

  // 页面初次加载的时候
  onPageShow(): void {
    if (this.isFirstShow) {
      this.isFirstShow = false;
    } else {
      //退到后台时如果播放器处于播放状态，将变为pause状态。重新进入进行恢复
      if (this.playState == VHPlayerStatus.PLAYING) {
        this.livePlayerModel.resumePlay();
      }
    }
  }

  onPageHide(): void {
    this.playState = this.livePlayerModel.getPlayerState();
    if(!this.isCasting){
      this.livePlayerModel.pausePlay();
    }
  }

  onPipControlPanelStatusChange(state:VHPlayerPipControlPanelStatus){
    switch (state){
      case VHPlayerPipControlPanelStatus.CONTROL_PAUSE:
        this.livePlayerModel.pausePlay();
        break;
      case VHPlayerPipControlPanelStatus.CONTROL_PLAY:
        this.livePlayerModel.resumePlay();
        break;
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

  onFailure(errorCode: number, errorMsg: string) {

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
  docChangePage(docViewModel: VHDocumentPageModel): void {

  }

  /**
   * 选择文档
   * @param documentView 文档视图
   */
  docSelect(cid: string): void {
    this.selectCid = cid;
  }

  /**
   * 投屏设备状体事件回调。
   * @param state. 0 设备已准备好可以播放。1：设备已断开
   */
  onCastPlayDeviceState(state: number) {
    this.isCasting = state == 0? true :false;
    if(state == 0) {
      TaskManager.startContinuousTask(getContext(this) as common.UIAbilityContext);
    }else{
      TaskManager.stopContinuousTask(getContext(this) as common.UIAbilityContext);

    }
  }
  /**
   * 投屏事件回调。
   * @param state:VHCastPlayState
   */
  onCastPlayState(state: VHCastPlayState) {

  }
  /**
   * 投屏播放时长。
   * @param duration:number  播放总时长 ，单位ms
   */
  onCastPlayDuration(duration: number) {


  }
  /**
   * 投屏播放当前位置。
   * @param position:number  播放当前进度 ，单位ms
   */
  onCastPlayPosition(position: number) {


  }
  onCastPlayDeviceConnected(device: VHCastPlayDevice){

  }
  /**
   * 投屏操作失败。
   * @param state:VHCastPlayState。执行相关操作失败。包括开播、暂停、设置进度
   */
  onCastPlayError(state: VHCastPlayState) {

  }


  setTabSelectDocumentByCid(cid: string) {
    for (let index = 0; index < this.documentViews.length; index++) {
      const element = this.documentViews[index].documentViewModel
      if (element?.cid == cid) {
        // this.controller.changeIndex(index);
      }
    }
  }

  /**
   * 添加文档
   * @param documentView 文档视图
   */

  docAdd(docViewModel: VHDocumentViewModel): void {
    if (!this.isExistDocument(docViewModel.cid)) {
      let document: VHDocument = new VHDocument(docViewModel);
      docViewModel.getLastData = true;
      this.insertDocumentItem(document);
    }
  }

  /**
   * 删除文档
   * @param documentView 文档视图
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

  /**
   * @description 文档加载完成
   * @param documentView   文档id 为空时没有 文档
   */
  docViewLoadEnd(doc: VHDocument){

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

  // 封装NavigationTitle
  @Builder
  NavigationTitle() {
    Text('直播界面')
      .fontColor($r('app.color.title_text_color'))
      .fontSize($r('app.float.title_font_size'))
      .lineHeight($r('app.float.nav_size_height'))
  }

  initScalingMode() {
    let modes: Array<VHPlayerScalingMode> = this.livePlayerModel.getPlayerScalingMode()
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
      if (this.livePlayerModel.getCurrentScalingMode() == VHPlayerScalingMode.FILL) {
        this.scalingIndex = 0;
        this.scalingText = StyleConstants.PLAY_Fill;
      }
      if (this.livePlayerModel.getCurrentScalingMode() == VHPlayerScalingMode.ASPECT_FIT) {
        this.scalingIndex = 1;
        this.scalingText = StyleConstants.PLAY_AspectFit;
      }
      if (this.livePlayerModel.getCurrentScalingMode() == VHPlayerScalingMode.ASPECT_FILL) {
        this.scalingIndex = 2;
        this.scalingText = StyleConstants.PLAY_AspectFill;
      }
    }
  }

  /**
   * 组件加载成功
   */
  onVHPlayerViewLoaded() {
    // 初次进入调用播放
    this.livePlayerModel.startPlay(this.lss_id, this.access_token,VHDefinition.ORIGIN);
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
    this.livePlayerModel.setWaterMarkUrl(false);
    promptAction.showToast({
      duration: StyleConstants.PLAY_ERROR_TIME,
      message: '水印加载失败' + error
    });
  }

  /**
   * 画中画状态
   */
  onPipStatusChange(state: VHPlayerPipStatus) {
    if (state == VHPlayerPipStatus.STOP) {
      this.livePlayerModel.destroyPlayer()
      this.livePlayerModel.setPlayerScalingMode(VHPlayerScalingMode.ASPECT_FILL)
    }
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
        if(this.rePullStreamTimerId != 0){
          clearInterval(this.rePullStreamTimerId);
          this.rePullStreamTimerId = 0;
        }
        this.rePullStreamTimerId = setInterval(() => {
          let def = this.getPlayDefinition(this.vhLiveDefText);
          this.livePlayerModel.startPlay(this.lss_id, this.access_token,def);
          if(this.rePullStreamTimerId){
            clearInterval(this.rePullStreamTimerId);
            this.rePullStreamTimerId = 0;
          }
        }, 2000);
        let id = $r('app.string.play_url_error').id;
        let context = getContext(this) as common.UIAbilityContext;
        let str = context.resourceManager.getStringSync(id);
        msg = msg + str;
        break;
      }
      case VHErrorCode.PLAY_TIMEOUT:{
        if(this.rePullStreamTimerId){
          clearInterval(this.rePullStreamTimerId);
          this.rePullStreamTimerId = 0;
        }
        this.rePullStreamTimerId = setInterval(() => {
          let def = this.getPlayDefinition(this.vhLiveDefText);
          this.livePlayerModel.startPlay(this.lss_id, this.access_token,def);
          if(this.rePullStreamTimerId){
            clearInterval(this.rePullStreamTimerId);
            this.rePullStreamTimerId = 0;
          }
        }, 2000);
        let playTimeout = $r('app.string.play_timeout').id;
        let cont = getContext(this) as common.UIAbilityContext;
        let strMsg = cont.resourceManager.getStringSync(playTimeout);
        msg = msg + strMsg;
        break;
      }
      case VHErrorCode.PLAY_CURRENT_DEF_FAILED:{
        //如果没有当前清晰度调度，重新播放当前选中的清晰度
        let def = this.getPlayDefinition(this.vhLiveDefText);
        this.livePlayerModel.changeDefinition(def);
        break;
      }
      case VHErrorCode.DISPATCH_URL_EMPTY:
      case VHErrorCode.PLAY_FORMAT_ERROR:
      case VHErrorCode.NETWORK_ERROR:{
        //如果没有播放调度地址或播放失败，需要应用层根据业务需求判断是否重新拉流。
        if(true){
          if(this.rePullStreamTimerId){
            clearInterval(this.rePullStreamTimerId);
            this.rePullStreamTimerId = 0;
          }
          this.rePullStreamTimerId = setInterval(() => {
            this.livePlayerModel.startPlay(this.lss_id, this.access_token,VHDefinition.ORIGIN);
            if(this.rePullStreamTimerId){
              clearInterval(this.rePullStreamTimerId);
              this.rePullStreamTimerId = 0;
            }
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
      this.livePlayerModel.setPlayerScalingMode(VHPlayerScalingMode.ASPECT_FILL)
    } else if (state == VHPlayerStatus.PAUSE) {
      promptAction.showToast({
        duration: StyleConstants.PLAY_ERROR_TIME,
        message: '已暂停播放'
      });
    } else if (state == VHPlayerStatus.COMPLETE) {
      promptAction.showToast({
        duration: StyleConstants.PLAY_ERROR_TIME,
        message: '播放完毕'
      });
      //直播状态如果远端停止推流，会触发此事件。应用层根据业务判断是否重新拉流。
      if(true){
        this.livePlayerModel.startPlay(this.lss_id, this.access_token,VHDefinition.ORIGIN);
      }
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
    } else if (state == VHPlayerStatus.LOADING) {
      promptAction.showToast({
        duration: StyleConstants.PLAY_ERROR_TIME,
        message: '视频加载中'
      });
    }else if(state == VHPlayerStatus.PREPARED){
      this.livePlayerModel.initPipController(true,'');
    }
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
        if (this.livePlayerModel.getCurDefinition() == VHDefinition.ORIGIN) {
          this.vhLiveDefText = '原画';
        }
        this.vhLiveDefinition.push({ value: '原画' });
      } else if (element == VHDefinition.UHD) {
        if (this.livePlayerModel.getCurDefinition() == VHDefinition.UHD) {
          this.vhLiveDefText = '超高清';
        }
        this.vhLiveDefinition.push({ value: '超高清' });
      } else if (element == VHDefinition.HD) {
        if (this.livePlayerModel.getCurDefinition() == VHDefinition.HD) {
          this.vhLiveDefText = '高清';
        }
        this.vhLiveDefinition.push({ value: '高清' });
      } else if (element == VHDefinition.SD) {
        if (this.livePlayerModel.getCurDefinition() == VHDefinition.SD) {
          this.vhLiveDefText = '标清';
        }
        this.vhLiveDefinition.push({ value: '标清' });
      } else if (element == VHDefinition.AUDIO) {
        if (this.livePlayerModel.getCurDefinition() == VHDefinition.AUDIO) {
          this.vhLiveDefText = '纯音频';
        }
        this.vhLiveDefinition.push({ value: '纯音频' });
      } else if (element == VHDefinition.FULL_HD) {
        if (this.livePlayerModel.getCurDefinition() == VHDefinition.FULL_HD) {
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

  @Builder
  componentBuilder() {
    Image($r('app.media.icon'))
      .width('40vp')
      .height('40vp')
  }

  private onStateChange(state: AVCastPickerState) {
    if (state == AVCastPickerState.STATE_APPEARING) {
      console.log('The picker starts showing.');
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

  @Builder
  VHLivePlayCtl() {
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start }) {
      Button($r('app.string.pause')).onClick(() => {
        this.livePlayerModel.pausePlay();
      })
      Button($r('app.string.resume')).onClick(() => {
        this.livePlayerModel.resumePlay();
      })

      Button($r('app.string.stop')).onClick(() => {
        this.livePlayerModel.stopPlay();
      })
      Button($r('app.string.start_play')).onClick(() => {
        this.livePlayerModel.startPlay(this.lss_id, this.access_token,VHDefinition.ORIGIN);
      })
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
              this.livePlayerModel.setPlayerScalingMode(VHPlayerScalingMode.FILL);
            } else if (index == 1) {
              this.livePlayerModel.setPlayerScalingMode(VHPlayerScalingMode.ASPECT_FIT);
            } else if (index == 2) {
              this.livePlayerModel.setPlayerScalingMode(VHPlayerScalingMode.ASPECT_FILL);
            }
          }).value(this.scalingText).selected(this.scalingIndex)

        Select(this.vhLiveDefinition)
          .onSelect((index: number, text?: string | undefined) => {
            console.info('Select:' + index)
            this.vhLiveDefText = text as string;
            this.vhLiveDefIndex = index;

            let def = this.getPlayDefinition(this.vhLiveDefText);
            this.livePlayerModel.changeDefinition(def);

          }).value(this.vhLiveDefText).selected(this.vhLiveDefIndex)
      }
    }

    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceEvenly, alignItems: ItemAlign.Center }) {
      SaveButton({ text: SaveDescription.SAVE_IMAGE })
        .onClick(async () => {
          try {
            let pixmap = await this.livePlayerModel.getVideoFrame();
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
        let ret = this.livePlayerModel.startPiP();
        if(ret != 0){
          promptAction.showToast({
            duration: StyleConstants.PLAY_ERROR_TIME,
            message: '画中画播放失败：' + ret
          });
        }
      })
      Button($r('app.string.stop_pip')).onClick(() => {
        this.livePlayerModel.stopPip();
      })
    }

    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.Start }) {
      Button($r('app.string.enable_water_mask')).onClick(() => {
        this.livePlayerModel.setWaterMarkUrl(true, this.userWaterMarkUrl);
      })
      Button($r('app.string.disable_water_mask')).onClick(() => {
        this.livePlayerModel.setWaterMarkUrl(false);

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
          this.livePlayerModel.setWaterMarkLocation(this.waterMarkLocation);
        }).value(this.waterPText).selected(this.vhLiveDefIndex)

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
            this.livePlayerModel.setPlayerVolume(value);

          })
        Button(this.muteText).onClick(() => {
          if (this.isMute) {
            if (this.livePlayerModel.setMute(false) == VHErrorCode.OK) {
              this.isMute = false;
            }
          } else {
            if (this.livePlayerModel.setMute(true) == VHErrorCode.OK) {
              this.isMute = true;
            }
          }
        })
      }
    }
  }

  @Builder
  tabBuilder(model: VHDocument, targetIndex: number) {
    Column() {
      Text(model.documentViewModel.cid)
        .fontColor(Color.White)
        .margin({ top: 17, bottom: 7 })
    }.backgroundColor('#ffcbd9d9')
  }

  @Builder
  documentViewBuilder() {
    Button("还原").onClick((event: ClickEvent) => {
      for (let index = 0; index < this.documentViews.length; index++) {
        const element = this.documentViews[index] as VHDocument;
        element.zoomReset()
      }
    })
    Tabs({ barPosition: BarPosition.Start, controller: this.controller }) {
      ForEach(this.documentViews, (doc: VHDocument, index: number) => {
        TabContent() {
          if(this.showDoc == true){
            VHDocumentView({ vhDocInterface: this, vhDocument: doc, demonstrateProgress: doc.documentViewModel.getLastData })
              .width('100%')
              .height('100%')
              .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
                //添加到控件内，根据控件大小重置文档的渲染大小
                doc.setDocumentViewSize(newValue.width as number, newValue.height as number);
              })
          }

        }.tabBar(this.tabBuilder(doc, index))
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
    // .opacity(this.showDoc == true ? 100 : 0)//通过设置透明度来显示和隐藏
    .animationDuration(0)
    .backgroundColor('#ffd7ecb3')
    .height('60%')
    .scrollable(false)
  }

  build() {
    NavDestination(){
      Column({ space: StyleConstants.COLUMN_SPACE }) {
        Navigation().title(this.NavigationTitle).width(StyleConstants.FULL_HEIGHT).height('5%')
        Column() {
          Stack({ alignContent: Alignment.TopEnd }) {
            // 播放器容器
            VHLivePlayerView({ componentListener: this, livePlayer: this.livePlayerModel})
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
              AVCastPicker({
                customPicker: (): void => this.componentBuilder(),
                normalColor: Color.Black,
                onStateChange: this.onStateChange
              })
                .width('40vp')
                .height('40vp')
            }.align(Alignment.TopEnd)
            .zIndex(2)

            Column() {
              Row() {
                Button("停止投屏")
                  .fontColor(Color.White)
                  .backgroundColor('#333333')
                  .onClick(() => {
                    this.livePlayerModel.StopCastPlay();
                  })
                  .margin({
                    left: '12vp',
                    right: '12vp'
                  })
              }
              .justifyContent(FlexAlign.Center)
              .width('50%')
              .zIndex(this.isCasting ? 3 : 0)
            }
            .justifyContent(FlexAlign.Center)
            .backgroundColor(Color.Black)
            .width(StyleConstants.FULL_WIDTH)
            .height(this.playLandSpaceMode ? StyleConstants.FULL_HEIGHT : StyleConstants.VH_PLAYER_NORMAL_HEIGHT)
            .zIndex(this.isCasting ? 3 : 0)
          }
          Stack(){

          }
          // this.documentViewBuilder();
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
    }.onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    }).hideBackButton(true)
    .id('VHLiveWatch')

  }
}