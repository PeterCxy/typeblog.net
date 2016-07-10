```json
{
  "title": "博客Docker化并迁移到CaaS",
  "url": "dockerizing-blog",
  "date": "2016-01-22",
  "parser": "Markdown"
}
```

### 起因

我用自己的VPS搭建博客，算起来也有很久了。我选择用VPS，是因为和当年比较流行的虚拟主机比起来，VPS更自由。比如说，我可以自己决定使用什么 `HTTP` 服务软件，可以自己选择各种程序的版本，等等。这些都是从前的虚拟主机所做不到的。

然而，距离那个时代已经有不少年了。我开始用VPS的时候，虚拟主机还大行其道；现在，我已经看不见多少人使用过时的虚拟主机了。而各种所谓 `云服务` 渐渐兴起，比如说基于容器的 `Container-as-a-Service` (CaaS) 服务。当然，VPS在很多服务商眼里也算作他们的一员，但我向来是拒绝承认VPS属于 `云服务` 的。

VPS用了这么久，我也是有点累了。毕竟VPS是个完整的服务器环境，一旦我想迁移，就意味着我需要从头开始重新配置整个环境。而我又是这样一个折腾党，这令人很难过。另外，虽然VPS不是个新东西，但是优质的VPS价格并不会随时间推移而降低多少，这对身为学生狗的我来说也是个不小的压力。比如说，我之前所使用的 `ConoHa`，不算个非常好的服务，但也要60元一个月，这不算一个非常小的数目。

什么？你叫我去用 <ruby>搬瓦工<rt>chāo shòu kuáng</rt></ruby>？还是省省吧，毕竟是 `OpenVZ` 虚拟化，这玩意撑死也就是个容器，我一直很排斥把这种东西叫做 `VPS`。但是想到容器，我就想到了 `Docker`，这个轻量的容器虚拟化工具。它可以把应用及其所依赖的环境打包执行和分发，省去了在各种不同的环境下重新配置的步骤。即使是使用自己的VPS，`Docker` 也能带来很多方便。

但我毕竟已经下定决心寻找一种新的主机服务，因为我懒，因为我懒得再去配置VPS了。于是，自然而然地， `CaaS` 服务进入了我的视线。似乎是 `Docker` 出现以来，这种服务才开始兴起。正是因为 `Docker` 拥有的便于分发和使用的特性，这些服务才能够大行其道。虽然没有和VPS一样的权限，这些服务却能提供一样的自由，因为你可以提供自己的 `Dockerfile`, 可以构建自己的镜像并部署，整个环境仍然由你控制。最重要的是，这些服务比大部分VPS都便宜，因为它们可以以更小的单位来分割资源。比如说我买了个1G内存的VPS，那么无论我运行多少应用，这1G内存是不会变的，收费也始终是这样。而这类服务则是对每个应用分别分配资源，比如说我的博客只需要256M的内存，那我就只给它分配这么多内存。每个应用分配独立的内存，这就保证了在应用少的情况下浪费的减少 -- 再也不会空闲500-600M内存没用了。蛤？你说有内存256M甚至更小的廉价VPS？然而那样的VPS往往本身就只是个容器，这我刚刚已经提及，还不如使用更加轻量和方便的 `Docker`。

### 服务选择

既然已经决定要使用 `CaaS` 服务，那就到了选择服务的时候了。说到这样的服务，我想出来的有两家：`DaoCloud` 和 `灵雀云`。

但我把 `灵雀云` 从列表里排除了，原因只有一个：在移动浏览器上没法使用后台，连最基本的查看日志功能都没法实现。这我就完全无法忍受了，毕竟我是个高三狗 = =

而 `DaoCloud` 的后台可以在手机浏览器上完美运行，操作全部可以正常进行，这让人十分开心。而且它对每个账号提供了 `2x` 的免费资源，实际上跑一个小博客已经够了，因为它相当于128M内存加上10G的磁盘空间。

所以，比较之后，我选择了 `DaoCloud`

### Dockerfile

要迁移到这类平台，必须先把应用Docker化。而将应用Docker化的方法往往是写一个名为 `Dockerfile` 的脚本，让它自动执行一系列命令和配置，构建某个应用的容器以便分发。

我使用的博客系统是 `Ghost`。当然，已经有人为它编写好了 `Dockerfile` 并构建好了镜像，但它并不能满足我的需求。在上一篇博客中我也提及了，我的博客需要通过 `Nginx` 来替换部分被和谐或在国内访问较慢的css和js到CDN的URL，并且需要将内链中的 `http` 全部替换成 `https`, 而这些写好的 `Dockerfile` 都没有这样的功能。另外，我需要以较新版本的 `node` 运行，这也是它们所做不到的。

因此我决定自己开坑写一个 `Dockerfile`。考虑到 `ArchLinux` 的软件源比较新而且比较全，所以我选择使用 `ArchLinux` 作为基础镜像。在 `Dockerfile` 中，首先需要对这个镜像进行更新，使它升级到最新版本

```dockerfile
FROM base/archlinux:2015.06.01

# Initialize the environment
RUN pacman -Syyu --noconfirm
```

像 `nodejs` 这类的软件包在官方源里已经有非常新的版本，所以只需要这样安装就好了

```docker
RUN pacman -S --noconfirm base-devel nodejs npm wget unzip git
```

但是， `Nginx` 不一样。不知道为什么，在 `ArchLinux` 的软件源里面的 `Nginx` 仍然是 `1.8.0` 版本。所以在 `Dockerfile` 中我们必须从 `AUR` 获取最新的 `PKGBUILD` 并构建安装。这也是为什么刚才那行脚本里我安装了个 `base-devel`

在这之前我们必须创建工作目录 `/usr/src/ghost`

```docker
WORKDIR /usr/src/ghost
```

这之后执行的命令全部是在这个目录下。于是我们就可以从AUR获取并编译安装最新的 `Nginx` 了

```docker
RUN git clone https://aur.archlinux.org/psol.git && \
  chmod -R 777 /usr/src/ghost/psol && \
  cd /usr/src/ghost/psol && \
  sudo -u nobody makepkg -sci --noconfirm
RUN git clone https://aur.archlinux.org/nginx-devel.git && \
  chmod -R 777 /usr/src/ghost/nginx-devel && \
  cd /usr/src/ghost/nginx-devel && \
  sudo -u nobody makepkg -sci --noconfirm
```

之所以要 `sudo -u nobody`, 是因为 `makepkg` 从某个版本开始不再支持以 `root` 身份运行，如果一定要运行则会中途出错。但是，如果仅仅这么做，把它切换到 `nobody` 用户，也是会出问题的，因为在安装时 `makepkg` 必须调用 `sudo`, 这会导致报错。所以，我加了这样一句

```docker
RUN echo 'nobody ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
```

让 `nobody` 用户具有免密码的 `sudo` 权限。当然，这么做可能有些安全隐患，但毕竟这只是个容器，大可不必太过担心。你若是实在放心不下，完全可以在 `Dockerfile` 的末尾直接移除掉 `sudo` 这个程序。

接下来，我们就可以直接获取 `Ghost` 并执行安装了。在写这篇博客的时候， `Ghost` 的最新版本是 `0.7.5`

```docker
# Populate basic Ghost environment
RUN  wget https://ghost.org/zip/ghost-0.7.5.zip && \
  unzip ghost-0.7.5.zip && \
  sed -i 's/preinstall/hhh/g' package.json && \
  npm install --production
```

之所以有一句 `sed`, 是因为 `Ghost` 在安装时会检测 `nodejs` 版本。我通过 `sed` 把 `preinstall` 改成瞎写的字符串，这就阻止了它的版本检测，以保证顺利安装。

然后，我们需要拷贝一份配置好的 `nginx.conf` 到 `Nginx` 的配置目录下。这是我配置好的反向代理

```nginx
user       nobody nobody;  ## Default: nobody
worker_processes  5;  ## Default: 1
worker_rlimit_nofile 8192;
 
events {
  worker_connections  4096;  ## Default: 1024
}
 
http {
  include       mime.types;
  default_type application/octet-stream;
 
  server {
    listen 80;
 
    location / {
      #https filtering
      sub_filter 'ajax.googleapis.co[hide].[/hide]m' 'ajax.css.network';
      sub_filter 'fonts.googleapis.co[hide].[/hide]m' 'fonts.css.network';
      sub_filter 'www.gravatar.co[hide].[/hide]m' 'gravatar.css.network';
      sub_filter 'cdnjs.cloudflare.co[hide].[/hide]m/ajax/libs' 'cdn.css.net/libs';
      sub_filter_once off;
      sub_filter_types text/css text/html;
 
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $host;
      proxy_set_header Accept-Encoding "";
      proxy_pass http://127.0.0.1:2368/;
    }
  }
}
```

这个配置文件是一个运行在80端口的反向代理，在代理的同时将页面内的资源链接替换成了由 `css.network` 提供的CDN。在 `Dockerfile` 中拷贝即可

```docker
COPY nginx.conf /etc/nginx/
```

实际上，整个配置过程到这里就可以结束了。但是，还有一些问题需要处理。一个问题是，`Ghost` 的博客URL是在 `config.js` 内设置的，而 `Docker` 内部的环境在启动容器时不能任意修改，即使要修改也很不方便，且不被 `DaoCloud` 支持。所以，我们需要一份自己修改的 `config.js`, 将其中 `url: 'http://my-ghost-blog.com` 替换为

```javascript
url: 'http://' + process.env.GHOST_SITE_URL,
```

这样，我们只需要在启动容器的时候将环境变量 `GHOST_SITE_URL` 设置为博客的域名即可。

在 `Ghost` 启动时仍然会检测 `nodejs` 版本，所以你需要写一个启动脚本，将环境变量 `GHOST_NODE_VERSION_CHECK` 设为 `false`, 再并行启动 `nginx` 和 `npm start --production`。还有几个问题，比如说 `DaoCloud` 的 `Volume` 共享的处理(其实就是建立软链接把挂载的目录里的子目录链接出来并初始化作为数据目录)和 `https` 的处理，我不再赘述，大体就是设置对应的环境变量并以脚本来完成对应的功能。大家可以直接移步我写好的 `Dockerfile`:

[docker-nginx-ghost](https://github.com/PeterCxy/docker-nginx-ghost)

### 部署

首先把写好的 `Dockerfile` 作为版本库提交到 `GitHub`。然后，我们必须在 `DaoCloud` 上构建出这个镜像，才能使用。前往 `DaoCloud` 后台的 `代码构建`，选择好镜像名，连接到GitHub，然后同步并构建即可。构建的过程中千万不要着急，因为这东西很神奇，构建过程倒不慢，但最后构建完了 `push` 的时候简直慢成doge，我还体验过传了十分钟才传完的感觉。所以，千万别着急，实在不行中断掉重新开始，千万不要狂戳。。

代码构建好以后，你需要先创建一个 `Volume` 即数据卷以保存数据。我就建立了一个标准的10G的数据卷(然而这对于我博客而言似乎还是大了点)

接下来就可以部署应用了。假设你使用了我的构建配置。在部署的时候，选中刚刚构建好的镜像即可。为了持久保存数据，我们还必须挂载存储卷。以我为例，首先在数据卷内建立一个名为 `content` 的目录，然后在部署应用时将该数据卷绑定到 `/mnt/volume`，再将环境变量 `GHOST_SITE_DATA` 设为 `/mnt/volume/content` 即可。之所以不使用整个数据卷而只用它的一个目录，是因为数据卷对于大部分博客而言都太大了，只用它的一个目录的话，就可以在多个应用之间共享数据卷，达到最大化利用的目的，这也是为什么我GitHub上那个 `Dockerfile` 里面弄了这么一大堆环境变量配置。。

当然，别忘记把 `GHOST_SITE_URL` 设为博客的域名(如果你不知道，可以等部署完成生成了应用域名以后再设置)。设置完成后，按下部署，再等一分钟左右，这个应用就部署完毕了。然后你就可以用它分配的域名访问你搭建好的博客了。记得先访问 `Ghost` 的后台。

### 数据迁移和域名绑定

由于 `DaoCloud` 的 `Volume` 提供了很好的在线管理器，所以要导入旧的数据很简单，只要把原来的 `Ghost` 的 `content` 目录的内容打包上传到 `Volume` 内刚刚创建的那个 `content` 目录里再解压即可。导入完成后需要重新启动一下容器。

`DaoCloud` 同时支持域名绑定，只要添加CNAME记录即可，未备案域名会从国外中转回来，但是不支持 `https`。所以我选择加上一层 `CloudFlare`, 用 `CloudFlare` 来提供SSL支持，虽然安全上还是存在问题，但至少比没有要好一些。根据客服的回复，`DaoCloud` 正在开发SSL支持，所以我们只要坐等就好啦。

### 小结

话说128M内存的容器果然还是不够用，在进入 `Ghost` 后台时直接卡死，所以我还是买了28元每月的收费服务，建立了256M内存的容器。

其他基本没什么大问题，用起来就和部署在自己的VPS上一样舒服。当然，`DaoCloud` 也存在很多不足，比如说有时候操作会莫名卡住。但它总体上还是一个比较优秀的 `CaaS` 服务。更重要的是有了 `Docker`, 一切都变得方便起来，包括升级 `Ghost` 也不再是个蛋疼的活。