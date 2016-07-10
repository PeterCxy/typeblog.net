```
{
  "title": "Hello, Ghost!",
  "url": "hello-ghost",
  "date": "2016-01-11",
  "parser": "Markdown"
}
```

### Bye, Jekyll
在发布这篇文章之前，我一直在使用 `Jekyll` 作为我的博客工具。以前我看中 `Jekyll`, 是因为它是一个静态的博客工具，生成静态的页面。相比臃肿的 `WordPress`，静态的 `Jekyll` 更方便部署，随便在哪里丢上那几个生成的页面就可以部署一个能用的博客。由于省去了动态页面的执行时间，它的访问速度也有一定的提升。但是，当我用了一段时间以后，我发现 `Jekyll` 存在如下的问题，这些问题导致我不得不放弃 `Jekyll` 这一博客工具

1. 更新、同步麻烦，需要自己写一个 `GitHub Webhook` 来同步自己发布到 `Git Repo` 内的文章
1. 功能缺失，甚至图片尺寸调节这类非常基本的功能也要通过插件实现
1. 博客撰写体验 <ruby>不好<rt>kēng diē</rt></ruby>，特别是在移动平台上，很难找到像样的Markdown编辑器
1. 启动速度慢导致生成时间较长
1. 博客标签系统不灵活，难以实现多标签以及标签云等功能

第三点尤为致命，因为我经常在手机上编写博客，如果不能找到一个像样的编辑器，我就没法找到写博客的热情，而博客的更新也进入了有生之年系列。

### Hello, Ghost

正巧前两天我更换VPS，从 `老鹰主机` 回到 `ConoHa`，正打算把博客迁移过去，转念一想既然自己已经受不了 `Jekyll`, 何不趁此机会把博客系统也换掉呢？

想起来之前去过<ruby>HJC<rt>tǔ háo</rt></ruby>的博客 [hjc.im](https://hjc.im)，他使用的就是一个名叫 `Ghost` 的博客系统。于是我就去它的官网 [ghost.org](https://ghost.org) 看了一下。只看到官网首页的那几个截图，我就动心了，因为截图上显示的博客后台中的编辑器能完美地在手机等移动端使用。这正是我所需要的东西。

而且这又是个动态博客系统，我也就不再需要配置麻烦的 `Webhook` 了。相比于 `WordPress`, 它又轻量很多，没有一大坨复杂的只有大型CMS才会用到的功能。Wikipedia上是这么介绍的

> The idea for the Ghost platform was first written about at the start of November 2012 in a blog post by project founder John O'Nolan, the former deputy lead for the WordPress User Interface team, after becoming frustrated with the complexity of using WordPress as a blog rather than a content management system.

再加上它一样采用优雅的 `Markdown` 来写作，我怎么可能抵挡住这样一个东西的诱惑呢。于是，我欣然决定从 `Jekyll` 迁移到 `Ghost`。

### 配置

`Ghost` 配置起来并不比其他 `Node.js` 程序复杂。只要下载程序包，执行 `npm install`，再 `npm start`，它就会在本地监听一个端口。然后只需要用 `Nginx` 反向代理一下即可。

要注意的是 `Ghost` 并不支持所有 `node.js` 版本。它仅支持 `LTS` 版的node。而在 `ArchLinux` 官方源中，这是不可能的，所以我选择从 `AUR` 中安装 `nvm` 进行版本管理。我通过 `nvm` 安装了 `Node.js v4.2.4`。

然后只需配置 `Systemd` 开机启动服务即可。我写了一个服务配置

```ini
[Unit]
Description=Ghost blog service
After=network.target
[Service]
Restart=always
Type=simple
User=peter
Environment=PATH=/usr/bin:/home/peter/.nvm/versions/node/v4.2.4/bin
ExecStart=/home/peter/.nvm/versions/node/v4.2.4/bin/npm start --production
WorkingDirectory=/home/peter/web/ghost
[Install]
WantedBy=multi-user.target 
```

其中所有 `peter` 都是指我的用户名，而 `/home/peter/.nvm` 是 `nvm` 默认的安装路径，我指向了它安装的 `Node.js v4.2.4`。`WorkingDirectory` 指向的是 `Ghost` 程序的所在目录。

### 转移文章

博客的关键就是文章，转移博客的关键也是转移文章。其他的什么都不重要，最关键的就是要把文章毫无损坏地转移到新的博客系统。

我在Google上搜索 `migrate from Jekyll to Ghost`, 找到了这样一篇文章

[Migrating Jekyll to Ghost](http://www.bymichaellancaster.com/blog/migrate-jekyll-to-ghost-built-with-nodejs/)

这篇文章介绍了一个能够把 `Jekyll` 的文章转换为 `Ghost` 的格式的 `node.js` 小程序 [nodejs-jekyll-to-ghost](https://github.com/weblancaster/nodejs-jekyll-to-ghost)

按照这个小程序的说明，我着手进行文章的转换。但这个小程序有一个问题，就是无法处理 `Jekyll` 的 `_posts` 目录下有多个子目录作为分类的情况。于是我只能采取最原始的办法，就是对各个子目录分别执行这个脚本，分次导入 `Ghost`。

由于 `Ghost` 版本的更新， `README` 中所指示的导入数据的页面已经不再有效，这个功能已经被转移到 `Ghost` 后台的 `Labs` 选项内。

分次导入后，文章就原样进入了 `Ghost` 博客系统

### 标签和图片

导入文章虽然对文章本身没有任何影响，但是却丢失了标签和图片，这也是正常的情况，毕竟是截然不同的博客系统。

由于原来我使用的 `Jekyll` 缺乏多标签支持，所以我的整个博客只有两个标签，这反倒无形中方便了我的迁移工作。我只是打开每一篇文章，看一看内容，然后重新为它加上属于它的标签，就这么搞定了。

我本来以为转移图片会是个蛋疼的工作，但实际上并非如此。`Ghost` 的编辑器对图片的上传提供了完美的支持，如果一篇文章中存在无效的图片引用，那么在预览模式下它就会显示这样一个框框

![image-upload](/content/images/2016/01/Screenshot_20160112-202158.png)

只消轻触，即可上传图片。于是我只在网页上就完成了这个工作——打开原有的文章，一张张重新上传其中的图片。

### 主题

用 `Jekyll` 的时候，我使用的是自己适配到 `Jekyll` 的MDL官方示例中的博客模板。那个模板毕竟只是个示例，使用下来有一些比较难以忍受的问题。而且我也懒得重新适配一次模板，所以我选择重新寻找模板。

在 [Ghost Marketplace](http://marketplace.ghost.org/themes/free/) 上，我找到了一个名叫sticko的主题，第一眼我就爱上了她。这个配色，这个布局，这个……简直sexy!

但这个主题已经有很长时间没更新过了，连最新版 `Ghost` 的导航菜单功能都没有支持。所以，我 [Fork](https://github.com/PeterCxy/sticko) 了一份这个主题，魔改了一下

* 添加导航菜单支持
* 引用 `Prism.js` 作为代码高亮实现
* 采用 `Disqus` 作为评论系统
* 修复css字体引用的 `https` 支持

目前就改了这么多，已经在我的博客上使用。我非常喜欢这样的主题，所以应该也会持续维护我的那个fork。

### HTTPS 和 CDN

在 `Ghost` 的 `config.js` 里面，可以配置博客的默认URL。但是这里有个坑，就是如果你把这个URL配置成 `HTTPS` 开头，那么你将会陷入重定向循环。但是，如果你把这个URL配置成 `HTTP` 开头，那么页面中内嵌的RSS订阅链接等将无法自动改为 `HTTPS`。为了解决这个问题，我将默认URL配置为 `HTTP`， 再祭出 `Nginx` 的 `http_sub` 大法

```nginx
sub_filter 'http[hide].[/hide]://typeblog.net' 'https://typeblog.net';
sub_filter_types text/css text/html;
sub_filter_once off;
```

其中 `typeblog.net` 是我博客的域名。这是把页面中所有 `http` 链接到本博客的目的地址全部改成 `https`, 包括rss订阅等。这样会带来一个问题，就是如果文章中出现且一定要出现 `http[hide].[/hide]://typeblog.net` 之类的字样，将无法正确显示。这个问题可以通过JavaScript解决，详情请见本博客页面源码底部。

既然用到了 `http_sub`，那我们也可以顺手解决一下 `CDN` 问题了。由于众所周知的原因，主题所引用的 `Google CDN` 上的字体和css等无法被正确加载，且 `cdnjs` 在国内速度也不够理想。所以，我们可以把它替换为由<ruby>兽兽<rt>RICH</rt></ruby> `css.network` 提供的CDN

```nginx
sub_filter 'ajax.googleapis.co[hide].[/hide]m' 'ajax.css.network';
sub_filter 'fonts.googleapis.co[hide].[/hide]m' 'fonts.css.network';
sub_filter 'www.gravatar.co[hide].[/hide]m' 'gravatar.css.network';
sub_filter 'cdnjs.cloudflare.co[hide].[/hide]m/ajax/libs' 'cdn.css.net/libs';
```

注意，多条 `sub_filter` 语句需要 `Nginx 1.9.x` 才能支持。在 `ArchLinux AUR` 中有最新版本的 `PKGBUILD`。

### 重定向

更换了博客系统，URL也发生了变化。`Jekyll` 的URL格式是

```
scheme://domain.com/category/year/month/date/some-article.html
```

而 `Ghost` 在不打开日期URL时的格式为

```
scheme://domain.com/some-article/
```

原来的链接失效，无论是对于搜索引擎收录还是对于访客来说都是不利的。好在迁移文章时并没有改变文章的短链接名称。所以使用 `Nginx` 的重写规则，我将老的URL重定向至新的

```nginx
rewrite ^/(life|tech)/.*/.*/.*/(.*?).html(|/) https://typeblog.net/$2/ permanent;
```

其中 `life|tech` 是我原有的两个分类名称，`typeblog.net` 是我的域名。

### 大功告成

至此，我的博客已经迁移至 `Ghost` 并恢复正常运行。有了 `Ghost` 的优雅，我重新找回了写博客的热情。我不需要再忍受糟糕的编辑体验，不需要再在更新文章之后焦急等待重新生成。这是我的新博客。

`Ghost` 作为一个轻量级的博客系统，其开发者非常积极，十分注重细节体验(似乎领导开发者是个妹子，逃)。官方博客还时常发布一些关于如何写好博客的文章。我也相信有了这些，我的博客也会有个全新的开端。