# lucky_coin

**这是项目的说明文档**

**Author：Ziggy Stardust**



## 最终说明

### 关于商店

不管是实现还是没实现的物品，我都没有把他们从商店下架，方便展示刷新机制，也可以购买，但是不会生效

未实现的物品清单

```

	"metal_detector": {
	  "name": "金属探测器",
	  "description": "显示每个通道内不同硬币的组成比例",
	  "price": 100,
	  "texture": "res://project/assets/item/metal_detector.png",
	  "effect_type": "permanent",
	  "effect": "show_channel_distribution"
	},    原因：现在鼠标停留在通道上就可以显示比例
	"talisman": {
	  "name": "护身符",
	  "description": "限次道具，二次筛选时有33%概率触发幸运值+5，最多触发8次",
	  "price": 600,
	  "texture": "res://project/assets/item/talisman.png",
	  "effect_type": "limited_use",
	  "max_uses": 8,
	  "effect": "increase_luck",
	  "effect_value": {"probability": 0.33, "luck_bonus": 5}
	},     原因：无幸运值
	"abyss_eye": {
	  "name": "深渊之眼",
	  "description": "限次道具，小回合结束后有20%概率触发额外小回合，最多触发3次",
	  "price": 450,
	  "texture": "res://project/assets/item/abyss_eye.png",
	  "effect_type": "limited_use",
	  "max_uses": 3,
	  "effect": "extra_sub_round",
	  "effect_value": {"probability": 0.20}
	},     原因：逻辑很复杂，会影响所有系统的回合末结算
	"digital_totem": {
	  "name": "数字图腾",
	  "description": "三四五连的图案倍率+0.5",
	  "price": 350,
	  "texture": "res://project/assets/item/digital_totem.png",
	  "effect_type": "permanent",
	  "effect": "increase_basic_pattern_multiplier",
	  "effect_value": 0.5
	},      原因：不是图案结算机制，其他的提升图案出现机制我都是直接加在出现概率上，但提升特定图案做不到
	"originium_tech": {
	  "name": "源石科技",
	  "description": "一次性道具，所有充能道具立刻准备就绪",
	  "price": 666,
	  "texture": "res://project/assets/item/originium_tech.png",
	  "effect_type": "consumable",
	  "max_uses": 1,
	  "effect": "recharge_all_items"
	}
```



## 更新日志

**2025 10.25 Ziggy**

完成了所有场景和后端，剩下debug，今天还会有push

**2025 10.24 Ziggy**

完善商店/贷款系统与ui的链接与刷新，先推上来，今天还会继续改

商店系统和贷款系统大成，channel_view的动画bug无法解决暂且搁置

**2025.10.23 Ziggy**

完成银行的贷款功能和ui更新，删除了重复的方法，简化了游戏状态判断的逻辑

**2025.10.23 泽康**
完成所有场景的转换逻辑<br>
最后需要完成的都使用[TODO]标记

**2025.10.20 泽康**

完成了除channel场景之外所有场景逻辑的建立，制作了hall_view硬币掉落的动画

**2025.10.20 Ziggy**

重新更新了债务系统和游戏胜利判定逻辑，完成了商店物品的上架和刷新

**2025.10.19 泽康**

导入了UI图片

完成了除channel视角之外其他所有视角的切换逻辑、点击逻辑；<br>
[TODO]channel视角未完成

**2025.10.17 Ziggy**

修了一些显然的bug，但估计还有不少得具体调试才知道。尝试实现硬币从硬币山进入通道的物理效果（coin_system.gd/coin.gd/channel.gd）

配置了事件系统和商店系统，但这部分我想优先级往后放，所以一些buff先留着还没有实现。

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



- ## 
