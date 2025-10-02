# lucky_coin

**这是项目的说明文档**

**Author：Ziggy Stardust**


## 项目结构

```
project/
├── scenes/                          # 主要场景文件
│   ├── ui/                         # UI相关场景
│   │   ├── main_ui.tscn            # 主UI界面
│   │   ├── hud.tscn                # 游戏HUD
│   │   └── dialogs/                # 各种对话框
│   ├── views/                      # 游戏视图场景
│   │   ├── hall_view.tscn          # 大厅视角（一级）
│   │   ├── slot_machine_view.tscn  # 推币机视角（二级）
│   │   └── channel_view.tscn       # 通道视角（三级）
│   └── systems/                    # 系统管理场景
│       └── game_manager.tscn       # 游戏管理器
├── scripts/                        # 脚本文件
│   ├── systems/                    # 核心系统
│   │   ├── game_manager.gd         # 游戏总管理器
│   │   ├── coin_system.gd          # 硬币系统
│   │   ├── debt_system.gd          # 债务系统
│   │   ├── stress_system.gd        # 压力系统
│   │   ├── currency_system.gd      # 货币系统
│   │   ├── shop_system.gd          # 商店系统
│   │   ├── bank_system.gd          # 银行系统
│   │   └── event_system.gd         # 事件系统
│   ├── views/                      # 视图控制
│   │   ├── hall_view.gd
│   │   ├── slot_machine_view.gd
│   │   └── channel_view.gd
│   ├── ui/                         # UI控制
│   │   ├── main_ui.gd
│   │   └── hud.gd
│   └── components/                 # 组件脚本
│       ├── coin.gd                 # 硬币基类
│       ├── channel.gd              # 通道组件
│       └── interactive_area.gd     # 可交互区域
├── assets/                         # 资源文件
│   ├── images/
│   │   ├── coins/                  # 硬币图片
│   │   ├── ui/                     # UI图片
│   │   └── backgrounds/            # 背景图片
│   ├── fonts/                      # 字体文件
│   └── audio/                      # 音效文件
├── data/                           # 数据文件
│   ├── coin_types.json             # 硬币类型配置
│   ├── shop_items.json             # 商店物品配置
│   ├── debt_config.json            # 债务配置
│   └── game_config.json            # 游戏配置
└── autoload/                       # 自动加载脚本
	├── global.gd                   # 全局变量和方法
	└── audio_manager.gd            # 音频管理器
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
