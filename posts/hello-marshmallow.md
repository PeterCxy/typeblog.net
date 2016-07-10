```
{
  "title": "Hello, Marshmallow!",
  "url": "hello-marshmallow",
  "date": "2015-11-27",
  "parser": "Markdown"
}
```


和我的Moto X 2014一起吃的那些棉花糖。

Android 6.0 也即 `Marshmallow` 出来也一个多月了，而我一直没能用上。好在 `Moto X 2014` 还算是个旗舰机，这等待的过程并未持续很久。

### CyanogenMod 13

首先给 `Moto X 2014` 带来棉花糖的是非官方的CM13。这个非官方的CM13是由 `xda-developers` 上的一位开发者自行适配的: 

<http://forum.xda-developers.com/moto-x-2014/development/rom-cyanogenmod-13-t3243768>

作为折腾党，我肯定第一时间就更新了CM13。但是最初的一个版本有严重的问题，比如说锁屏密码无法设置。这个bug后来修复了，可是 `Smart Lock` 的人脸解锁仍不正常。而且根据作者近两天所说

> Once again, im here to sadly say that I was robbed and the robbers took my cell phone, AGAIN, and at the moment I cannot buy another phone to continue the development work. I apologize to all who encouraged my work, and who believed in me.

也就是说，作者的手机被人抢劫了。无论真实与否，这个非官方的CM13是不可能再更新了，而CM13官方夜版也还遥遥无期。

### Motorola Stock

非常开心的是，仅仅过去了一个多月，摩托就开始对巴西版本的 `Moto X 2014` 和今年的Style机型推送官方的 `Android 6.0` 升级。

在XDA上，很快有巴西用户提取了这个更新并上传提供他人下载

<http://forum.xda-developers.com/moto-x-2014/general/ota-android-marshmallow-6-0-final-t3248315>

这个更新包是以OTA而非完整固件形式提供的，需要先刷入巴西版的5.1底包才能进行OTA。但是因为Moto的分区表和 `bootloader` 匹配问题，我害怕OTA会玩坏，所以选择直接使用 `TWRP` 还原其他用户提供的备份包。备份只包含system和boot，只要分区表是国外版本的，就没有任何问题，不用担心bootloader和分区表的版本问题。比如说，我的机器的分区表和bootloader就都是 `XT1092` 的 `Android 5.1` 的版本。

无论你用哪种方式刷机，请一定 __不要刷基带和其他通信相关分区__ !!!!!! (modem, fsg等)

### 电信

彼得蔡日常之一就是修电信问题>_<

显然，巴西版的ROM刷完以后是不可能直接正常使用中国电信大法的。所以做完以后第一件事就是把它root了(那个ROM帖子里有root方法)

然后开机，没信号，没关系，直接激活进入系统。连网络，下载个支持root的文件管理器。

我在 `build.prop` 里面发现了这一行

```
telephony.lteOnCdmaDevice=0
```

把它改成1，然后把 `/etc/apns-conf.xml` 换成来自 `CyanogenMod` 的同名配置文件 <https://raw.githubusercontent.com/CyanogenMod/android_vendor_cm/cm-13.0/prebuilt/common/etc/apns-conf.xml>. 保存后重启，这个时候，系统应该能够识别电信这个运营商，但是无法显示信号。这时，到 `设置->更多->移动网络` 里面，把APN改成电信LTE，然后把网络改成3G，再等一会，应该就会出现信号。如果不能，那么你需要手动在调试界面 (拨号 `*#*#4636#*#*` 把网络模式改成 `GSM/CDMA auto`

但是就算是这样，你也只能使用3G。一旦开启4G，系统就无法保持 `LTE/CDMA` 这一网络配置，而会自动跳到 `LTE/GSM`, 这就无法使用网络了。猜想这可能和巴西本地的运营商配置有关。

于是想起了我以前做的一个 `Xposed` 模块，叫 `LockNetworkType`。这个模块就是用来解决这个问题的，它能够把手机的网络模式锁死在某一个值，通过在 `RIL.class` 里面加入钩子来阻止网络模式的改变。问题就在于 `Xposed`。好在，`Android 6.0` 已经有可用的 `Xposed`

<http://forum.xda-developers.com/showthread.php?t=3034811>

刷入后，安装我的这个模块

<https://github.com/PeterCxy/LockNetworkType/releases/tag/1.1>

在里面选中 `LTE/CDMA`，锁死，再到设置->移动网络里面选中4G模式即可。

至此所有影响使用的问题都已经解决

### 彩蛋

`Marshmallow` 的彩蛋还是一个类似 `Flappy Bird` 的游戏，不过，这次比5.x多了一个新的功能，就是支持多人模式，最多六个玩家。系统会通过识别触摸点位置来区分不同的玩家。这个彩蛋已经俨然一个完整的游戏了。

### Runtime Permissions

`Android` 向来饱受诟病的就是权限问题，所以在 `Android 6.0` 里面引入了新的权限机制。所有应用在使用敏感权限之前，都必须向用户发出请求，被允许后才可以调用对应函数。

但是这需要应用代码的大幅度修改，需要显式发送请求，这相比于一些国内ROM所做的权限管理机制，还是有一些 `蠢` 的感觉。不管怎么说，这至少有助于限制一些开发者随心所欲的行为，也让人意识到权限不是能随便声明和调用的东西。

不过支付宝新版虽然适配了这个机制，可是如果不授权的话就会崩溃。呜呼，若是这样，也真是没救了。

### 其他杂项

在我眼中最值得关注的变化就是以上两点。还有一些摩托的优化、修复之类的不值得列举。在UI方面，`Android 6.0` 在启动器上有较大变化，在水波动画逻辑 (Ripple) 上的变化也比较大，以至于我甚至以为出了问题。以前的水波是按下后就会触发，而现在是离开触摸区域或释放后才会触发水波动画。这实际上也更加符合真实的水波。

新版本还替换了默认的SSL实现，采用自己fork出来的 `BoringSSL` 替换了以前的 `OpenSSL` (好吧我都想弄个 `ExcitedSSL` 了)。同时，替换了以前的DHCP实现，虽然不知道目的是啥。

开发者选项里面的模拟位置不再是一个全局开启或关闭的选择框，而是一个列表，可以单独对某些app开启模拟位置授权。这相比以前也是个进步吧。

在存储页面多了个自带的文件浏览器，虽然那个并不能用来安装apk。

暗黑UI被摩托吃掉了。

另外，也许是因为我刷了个官方ROM，真的好省电的说。。。

以上。
