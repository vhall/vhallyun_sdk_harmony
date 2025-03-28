import router from '@ohos.router'
import { BusinessError } from '@ohos.base';

import { VHBase } from '@vhall/vhallyun-framework'
import StyleConstants from '../common/constants/StyleConstants';

@Entry
@Component
struct Index {
  @State message: string = VHBase.getSDKVersion();
  @State appid: string = '15df4d3f';
  @State access_token: string = 'vhall';
  //@State channel_id: string = 'ch_na5zaU6G';
  //@State channel_id: string = 'ch_yzD7FeyM';
  @State channel_id: string = 'ch_JEiMVGoQ';

  //@State lss_id: string = 'lss_95216081';
  // @State lss_id: string = 'lss_69a29f8f';
  @State lss_id: string = 'lss_91050b4e';

  // @State record_id: string = '4dca92af';
  //@State record_id: string =  '7f108fea';
  @State record_id: string = '829df412';
  // @State userid: string = (Math.random() * 1000000000).toString().substring(0, 7);
  @State userid: string = 'HarmonyOSChao';
  @State nickName: string = '阿超';
  @State avatar: string = 'https://gw.alipayobjects.com/zos/antfincdn/XAosXuNZyF/BiazfanxmamNRoxxVxka.png';
  @State context: Map<string, string> = new Map<string,string>();


  aboutToAppear(): void {
    // 初始化sdk
    VHBase.registerApp(this.appid, '',
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

  build() {
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
            this.enterIMDemo()
          })

        Button($r("app.string.enter_live"))
          .width('45%')
          .height('100%')
          .fontSize($r('app.float.normal_text_size'))
          .fontWeight(FontWeight.Medium)
          .backgroundColor($r('app.color.login_button_color'))
          .onClick(() => {
            this.enterLiveDemo()
          })
      }
      .height($r('app.float.login_button_height'))
      .margin({
        top: $r('app.float.login_button_top'),
        bottom: $r('app.float.login_button_bottom')
      })

      Row({ space: 5 }) {
        Button($r("app.string.enter_vod_room"))
          .width('45%')
          .height('100%')
          .fontSize($r('app.float.normal_text_size'))
          .fontWeight(FontWeight.Medium)
          .backgroundColor($r('app.color.login_button_color'))
          .onClick(() => {
            this.enterVodDemo()
          })
        Button($r("app.string.enter_doc_room"))
          .width('45%')
          .height('100%')
          .fontSize($r('app.float.normal_text_size'))
          .fontWeight(FontWeight.Medium)
          .backgroundColor($r('app.color.login_button_color'))
          .onClick(() => {
            this.enterDocDemo()
          })
      }
      .height($r('app.float.login_button_height'))
      .margin({
        bottom: $r('app.float.login_button_bottom')
      })

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