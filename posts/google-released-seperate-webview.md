```json
{
  "title": "Google 出手尝试解决 Android WebView 的碎片化",
  "url": "google-released-seperate-webview",
  "date": "2015-04-06",
  "parser": "Markdown"
}
```



最近可能不少人都在 `Google Play Store` 上发现了一个新的App: [Android System WebView](https://play.google.com/store/apps/details?id=com.google.android.webview) 根据解释，这个是 `Android` 内置的 `WebView` 的独立版本。很多人都下载安装了这个App，评论里也有各种奇(xia)葩(bai)评论，说是这个组件非常有效果。Google甚至还建立了一个社群用于发布最新的测试版 `WebView`。作为一个折腾党，我肯定不能而且没有错过这个App。倒是只有一个问题：`WebView` 这种组件如何能够独立出来？

<!--more-->

### What

`WebView` 是 `Android` 系统内置的供第三方App调用的浏览器组件。更严格地说，它仅仅是内置的渲染引擎的一个封装。在 `Android 4.4` 以前， `WebView` 的后端是经过轻微修改的 `WebKit`，其源码位于 `Android` 源代码的 `external/webkit` 下，基本上就是原 `WebKit` 的一个拷贝。从 `Android 4.4` 开始，这个 `WebKit` 后端被替换成了谷歌自己做的 `Chromium`，就是那个版本号狂魔。并且，在替换为 `Chromium` 的同时，`WebView` 的实现还被从 `frameworks/base` 中解耦出来，移动到 `frameworks/webview` 下，但仍然会被编译为 `framework` 的一部分。`frameworks/base` 中只留下了与 SDK 有关的接口。

到了 `Android 5.0`，`WebView` 又发生了变化。一是 `Chromium` 升级到了37，二是 `frameworks/webview` 内的结构发生了变化。原来作为 `framework` 的一部分被引入的 `chromium` 包又被修改，变成了编译为一个独立的 `apk` ，包名是 `com.android.webview` (详见 [CyanogenMod GitHub](https://github.com/CyanogenMod/android_frameworks_webview/blob/cm-12.0/chromium/AndroidManifest.xml)) 但是没有用户界面，只是在开机时由 `framework` 根据包名自动载入(这个载入是将class载入到framework中，因此仅仅把自带`WebView`这个apk给禁用掉是不会出现任何问题的)。这就是 `WebView` 独立更新的基础。

### Why

看了 `What` 以后我想大家也该知道个大概了，为什么Google这次要这么做。事实上 `Android` 的碎片化是其饱受的诟病之一，一是因为它开源，二就是因为各个组件无法独立更新，导致不同版本之间差异过大。就拿 `WebView` 来说，在4.4以前是 `WebKit`（每个版本还不一样)，到了4.4变成 `Chromium`，而到了5.0又升级到 `Chromium 37`，到了5.1又升级到 `Chromium 39`，这就给开发者特别是前端开发者们造成极大的困扰：如果我要针对 `Android` 优化一个页面，我是不是得先刷到5.1,调试完毕以后再刷5.0,再调试完毕以后再刷到4.4,再调试完毕以后再刷到4.3……直到调试到几乎没人用的版本为止。

而这次的独立版本的发布，很轻松地解决了这个问题：因为 `Play 商店` 有自动更新功能，往往(非天朝)用户在不知不觉间就自动更新到最新版本的 `WebView`，那么开发者几乎只要调试最新版本就可以解决大部分用户的问题了。

另外，独立更新还可以让开发者提前得到最新的API测试(加入其测试社群即可)，以便在用户得到更新之前就早早调试完毕。特别是对于 `Chromium` 这种版本号狂魔，这在不独立更新的时期是无法想象的。

### How

但是很多人下载并安装了这个app以后，发现他们的 `WebView` 的版本号并没有改变，仍然是 `Chrome 37`，即使将系统自带的 `WebView` 禁用也无济于事，如果删除系统自带的还会导致各种app发生FC。这又是什么鬼？

我在发现这个App并安装后也遇到了一样的问题，系统根本不会调用这个app里面的 `WebView` 实现，那又有什么用？但是有一些用户却表示一点问题也没有。

后来我在 `Android Frameworks` 里面找到了答案 [CyanogenMod GitHub](https://github.com/CyanogenMod/android_frameworks_base/blob/cm-12.0/core/res/res/values/config.xml)

```xml
<!-- Package name providing WebView implementation. -->
<string name="config_webViewPackageName" translatable="false">com.android.webview</string>
```

是的，在 `AOSP` 开放的源代码里面，系统所加载的 `WebView` 被写死了，指向到 `com.android.webview` ，这也就是为什么这个独立更新的 `WebView` 不起作用。

但是，对于Nexus设备的官方ROM和部分国外厂商的带有全套`GMS`的ROM来说，这个值被指向 `com.google.android.webview`，也就是那个独立更新的 `WebView` ，这样，独立的更新就会起到作用 —— 系统会自动将独立的 `	WebView` 载入class

知道了这个就容易解决了，请出 `Xposed` 大法

```java
import android.content.res.XResources;

import de.robv.android.xposed.IXposedHookZygoteInit;

public class ModWebView implements IXposedHookZygoteInit
{

	@Override
	public void initZygote(IXposedHookZygoteInit.StartupParam startupParam) throws Throwable {
		XResources.setSystemWideReplacement("android", "string", "config_webViewPackageName", "com.google.android.webview");
	}

}
```

也就是把那个值像 `Google 原生ROM` 一样指向 `com.google.android.webview`。完美解决。

上述 `Xposed` 模块开源于 <https://github.com/PeterCxy/WebViewGoogle> 可在 `Xposed 商店` 找到下载，名为 `WebViewGoogle`

### 吐槽

这种解决方案很明显是有问题的，只能解决 `Google 官方ROM` 或各大国外厂商内置了完整GMS的部分官方ROM的碎片化 `WebView` 问题。但是由于 `Android` 的开源性，能做到这样已经非常不容易了。况且我等屌丝还是有 `Xposed` 大法的，不是么？这也算是一次尝试吧。

另外，也希望各大第三方ROM的开发者在 `framework` 里面找到一种方法，自动检测这个独立更新版本是否已安装，如果安装，就加载独立更新的版本，这也不是什么难事。

而且，似乎以后如果直接在 `Android ROM` 里面内置这个APK，我们就可以跳过编译坑爹的 `Chromium` 啦！！！！！撒花！！！！！

### 总结

要使用这个独立的 `WebView` ，要求是

* \>= Android 5.0
* Google Nexus 官方推送ROM或国外厂商附带完整GMS的部分ROM或使用 `WebViewGoogle` 这一模块
* 使用调用系统 `WebView` 的app

另外，加入他们的测试社群，你会得到第一时间的更新，就像电脑上 `Chrome` 刷版本号的速度之快一样。
