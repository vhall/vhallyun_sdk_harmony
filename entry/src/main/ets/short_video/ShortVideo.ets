import { VHVodPlayer, VHVodPlayerView, VHPlayerStatus, VHDefinition, VHCastPlayState,
  VHCastPlayMediaSource,VHCastPlayDevice,  VHPlayerScalingMode,
  WaiterMaskPostion,
  VHPlayerPipStatus,
  VHPlayerPipControlPanelStatus,
  VHPlayStreamType,
  VHErrorCode,
  VHPlayerError,
  VHVodPlayerSpeed,
  VHWaterMarkLocation,
  VHLivePlayer} from '@vhall/vhallyun-lss-vod'
import { promptAction, router, UIUtils, window } from '@kit.ArkUI';
import StyleConstants from '../common/constants/StyleConstants';
import {logData} from '../common/constants/StyleConstants';
import { BusinessError } from '@ohos.base';
import { common, wantAgent } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import {VodShortPlayer} from './VodShortPlayer'
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
import { bundleManager } from '@kit.AbilityKit';
import { AVCastPicker, AVCastPickerState } from '@kit.AVSessionKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { TaskManager } from '../common/utils/TaskUitl';
import { emitter } from '@kit.BasicServicesKit';
import { PlayContact, PlayInfoSource } from './PlayInfo';
import { Logger } from '@vhall/vhallyun-framework';
import { LiveShortPlayer } from './LiveShortPlayer';
import { util } from '@kit.ArkTS';


@Builder
export function ShortVideoBuilder(name: string, param: object) {
  ShortVideo({ record_id: param['record_id'], access_token: param['access_token'], user_id: param['userid']})
}
@Entry
@Component
struct ShortVideo {


  private swiperController: SwiperController = new SwiperController();
  @State livePlayCreate: boolean = false;
  @State curIndex: number = 0;
  // 获取上个界面传递过来的房间号
  params: object = router.getParams() as object;
  public record_id: string = '';
  public access_token: string = '';
  public user_id:string = '';

  private playInfoArray: PlayInfoSource = new PlayInfoSource();
  pageInfos: NavPathStack = new NavPathStack() // 导航

  aboutToAppear(): void {
    this.playInfoArray.pushData(new PlayContact("86e18970"));
    this.playInfoArray.pushData(new PlayContact("lss_9a20f843"));
    this.playInfoArray.pushData(new PlayContact("70c574e1"));
    this.playInfoArray.pushData(new PlayContact("lss_9a20f843"));
    this.playInfoArray.pushData(new PlayContact("07ecdee0"));
    this.playInfoArray.pushData(new PlayContact("lss_9a20f843"));
    this.playInfoArray.pushData(new PlayContact("f22dbd8f"));
    this.playInfoArray.pushData(new PlayContact("86e18970"));
    this.playInfoArray.pushData(new PlayContact("lss_9a20f843"));
    this.playInfoArray.pushData(new PlayContact("70c574e1"));
    this.playInfoArray.pushData(new PlayContact("lss_9a20f843"));
    this.playInfoArray.pushData(new PlayContact("07ecdee0"));
    this.playInfoArray.pushData(new PlayContact("f22dbd8f"));
    this.playInfoArray.pushData(new PlayContact("86e18970"));
    this.playInfoArray.pushData(new PlayContact("70c574e1"));
    this.playInfoArray.pushData(new PlayContact("07ecdee0"));
    this.playInfoArray.pushData(new PlayContact("f22dbd8f"));
    this.playInfoArray.pushData(new PlayContact("86e18970"));
    this.playInfoArray.pushData(new PlayContact("70c574e1"));
    this.playInfoArray.pushData(new PlayContact("07ecdee0"));
    this.playInfoArray.pushData(new PlayContact("f22dbd8f"));
    this.playInfoArray.pushData(new PlayContact("86e18970"));
    this.playInfoArray.pushData(new PlayContact("70c574e1"));
    this.playInfoArray.pushData(new PlayContact("07ecdee0"));
    this.playInfoArray.pushData(new PlayContact("f22dbd8f"));

  }

  aboutToDisappear(): void {

  }

  // 页面初次加载的时候
  onPageShow(): void {

  }

  onPageHide(): void {

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
   * 组件加载成功
   */
  onVHPlayerViewLoaded() {
    // 初次进入调用播放
    //this.vodPlayerModel.startPlay(this.record_id, this.access_token,VHDefinition.ORIGIN);
  }

  /**
   * 画中画状态
   */
  onPipStatusChange(state: VHPlayerPipStatus) {

  }


  onPipControlPanelStatusChange(state:VHPlayerPipControlPanelStatus){

  }

  // 封装NavigationTitle
  @Builder
  NavigationTitle() {
    Text('短视频')
      .fontColor($r('app.color.title_text_color'))
      .fontSize($r('app.float.title_font_size'))
      .lineHeight($r('app.float.nav_size_height'))
  }

  /**
   * 监听资源播放资源的时长，单位为毫秒（ms），用于刷新进度条长度
   * @param duration  回放时长，单位为毫秒（ms）。
   */
  onVodTotalDuration(duration: number) {

  }

  /**
   * 当前播放时长，单位为毫秒（ms），用于刷新进度条长度
   * @param currentDuration  当前播放时长，单位为毫秒（ms）。
   */
  onVodCurrentDuration(currentDuration: number) {
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

  }

  /**
   * 监听水印图片加载成功回调
   * @param width   组件宽
   */
  onVHWaterMaskLoadedSucceed() {

  }

  /**
   * 监听水印图片加载失败回调
   * @param error 失败原因
   */
  onVHWaterMaskLoadedError(error: string) {

  }

  onPlayerVolume(volume: number) {

  }

  onPlayerError(error: VHPlayerError) {

  }

  onStatusDidChange(state: VHPlayerStatus) {

  }

  onValidDefinitions(definitions: VHDefinition[]) {

  }

  onStreamType(streamType: VHPlayStreamType) {

  }

  onVideoFrameSize(width: number, height: number) {

  }

  /**
   * 投屏设备状体事件回调。
   * @param state. 0 设备已准备好可以播放。1：设备已断开
   */
  onCastPlayDeviceState(state: number) {

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

  }

  /**
   * 投屏操作失败。
   * @param state:VHCastPlayState。执行相关操作失败。包括开播、暂停、设置进度
   */
  onCastPlayError(state: VHCastPlayState) {

  }

  build() {
    NavDestination(){
      Swiper(this.swiperController) {
        LazyForEach(this.playInfoArray, (item: PlayContact,index:number) => {
          if(item.id?.includes("lss")){
            LiveShortPlayer({roomId:item.id,token:this.access_token,dataIndex:index,curIndex:this.curIndex})
          }else{
            VodShortPlayer({roomId:item.id,token:this.access_token,dataIndex:index,curIndex:this.curIndex})
          }

        },(item: string, index: number) => index.toString())
      }
      .cachedCount(3) // 缓存视频数量
      .width("100%")
      .height("100%")
      .vertical(true)
      .loop(true)
      .curve(Curve.Ease)
      .duration(300)
      .indicator(false)
      .backgroundColor(Color.Black)
      .onGestureSwipe((index: number, extraInfo: SwiperAnimationEvent) => {
        Logger.info("TAG", `onAnimationEnd index:${index}}`);
      })
      .onAnimationStart((index: number, targetIndex: number, extraInfo: SwiperAnimationEvent) => {
        Logger.info("TAG", `onAnimationStart index:${targetIndex}}`);
        this.curIndex = targetIndex;
      })
      .onAnimationEnd((index: number, extraInfo: SwiperAnimationEvent) => {
        Logger.info("TAG", `onAnimationEnd index:${index}}`);
      })
      .onSelected((index:number)=>{
        Logger.info("TAG", `onAnimationEnd index:${index}}`);
      })
      .onChange((index:number)=>{
        Logger.info("TAG", `onAnimationEnd index:${index}}`);
      })

    }.onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    })
    .id('ShortVideo')
    .hideBackButton(true)
  }
}

