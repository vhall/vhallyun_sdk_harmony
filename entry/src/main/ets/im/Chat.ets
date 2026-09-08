import router from '@ohos.router'
import { promptAction } from '@kit.ArkUI';
import  StyleConstants  from '../common/constants/StyleConstants';
import { VHBase, VHMessage } from '@vhall/vhallyun-framework';
import { VHIM, VHInternal } from '@vhall/vhallyun-ims'
import { SwipeRefresher } from '@kit.ArkUI';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApplicationStateChangeCallback, common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { VHHistoryMessageDataSource, Contact } from '../class/VHHistoryMessageDataSource'
import { JSON } from '@kit.ArkTS';

@Builder
export function ChatBuilder(name: string, param: object) {
  Chat({ channel_id: param['channel_id'], access_token: param['access_token']})
}



@Entry
@Component
struct Chat {

  static isJSONStr(str: string): boolean {
    try {
      JSON.parse(str);
      return true;
    } catch (error) {
      return false;
    }
  }

  // 获取上个界面传递过来的房间号
  params: object = router.getParams() as object;
  @State channel_id: string = '';//this.params['channel_id'];
  @State access_token: string = '';//this.params['access_token'];
  // IM消息初始化
  private imBase: VHIM = new VHIM();
  private isReconnect:number = -1;
  // 聊天信息
  @State chatMsg: string = '';
  // 自定义信息
  @State customMsg: string = '';

  pageInfos: NavPathStack = new NavPathStack() // 导航
  // 历史聊天记录
  private historyData: VHHistoryMessageDataSource = new VHHistoryMessageDataSource();
  @State srStr: string = '正在加载中';
  @State srStatus: boolean = true;
  @State srHeight: number = 100;
  // 成员列表
  @Provide members: Array<MemberItem> = [];
  // 人数
  @Provide numberTotal: string = '';
  // 全体禁言状态
  @State isAllBannedPostStatus: boolean = false;
  // 滚动视图
  private scrollerForList: Scroller = new Scroller();
  // 输入框控制器
  private textInputController = new TextInputController();

  private context = getContext() as common.UIAbilityContext;
  // 用户列表
  membersCustomDialog: CustomDialogController | null = new CustomDialogController
  (
    {
      builder: MembersCustomDialog(),
      alignment: DialogAlignment.Bottom,
    }
  )

  startContinuousTask() {
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      // 添加需要被拉起应用的bundleName和abilityName
      wants: [
        {
          bundleName:this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name
        }
      ],
      // 指定点击通知栏消息后的动作是拉起ability
      actionType: wantAgent.OperationType.START_ABILITY,
      // 使用者自定义的一个私有值
      requestCode: 0,
      // 点击通知后，动作执行属性
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
      // extraInfo: { [backgroundTaskManager.BackgroundModeType.SUB_MODE] : backgroundTaskManager.BackgroundSubMode.CAR_KEY }
    };

    try {
      // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
      wantAgent.getWantAgent(wantAgentInfo).then((wantAgentObj: WantAgent) => {
        try {
          let list: Array<string> = ["audioPlayback"];
          backgroundTaskManager.startBackgroundRunning( this.getUIContext().getHostContext(), list, wantAgentObj).then((res: backgroundTaskManager.ContinuousTaskNotification) => {
            console.info("Operation startBackgroundRunning succeeded");
           // this.taskStatus = '开启长时任务成功，正在播放'
            // 此处执行具体的长时任务逻辑，如录音，录制等。
          }).catch((error: BusinessError) => {
            console.error(`Failed to Operation startBackgroundRunning. code is ${error.code} message is ${error.message}`);
          });
        } catch (error) {
          console.error(`Failed to Operation startBackgroundRunning. code is ${(error as BusinessError).code} message is ${(error as BusinessError).message}`);
        }
      });
    } catch (error) {
      console.error(`Failed to Operation getWantAgent. code is ${(error as BusinessError).code} message is ${(error as BusinessError).message}`);
    }
  }

  stopContinuousTask() {
    backgroundTaskManager.stopBackgroundRunning( this.getUIContext().getHostContext()).then(() => {
      console.info(`Succeeded in operationing stopBackgroundRunning.`);
    //  this.taskStatus = '关闭长时任务成功，停止播放'
    }).catch((err: BusinessError) => {
      console.error(`Failed to operation stopBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
    });
  }


  // 绘制
  build() {
    NavDestination(){
      Column({ space: StyleConstants.COLUMN_SPACE }) {
        Row(){
          Button() {
            Text('申请长时任务').fontSize(25).fontWeight(FontWeight.Bold)
          }
          .type(ButtonType.Capsule)
          .margin({ top: 10 })
          .backgroundColor('#0D9FFB')
          .width(250)
          .height(40)
          .onClick(() => {
            // 通过按钮申请长时任务
            this.startContinuousTask();
          })


          Button() {
            Text('取消长时任务').fontSize(25).fontWeight(FontWeight.Bold)
          }
          .type(ButtonType.Capsule)
          .margin({ top: 10 })
          .backgroundColor('#0D9FFB')
          .width(250)
          .height(40)
          .onClick(() => {
            // 此处结束具体的长时任务的执行

            // 通过按钮取消长时任务
            this.stopContinuousTask();
          })
        }


        Button() {
          Image($r('app.media.chatMsgSendBtn'))
            .width('24vp').height('24vp')
        }
        .backgroundColor(Color.White)
        .onClick((event) => {
          this.pageInfos.pushPath({ name: 'VHLoginVC', param: null,
            onPop: (popInfo: PopInfo) => {
            }});
        })
        Divider().strokeWidth(2).color('#F1F3F5')
        List({ space: 4, scroller: this.scrollerForList }) {

          SwipeRefresher({
            content: this.srStr,
            isLoading: this.srStatus
          }).height(this.srHeight)

          LazyForEach(this.historyData, (item: Contact) => {
            ListItem() {
              Row({ space: 8 }) {
                Image(item.avatar)
                  .width(40)
                  .height(40)
                  .borderRadius(20)
                Column() {
                  Text(item.nick_name).fontSize(12)
                  Text(item.data).fontColor(Color.Gray).fontSize(10)
                  if (item.image_urls !== undefined && item.image_urls.length > 0) {
                    Grid() {
                      ForEach(item.image_urls, (imgStr: string) => {
                        GridItem() {
                          Image(imgStr)
                            .width(80)
                            .height(80)
                        }
                      }, (imgStr: string):string => imgStr)
                    }
                  }
                }
                .alignItems(HorizontalAlign.Start)
                .padding({right: 48})
              }
              .width('100%')
            }
          }, (item: VHMessage) => item.key
          )
        }.width('100%').height('80%').cachedCount(3)

        Divider().strokeWidth(1).color('#F1F3F5')
        Row({ space: 8 }) {
          TextInput({ placeholder: '请输入聊天信息', text: this.chatMsg, controller: this.textInputController })
            .placeholderColor($r('app.color.placeholder_color'))
            .placeholderFont({ size: $r('app.float.little_text_size') })
            .fontSize($r('app.float.little_text_size'))
            .backgroundColor('#F9F9F9')
            .borderWidth(0.5)
            .borderColor(Color.Gray)
            .borderRadius(6)
            .margin({ top: $r('app.float.input_margin_top') })
            .padding({ left: $r('app.float.forgot_padding_left') })
            .width('90%')
            .height('32vp')
            .onChange((value: string) => {
              this.chatMsg = value;
            })
          Button() {
            Image($r('app.media.chatMsgSendBtn'))
              .width('24vp').height('24vp')
          }
          .backgroundColor(Color.White)
          .onClick((event) => {
            // 发送聊天消息
            let images:Array<string> = [];
            images.push("https://cnstatic01.e.vhall.com/upload/lss_75725302/img/45/08/4508f43c06f6ad21fbb1ebeb4660b4ef5538.png?have-wap-image=7501");
            images.push("https://cnstatic01.e.vhall.com/upload/lss_75725302/img/45/08/4508f43c06f6ad21fbb1ebeb4660b4ef5538.png?have-wap-image=7502");
            images.push("https://cnstatic01.e.vhall.com/upload/lss_75725302/img/45/08/4508f43c06f6ad21fbb1ebeb4660b4ef5538.png?have-wap-image=7503");
            let msg = JSON.stringify(images);
            this.imBase.sendTypeMessage(msg,"",1,
              {
                onSuccess: () => {
                  console.log('发送聊天消息成功 === ');
                },
                onFailure: (errorCode, errorMsg) => {
                  console.log('错误码 === ' + errorCode + errorMsg);
                }
              }
            )

            this.sendMessgae(this.chatMsg);
            // 关闭自定义键盘
            this.textInputController.stopEditing();
            // 清空
            this.chatMsg = '';
          })




        }.width('100%')

        Row({ space: 8 }) {
          TextInput({ placeholder: '请输入自定义信息', text: this.customMsg, controller: this.textInputController })
            .placeholderColor($r('app.color.placeholder_color'))
            .placeholderFont({ size: $r('app.float.little_text_size') })
            .fontSize($r('app.float.little_text_size'))
            .backgroundColor('#F9F9F9')
            .borderWidth(0.5)
            .borderColor(Color.Gray)
            .borderRadius(6)
            .margin({ top: $r('app.float.input_margin_top') })
            .padding({ left: $r('app.float.forgot_padding_left') })
            .width('90%')
            .height('32vp')
            .onChange((value: string) => {
              this.customMsg = value;
            })
          Button() {
            Image($r('app.media.customMsgSendBtn'))
              .width('24vp').height('24vp')
          }
          .backgroundColor(Color.White)
          .onClick((event) => {
            // 发送自定义消息
            this.sendCustomMsg(this.customMsg);
            // 关闭自定义键盘
            this.textInputController.stopEditing();
            // 清空
            this.customMsg = '';
          })
        }.width('100%')

        Divider().strokeWidth(1).color('#F1F3F5')
        Row({ space: 8 }) {
          Button('用户列表')
            .height(22)
            .fontSize(16)
            .fontColor('#007DFF')
            .fontWeight(500)
            .backgroundColor(Color.Transparent)
            .padding({ right: 0 })
            .margin({ right: 0 })
            .align(Alignment.End)
            .width(120)
            .onClick
            (
              (event) => {
                if (this.membersCustomDialog) {
                  this.membersCustomDialog.open();
                }
                // 获取用户列表
                this.imBase.userList(1, 200,
                  {
                    onSuccess: (data) => {
                      console.log('获取用户列表成功' + data);
                      // 清理数组
                      this.members = [];
                      // 数据转换
                      this.numberTotal = data['total'];
                      let listAry: string[] = data['list'];
                      let contextObj: object = data['context'];
                      listAry.forEach((user_id: string) => {
                        let item = JSON.parse(contextObj[user_id]) as MemberItem;
                        // 添加数据
                        this.members.push(item);
                      });
                    },
                    onFailure: (errorCode, errorMsg) => {
                      console.error(`获取用户列表失败 Error code: ${errorCode}, Error message: ${errorMsg}`);
                    }
                  }
                );
              }
            )
          Divider()
            .vertical(true)
            .height(22)
            .strokeWidth(1)
            .color('#F1F3F5')
            .opacity(1)
            .margin({ left: 8, right: 8 })
          Row({ space: 4 }) {
            Text('全体禁言')
              .height(22)
              .fontSize(16)
              .fontWeight(500)
              .fontColor('#007DFF')
              .backgroundColor(Color.Transparent)
            Toggle({ type: ToggleType.Switch, isOn: this.isAllBannedPostStatus })
              .height(30)
              .onChange((isOn) => {
                this.isAllBannedPostStatus = isOn;
                this.imBase.setForbiddenAll
                (
                  this.isAllBannedPostStatus,
                  {
                    onSuccess: () => {
                      console.log(this.isAllBannedPostStatus == true ? '开启' : '关闭' + '全体禁言成功')
                    },
                    onFailure: (errorCode, errorMsg) => {
                      console.error(`操作全体禁言失败 Error code: ${errorCode}, Error message: ${errorMsg}`);
                    }
                  }
                )
              })
          }.width(120)
        }
      }
      .alignItems(HorizontalAlign.Center)
      .height('100%')
      .padding({
        top: 0,
        left: 8,
        bottom: 0,
        right: 8
      })
      .padding({ bottom: '60vp' })
    }.onReady((context: NavDestinationContext) => {
      this.pageInfos = context.pathStack
    }).onShown(() => {
      // this.imBase.setVHIMInterface(this);
      // this.imBase.init(this.channel_id, this.access_token);
    })
    .hideBackButton(true)
    .onHidden(() => {
      // 销毁IM
     // this.imBase.closeMsg()
    })

  }

  onPageShow(): void {

  }

  onPageHide(): void {

  }




  aboutToAppear(): void {

    VHInternal.getQuestionInfo("1","","",{
      // 成功
      onSuccess(data){

      },
      // 失败
      onFailure(errorCode: number, errorMsg: string){

      }
    })
    // 打印版本号
    console.log('IM版本号' + VHIM.getSDKVersion());
   // 初始化
    this.imBase.init(this.channel_id, this.access_token);

    this.imBase.setVHIMInterface(this);

    // 聊天历史消息查询
    this.imBase.messageList(1, 99, '2020/03/01', '2025/03/01',
      {
        onSuccess: (data) => {
          const map: Map<string, string> = new Map(Object.entries(data));
          let list: string = JSON.stringify(map.get('list'));
          console.log('获取聊天历史成功' + list);

          // 转换模型
          let array = JSON.parse(list);
          if (Array.isArray(array)){
            array.forEach((obj: object) => {
              let contact = obj as Contact;
              if (obj['type'] === 'permit') {
                contact.avatar = 'https://img.soogif.com/nQprbtX8geM7vreWoq4urNLR7DoOiZz3.gif';
                contact.nick_name = '禁言';
                contact.data = '这是全体禁言消息';
              }
              if (obj['type'] === 'disable') {
                contact.avatar = 'https://img.soogif.com/nQprbtX8geM7vreWoq4urNLR7DoOiZz3.gif';
                contact.nick_name = '取消禁言';
                contact.data = '这是取消全体禁言消息';
              }
              if (obj['type'] === 'permit_all') {
                contact.avatar =
                  'https://img1.baidu.com/it/u=2064520578,3901995817&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=500';
                contact.nick_name = '全体禁言';
                contact.data = '这是全体禁言消息';
              }
              if (obj['type'] === 'disable_all') {
                contact.avatar =
                  'https://img1.baidu.com/it/u=2064520578,3901995817&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=500';
                contact.nick_name = '取消全体禁言';
                contact.data = '这是取消全体禁言消息';
              }
              this.historyData.pushData(contact);
            });
          }


          // loading提示
          this.srStr = '列表加载完成';
          this.srStatus = false;
          this.srHeight = 0;
        },
        onFailure: (errorCode, errorMsg) => {
          // loading提示
          this.srStr = '列表加载失败';
          this.srStatus = false;
          this.srHeight = 100;

          console.error(`获取聊天历史失败 Error code: ${errorCode}, Error message: ${errorMsg}`);
        }
      }
    )
  }

  aboutToDisappear(): void {
    // 关闭消息服务
    this.imBase.closeMsg();  }
  /**
   * 发送聊天消息
   * @param msg 消息内容
   */
  sendMessgae(msg: string): void {
    if (this.imBase.forbidden) {
      promptAction.showToast({
        duration: 2000,
        message: '您已被禁言'
      });
      return;
    }
    if (this.imBase.forbiddenAll) {
      promptAction.showToast({
        duration: 2000,
        message: '全体已被禁言'
      });
      return;
    }
    this.imBase.sendMessage(msg,
      {
        onSuccess: () => {
          console.log('发送聊天消息成功 === ');
        },
        onFailure: (errorCode, errorMsg) => {
          console.log('错误码 === ' + errorCode + errorMsg);
        }
      }
    )
  }

  /**
   * 发送自定义消息
   * @param msg 消息内容
   */
  sendCustomMsg(msg: string): void {
    if (this.imBase.forbidden) {
      promptAction.showToast({
        duration: 2000,
        message: '您已被禁言'
      });
      return;
    }
    if (this.imBase.forbiddenAll) {
      promptAction.showToast({
        duration: 2000,
        message: '全体已被禁言'
      });
      return;
    }
    this.imBase.sendCustomMessage(msg,
      {
        onSuccess: () => {
          console.log('发送自定义消息成功 === ');
        },
        onFailure: (errorCode, errorMsg) => {
          console.log('错误码 === ' + errorCode + errorMsg);
        }
      }
    )
  }

  // 聊天消息
  imSDKReceiveChatMessage(im: VHIM, message: VHMessage): void {
    console.log(`imSDKReceiveChatMessage === ${JSON.stringify(message)}}`)

    const data: object = JSON.parse(message.data as string) as object;
    if (data['type'] == 'text') {
      let contact: Contact = new Contact(message.avatar, message.nick_name, data['text_content']);
      this.historyData.unshiftData(contact);
    }
    if ( data['type'] == 'image') {
      let contact: Contact = new Contact(message.avatar, message.nick_name, data['text_content'], data['image_urls']);
      this.historyData.unshiftData(contact);
    }
  }

  // 上下线消息
  imSDKReceiveOnlineMessage(im: VHIM, message: VHMessage): void {
    console.log(`imSDKReceiveOnlineMessage === ${JSON.stringify(message)}}`)

    const data: object = JSON.parse(message.data as string) as object;
    let type: string = data['type'] === 'Join' ? '这个好看的用户上线啦！' : '调皮的用户离开咯~'
    let contact: Contact = new Contact(message.avatar, message.nick_name, type);
    this.historyData.unshiftData(contact)
  }

  // 自定义消息
  imSDKReceiveCustomMessage(im: VHIM, message: VHMessage): void {
    console.log(`imSDKReceiveCustomMessage === ${JSON.stringify(message)}}`)
    const contextData: object = JSON.parse(message.context) as object;
    let contact: Contact = new Contact(contextData['avatar'], contextData['nick_name'], `自定义消息 === ${message.data}`);
    this.historyData.unshiftData(contact)
  }

  // 房间消息
  imSDKReceiveRoomMessage(im: VHIM, message: VHMessage): void {
    console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)

    // const data: object = message.data as object;
    // if(JSON.has(data,"event_type")){
    //   console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
    //   console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
    // }else{
    //   console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
    //   console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
    //   console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
    //   console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
    // }
    // console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
    // console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
    // console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
    // console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
  }

  // 消息错误
  imSDKError(im: VHIM, code:number, errorMsg: string): void {
    console.log(`imSDKError === ${errorMsg}}`)
  }

  onNetworkDisconnect(code:number,message:string):void{
    console.log(`imSDKError === ${code}}`)
    if(this.isReconnect != -1){
      return;
    }
    this.isReconnect = setTimeout(()=>{
      this.imBase.init(this.channel_id, this.access_token);
      this.isReconnect = -1;
    },3000);
  }

  /**
   * 消息服务连接成功
   * */
  onNetworkConnect () {
    console.log(`imSDKError === onNetworkConnect}`)
  }

  /**
   * 消息服务连接正在重新链接
   * */
  onNetworkConnecting(){
    console.log(`imSDKError === onNetworkConnecting}`)
  }

  // 用户禁言
  imSDKForbidden(im: VHIM, forbidden: boolean): void {
    console.log(`imSDKForbidden === ${forbidden}}`)
    let contact: Contact =
      new Contact('https://img.soogif.com/nQprbtX8geM7vreWoq4urNLR7DoOiZz3.gif', VHBase.getContext()['nick_name'],
        forbidden == true ? '我被禁言了' : '我可以说话了');
    this.historyData.unshiftData(contact)
  }

  // 全体禁言
  imSDKForbiddenAll(im: VHIM, forbiddenAll: boolean): void {
    console.log(`imSDKForbiddenAll === ${forbiddenAll}}`)
    if (this.isAllBannedPostStatus !== forbiddenAll) {
      this.isAllBannedPostStatus = forbiddenAll;
    }
    let contact: Contact =
      new Contact('https://img1.baidu.com/it/u=2064520578,3901995817&fm=253&fmt=auto&app=138&f=JPEG?w=500&h=500',
        '全体禁言', forbiddenAll == true ? '开启全体禁言' : '关闭全体禁言');
    this.historyData.unshiftData(contact)
  }
}

@CustomDialog
struct MembersCustomDialog {
  // 成员列表
  @Consume members: Array<MemberItem>;
  // 人数
  @Consume numberTotal: string;
  // 滚动视图
  private scrollerForList: Scroller = new Scroller()
  // 弹窗
  controller?: CustomDialogController

  build() {
    Column() {
      Text(`在线用户 (${this.numberTotal})`)
        .margin({ top: 10 })
      List({ space: 4, scroller: this.scrollerForList }) {
        ForEach(this.members, (item: MemberItem) => {
          ListItem() {
            Row({ space: 8 }) {
              Image(item.avatar)
                .width(40)
                .height(40)
                .borderRadius(20)
              Column() {
                Text(item.nickname).fontSize(12).margin({ top: 0 })
              }.alignItems(HorizontalAlign.Start)
            }
            .height(40)
            .width('100%')
          }
        }
        )
      }
      .width(300).height(300)
    }

  }
}

@Extend(TextInput)
function inputStyle() {
}

@Extend(Button)
function btnStyle() {
  .fontSize($r('app.float.normal_text_size'))
  .fontWeight(FontWeight.Medium)
  .backgroundColor($r('app.color.login_button_color'))
}

class MemberItem {
  nick_name: string = ''; // 昵称
  nickname: string = ''; // 昵称
  avatar: string = ''; // 第三方用户头像
}
