# Tracker AppImage

**给 Linux 用户的即开即用 [Tracker](https://opensourcephysics.github.io/tracker-website/) 视频分析工具。**

Tracker 官方对 Windows / macOS 都提供安装包，唯独 Linux 停在 6.2.0（2024 年 6 月），
而且托管在 `physlets.org` 上——这个域名在国内经常连接超时，点"下载"半天没反应。
本仓库直接把**官方最新 6.3.5 的 jar** 打包成一个 55 MB 的 AppImage：

- 从 Releases 下载一个文件 → 双击就能用，不写注册表、不装依赖（除 Java）
- 视频解码用官方随附的 xuggle 引擎，mp4 / avi / mov / 序列帧都能开
- 高分屏自动缩放（读 `Xft.dpi`），也可用环境变量覆盖

## 下载即用

从 **Releases** 页面下载 `Tracker-6.3.5-x86_64.AppImage`，然后：

```bash
chmod +x Tracker-6.3.5-x86_64.AppImage
./Tracker-6.3.5-x86_64.AppImage
```

完事。没有安装步骤，也没有安装残留——文件删了就等于卸载。

### 运行要求

| 依赖 | 说明 |
|---|---|
| **Java 17+** | 唯一的非内置依赖，用系统 JRE 即可。没有的话 `sudo apt install openjdk-17-jre`（Debian/Ubuntu）或到 [Adoptium](https://adoptium.net/) 装一个，缺失时 AppImage 会打印安装指引 |
| FUSE | 绝大多数发行版自带。若报 `libfuse.so.2: cannot open shared object file`（Ubuntu 24.04+ 常见），改用 `./Tracker-6.3.5-x86_64.AppImage --appimage-extract-and-run`，或 `sudo apt install libfuse2t64` |

### 高分屏缩放

启动时自动读 `Xft.dpi` 换算（96→1×、192→2×、240→2.5×）。不合适就覆盖：

```bash
TRACKER_SCALE=3 ./Tracker-6.3.5-x86_64.AppImage
```

### 个人数据在哪

Tracker 自己的配置写在 `~/.tracker.prefs` 和 `~/.config/OSP/`（含 Library Browser 的
下载缓存，可能到几百 MB）。AppImage 不碰系统级目录，不注册 `.desktop`；
想要应用菜单图标的话，用桌面自带的"集成到系统"功能，或 `appimagetool --install-appimage`——由你主动选择。

## 自己构建

需要 `curl`、`unzip`，其余脚本自动下载；**装了 `aria2c` 会自动用 16 线程分段下载**（`sudo apt install aria2`，国内直连 GitHub 明显更快，没有则回退单线程 curl）：

```bash
./build.sh                       # 默认 6.3.5
TRACKER_VERSION=6.3.4 ./build.sh  # 指定版本
```

产物：`Tracker-<版本>-x86_64.AppImage`。上游 jar 缓存在 `build/cache/`（已 gitignore）。

所有上游文件的来源：

| 组件 | 来源 |
|---|---|
| `tracker.jar` | `opensourcephysics.github.io/tracker-website/archives/`（官网同款） |
| `xuggle-xuggler-server-all.jar` 等 3 个库 | GitHub 仓库 `OpenSourcePhysics/tracker` 的 `version_*` tag |
| appimagetool / runtime | `github.com/AppImage/*` continuous release |

## AppRun 的两个坑（改脚本前先看）

1. **必须预先 `export TRACKER_HOME` / `XUGGLE_HOME`**：否则 Tracker 启动时会用
   `TrackerStarter` 把自己重启一遍（换父进程），AppImage 的 FUSE 挂载点随即卸载，
   之后的懒加载类会报 `NoClassDefFoundError`。
2. **缩放必须走 `_JAVA_OPTIONS` 环境变量**，不能用命令行 `-D`——同样会被那次
   relaunch 丢掉（环境变量则会继承给子进程）。

## 许可

- Tracker 本身：GPL-3.0，© Douglas Brown、Wolfgang Christian、Robert M Hanson，
  源码见 [OpenSourcePhysics/tracker](https://github.com/OpenSourcePhysics/tracker)。
  本仓库不含修改过的 Tracker 代码，只做打包分发。
- 本仓库的脚本与配置：GPL-3.0（见 `LICENSE`）。
- 图标 `icon.png` 取自官方 jar 内的 `tracker_icon_256.png`，随 Tracker 许可。

本项目与 Tracker 上游作者无关，仅解决其 Linux 分发渠道的可达性问题。

## 已验证环境

- Linux Mint 22.3 x86_64、OpenJDK 25、3200×2000 高分屏（`Xft.dpi=192`）
- 验证内容：启动出窗口、mp4 播放、自动缩放 2.5×、Tracker 自重启场景下挂载点存活