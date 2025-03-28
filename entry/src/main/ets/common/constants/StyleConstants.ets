/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
// 创建一个包含多个参数的对象
export class logData {
  public join_id: number =  0;
  public is_filter: number = 0;
  public visitor_id: string = '';
}

/**
 * Style constants for all features.
 */
export default class StyleConstants {
  /**
   * The width or height of the component is spread across the parent component.
   */
  static readonly FULL_HEIGHT: string = '100%';

  /**
   * The width of button.
   */
  static readonly FULL_WIDTH: string = '100%';

  /**
   * The player height.
   */
  static readonly VH_PLAYER_NORMAL_HEIGHT: string = '30%';

  /**
   * Grid columns of the 4.
   */
  static readonly GRID_COLUMNS: string = '1fr 1fr 1fr 1fr';

  /**
   * Grid rows of two the 2.
   */
  static readonly GRID_ROWS: string = '1fr 1fr';

  /**
   * Column space of the 12pv.
   */
  static readonly COLUMN_SPACE: string = '12pv';

  /**
   * Row space of the 12pv.
   */
  static readonly ROW_SPACE: string = '10pv';

  /**
   * Item space of the 8pv.
   */
  static readonly ITEM_SPACE: string = '8pv';

  /**
   * 播放时长
   * */
  static readonly PLAY_TIME: string = '100vp';

  /**
   * 循环播放
   * */
  static readonly PLAY_LOOP_TEXT_WIDHT: string = '80vp';

  /**
   * Input length of the account.
   */
  static readonly INPUT_ACCOUNT_LENGTH: number = 11;

  /**
   * Input length of the account.
   */
  static readonly BUTTON_FONT_SIZE: number = 14;

  /**
   * 提示时长
   * */
  static readonly PLAY_ERROR_TIME: number = 4000;

  /**
   * 1024 bps 以下
   * */
  static readonly PLAY_SPEED_BPS: number = 1024;
  /**
   * kbps
   * */
  static readonly PLAY_SPEED_KBPS: number = 1024*1024;
  /**
   * mbps
   * */
  static readonly PLAY_SPEED_MBPS: number = 1024*1024*1024;
  /**
   * gbps
   * */
  static readonly PLAY_SPEED_GBPS: number = 1024*1024*1024*1024;

  /**
   * 静音
   * */
  static readonly PLAY_MUTE: string = '静音';

  /**
   * 播放
   * */
  static readonly PLAY_UN_MUTE: string = '播放';

  /**
   * 播放
   * */
  static readonly PLAY_SPEED_0_75: string = '0.75倍';
  static readonly PLAY_SPEED_1_00: string = '1.00倍';
  static readonly PLAY_SPEED_1_25: string = '1.25倍';
  static readonly PLAY_SPEED_1_75: string = '1.75倍';
  static readonly PLAY_SPEED_2_00: string = '2.00倍';

  /**
   * 裁剪
   * */
  static readonly PLAY_Fill: string = '拉伸填充';
  static readonly PLAY_AspectFit: string = '等比例缩放';
  static readonly PLAY_AspectFill: string = '等比例铺满';
  static readonly WATERMARK_InputWidth: string = '150vp';


  static readonly START_PAINT: string = '开始涂鸦';
  static readonly STOP_PAINT: string = '结束涂鸦';

  static readonly SPACE_SIZE = 4;
}