import { util } from '@kit.ArkTS';

// Basic implementation of IDataSource to handle data listener
class VHBasicDataSourceClass implements IDataSource {
  private listeners: DataChangeListener[] = [];
  private originDataArray: Contact[] = [];

  public totalCount(): number {
    return 0;
  }

  public getData(index: number): Contact {
    return this.originDataArray[index];
  }

  // 该方法为框架侧调用，为LazyForEach组件向其数据源处添加listener监听
  registerDataChangeListener(listener: DataChangeListener): void {
    if (this.listeners.indexOf(listener) < 0) {
      console.info('add listener');
      this.listeners.push(listener);
    }
  }

  // 该方法为框架侧调用，为对应的LazyForEach组件在数据源处去除listener监听
  unregisterDataChangeListener(listener: DataChangeListener): void {
    const pos = this.listeners.indexOf(listener);
    if (pos >= 0) {
      console.info('remove listener');
      this.listeners.splice(pos, 1);
    }
  }

  // 通知LazyForEach组件需要重载所有子组件
  notifyDataReload(): void {
    this.listeners.forEach(listener => {
      listener.onDataReloaded();
    })
  }

  // 通知LazyForEach组件需要在index对应索引处添加子组件
  notifyDataAdd(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataAdd(index);
    })
  }

  // 通知LazyForEach组件在index对应索引处数据有变化，需要重建该子组件
  notifyDataChange(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataChange(index);
    })
  }

  // 通知LazyForEach组件需要在index对应索引处删除该子组件
  notifyDataDelete(index: number): void {
    this.listeners.forEach(listener => {
      listener.onDataDelete(index);
    })
  }

  // 通知LazyForEach组件将from索引和to索引处的子组件进行交换
  notifyDataMove(from: number, to: number): void {
    this.listeners.forEach(listener => {
      listener.onDataMove(from, to);
    })
  }
}

export class VHHistoryMessageDataSource extends VHBasicDataSourceClass {
  private dataArray: Contact[] = [];

  public totalCount(): number {
    return this.dataArray.length;
  }

  public getData(index: number): Contact {
    return this.dataArray[index];
  }

  public addData(index: number, item: Contact): void {
    this.dataArray.splice(index, 0, item);
    this.notifyDataAdd(index);
  }

  public pushData(item: Contact): void {
    this.dataArray.push(item);
    this.notifyDataAdd(this.dataArray.length - 1);
  }

  public unshiftData(item: Contact): void {
    this.dataArray.unshift(item);
    this.notifyDataAdd(0);
  }

}

export class Contact {
  avatar: string | undefined;
  nick_name: string | undefined;
  data: string | undefined;
  image_urls : string[] = [];
  key: string = util.generateRandomUUID(true);

  constructor(avatar: string, nick_name: string, data: string, image_urls?: string[]) {
    this.avatar = avatar;
    this.nick_name = nick_name;
    this.data = data;
    if (image_urls) {
      this.image_urls = image_urls;
    }
  }
}