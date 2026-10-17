# TypingPet for Mac

Swift + AppKit 的非官方 macOS 打字桌宠。优先 Apple Silicon（M1/M2/M3/M4 等），最低 macOS 13。

**此公开版本不附带任何第三方角色图片。** 首次打开显示代码绘制的原创小猫；你可以自行下载有权使用的素材，再一键导入。

## 下载与安装

打开本仓库 [Releases](../../releases/latest)，下载 `TypingPet-arm64.dmg`。不需要 Xcode 或开发经验。

1. 打开 DMG，将 TypingPet 拖到“应用程序”。已有旧版请先从爪印菜单退出，再替换。
2. 首次启动可能提示 Apple 无法验证。该版本只有 ad-hoc 签名，尚未经过 Developer ID 签名或 Apple 公证。确认来源后，在系统设置 → 隐私与安全性中对这个应用选择“仍要打开”。不要关闭系统整体安全保护。
3. 点击菜单栏爪印 → 授权／重新连接键盘互动。在系统设置 → 隐私与安全性 → 输入监控中允许 TypingPet，并退出重新打开。
4. 如果升级后开关已开却不动，移除输入监控里的旧 TypingPet，再点加号，添加 `/Applications/TypingPet.app` 并允许，退出重新打开。

## 一键导入角色

从素材作者提供的来源自行下载并解压。爪印菜单 → **一键导入素材文件夹** → 选中直接包含图片的文件夹。

自动识别文件名，不区分大小写，可使用 PNG/JPEG/GIF/APNG/WebP：

| 状态 | 文件名（任选一种，同一状态只留一张） |
|---|---|
| 待机，必需 | basic、idle、待机 |
| 左手，可选 | Left、左手 |
| 右手，可选 | Right、右手 |
| T-pose，可选 | T、tpose、t-pose |
| 太空，可选 | space、太空 |
| 庆祝，可选 | 1、celebrate、庆祝 |

例如 basic.png、Left.png、Right.png、T.png、space.png、1.png 可一次配好。每个文件小于 30 MB。只读取所选文件夹的这一层，不递归；若提示未找到待机图片，请进入解压包里的实际素材文件夹。导入前校验图片，失败保留现有角色。

打字时左右手交替，停笔约 0.55 秒后显示动作约 1.6 秒，然后回到待机；再次输入立即中断动作。有 T-pose 时以它为主，穿插其他可用造型。没有配置动作的角色正常待机。素材原本为静态图时，互动采用状态切换和轻微浮动，不会凭空生成新动画。

## 操作与隐私

拖动宠物移动，右键或菜单栏爪印设置尺寸、置顶、鼠标穿透、隐藏和暂停。鼠标穿透后可从菜单栏解锁。

监听仅响应系统 keyDown 事件，不读取字符内容、不记录按键、不联网上传。输入监控是系统权限；密码框与安全输入模式可能不触发。静态图使用 AppKit；动画使用系统 WebKit 图片解码，禁用脚本与外部网络资源，不使用 Electron。

素材和设置保存在 `~/Library/Application Support/TypingPet/`。导入后素材复制到本机，可移走原下载文件。旧版用户的本地角色保留，但不会上传到本仓库。

## 来源与署名

- 功能灵感：[swoonqx/TypingPet](https://github.com/swoonqx/TypingPet)，原项目为 Windows 应用。
- 用户提供的原素材来源：[Google Drive 文件夹](https://drive.google.com/drive/folders/1da-3jEGaK8cSDhahd9ijKUiewfrq0yf4?usp=sharing)。这是外部来源链接，不代表本项目拥有其版权或授予转载许可。请尊重作者说明，仅导入你有权使用的素材。

本项目借助 AI 使用 Swift/AppKit 独立实现，没有复制原项目源码或二进制，不是官方移植。源码 MIT 许可仅涵盖本仓库代码，不涵盖任何外部角色素材。

## 开发和验证

有 Apple 开发工具时运行 `bash scripts/build.sh`。先执行 XCTest，再编译 arm64、校验签名、生成 ZIP/DMG。没有开发工具可用 GitHub Actions 构建。14 项测试覆盖互动时序、旧设置兼容、素材文件夹匹配和缺失／歧义状态。云端构建不能代替完整真机测试，GIF/APNG/WebP 与不同 macOS 版本仍可能需要兼容性修复。

当前不含多宠物、开机启动、自动更新、连续尺寸滑块。仅支持 keyDown，不承诺媒体键、Fn 或单独修饰键触发。
