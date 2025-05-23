import router from '@ohos.router'
import { promptAction } from '@kit.ArkUI';
import  StyleConstants  from '../common/constants/StyleConstants';
import { VHBase, VHMessage } from '@vhall/vhallyun-framework';
import { VHIM } from '@vhall/vhallyun-ims'
import { SwipeRefresher } from '@kit.ArkUI';

import { VHHistoryMessageDataSource, Contact } from '../class/VHHistoryMessageDataSource'

@Entry
@Component
struct Chat {
  // 获取上个界面传递过来的房间号
  params: object = router.getParams() as object;
  @State channel_id: string = this.params['channel_id'];
  @State access_token: string = this.params['access_token'];
  // IM消息初始化
  private imBase: VHIM = new VHIM();
  // 聊天信息
  @State chatMsg: string = '';
  // 自定义信息
  @State customMsg: string = '';
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
  // 用户列表
  membersCustomDialog: CustomDialogController | null = new CustomDialogController
  (
    {
      builder: MembersCustomDialog(),
      alignment: DialogAlignment.Bottom,
    }
  )

  // 绘制
  build() {
    Column({ space: StyleConstants.COLUMN_SPACE }) {
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
  }

  onPageShow(): void {

  }

  onPageHide(): void {

  }

  aboutToAppear(): void {
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
          let array: object[] = JSON.parse(list);
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
    const data: object = JSON.parse(message.data);
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
    const data: object = JSON.parse(message.data);
    let type: string = data['type'] === 'Join' ? '这个好看的用户上线啦！' : '调皮的用户离开咯~'
    let contact: Contact = new Contact(message.avatar, message.nick_name, type);
    this.historyData.unshiftData(contact)
  }

  // 自定义消息
  imSDKReceiveCustomMessage(im: VHIM, message: VHMessage): void {
    console.log(`imSDKReceiveCustomMessage === ${JSON.stringify(message)}}`)
    const context: object = JSON.parse(message.context);
    let contact: Contact = new Contact(context['avatar'], context['nick_name'], `自定义消息 === ${message.data}`);
    this.historyData.unshiftData(contact)
  }

  // 房间消息
  imSDKReceiveRoomMessage(im: VHIM, message: VHMessage): void {
    console.log(`imSDKReceiveRoomMessage === ${JSON.stringify(message)}}`)
  }

  // 消息错误
  imSDKError(im: VHIM, errorMsg: string): void {
    console.log(`imSDKError === ${errorMsg}}`)
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
