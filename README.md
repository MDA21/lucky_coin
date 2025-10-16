# lucky_coin

**这是项目的说明文档**

**Author：Ziggy Stardust**

## 更新日志
**2025.10.15 Ziggy**

重构了债务系统、银行系统、商店系统，配置了对应的数据文件，仍然存在bug，稍后修

**2025.10.15 泽康**

导入了道具素材，将所有图片、动画进行了归类；<br>
重新设计了银行、商店和出口场景，完善了场景的转换；<br>
完善了此文件下方的文件树；<br>
删除了base_view场景；<br>
在该文件下方添加“场景接口”部分<br>
[TODO]仍有：推币机大厅视图、推币机视图、贷款弹窗未完成，场景切换的bug未解决

**2025.10.15 Ziggy**

完成了图案识别脚本，硬币板脚本，更新了货币系统、压力系统、硬币系统

**2025.10.13 泽康**

导入了图片和动画素材 

**2025.10.6 泽康**

完成了左上角进度条UI的初步编写，并合并了两个冲突的代码分支。

**2025.10.6 Ziggy**

完成了大部分游戏核心系统的脚本编写，并挂载到game_manager。创建了两个全局变量（autoload和game_manager），新增了通知弹窗场景并配上粗糙动画。更新了game_manager的控制脚本。更新了硬币、商店、债务等数据文件（.json）

**2025.10.6 泽康** 

创建了main_menu hall bank store四个一级视图和base视图用于继承。在main_menu视图中设置了“开始游戏”按钮，在hall场景中建立了简单的文字说明和拉杆的接口，实现了三个场景之间的跳转（按A D键跳转）。

**2025.10.4  Ziggy**

在文档末尾补充了每个脚本/场景的具体功能，完成了scripts/components三个脚本，在场景中新建了一些节点，具体见代码

## 场景接口

### exit_view

变量`current_door_state`对应场景的三种状态：未解锁、解锁和打开，对应场景中的四张贴图；在`game_manager.gd`中存在`is_game_won()`函数，如果输出`true`，则场景对应变为解锁，象征着游戏已经胜利。玩家可以逃出去。

### store_view

远近场景切换已完成，近景`CloseUpView`下的`RefreshPanel`为刷新设置，子节点`Label`可以设置本次刷新所需要的价格；`ItemContainer`下的五个分别对应不同道具，可以设置其点击逻辑、道具贴图和购买价格

### bank_view

远近景切换逻辑已完成，其对应的弹窗中的三个`label`可以设置三档贷款的金额、利率和还款时间并设置其逻辑，并设置下面按钮的跳转逻辑。

## 项目结构（更新中）

```
lucky_coin/
├── scenes/                          # 主要场景文件
│   ├── components/                  # 组件场景
│   │   ├── coin.tscn               # 硬币组件场景（待创建）
│   │   ├── channel.tscn            # 通道组件场景（待创建）
│   │   └── interactive_area.tscn   # 交互区域场景（待创建）
│   ├── ui/                         # UI相关场景
│   │   ├── notification_popup.tscn # 通知弹窗场景 ✅ 
│   │   │   └── Control (NotificationPopup)
│   │   │       ├── ColorRect
│   │   │       ├── MarginContainer
│   │   │       │   └── Label
│   │   │       └── AnimationPlayer
│   │   ├── main_ui.tscn            # 主UI界面（待创建）
│   │   ├── hud.tscn                # 游戏HUD（待创建）
│   │   └── dialogs/                # 各种对话框（待创建）
│   ├── views/                      # 游戏视图场景
|   |   ├── base_view.tscn          # 一级视角基类，用于继承✅
│   │   ├── main_menu_view.tscn     # 主菜单视角（一级）✅
│   │   ├── hall_view.tscn          # 大厅视角（一级）✅
|   |   ├── bank_view.tscn          # 银行视角（一级）✅
|   |   ├── store_view.tscn         # 商店视角（一级）✅
│   │   ├── slot_machine_view.tscn  # 推币机视角（二级）（待创建）
│   └── systems/                    # 系统管理场景
│       └── game_manager.tscn       # 游戏管理器 ✅ (已创建，并包含子系统节点)
├── scripts/                        # 脚本文件
│   ├── systems/                    # 核心系统
│   │   ├── game_manager.gd         # 游戏总管理器✅（暂时）
│   │   ├── coin_system.gd          # 硬币系统 ✅
│   │   ├── debt_system.gd          # 债务系统 ✅
│   │   ├── stress_system.gd        # 压力系统 ✅
│   │   ├── currency_system.gd      # 货币系统（待创建）
│   │   ├── shop_system.gd          # 商店系统 ✅
│   │   ├── bank_system.gd          # 银行系统 ✅
│   │   └── event_system.gd         # 事件系统（待创建）
│   ├── views/                      # 视图控制
│   │   ├── main_menu_view.gd       # 主菜单控制（开始游戏）✅
│   │   ├── base_view.gd            # 基类视图控制✅
│   │   ├── hall_view.gd            # 大厅视图控制✅
│   │   ├── store_view.gd           # 大厅视图控制✅
│   │   ├── bank_view.gd            # 大厅视图控制✅
│   │   ├── slot_machine_view.gd    # 推币机视图控制（待创建）
│   │   └── channel_view.gd         # 通道视图控制（待创建）
│   ├── ui/                         # UI控制
│   │   ├── notification_popup.gd   # 通知弹窗脚本 ✅ 
│   │   ├── main_ui.gd              # 主UI控制（待创建）
│   │   └── hud.gd                  # HUD控制（待创建）
│   └── components/                 # 组件脚本
│       ├── coin.gd                 # 硬币基类 ✅
│       ├── channel.gd              # 通道组件 ✅
│       └── interactive_area.gd     # 可交互区域 ✅
├── assets/                         # 资源文件
│   ├── images/
│   │   ├── coins/                  # 硬币图片（需要创建）
│   │   ├── ui/                     # UI图片（需要创建）
│   │   └── backgrounds/            # 背景图片（需要创建）
│   ├── fonts/                      # 字体文件（需要创建）
│   └── audio/                      # 音效文件（需要创建）
├── data/                           # 数据文件
│   ├── coin_types.json             # 硬币类型配置 ✅ (已更新内容)
│   ├── shop_items.json             # 商店物品配置 ✅ (已更新内容)
│   ├── debt_config.json            # 债务配置 ✅ (已更新内容)
│   └── game_config.json            # 游戏配置 ✅ (已更新内容)
└── autoload/                       # 自动加载脚本
	├── global.gd                   # 全局变量和方法 ✅ (已设置Autoload)
	└── audio_manager.gd            # 音频管理器（待创建）
```



- ## 已完成的核心系统功能与责任

  ### ✅ 已完成的系统

  #### 1. **GameManager** (`scripts/systems/game_manager.gd`)
  - **责任**: 游戏总控制器，协调所有子系统
  - **功能**: 
    - 初始化所有子系统
    - 管理游戏状态（开始、进行中、结束）
    - 提供系统获取接口
    - 场景切换和视图管理

  #### 2. **CoinSystem** (`scripts/systems/coin_system.gd`)
  - **责任**: 硬币生成和概率管理
  - **功能**:
    - 管理硬币山分布（6种硬币类型）
    - 实现条件概率：硬币山 → 通道 → 硬币板
    - 处理硬币两面性和高价值概率
    - 应用增益效果到硬币分布

  #### 3. **ChannelSystem** (`scripts/systems/channel_system.gd`)
  - **责任**: 通道解锁和管理
  - **功能**:
    - 管理递增解锁费用
    - 处理通道的解锁、抛弃状态
    - 与硬币系统集成填充通道

  #### 4. **PatternSystem** (`scripts/systems/pattern_system.gd`)
  - **责任**: 图案识别和检测
  - **功能**:
    - 检测11种图案组合
    - 实现排除规则（基础图案算大不算小）
    - 提供图案数据查询

  #### 5. **ComboCalculator** (`scripts/systems/combo_calculator.gd`)
  - **责任**: 收益和压力结算计算
  - **功能**:
    - 计算单个/多个通道的结算结果
    - 应用特殊规则（血币+骷髅币惩罚）
    - 分离真硬币收益和图案收益

  #### 6. **CurrencySystem** (`scripts/systems/currency_system.gd`)
  - **责任**: 货币管理和区分
  - **功能**:
    - 区分贷款币和普通币
    - 管理货币来源和消费策略
    - 银行存储限制（贷款币不能存）
    - 统一的货币交易接口

  #### 7. **StressSystem** (`scripts/systems/stress_system.gd`)
  - **责任**: 压力值管理和视觉效果
  - **功能**:
    - 压力值计算和限制
    - 压力触发条件实现
    - 视觉效果（扭曲、滤镜）
    - 贷款压力管理

  #### 8. **BankSystem** (`scripts/systems/bank_system.gd`)
  - **责任**: 银行和贷款管理
  - **功能**:
    - 存款利息计算
    - 短期/长期贷款管理
    - 还款计划和压力减少
    - 贷款违约处理

  #### 9. **Global** (`autoload/global.gd`)
  - **责任**: 全局接口和信号中心
  - **功能**:
    - 系统引用缓存和转发
    - 全局信号中心
    - 便捷方法提供
    - 游戏状态管理

  ### ⏳ 待更新/创建的系统

  #### 1. **DebtSystem** (`scripts/systems/debt_system.gd`)
  - **责任**: 债务目标管理和检查
  - **待完成**:
    - 实现6个大回合债务目标
    - 集成新货币系统检查偿还能力
    - 债务结算和游戏结束条件

  #### 2. **ShopSystem** (`scripts/systems/shop_system.gd`)
  - **责任**: 商店道具管理和效果
  - **待完成**:
    - 更新道具效果匹配新系统
    - 实现刷新机制（初始20\$，×1.5递增）
    - 道具分类管理（永久、充能、限次、一次性）

  #### 3. **EventSystem** (`scripts/systems/event_system.gd`)
  - **责任**: 随机增益事件管理
  - **待完成**:
    - 实现5个增益选择（3选1）
    - 增益分类实现（图案概率、价值、压力、银行、道具）
    - 增益效果应用

  #### 4. **UI系统** (`scripts/ui/`)
  - **责任**: 用户界面和HUD
  - **待完成**:
    - 主UI界面 (`main_ui.gd`)
    - HUD控制 (`hud.gd`)
    - 货币区分显示
    - 压力视觉效果集成

  ## 剩余工作优先级

  ### 🔴 高优先级（核心游戏循环）

  1. **更新债务系统** - 实现回合债务目标
  2. **更新商店系统** - 适配新道具效果
  3. **创建事件系统** - 随机增益机制
  4. **主UI/HUD** - 游戏状态显示

  ### 🟡 中优先级（游戏流程）

  5. **回合管理系统** - 6大回合×4小回合流程
  6. **推币机流程完善** - 倍率选择、通道观察
  7. **资源创建** - 硬币纹理、UI素材

  ### 🟢 低优先级（完善功能）

  8. **音频系统** - 音效和背景音乐
  9. **保存/加载系统** - 游戏进度管理
  10. **优化和调试** - 平衡性和性能

  ## 系统依赖关系

  ```
  GameManager (协调中心)
      ├── CoinSystem (硬币生成)
      │   └── 被: ChannelSystem, PatternGrid 调用
      ├── ChannelSystem (通道管理) 
      │   └── 被: SlotMachineView 调用
      ├── PatternSystem (图案识别)
      │   └── 被: ComboCalculator 调用
      ├── ComboCalculator (收益计算)
      │   ├── 依赖: PatternSystem, StressSystem
      │   └── 被: SlotMachineView 调用
      ├── CurrencySystem (货币管理)
      │   └── 被: 所有经济相关系统调用
      ├── StressSystem (压力管理)
      │   └── 被: ComboCalculator, BankSystem 调用
      ├── BankSystem (银行系统)
      │   ├── 依赖: CurrencySystem, StressSystem
      │   └── 被: BankView 调用
      ├── DebtSystem (债务系统) [待更新]
      ├── ShopSystem (商店系统) [待更新]
      └── EventSystem (事件系统) [待创建]
  ```

  ## 下一步建议

  建议按以下顺序完成剩余工作：

  1. **先完成债务系统更新** - 这是游戏进度控制的核心
  2. **然后更新商店系统** - 提供玩家成长路径  
  3. **创建事件系统** - 增加游戏随机性和重玩价值
  4. **最后完善UI系统** - 提供完整的用户体验

  每个系统完成后都可以进行独立测试，确保核心机制正确后再进行集成。

## 数据文件内容

### **data/coin_types.json**

我暂时填充了两种

```json
{
  "real_coin": {
	"name": "真硬币",
	"base_value": 1,
	"texture": "res://assets/coins/real.png",
	"is_direct_cash": true
  },
  "clover_coin": {
	"name": "三叶草币",
	"texture": "res://assets/coins/clover.png",
	"patterns": ["weed", "clover", "four_leaf_clover"],
	"pattern_values": [1, 2, 5],
	"combo_settings": {
	  "same_type_multiplier": 1.2,
	  "min_combo_count": 3
	}
  }
  // ... 其他硬币类型
}
```

### **data/shop_items.json**

- 道具名称、描述、价格
- 道具效果类型和数值
- 使用限制（次数、冷却）
- 图标路径和稀有度

### **data/debt_config.json**

- 债务周期设置
- 偿还目标计算公式
- 利息率和惩罚规则
- 游戏结束条件

### **data/game_config.json**

- 游戏基础参数
- 压力系统配置
- 视觉和音频设置
- 平衡性参数
