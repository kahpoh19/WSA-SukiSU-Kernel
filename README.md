# WSA SukiSU Nova Kernel

为 Windows Subsystem for Android 编译的内核，内置 [SukiSU Nova](https://github.com/SukiSU-Nova/SukiSU-Nova)。适用于 [WSABuilds](https://github.com/MustardChef/WSABuilds) LTS_8 等 **WSA 2407.40000.4.0 x64** 的包。

SukiSU Nova 发布新的稳定版后，本仓库会通过 GitHub Actions 自动编译并发布对应的内核。

| 项目 | 内容 |
|---|---|
| 内核源码 | [microsoft/WSA-Linux-Kernel](https://github.com/microsoft/WSA-Linux-Kernel) `android-lts/latte-2/5.15.104.4` |
| 配置 | 官方 `configs/wsa/config-wsa-x64` + `CONFIG_KSU=y` + `CONFIG_KSU_X86_PATCH_SYSCALL_DISPATCHER=y` |
| 编译器 | clang / LLD（Ubuntu 24.04 自带） |
| `uname -r` | `5.15.104-windows-subsystem-for-android-20230927`，与原版内核相同 |

> [!WARNING]
> 个人项目，与 Microsoft、WSABuilds、SukiSU 官方均无关。只在 QEMU 里验证过能启动，以及在作者自己的 WSA 上用过。替换前请务必备份原内核。

---

## 目录

- [下载](#下载)
- [完整安装流程（GApps + SukiSU，不带 Magisk）](#完整安装流程gapps--sukisu不带-magisk)
- [更新 SukiSU](#更新-sukisu)
- [挂载模块（metamodule）兼容性](#挂载模块metamodule兼容性)
- [常见问题](#常见问题)
- [自动构建与手动构建](#自动构建与手动构建)
- [tools/](#tools)
- [致谢](#致谢)

---

## 下载

到 [**Releases**](../../releases) 下载 `kernel`。

- Release 名称格式：`WSA-5.15.104.4-SukiSU-<版本>`（开了 KPM 的会带 `-KPM` 后缀）
- 同版本的管理器 APK 会一起附在 Release 里：上游有 **x86_64** 版就用 x86_64 版，没有才用 **universal** 版，两种都没有就不附带（Release 说明里会给出上游的下载链接）

---

## 完整安装流程（GApps + SukiSU，不带 Magisk）

WSABuilds 的 GApps 包默认自带 Magisk，GApps 也是靠 Magisk 挂载的，所以和 SukiSU 会冲突。这里的做法是：用**不带 GApps 和 Magisk** 的包打底，换上 SukiSU 内核，再把 GApps 作为 SukiSU 模块装进去。

### 需要准备的文件

| 文件 | 来源 |
|---|---|
| `WSA_2407.40000.4.0_x64_Release-Nightly-NoGApps-NoAmazon.7z` | WSABuilds [LTS_8 Release](https://github.com/MustardChef/WSABuilds/releases)，选文件名里**没有 `magisk`** 的那个 |
| `kernel` + SukiSU Nova 管理器 APK | 本仓库的 Releases |
| 挂载用的 metamodule，推荐 `meta-overlayfs` | [KernelSU-Modules-Repo/meta-overlayfs](https://github.com/KernelSU-Modules-Repo/meta-overlayfs/releases) |
| `lsp_gapps-ksu.zip`、`lsp_cust-ksu.zip` | 用 [`tools/repack_wsa_addon_for_ksu.sh`](tools/repack_wsa_addon_for_ksu.sh) 生成，见 [tools/](#tools) |
| adb | Android SDK Platform-Tools |

### 1. 卸载旧的 WSA（如果装过）

> 会清空 WSA 里的全部应用和数据。

先在 WSA 设置里点"关闭"，然后在管理员 PowerShell 里运行：

```powershell
Get-AppxPackage *WindowsSubsystemForAndroid* | Remove-AppxPackage
```

确认卸载成功后，再删除旧的 WSA 文件夹。**一定要先卸载再删文件夹**，顺序反了的话，系统里会残留找不到文件的注册信息。

### 2. 安装 NoGApps NoAmazon

1. 把 7z 解压到一个固定位置，例如 `D:\WSA\WSA_SukiSU`。**装好之后这个文件夹不能移动或删除。**
2. 右键 `Run.bat` → 以管理员身份运行。
3. 从**开始菜单**打开"Windows Subsystem for Android"设置，开启**开发人员模式**。
   - 不要直接双击文件夹里的 `WsaSettings.exe`，会报 `VCRUNTIME140_APP.dll` 找不到的错误。
4. 确认 adb 能连上，并且系统里没有 Magisk：
   ```bat
   adb connect 127.0.0.1:58526
   adb shell pm list packages | findstr magisk
   ```
   第二条命令没有输出就对了。

### 3. 替换内核

1. 在 WSA 设置里点"关闭"。
2. 进入 `WSA_SukiSU\Tools`，把原来的 `kernel` 改名为 `kernel_origin`，再放入本仓库 Release 里的 `kernel`。
3. 启动 WSA，然后安装管理器：
   ```bat
   adb connect 127.0.0.1:58526
   adb install SukiSU-Nova-vX.X.X.apk
   ```
4. 打开 SukiSU 管理器，应该显示**工作中**。

### 4. 安装 metamodule

SukiSU Nova v3 和 KernelSU 3.x 一样，**自己不负责挂载模块**，而是交给一个 metamodule 处理。没装 metamodule 的话，模块里的 `system/` 目录不会生效。

```bat
adb push meta-overlayfs-vX.X.X.zip /sdcard/Download/
```

在管理器里依次点：模块 → ＋ → 选择这个 zip，然后**重启 WSA**。在 WSA 上，管理器里的"重启"通常等于关机，关掉之后从开始菜单重新打开就行。

### 5. 安装 GApps 模块

```bat
adb push lsp_gapps-ksu.zip /sdcard/Download/
adb push lsp_cust-ksu.zip /sdcard/Download/
```

在管理器里刷入这两个 zip（`lsp_cust` 可以不装），再重启 WSA，然后检查：

```bat
adb shell pm list packages | findstr "vending gms"
adb shell getprop ro.build.fingerprint
```

- 第一条应该能看到 `com.android.vending` 和 `com.google.android.gms`
- 第二条的输出应该以 `google/` 开头

最后从开始菜单打开 **Google Play 商店** 登录。首次登录时闪退一两次是正常的，重新打开即可。

---

## 更新 SukiSU

> [!IMPORTANT]
> WSA 没有 boot 分区，内核也不是 GKI，所以**不能用管理器里的"直接安装"**，只能替换内核文件。

1. 从 Releases 下载新版本的 `kernel` 和管理器 APK
2. 关闭 WSA，把 `Tools\kernel` 改名备份（如 `kernel_v3.0.0`），放入新的 `kernel`
3. 启动 WSA，然后运行 `adb install -r SukiSU-Nova-vX.X.X.apk`

内核和管理器的版本要保持一致。如果只升级了管理器，它可能会提示"内核版本过低"。

---

## 挂载模块（metamodule）兼容性

WSA 内核开启了 `CONFIG_OVERLAY_FS`、`CONFIG_TMPFS_XATTR` 和 `CONFIG_MODULES`，但它**不是 GKI 内核**，为 GKI 编译的 `.ko` 文件加载不了。

| metamodule | WSA 上可用 | 说明 |
|---|---|---|
| meta-overlayfs | ✅ | 官方参考实现，推荐 |
| Magic Mount 类 | ✅ | 挂载方式和 Magisk 一致，最接近 GApps 模块原本的运行环境 |
| Mountify | ✅ | 需要 OverlayFS 和 TMPFS_XATTR，这两项内核都已开启 |
| Hybrid Mount | ⚠️ | 请选 **lite / nano** 版；full 版自带的 LKM 加载不了 |
| Hymo | ⚠️ | HymoFS 模式需要内核补丁，只能用 OverlayFS 或 Magic Mount 模式 |
| NoMount | ❌ | 需要 `CONFIG_NOMOUNT=y` 或 GKI 的 `.ko`，在 WSA 上 `init_module` 会失败 |

同一时间只能安装一个 metamodule。

---

## 常见问题

| 现象 | 处理 |
|---|---|
| 换内核后 WSA 起不来 | 把 `Tools\kernel_origin` 改回 `kernel` 就能恢复，Userdata 不受影响。也欢迎提 Issue |
| SukiSU 模块页提示和 Magisk 冲突 | 你用的 WSA 包自带 Magisk（GApps 包都带）。请改用 NoGApps NoAmazon 包，按上面的流程重装 |
| 刷了 GApps 模块，但看不到 Play 商店 | metamodule 没装或没生效。在管理器里确认它已启用，然后重启 WSA |
| Play 服务反复闪退 | 先关掉 Zygisk（如 NyaZygisk）排查；还不行就禁用 GApps 模块：`adb shell su -c "touch /data/adb/modules/lsp_gapps/disable"`，然后重启 WSA |
| arm64 应用闪退 | 走的是 Libhoudini 转译，和内核无关。请使用 LTS_8 或更新的 WSA 包，能选 x86_64 版本的应用尽量选 x86_64 |

---

## 自动构建与手动构建

工作流文件：[`.github/workflows/build-wsa-sukisu.yml`](.github/workflows/build-wsa-sukisu.yml)

**自动构建**
- 每天 UTC 03:37（马来西亚时间 11:37）检查上游 SukiSU Nova 的 **Latest release**。pre-release、draft 和不是 `v*` 格式的 tag 会被跳过。
- 本仓库还没有对应的 Release 时，自动编译并发布。
- 编译失败时，GitHub 会发邮件通知仓库所有者。
- 内置 keepalive 步骤，防止仓库 60 天没有活动时定时任务被 GitHub 停用。

**手动构建**：Actions → *Build WSA Kernel - SukiSU Nova* → **Run workflow**

| 参数 | 说明 |
|---|---|
| `sukisu_ref` | 留空表示最新稳定版；也可以填 tag、分支名或 commit |
| `kernel_tag` | WSA 内核版本，WSA 2407 对应 `5.15.104.4` |
| `enable_kpm` | 开启 KPM（实验性） |
| `force` | 已有同名 Release 时也重新编译并覆盖 |

**编译细节**
- 内核版本号（如 `30000`）按上游 tag 对应的提交数计算，和官方同版本的管理器一致。
- 必须开启 `CONFIG_KSU_X86_PATCH_SYSCALL_DISPATCHER`：WSA 5.15 内核没有 x86 间接系统调用的绕过补丁，不开这个选项的话，SukiSU 会放弃初始化。
- 编译时会先执行 `make headers`，因为 SukiSU 的 preinit 需要用到 `usr/include`。

---

## tools/

### `repack_wsa_addon_for_ksu.sh`

把 LSPosed [WSA-Addon](https://github.com/LSPosed/WSA-Addon) 里的 `gapps-13.0-*.img` 和 `cust.img`（也就是 WSABuilds GApps 包里那两个 "GApps for WSA" 和 "WSA Customization" 模块），转换成 KernelSU / SukiSU 可以直接刷入的模块 zip。

```bash
# Debian / Ubuntu
sudo apt install curl erofs-utils zip
./tools/repack_wsa_addon_for_ksu.sh          # 默认 x86_64
./tools/repack_wsa_addon_for_ksu.sh arm64    # ARM 设备上的 WSA
```

运行后会在当前目录生成 `lsp_gapps-ksu.zip` 和 `lsp_cust-ksu.zip`。

原版模块里用 `model.prop` 把设备指纹的品牌改成 `google`，转换后这一步改由模块的 `post-fs-data.sh` 调用 `resetprop` 完成，效果一样。

---

## 致谢

- [microsoft/WSA-Linux-Kernel](https://github.com/microsoft/WSA-Linux-Kernel)：WSA 内核源码（GPL-2.0）
- [SukiSU-Nova](https://github.com/SukiSU-Nova/SukiSU-Nova) / [KernelSU](https://github.com/tiann/KernelSU)
- [MustardChef/WSABuilds](https://github.com/MustardChef/WSABuilds)
- [LSPosed/MagiskOnWSALocal](https://github.com/LSPosed/MagiskOnWSALocal)、[LSPosed/WSA-Addon](https://github.com/LSPosed/WSA-Addon)
- [KernelSU-Modules-Repo/meta-overlayfs](https://github.com/KernelSU-Modules-Repo/meta-overlayfs)
