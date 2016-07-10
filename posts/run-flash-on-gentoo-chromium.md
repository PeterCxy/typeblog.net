```
{
  "title": "在Gentoo的Chromium浏览器上运行Flash",
  "url": "run-flash-on-gentoo-chromium",
  "date": "2014-08-06",
  "parser": "Markdown"
}
```


之前转战Gentoo坑，然后自编译了一个 `chromium` 来用，但是它不自带Flash插件，这非常蛋疼。

曾经尝试过安装 `Adobe Flash Player`，但是无论如何就是不认。后来在Google上查到，Chromium已经不支持npapi插件。

而现在的 `Chrome` 自带的插件叫做 `Pepper Flash`，这个插件完美兼容Adobe的Flash格式。

<!--more-->

在Gentoo的 `portage` 上面没有 `Pepper Flash` 这个包，但是我发现在 `www-plugins/chrome-binary-plugins` 这个包里面包含了 `Pepper Flash` 插件。所以我们只需要用 `emerge` 命令安装这个包（安装的时候会提示修改 `package.license` 和 `package.keywords` ，按照提示修改就是了）

安装完了以后，用超级用户编辑 `/etc/chromium/default` ，把如下内容加在最后一行：

```sh
alias chromium="/usr/bin/chromium --embed-flash-fullscreen --ppapi-flash-path=/usr/lib64/chromium-browser/PepperFlash/libpepflashplayer.so --ppapi-flash-version=12.0.0.44 --disable-metrics --disable-metrics-reporting --purge-memory-button"
```

重启chromium即可。
