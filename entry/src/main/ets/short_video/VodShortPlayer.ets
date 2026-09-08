import {
  VHCastPlayDevice,
  VHCastPlayState,
  VHDefinition, VHPlayerError,
  VHPlayerPipControlPanelStatus,
  VHPlayerPipStatus,
  VHPlayerStatus,
  VHPlayStreamType,
  VHVodPlayer,
  VHVodPlayerSpeed,
  VHVodPlayerView } from '@vhall/vhallyun-lss-vod';
import { common } from '@kit.AbilityKit';
import { Logger } from '@vhall/vhallyun-framework';

@Component
export struct VodShortPlayer{
  private vodPlayerModel1: VHVodPlayer = new VHVodPlayer(this.getUIContext().getHostContext() as common.UIAbilityContext);
  public roomId:string = "";
  public token:string = "";
  private dataIndex: number = 0;
  @State flag: boolean = false;
  @Prop @Watch('onIndexChange') curIndex: number = 0;
  onPageShow(): void {

  }

  onPageHide(): void {

  }


  aboutToAppear(): void {
    this.vodPlayerModel1.setVHLivePlayerInterface(this,this);
    Logger.info("TAG", `onAnimationStart VodShortPlayer aboutToAppear :${this.dataIndex}} vod:${this.roomId}`);
  }

  aboutToDisappear(): void {
    this.vodPlayerModel1.destroyPlayer();
  }

  onIndexChange() {
    if (this.curIndex == this.dataIndex) {
      this.vodPlayerModel1.resumePlay();
      Logger.info("TAG", `onAnimationStart VodShortPlayer:resumePlay ${this.dataIndex}}`);
    }else{
      Logger.info("TAG", `onAnimationStart VodShortPlayer pausePlay :${this.dataIndex}}`);
      this.vodPlayerModel1.pausePlay();
    }
  }

  /**
   * 播放器播放失败事件
   */
  onPlayerError(error: VHPlayerError) {


  }
  /**
   * 观看状态回调
   * @param player  播放器实例
   * @param state   状态类型 详见 VHPlayerStatus 的定义.
   */
  onStatusDidChange(state: VHPlayerStatus){
    if(this.curIndex != this.dataIndex){
      if(state == VHPlayerStatus.PLAYING){
        setTimeout(() => {
          this.vodPlayerModel1.pausePlay();
        }, 0);
      }
    }
  }
  /**
   * 画中画状态
   * @param state: 画中画播放状态
   */
  onPipStatusChange(state: VHPlayerPipStatus){


  }

  /**
   * 画中画控制中心播放状态
   * @param state: VHPlayerPipControlPanelStatus
   */
  onPipControlPanelStatusChange(state: VHPlayerPipControlPanelStatus){


  }

  /**
   * 播放器音量
   * @param volume :当前播放器音量值
   */
  onPlayerVolume(volume: number){


  }
  /**
   * 当前房间支持的清晰度列表
   * @param definitions   支持的清晰度列表
   */
  onValidDefinitions(definitions: VHDefinition[]){


  }
  /**
   * streamType 观看流类型
   * @param streamType   观看流类型   1:音频+视频 2:仅视频 3:仅音频
   */
  onStreamType(streamType: VHPlayStreamType){


  }
  /**
   * 视频流播放成功后，回调视频流的宽髙。用户可根据视频流实际宽高，调整播放容器大小。
   * @param width   视频帧宽度
   * @param height  视频帧高度
   */
  onVideoFrameSize(width: number, height: number){


  }
  /**
   * 投屏设备状体事件回调。
   * @param state. 0 设备已准备好可以播放。1：设备已断开
   */
  onCastPlayDeviceState(state: number){


  }
  /**
   * 已连接的投屏设备。
   * @param state. 0 设备已准备好可以播放。1：设备已断开
   */
  onCastPlayDeviceConnected(device: VHCastPlayDevice){


  }
  /**
   * 投屏事件回调。
   * @param state:VHCastPlayState
   */
  onCastPlayState(state: VHCastPlayState){


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
  onCastPlayPosition(position: number){


  }
  /**
   * 投屏操作失败。
   * @param state:VHCastPlayState。执行相关操作失败。包括开播、暂停、设置进度
   */
  onCastPlayError(state: VHCastPlayState){


  }

  /**
   * 组件加载成功
   */
  onVHPlayerViewLoaded(){
    this.vodPlayerModel1.startPlay(this.roomId,this.token,VHDefinition.ORIGIN);
  }
  /**
   * 监听水印图片加载成功回调
   * @param width   组件宽
   */
  onVHWaterMaskLoadedSucceed(){

  }
  /**
   * 监听水印图片加载失败回调
   * @param error 失败原因
   */
  onVHWaterMaskLoadedError(error:string){

  }

  /**
   * 监听资源播放资源的时长，单位为毫秒（ms），用于刷新进度条长度
   * @param duration  回放时长，单位为毫秒（ms）。
   */
  onVodTotalDuration(duration: number){

  }
  /**
   * 当前播放时长，单位为毫秒（ms），用于刷新进度条长度
   * @param currentDuration  当前播放时长，单位为毫秒（ms）。
   */
  onVodCurrentDuration(current: number){

  }
  /**
   * 监听SeekTime，用于刷新进度条长度
   * @param duration  当前时长，单位为毫秒（ms）。
   */
  onVodSeekDuration(duration: number){

  }
  /**
   * 监听setSpeed，表示切换倍速成功。
   * @param speed  当前倍速
   */
  onVodSpeedDone(speed: VHVodPlayerSpeed){

  }

  build() {
    VHVodPlayerView({ componentListener: this, vodPlayer: this.vodPlayerModel1 })
      .width('100%')
      .height('100%')
      .align(Alignment.Center)
  }
}