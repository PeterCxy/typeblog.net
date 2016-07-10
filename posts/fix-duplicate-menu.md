```json
{
  "title": "修复Android App中出现的重复菜单项及Fragment重叠",
  "url": "fix-duplicate-menu",
  "date": "2014-08-22",
  "parser": "Markdown"
}
```


我的 `BlackLight` 项目，从一开始，就存在一个非常严重的问题：在屏幕旋转/程序崩溃/低剩余内存等导致Activity重启的情况下，`MenuItem` 们会重复显示，`Fragment` 也会不断重复，更严重的是重复的 `Fragment` 是像堆栈一样堆在底下，导致界面无限卡顿和重叠。

曾经尝试过使用 `menu.clear()`, 完全无效。对于 `Fragment` 的问题，我也无数次尝试过每次启动都销毁所有 `Fragment`，但是也无济于事。

所以，这个奇葩的问题就从第一个alpha版本一直延续到上一个测试版，都没有解决。

<!--more-->

而我昨天在调试 `夜间模式`, 由于需要即时切换到 `夜间模式`，所以需要用 `Activity.recreate()` 方法重启界面。但是这一重启彻底暴露了这个问题的严重性，因为重启也会导致重叠和重复问题。所以，我今天终于下定决心解决这个问题。

其实很多事情就是巧合，我以前自己折腾+GitHub+Google+Baidu都一直没有解决的问题，今天居然在 `GitHub` 上的一个 `Issue` 里面看见了：

<https://github.com/JakeWharton/ActionBarSherlock/issues/460>

是的，那是 `ActionBarSherlock` 的repo，不过，看问题的描述似乎和库本身没什么关系。抱着试试看的心理，我按照他描述的方法

> If I override onSaveInstanceState() in my activity, and I don't call super.onSaveInstanceState(), the menu items are not duplicated anymore.

试了一下，也就是在Activity源码里加这一小段代码：

```java
@Override
protected void onSaveInstanceState(Bundle bundle) {
	// Empty
}
```

就可以完美解决问题。至于这样解决的原理，我想 [JakeWharton](https://github.com/JakeWharton) 说得很清楚且正确

> That's because not calling the superclass method doesn't allow the fragment manager to save its state. This is probably just an interaction bug since fragment management and state saving has nothing to do with ActionBarSherlock itself.

意思是，这样做了以后，`FragmentManager` 就不能够自动保存 `Fragment` 的状态。而之前所遇到的那个问题，正是因为 `Fragment` 的状态被保存（其实是被锁死了）导致菜单和 `Fragment` 本身都无法被正确清空。

有时候解决一个BUG就是这么简单……
