MouseDistanceHUD v1.0.0
========================================================================

【这是什么 / What it is】

一个 Windows 桌面悬浮小窗：统计你的鼠标移动距离（自动换算 cm / m / km），
并让一个像素拳击手在街道上跟着你一起动。敲键盘它就出拳，可以当打字计数器用。

A small always-on-top Windows overlay: it counts how far your mouse travels
(auto-switching between cm / m / km) and shows a pixel boxer running down a
street alongside you. Every keystroke makes him throw a punch, so it doubles
as a typing counter.


【系统要求 / Requirements】

- 64 位 Windows 10 或 11 / 64-bit Windows 10 or 11
- 不需要安装 Godot、.NET 或任何运行库 / No Godot, .NET or other runtime needed
- 需要 OpenGL 3.3（近十年的集显、独显都支持）/ Requires OpenGL 3.3


【安装 / Install】

1. 把 zip 里的全部文件解压到同一个文件夹（共四个：MouseDistanceHUD.exe、
   keyhook.exe、README.txt、LICENSE.txt）
2. 双击 MouseDistanceHUD.exe 运行
3. 想开机自启：把 MouseDistanceHUD.exe 的快捷方式放进 shell:startup

   重要：不要在压缩软件里直接双击运行。那样只有主程序被释放到临时目录，
   旁边没有 keyhook.exe，敲键盘的 punches 计数会一直是 0，而且不会报错。

   Important: extract the whole archive first, then run the exe from the
   folder. Launching it inside the archive viewer leaves keyhook.exe behind,
   and the punch counter then silently stays at 0 (no error message).


【首次运行 / First launch】

程序没有做代码签名，Windows 可能会拦一次：

- SmartScreen 蓝框：点「更多信息」→「仍要运行」
  "More info" -> "Run anyway"
- 若 Microsoft Defender 把 keyhook.exe 隔离：在「病毒和威胁防护」→「保护
  历史」里选「允许」或「还原」，也可以把解压出来的文件夹加入排除项
  If Defender quarantines keyhook.exe, restore it from "Protection history"
  and add the folder to the exclusion list.


【用法 / Using it】

- 移动鼠标      → 距离累计，拳击手奔跑 / move the mouse: distance counts
- 敲键盘        → 出一拳（左右手交替），punches +1
                 全局生效，窗口没有焦点也照样计数 / works globally, even
                 without focus
- 按住画面拖动  → 移动窗口 / drag anywhere to move the window
- Reset         → 距离和 punches 归零 / zero the counters
- ×             → 退出，keyhook.exe 会跟着一起退出 / quit


【距离是怎么算的 / How distance is computed】

按你显示器的真实 DPI 把鼠标移动的像素换算成物理距离，所以 125% 缩放的 2K
屏和 100% 缩放的 1080p 屏口径一致。换显示器或改系统缩放后，读数会跟着变。

Readings use your display's real DPI and represent physical distance, so
they stay comparable across different scaling factors. Changing monitors or
display scaling changes the numbers.


【隐私 / Privacy】

keyhook.exe 只注册一个「按键抬起」计数钩子：每敲一次，向本机 127.0.0.1 发
一个 1 字节的 UDP 包，仅用于计数。它不读取、不记录、不上传你按的是哪个键，
整个程序也没有任何外网请求。

keyhook.exe only counts key releases. Each one sends a single byte to
127.0.0.1 on your own machine. It never reads, logs or transmits which key
you pressed, and the app makes no internet requests at all.


【版本与反馈 / Version & feedback】

v1.0.0 · https://github.com/suntectec/MouseDistanceHUD
