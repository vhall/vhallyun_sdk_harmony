import {
  VHCastPlayDevice,
  VHCastPlayState,
  VHDefinition,
  VHLivePlayer,
  VHLivePlayerView,
  VHPlayerError,
  VHPlayerPipControlPanelStatus,
  VHPlayerPipStatus, VHPlayerStatus,
  VHPlayStreamType } from "@vhall/vhallyun-lss-vod";
import { common } from "@kit.AbilityKit";
import { StyleConstants } from "@vhall/vhallyun-framework";

@Component
export struct LiveShortPlayer{
  private livePlayerModel: VHLivePlayer = new VHLivePlayer(this.getUIContext().getHostContext() as common.UIAbilityContext);
  private isPrePlayer:boolean = false;
  private roomId:string = "";
  public token:string = "";
  private dataIndex: number = 0;
  @State flag: boolean = false;
  @Prop @Watch('onIndexChange') curIndex: number = 0;

  aboutToAppear(){
    this.livePlayerModel?.setVHLivePlayerInterface(this);
  }

  aboutToDisappear(): void {
    this.livePlayerModel.destroyPlayer();
  }

  onIndexChange() {
    if (this.curIndex == this.dataIndex) {
      this.livePlayerModel.setMute(false);
    }else{
      this.livePlayerModel.setMute(true);
    }
  }

  /**
   * 播放器播放失败事件
   */
  onPlayerError(error: VHPlayerError){

  }
  /**
   * 观看状态回调
   * @param player  播放器实例
   * @param state   状态类型 详见 VHPlayerStatus 的定义.
   */
  onStatusDidChange(state: VHPlayerStatus){

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
    this.livePlayerModel.startPlay(this.roomId,this.token);
    if (this.curIndex == this.dataIndex) {
      this.livePlayerModel.setMute(false);
    }else{
      this.livePlayerModel.setMute(true);
    }
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

  build() {
    VHLivePlayerView({ componentListener: this, livePlayer: this.livePlayerModel})
      .width(StyleConstants.FULL_WIDTH)
      .height(StyleConstants.FULL_HEIGHT)
      .backgroundColor(Color.Black)
      .align(Alignment.Center)
  }
}