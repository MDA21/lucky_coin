# lucky_coin

**这是项目的说明文档**

**Author：Ziggy Stardust**

## 更新日志

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



## 初始项目结构时的节点类型选择和脚本继承

### 节点类型

在Godot中新建节点通常会要求用户在“2D场景”、“3D场景”、“用户界面”、“Node”......中进行选择，以下是我在创建框架时节点的类型配置，后续大家在创建时也请注意类型，避免后续重构的麻烦。

```
scenes/
├── ui/                           # 全部选择"用户界面"
│   ├── main_ui.tscn             → 用户界面
│   ├── hud.tscn                 → 用户界面
│   └── dialogs/                 → 用户界面
├── views/                       # 全部选择"2D场景"
│   ├── hall_view.tscn           → 2D场景
│   ├── slot_machine_view.tscn   → 2D场景
│   └── channel_view.tscn        → 2D场景
└── systems/                     # 选择"Node"
	└── game_manager.tscn        → Node

autoload/                       # 选择"Node"
	├── global.gd               → Node
	└── audio_manager.gd        → Node
```

### 脚本继承

#### **系统管理类脚本 → Node**

```
scripts/systems/
├── game_manager.gd         → extends Node
├── coin_system.gd          → extends Node
├── debt_system.gd          → extends Node
├── stress_system.gd        → extends Node
├── currency_system.gd      → extends Node
├── shop_system.gd          → extends Node
├── bank_system.gd          → extends Node
└── event_system.gd         → extends Node
```

**原因**：纯逻辑，不需要2D变换或UI功能

#### **视图控制类脚本 → Node2D**

```
scripts/views/
├── hall_view.gd            → extends Node2D
├── slot_machine_view.gd    → extends Node2D
└── channel_view.gd         → extends Node2D
```

**原因**：控制2D场景，需要位置、旋转、缩放等2D功能



#### **UI控制类脚本 → Control**

```
scripts/ui/
├── main_ui.gd              → extends Control
└── hud.gd                  → extends Control
```

**原因**：控制UI元素，需要锚点、布局、主题等UI功能



#### **组件脚本 → 根据功能选择**

```
scripts/components/
├── coin.gd                 → extends Node2D
├── channel.gd              → extends Node2D
└── interactive_area.gd     → extends Area2D (交互区域)
```

如果要修改，直接在脚本第一行修改即可。



## 杂项

由于我个人的开发习惯，我将场景`.tscn`与脚本`.gd`分开存放在不同文件夹中避免同名混淆以及美观。因此需要指定两者之间的依赖关系，方法也很简单：

1. 创建 `hall_view.tscn`，根节点选择 `Node2D`（在初始结构中已经完成）
2. 右键选中根节点，点击"添加脚本"
3. 选择 `hall_view.gd` 文件路径，选择现有的，新建的话，脚本统一存放在`script\`下
4. Godot会自动设置 `extends Node2D`



基于项目框架，我来详细说明每个脚本和场景需要完成的具体功能：

## 核心系统脚本

### **scripts/systems/game_manager.gd**

- 游戏总控制器，协调所有系统
- 管理游戏状态（开始、进行中、结束）
- 处理场景切换和视图层级管理
- 初始化所有子系统
- 保存/加载游戏进度

### **scripts/systems/coin_system.gd**

- 管理硬币池和硬币生成概率
- 实现硬币类型配置加载（从JSON）
- 处理硬币的组合算法（三叶草、柠檬、樱桃等图案组合）
- 计算硬币结算收益
- 根据道具效果调整硬币概率

### **scripts/systems/debt_system.gd**

- 跟踪玩家债务状态
- 管理每个大回合的强制偿还目标
- 检查玩家流动资产是否足够偿还债务
- 处理债务相关的debuff效果
- 实现债务结算逻辑

### **scripts/systems/stress_system.gd**

- 管理玩家压力值
- 实现压力增加/减少的计算公式
- 处理高压状态的特殊效果（幻觉界面、恐怖元素）
- 实现暴怒状态的惩罚机制
- 管理压力恢复机制

### **scripts/systems/currency_system.gd**

- 管理两种货币（常规货币$、赌场货币）
- 处理货币的获取和消耗
- 验证货币交易的有效性
- 实现货币转换逻辑

### **scripts/systems/shop_system.gd**

- 管理商店物品和库存
- 处理道具购买逻辑
- 实现道具效果应用
- 管理道具冷却和使用次数
- 处理商店刷新机制

### **scripts/systems/bank_system.gd**

- 管理存款和贷款功能
- 计算存款利息和贷款利息
- 处理猫猫币的买入、抛售和价值波动
- 实现强制扣款逻辑
- 管理金融资产状态

### **scripts/systems/event_system.gd**

- 管理随机事件触发
- 实现事件效果应用
- 处理事件选择界面
- 管理事件冷却和触发条件

## 视图控制脚本

### **scripts/views/hall_view.gd**

- 处理大厅视角的点击交互
- 管理墙面裂缝等可点击区域的检测
- 实现视角拉近/拉远效果
- 处理视角切换到大推币机
- 渲染大厅背景和压迫感视觉效果

### **scripts/views/slot_machine_view.gd**

- 管理推币机操作界面
- 处理通道解锁逻辑和费用计算
- 实现拉杆拉动动画和硬币灌注
- 管理倍率选择界面
- 处理退出到大厅的逻辑

### **scripts/views/channel_view.gd**

- 显示通道内硬币的排列
- 实现硬币堆的视觉表现（第一次拉杆后模糊，第二次清晰）
- 处理通道观察的交互
- 管理多个通道的切换查看

## UI控制脚本

### **scripts/ui/main_ui.gd**

- 管理主UI界面的布局
- 处理菜单按钮交互
- 实现设置界面
- 管理游戏暂停功能

### **scripts/ui/hud.gd**

- 显示玩家状态信息（金钱、压力、债务）
- 更新实时数据展示
- 管理通知和提示信息
- 处理HUD元素的动画效果

## 组件脚本

### **scripts/components/coin.gd**

- 定义硬币的基类行为
- 管理硬币的视觉表现（纹理、动画）
- 实现硬币类型特定的逻辑
- 处理硬币的交互检测

### **scripts/components/channel.gd**

- 管理单个通道的状态
- 处理通道内硬币的排列
- 实现通道结算逻辑
- 管理通道解锁状态

### **scripts/components/interactive_area.gd**

- 定义可交互区域的基础功能
- 处理鼠标悬停和点击事件
- 管理交互反馈效果
- 提供通用的交互接口

## 自动加载脚本

### **autoload/global.gd**

- 提供全局变量和常量
- 实现通用的工具函数
- 管理游戏配置数据
- 提供跨场景的数据传递

### **autoload/audio_manager.gd**

- 管理背景音乐播放
- 处理音效触发和播放
- 实现音频设置（音量控制）
- 管理音频资源加载

## 场景节点功能

### **scenes/views/hall_view.tscn**

- 渲染大厅背景和墙面
- 包含推币机、商店、银行等交互区域
- 实现视角切换的Camera2D
- 提供墙面裂缝等细节交互点

### **scenes/views/slot_machine_view.tscn**

- 推币机主体视觉表现
- 硬币山视觉效果（无边界、巨物感）
- 通道容器和单个通道UI
- 拉杆、按钮等交互元素
- 出币口视觉效果

### **scenes/views/channel_view.tscn**

- 通道内部硬币排列显示
- 多个通道的切换界面
- 硬币堆的视觉层次
- 观察模式的UI元素

### **scenes/ui/main_ui.tscn**

- 主菜单界面布局
- 开始游戏、设置、退出等按钮
- 标题和背景元素

### **scenes/ui/hud.tscn**

- 状态信息显示面板
- 货币数量显示
- 压力值进度条
- 债务信息面板

### **scenes/systems/game_manager.tscn**

- 系统管理器的容器节点
- 各个子系统的组织结构
- 全局状态管理节点

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
