import { promptAction, router } from '@kit.ArkUI';
import { VHDocument,VHDocumentView,VHDocumentViewModel,VHDocumentDrawType,VHDocumentWaterMark,VHDocumentDrawAction,VHDocFilType,
  VHDocumentPageModel} from '@vhall/vhallyun-doc';
import StyleConstants from '../common/constants/StyleConstants';


@Entry
@Component
struct Doc {
  // 获取上个界面传递过来的房间号
  params: object = router.getParams() as object;
  public lss_id: string = this.params['lss_id'];
  public record_id: string = this.params['record_id'];
  public channel_id: string = this.params['channel_id'];
  public access_token: string = this.params['access_token'];

  //需要用户根据业务自己生成docID
  @State docId: string = '6312efc7';
 // @State docId: string = 'cf191346';
  // 动态更新tab中的VHDocumentView
  @State documentViews: Array<VHDocument> = new Array();
  //当前文档页
  @State currentDocumentIndex: number = 0;
  @State tabTitle: string = '';
  @State startPaint: string = StyleConstants.START_PAINT;
  @State fontSize: number = 10;
  @State fontColor: string = '#ff0000';
  @State drawType: VHDocumentDrawType = VHDocumentDrawType.PATH;
  //水印参数
  private waterMark: VHDocumentWaterMark = new VHDocumentWaterMark('hello world', 20);
  //水印透明度
  private waterMarkOpacity: number = 1.0;
  //文档标清切换定时器。
  private selectDocument: number = 0;
  //被选中文档的cid标识
  @State selectCid: string = '';
  //是否开启涂鸦
  @State isDocPaint: boolean = false;
  //初始化文档对象，负责监听文档回调
  private document: VHDocument = new VHDocument(new VHDocumentViewModel(VHDocFilType.DOC));
  //如果是文档操作方
  @State isDocController:boolean = false;
  //文档是否显示可见状态
  @State showDoc:boolean = true;
  //文档演示状态，当前文档观看端是否可见
  @State docSwitchState:boolean = false;
  //
  private controller: TabsController = new TabsController()

  @Builder
  tabBuilder(model: VHDocument, targetIndex: number) {
    Column() {
      Text(model.documentViewModel.cid)
        .fontColor(Color.White)
        .margin({ top: 17, bottom: 7 })
    }.backgroundColor(this.currentDocumentIndex === targetIndex ? '#ff3ece16' : '#ffcbd9d9')
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

  getSelectDocumentByIndex(index: number): VHDocument | null {
    for (let i = 0; i < this.documentViews.length; i++) {
      if (index == i) {
        return this.documentViews[i];
      }
    }
    return null;
  }

  /**
   * @description 文档加载完成
   * @param documentView   文档id 为空时没有 文档
   */
  docViewLoadEnd(doc: VHDocument){

  }


  getSelectDocumentByCid(cid: string): VHDocument | null {
    for (let index = 0; index < this.documentViews.length; index++) {
      const element = this.documentViews[index].documentViewModel
      if (element?.cid == cid) {
        return this.documentViews[index];
      }
    }
    return null;
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

  setTabSelectDocumentByCid(cid: string) {
    for (let index = 0; index < this.documentViews.length; index++) {
      const element = this.documentViews[index].documentViewModel
      if (element?.cid == cid) {
        this.controller.changeIndex(index);
      }
    }
  }

  @Builder
  documentViewBuilder() {
    Tabs({ barPosition: BarPosition.Start, controller: this.controller }) {
      //doc文档模型对象需要作为参数传入VHDocumentView组件内。
      ForEach(this.documentViews, (doc: VHDocument, index: number) => {
        TabContent() {
          //vhDocument： 文档控制模型
          //isPaint： 控制文档是否可以进行涂鸦操作
          //demonstrateProgress: 是否同步历史画笔数据
          VHDocumentView({vhDocInterface:this, vhDocument: doc, demonstrateProgress: doc.documentViewModel.getLastData, isPaint:this.isDocPaint})
            .width('100%')
            .height('100%')
            .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
              //重置文档视图大小。
              doc.setDocumentViewSize(newValue.width as number, newValue.height as number);
            })
        }
        .tabBar(this.tabBuilder(doc, index))

      }, (doc: VHDocument, index: number) => {
        if (this.selectCid == doc.documentViewModel.cid) {
          if(this.selectDocument != 0){
            clearInterval(this.selectDocument);
            this.selectDocument = 0;
          }
          //启动定时延迟切换到对应标签。
          this.selectDocument = setInterval(() => {
            this.controller.changeIndex(index);
            if(this.selectDocument != 0){
              if(this.selectDocument != 0){
                clearInterval(this.selectDocument);
                this.selectDocument = 0;
              }
            }
          }, 100);
        }
        return doc.documentViewModel.cid;
      })
    }
    //.barHeight(0)// 可通过设置此参数隐藏tab
    .scrollable(false)
    .width('100%')
    .height('36%')
    .opacity(this.showDoc == true ? 100 : 0)
    .animationDuration(0)
    .backgroundColor('#F1F3F5')
    .onChange((index: number) => {
      this.currentDocumentIndex = index;
      this.getSelectDocumentByIndex(this.currentDocumentIndex)?.selectDoc();
    })
  }

  @Builder
  documentPageBuilder() {
    Row({ space: StyleConstants.SPACE_SIZE }) {
      Button('上一页').onClick(() => {
        this.getSelectDocumentByIndex(this.currentDocumentIndex)?.prevPage();
      })
        .fontSize(StyleConstants.BUTTON_FONT_SIZE)
        .padding({ left: 2, right: 2 })

      Button('下一页').onClick(() => {
        this.getSelectDocumentByIndex(this.currentDocumentIndex)?.nextPage();
      })
        .fontSize(StyleConstants.BUTTON_FONT_SIZE)
        .padding({ left: 2, right: 2 })

      Text('演示')
      Toggle({ type: ToggleType.Switch, isOn: this.docSwitchState })
        .onChange((isOn: boolean) => {
          for (let i = 0; i < this.documentViews.length; i++) {
            this.documentViews[i].switchStatusDoc(isOn);
          }
          this.docSwitchState = isOn;
        })
    }
    .width(StyleConstants.FULL_WIDTH)
    .alignItems(VerticalAlign.Center)
    .align(Alignment.Start)
    .justifyContent(FlexAlign.Start)

    Divider()
      .vertical(false)
      .height(2)
      .color('#ff2f3235')
      .opacity(0.6)
      .margin({ top: 4, bottom: 4 })
  }

  @Builder
  brushShapeBuilder() {
    Row({ space: StyleConstants.SPACE_SIZE }) {
      Text('画笔形状')
      //荧光笔
      Button('🖍').onClick(() => {
        this.drawType = VHDocumentDrawType.HIGHLIGHTER_PEN;
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawType(this.drawType);
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('🖌').onClick(() => {
        this.drawType = VHDocumentDrawType.PATH;
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawType(this.drawType);
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('□').onClick(() => {
        this.drawType = VHDocumentDrawType.RECT;
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawType(this.drawType);
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('○').onClick(() => {
        this.drawType = VHDocumentDrawType.CIRCLE;
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawType(this.drawType);
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('△').onClick(() => {
        this.drawType = VHDocumentDrawType.ISOSCELES_TRIANGLE;
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawType(this.drawType);
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('⊿').onClick(() => {
        this.drawType = VHDocumentDrawType.RIGHT_TRIANGLE;
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawType(this.drawType);
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('→').onClick(() => {
        this.drawType = VHDocumentDrawType.SINGLE_ARROW;
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawType(this.drawType);
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('↔').onClick(() => {
        this.drawType = VHDocumentDrawType.DOUBLE_ARROW;
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawType(this.drawType);
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
    }
    .width(StyleConstants.FULL_WIDTH)
    .alignItems(VerticalAlign.Center)
    .align(Alignment.Start)
    .justifyContent(FlexAlign.Start)
    .height(32)
  }

  @Builder
  brushColorBuilder() {
    Row({ space: StyleConstants.SPACE_SIZE }) {
      Text('画笔颜色')
      Button('红').onClick(() => {
        this.fontColor = '#ff0000';
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('橙').onClick(() => {
        this.fontColor = '#FFA500';
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('黄').onClick(() => {
        this.fontColor = '#FFFF00';
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('绿').onClick(() => {
        this.fontColor = '#00ff00';
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('蓝').onClick(() => {
        this.fontColor = '#0000ff';
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('粉').onClick(() => {
        this.fontColor = '#FFC0CB';
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
      Button('黑').onClick(() => {
        this.fontColor = '#000000';
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
        }
      }).padding({ left: 2, right: 2 })
    }
    .width(StyleConstants.FULL_WIDTH)
    .alignItems(VerticalAlign.Center)
    .align(Alignment.Start)
    .justifyContent(FlexAlign.Start)
    .height(32)
  }

  @Builder
  brushSizeBuilder() {
    Row({ space: StyleConstants.SPACE_SIZE }) {
      Text('线字大小').width('20%')
      Text(this.fontSize.toString()).width('10%')
      Slider({
        min: 0,
        max: 100,
        step: 1,
        value: this.fontSize
      })
        .onChange((value: number, mode: SliderChangeMode) => {
          this.fontSize = Math.ceil(value);
          for (let i = 0; i < this.documentViews.length; i++) {
            this.documentViews[i].setDrawType(this.drawType);
            this.documentViews[i].setDrawTypeOption(this.fontColor, this.fontSize);
          }
        }).width('70%')
    }
    .width(StyleConstants.FULL_WIDTH)
    .alignItems(VerticalAlign.Center)
    .align(Alignment.Start)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  @Builder
  waterMarkBuilder() {
    Row({ space: StyleConstants.SPACE_SIZE }) {
      Column({ space: StyleConstants.SPACE_SIZE }) {
        Text('水印设置')
        Toggle({ type: ToggleType.Switch, isOn: false })
          .onChange((isOn: boolean) => {
            if (isOn) {
              this.waterMark.opacity = this.waterMarkOpacity;
              for (let i = 0; i < this.documentViews.length; i++) {
                this.documentViews[i].setWaterMark(this.waterMark);
              }
            } else {
              this.waterMark.opacity = 0.0;
              for (let i = 0; i < this.documentViews.length; i++) {
                this.documentViews[i].setWaterMark(this.waterMark);
              }
            }
          })
      }.width('20%')

      Column({ space: StyleConstants.SPACE_SIZE }) {
        Row({ space: 2 }) {
          Text('水印内容：')
          TextInput({ placeholder: 'hello world', text: 'hello world' })
            .onChange((value: string) => {
              this.waterMark.text = value;
            }).width('60%')
        }
        .justifyContent(FlexAlign.SpaceAround)

        Row({ space: 2 }) {
          Text('水印颜色：')
          TextInput({ placeholder: '0x000000', text: '#000000' })
            .onChange((value: string) => {
              this.waterMark.color = value;
            }).width('60%')
        }
        .justifyContent(FlexAlign.SpaceAround)

        Row({ space: 2 }) {
          Text('旋转角度：')
          TextInput({ placeholder: '0', text: '0' })
            .onChange((value: string) => {
              this.waterMark.angle = Number(value);
            }).width('60%')
        }
        .justifyContent(FlexAlign.SpaceAround)

        Row({ space: 2 }) {
          Text('字体大小：')
          TextInput({ placeholder: '10', text: '10' })
            .onChange((value: string) => {
              this.waterMark.fontSize = Number(value);
            }).width('60%')
        }
        .justifyContent(FlexAlign.SpaceAround)

        Row({ space: StyleConstants.SPACE_SIZE }) {
          Text('不透明度：')
          TextInput({ placeholder: '1.0', text: '1.0' })
            .onChange((value: string) => {
              this.waterMark.opacity = Number(value);
              this.waterMarkOpacity = Number(value);
            }).width('60%')
        }
        .justifyContent(FlexAlign.SpaceAround)
      }
      .width('80%')
      .justifyContent(FlexAlign.Start)
    }
    .width(StyleConstants.FULL_WIDTH)
    .alignItems(VerticalAlign.Center)
    .align(Alignment.Start)
    .justifyContent(FlexAlign.SpaceEvenly)
  }

  @Builder documentPaintBuilder(){
    Row({space:StyleConstants.SPACE_SIZE}){
      Text('画笔涂鸦')
        .fontSize(StyleConstants.BUTTON_FONT_SIZE)

      Toggle({ type: ToggleType.Switch, isOn: this.isDocPaint})
        .onChange((isOn: boolean) => {
          this.isDocPaint = isOn;
        })

      Divider().vertical(true).height(22).color('#ff2f3235').opacity(0.6).margin({ left: 8, right: 8 })

      Button('撤销').onClick(() => {
        const doc: VHDocument = this.getSelectDocumentByIndex(this.currentDocumentIndex) as VHDocument;
        if (doc.documentViewModel.isBoard) {
          doc.undo()
        } else {
          doc.preStep()
        }
      }).fontSize(StyleConstants.BUTTON_FONT_SIZE)
        .padding({ left: 2, right: 2 })

      Button('恢复').onClick(() => {
        const doc: VHDocument = this.getSelectDocumentByIndex(this.currentDocumentIndex) as VHDocument;
        if (doc.documentViewModel.isBoard) {
          doc.redo()
        } else {
          doc.nextStep()
        }
      }).fontSize(StyleConstants.BUTTON_FONT_SIZE)
        .padding({ left: 2, right: 2 });

      Divider()
        .vertical(true)
        .height(22)
        .color('#ff2f3235')
        .opacity(0.6)
        .margin({ left: 10, right: 10 })

      Button('移动').onClick(() => {
        this.getSelectDocumentByIndex(this.currentDocumentIndex)?.setDrawAction(VHDocumentDrawAction.MODIFY);
      })
        .fontSize(StyleConstants.BUTTON_FONT_SIZE)
        .padding({ left: 2, right: 2 })

      Button('橡皮擦').onClick(() => {
        this.getSelectDocumentByIndex(this.currentDocumentIndex)?.setDrawAction(VHDocumentDrawAction.DELETE);
      })
        .fontSize(StyleConstants.BUTTON_FONT_SIZE)
        .padding({ left: 2, right: 2 })

      Button('清除').onClick(() => {
        this.getSelectDocumentByIndex(this.currentDocumentIndex)?.clear();
      })
        .fontSize(StyleConstants.BUTTON_FONT_SIZE)
        .padding({ left: 2, right: 2 })
        .backgroundColor(Color.Red)
    }
    .width(StyleConstants.FULL_WIDTH)
    .alignItems(VerticalAlign.Center)
    .align(Alignment.Start)
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  documentButtonBuilder() {
    Row({ space: StyleConstants.SPACE_SIZE }) {
      if(this.isDocController){
        TextInput({ placeholder: '文档id', text: this.docId })
          .onChange((value: string) => {
            this.docId = value;
          }).width('30%')

        Button('+文档').onClick(() => {
          if (this.docId.length <= 0) {
            promptAction.showToast({
              duration: 2000,
              message: '请输入文档id'
            });
            return;
          }
          let mode = new VHDocumentViewModel(VHDocFilType.DOC);
          mode.docId = this.docId;
          mode.editEnable = this.isDocController;
          mode.docWidth = 720;
          mode.docHeight = 360;
          mode.backgroundColor = '#777777';
          let document: VHDocument = new VHDocument();
          // document.setVHDocInterface(this);
          //文档演示发起端主动创建需要调用此接口。
          document.initDemonstration(mode, this.access_token, this.lss_id, this.channel_id,this);
          this.insertDocumentItem(document);
          this.selectCid = mode.cid;
        })
          .fontSize(StyleConstants.BUTTON_FONT_SIZE)
          .padding({ left: 2, right: 2 });

        Button('+白板').onClick(() => {
          const mode = new VHDocumentViewModel(VHDocFilType.BOARD);
          mode.docId = this.docId;
          mode.editEnable = this.isDocController;
          mode.docWidth = 720;
          mode.docHeight = 360;
          mode.backgroundColor = '#ffffff';
          const document: VHDocument = new VHDocument();
          // document.setVHDocInterface(this);
          this.insertDocumentItem(document);
          document.initDemonstration(mode, this.access_token, this.lss_id, this.channel_id,this);
          this.selectCid = mode.cid;
        })
          .fontSize(StyleConstants.BUTTON_FONT_SIZE)
          .padding({ left: 2, right: 2 });

        Button('移除').onClick(() => {
          const document: VHDocument = this.documentViews[this.currentDocumentIndex];
          if(document){
            document.deleteDoc();
          }
          this.documentViews.splice(this.currentDocumentIndex, 1);
        })
          .fontSize(StyleConstants.BUTTON_FONT_SIZE)
          .padding({ left: 2, right: 2 });

        Divider()
          .vertical(true)
          .height(22)
          .color('#ff2f3235')
          .opacity(0.6)
          .margin({ left: 8, right: 8 })
      }

      Text('设为演示端')
      .fontSize(StyleConstants.BUTTON_FONT_SIZE)
      Toggle({ type: ToggleType.Switch, isOn: this.isDocController})
      .onChange((isOn: boolean) => {
        for (let i = 0; i < this.documentViews.length; i++) {
          this.documentViews[i].setEditable(isOn);
        }
        this.isDocController = isOn;
        if(isOn){
          //被设置为演示端时文档可见且允许涂鸦
          this.isDocPaint = isOn;
          this.showDoc = isOn;
        }
      })
    }
    .width(StyleConstants.FULL_WIDTH)
    .alignItems(VerticalAlign.Center)
    .align(Alignment.Start)
    .justifyContent(FlexAlign.Start)
  }

  build() {
    Column() {
      this.documentViewBuilder();
      this.documentButtonBuilder();
      if(this.isDocController){
        Column() {
          this.documentPageBuilder();
          this.documentPaintBuilder();
          this.brushShapeBuilder();
          this.brushColorBuilder();
          this.brushSizeBuilder();
          this.waterMarkBuilder();
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Start)
        .align(Alignment.TopStart)
      }
    }
    .height('100%')
    .width('100%')

  };

  aboutToAppear(): void {
    // 打印版本号
    console.log('Doc版本号' + VHDocument.getSDKVersion());
    // this.document.setVHDocInterface(this);
    //初始化直播文档，监听文档消息。
    this.document.initLiveDoc(this.lss_id, this.channel_id, this.access_token, true, this)
  }

  aboutToDisappear(): void {
    //释放文档消息监听。
    this.document.destroyDoc();
  }

  /**
   * 文档初始化、创建失败回调
   * @param errorCode 错误码
   * @param errorMsg  错误信息
   * @param cid 文档白板标识。
   */
  docError(errorCode: number, errorMsg: string, cid?: string): void {
    promptAction.showToast({
      duration: 2000,
      message: errorMsg
    });
    if (cid) {
      //当创建文档失败时，删除文档。
      if (this.isExistDocument(cid)) {
        this.removeDocumentItem(cid);
      }
    }
  }

  /**
   * 是否显示文档
   * @param switchStatus : true 文档可见状态。false：文档不可见状态
   */
  docSwitchStatus(switchStatus: boolean): void {
    //如果不是演示端，则收到是否显示文档时进行隐藏或显示处理，同时不允许进行涂鸦。是否为演示端需要业务侧自行处理。
    if(!this.isDocController){
      this.isDocPaint = false;
      this.showDoc = switchStatus;
    }
    this.docSwitchState = switchStatus;
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
    this.setTabSelectDocumentByCid(cid);
    this.selectCid = cid;
  }

  /**
   * 添加文档
   * @param documentView 文档视图
   */
  docAdd(docViewModel: VHDocumentViewModel): void {
    for (let index = 0; index < this.documentViews.length; index++) {
      const element = this.documentViews[index].documentViewModel
      if (element?.cid == docViewModel.cid) {
        this.documentViews[index].documentViewModel = docViewModel;
        return;
      }
    }
    let document: VHDocument = new VHDocument(docViewModel);
    document.setEditable(this.isDocController);
    //文档演示发起端,如果监听到创建新文档，需要调用此接口
    document.initDemonstrationFromMsg(this.access_token, this.lss_id, this.channel_id);
    this.insertDocumentItem(document);
  }

  /**
   * 删除文档
   * @param documentView 文档视图
   */
  docRemove(cid: string): void {
    this.removeDocumentItem(cid);
  }
}