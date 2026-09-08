import router from '@ohos.router'
import { BusinessError } from '@ohos.base';
import { VHAppInfo } from '@vhall/vhallyun-framework';
import { VHBase } from '@vhall/vhallyun-framework'
import StyleConstants from '../common/constants/StyleConstants';

@Entry
@Component
struct Index {
  @State message: string = VHBase.getSDKVersion();
  @State appid: string = '';
  @State access_token: string = '';
  @State channel_id: string = '';
  @State lss_id: string = '';
  @State record_id: string = '';
  @State userid: string = 'HarmonyOS';
  @State nickName: string = '';
  @State packageName: string = '';
  @State signature: string = '';
  @State avatar: string = '';
  @State context: Map<string, string> = new Map<string,string>();
  @State inav_id: string = '';

  aboutToAppear(): void {
    // 初始化sdk
    VHBase.setPackageCheck(this.packageName,this.signature);
    VHBase.registerApp(this.getUIContext().getHostContext()?.getApplicationContext()! as Context, this.appid, 'api.vhallyun.com',
      {
        onSuccess: () => {
          console.log('SDK初始化成功');
        },
        onFailure: (msg) => {
          console.log('SDK初始化失败 === ' + msg);
        }
      }
    )
    // 设置
    this.context["nickname"] = this.nickName;
    this.context["avatar"] = this.avatar;
    //***重要：this.userid 直播推流建议使用主持人唯一三方用户id进行设置
    VHBase.setUserIdAndContext(this.userid, this.context);
  }

  enterIMDemo(): void {
    try {
      router.pushUrl({
        url: 'im/Chat',
        params: { 'channel_id': this.channel_id, 'access_token': this.access_token }
      })
    } catch (err) {
      console.error(`pushUrl failed, code is ${(err as BusinessError).code}, message is ${(err as BusinessError).message}`);
    }
  }

  enterLiveDemo(): void {
    try {
      router.pushUrl({
        url: 'lss/Live',
        params: { 'lss_id': this.lss_id, 'access_token': this.access_token, 'channel_id': this.channel_id,'userid' :this.userid }
      })
    } catch (err) {
      console.error(`pushUrl failed, code is ${(err as BusinessError).code}, message is ${(err as BusinessError).message}`);
    }
  }

  enterVodDemo(): void {
    try {
      router.pushUrl({
        url: 'vod/Vod',
        params: { 'record_id': this.record_id, 'access_token': this.access_token , 'userid':this.userid }
      })
    } catch (err) {
      console.error(`pushUrl failed, code is ${(err as BusinessError).code}, message is ${(err as BusinessError).message}`);
    }
  }

  enterDocDemo(): void {
    try {
      router.pushUrl({
        url: 'doc/Doc',
        params: {
          'lss_id': this.lss_id,
          'record_id': this.record_id,
          'channel_id': this.channel_id,
          'access_token': this.access_token
        }
      })
    } catch (err) {
      console.error(`pushUrl failed, code is ${(err as BusinessError).code}, message is ${(err as BusinessError).message}`);
    }
  }
  pathStack: NavPathStack = new NavPathStack()
  build() {

    Navigation(this.pathStack) {
      Column() {
        Column() {
          Row() {
            Text($r("app.string.appid"))
              .fontSize(14)
            TextInput({ placeholder: $r("app.string.appid"), text: this.appid })
              .maxLength(StyleConstants.INPUT_ACCOUNT_LENGTH)
              .inputStyle()
              .onChange((value: string) => {
                this.appid = value;
              })
          }

          Line()
            .width(StyleConstants.FULL_WIDTH)
            .height($r('app.float.line_height'))
            .margin({
              left: $r('app.float.line_margin_left'),
              right: $r('app.float.line_margin_right')
            })
            .backgroundColor($r('app.color.line_color'))

          Row() {
            Text("Token")
              .fontSize(14)
            TextInput({ placeholder: $r("app.string.access_token"), text: this.access_token })
              .inputStyle()
              .onChange((value: string) => {
                this.access_token = value;
              })
          }

          Line()
            .width(StyleConstants.FULL_WIDTH)
            .height($r('app.float.line_height'))
            .margin({
              left: $r('app.float.line_margin_left'),
              right: $r('app.float.line_margin_right')
            })
            .backgroundColor($r('app.color.line_color'))

          Row() {
            Text("UserID")
              .fontSize(14)
            TextInput({ placeholder: $r("app.string.user_id"), text: this.userid })
              .inputStyle()
              .onChange((value: string) => {
                this.userid = value;
              })
          }

          Line()
            .width(StyleConstants.FULL_WIDTH)
            .height($r('app.float.line_height'))
            .margin({
              left: $r('app.float.line_margin_left'),
              right: $r('app.float.line_margin_right')
            })
            .backgroundColor($r('app.color.line_color'))

          Row() {
            Text("ChannelID")
              .fontSize(14)
            TextInput({ placeholder: $r("app.string.channel_id_placeholder"), text: this.channel_id })
              .inputStyle()
              .onChange((value: string) => {
                this.channel_id = value;
              })
          }

          Line()
            .width(StyleConstants.FULL_WIDTH)
            .height($r('app.float.line_height'))
            .margin({
              left: $r('app.float.line_margin_left'),
              right: $r('app.float.line_margin_right')
            })
            .backgroundColor($r('app.color.line_color'))

          Row() {
            Text("LiveID")
              .fontSize(14)
            TextInput({ placeholder: $r("app.string.lss_id_placeholder"), text: this.lss_id })
              .inputStyle()
              .onChange((value: string) => {
                this.lss_id = value;
              })
          }

          Line()
            .width(StyleConstants.FULL_WIDTH)
            .height($r('app.float.line_height'))
            .margin({
              left: $r('app.float.line_margin_left'),
              right: $r('app.float.line_margin_right')
            })
            .backgroundColor($r('app.color.line_color'))

          Row() {
            Text("RecordID")
              .fontSize(14)
            TextInput({ placeholder: $r("app.string.record_id_placeholder"), text: this.record_id })
              .inputStyle()
              .onChange((value: string) => {
                this.record_id = value;
              })


            Row() {
              Text("inav_id")
                .fontSize(14)
              TextInput({ text: this.inav_id })
                .inputStyle()
                .onChange((value: string) => {
                  this.inav_id = value;
                })
            }
          }

          Line()
            .width(StyleConstants.FULL_WIDTH)
            .height($r('app.float.line_height'))
            .margin({
              left: $r('app.float.line_margin_left'),
              right: $r('app.float.line_margin_right')
            })
            .backgroundColor($r('app.color.line_color'))

          Row() {
            Text("昵称")
              .fontSize(14)
            TextInput({ placeholder: $r("app.string.nick_name"), text: this.nickName })
              .inputStyle()
              .onChange((value: string) => {
                this.nickName = value;
              })
          }

          Line()
            .width(StyleConstants.FULL_WIDTH)
            .height($r('app.float.line_height'))
            .margin({
              left: $r('app.float.line_margin_left'),
              right: $r('app.float.line_margin_right')
            })
            .backgroundColor($r('app.color.line_color'))

          Row() {
            Text("头像")
              .fontSize(14)
            TextInput({ placeholder: $r("app.string.avatar"), text: this.avatar })
              .inputStyle()
              .onChange((value: string) => {
                this.avatar = value;
              })
          }
        }

        Row({ space: 5 }) {
          Button($r("app.string.enter_im"))
            .width('45%')
            .height('100%')
            .fontSize($r('app.float.normal_text_size'))
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.login_button_color'))
            .onClick(() => {
              let param: object = new Object()
              param['channel_id'] = this.channel_id
              param['access_token'] = this.access_token
              this.pathStack.pushPath({ name: 'Chat', param: param }, true);
            })

          Button($r("app.string.enter_live"))
            .width('45%')
            .height('100%')
            .fontSize($r('app.float.normal_text_size'))
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.login_button_color'))
            .onClick(() => {
              // this.enterLiveDemo()
              let param: object = new Object()
              param['lss_id'] = this.lss_id
              param['access_token'] = this.access_token
              param['channel_id'] = this.channel_id
              param['userid'] = this.userid
              this.pathStack.pushPath({ name: 'Live', param: param }, true);
            })


        }
        .height($r('app.float.login_button_height'))


        Row({ space: 5 }) {
          Button($r("app.string.enter_vod_room"))
            .height('100%')
            .fontSize($r('app.float.normal_text_size'))
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.login_button_color'))
            .onClick(() => {
              // this.enterVodDemo()
              let param: object = new Object()
              param['record_id'] = this.record_id
              param['access_token'] = this.access_token
              param['userid'] = this.userid
              this.pathStack.pushPath({ name: 'Vod', param: param }, true);
            })
          Button($r("app.string.enter_doc_room"))
            .height('100%')
            .fontSize($r('app.float.normal_text_size'))
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.login_button_color'))
            .onClick(() => {
              this.enterDocDemo()
            })
        }
        .height($r('app.float.login_button_height'))

        Row({ space: 5 }) {
           Button("直播")
            .width('30%')
            .height('100%')
            .fontSize($r('app.float.normal_text_size'))
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.login_button_color'))
            .onClick(() => {
              // this.enterLiveDemo()
              let param: object = new Object()
              param['lss_id'] = this.lss_id
              param['access_token'] = this.access_token
              param['channel_id'] = this.channel_id
              param['userid'] = this.userid
              param['inav_id'] = this.inav_id
              this.pathStack.pushPath({ name: 'LivePusher', param: param }, true);
            })

          Button("互动")
            .width('30%')
            .height('100%')
            .fontSize($r('app.float.normal_text_size'))
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.login_button_color'))
            .onClick(() => {
              // this.enterLiveDemo()
              let param: object = new Object()
              param['lss_id'] = this.lss_id
              param['access_token'] = this.access_token
              param['channel_id'] = this.channel_id
              param['userid'] = this.userid
              param['inav_id'] = this.inav_id
              this.pathStack.pushPath({ name: 'RTC', param: param }, true);
            })

          Button("短视频")
            .width('30%')
            .height('100%')
            .fontSize($r('app.float.normal_text_size'))
            .fontWeight(FontWeight.Medium)
            .backgroundColor($r('app.color.login_button_color'))
            .onClick(() => {
              // this.enterLiveDemo()
              let param: object = new Object()
              param['lss_id'] = this.lss_id
              param['access_token'] = this.access_token
              param['channel_id'] = this.channel_id
              param['userid'] = this.userid
              param['inav_id'] = this.inav_id
              this.pathStack.pushPath({ name: 'ShortVideo', param: param }, true);
            })
        }
        .height($r('app.float.login_button_height'))


        Text("提示：使用demo演示时，需要使用测试包名和签名，注册测试应用，得到appid")
          .fontSize(12)
          .fontColor($r('app.color.more_text_color'))

        Row() {
          Text(this.message)
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
        }
      }
      .padding({
        top: $r('app.float.login_button_top'),
        left: $r('app.float.login_button_left'),
        right: $r('app.float.login_button_right'),
      })

    }
    .mode(NavigationMode.Stack)
    .id('VHCWatch')


  }
}

@Extend(TextInput)
function inputStyle() {
  .placeholderColor($r('app.color.placeholder_color'))
  .height($r('app.float.login_input_height'))
  .fontSize($r('app.float.normal_text_size'))
  .backgroundColor(Color.White)
  .margin({ top: $r('app.float.input_margin_top') })
  .padding({ left: $r('app.float.forgot_padding_left') })
}