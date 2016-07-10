```json
{
  "title": "今天，你混淆了吗",
  "url": "obfourscating-shadowsocks-with-obfs4",
  "date": "2015-08-18",
  "parser": "Markdown"
}
```


使用 `obfs4proxy` 混淆 `shadowsocks` 流量

### BOOOM

最近，在 `shadowsocks` 的 `GitHub` 上出现了这样一个 `Issue`: [Link](https://github.com/shadowsocks/shadowsocks/issues/410)

内容是说，最近有很多服务器因使用 `shadowsocks` 而受到干扰或者暂时性的封锁。当然，其真实性和是否与GFW有关，我都无从得知。但是后来又听说某些地区的 `中国移动` 开始尝试干扰 `shadowsocks`, 另外，这两天我的 `shadowsocks` 的确会出现在某些时刻突然完全无法访问的现象，与GFW是否有关？仍然无从得知。

但是 `shadowsocks` 的确有一些缺陷，比如说 `iv` 固定等等。这都导致了其封禁的可能性。

在这么多 `疑似` 的事情之后，对流量做一定的混淆还是有必要的，虽然我也有备用的方案。

### 工具

大名鼎鼎的 [Tor Project](https://www.torproject.org/) 之所以能够一直在国内活到今天，非常依赖于它所开发的各种 `Pluggable Transport`，就是各种传输层面的插件。这些插件中很多都是用来混淆加密流量，使其看起来没有特征或类似于另一种正常协议的特征。

其中比较有名的就是 `obfsproxy`。当然，其版本 `1` `2` `3` 都已经被某长城识别并成功实现干扰或者封锁，而第四个版本 `obfs4proxy` 至少在目前仍然没有受到干扰。因此，我选择使用 `obfs4proxy` 作为混淆的工具。

这些插件都是为 `Tor` 设计的，要将它们应用到非 `Tor` 的自建代理协议上，还需要一个脚本

<https://github.com/gumblex/ptproxy>

里面的 `ptproxy.sh`，它使用 `socat` 对任意基于 `TCP` 的协议通过 `Tor` 的 `Pluggable Trasnport` 进行混淆后传输。这就是我们所要的东西。

哦对了，顺便提一下，这个 `ptproxy` 工具调用的是 `socat`，而这个东西在2.0以前根本就不支持 `SOCKS5`，在2.0的测试版本中也仅仅实现了最基础的 `SOCKS5` ，连用户名-密码的认证都没有实现，而这是 `PT` 所要求的。非常遗憾， `obfs4proxy` 的最新版本使用的正是 `SOCKS5`。所以，我在 `GitHub` 上fork了它，并revert了那条升级到 `SOCKS5` 的commit: <https://github.com/PeterCxy/obfs4>

### 原理

我们假设原来我们使用的是 `shadowsocks` 作为代理，那么，其传输过程是这样的

> You -> (SOCKS5 ->) shadowsocks client ->...-> shadowsocks server -> Internet

注意从客户端到服务端的这一部分，这就是受到干扰或者阻断的地方。

如果使用了 `obfs4proxy`, 那么它就是这个样子

> You -> (SOCKS5 ->) shadowsocks client -> (SOCKS4 ->) obfs4proxy client ->...-> obfs4proxy server -> shadowsocks server -> Internet

也就是说，`obfs4proxy` 的服务端在服务器上监听一个端口，将其从这个端口收到的数据包解除混淆后传递给 `shadowsocks` 的服务端。当客户端链接的时候，由 `shadowsocks` 客户端链接到运行在本地或者国内中转服务器的 `obfs4proxy` 监听的端口上，然后 `obfs4proxy` 会将链接进行混淆，再传输到服务端。对于 `shadowsocks` 本身来说，这层混淆位于客户端和服务端的中间，对其本身没有任何影响， `shadowsocks` 本身并不需要对混淆作出任何调整，只不过需要把客户端链接的端口改成 `obfs4proxy` 所监听的端口。

### 服务端

我在 `ConoHa` 上的VPS运行的是 `Gentoo Linux`。`obfs4proxy` 是使用 `Go` 编写的，也就意味着这东西的打包脚本写起来比较容易 —— 非常容易，因为 `Go` 全部是静态链接。所以我就写了个 `ebuild` 在我的个人overlay里面

<https://github.com/PeterCxy/gentoo-peter/tree/master/net-proxy/obfs4proxy>

安装好以后，接下来只需要把 <https://github.com/gumblex/ptproxy> 这个 `git repo` 克隆到本地的一个目录下就可以了。

我的服务器上并不止一个端口需要混淆，这就意味着我需要运行多个 `obfs4` 实例。如果手工管理当然是很麻烦的，不过我使用的 `systemd` 完全可以胜任这类工作 —— 每个 `unit` 都可以接受一个传入的参数。但是，这要求 `ptproxy` 支持配置文件 —— 很可惜，它并不支持。所以我写了一个脚本来做一个 `伪配置文件`

```bash
#!/bin/bash

cat /path/to/config/dir/${1}.conf | xargs /path/to/ptproxy.sh
```

这样的话，只要在 `/path/to/config/dir` (这是一个任意目录，随便放在哪里，用于存放配置文件) 里面放入一些 `.conf` 后缀的文件，内容是要传给 `ptproxy` 的参数，然后调用这个脚本，将配置的文件名传给它（不带后缀），就可以将该配置文件的内容当作参数传递给 `ptproxy`

比如说，如果你的服务器上有一个监听在 `5555` 端口的 `shadowsocks` 服务端，想要让 `obfs4proxy` 在 `5556` 端口监听并将数据解除混淆后传递给这个 `shadowsocks` 服务端，那么配置文件就是这样的

```bash
-s 0.0.0.0:5556 127.0.0.1 5555
```

保存到配置目录里以后（扩展名为 `.conf`）再调用刚刚保存的脚本，即可启动服务端。你可以写一个 `systemd` 服务，接受参数并将其传递给这个启动脚本。这个写起来非常简单，我就不附上来了。不过，要注意设置好工作目录，否则可能会出现没权限创建日志/配置文件之类的奇怪问题。

### 客户端

因为我使用的电信网络到国外的延迟和丢包实在太大，所以我使用的是 `阿里云` 中转。因为从我到阿里云这段网络上 __应该__ 没有干扰，所以我只要混淆从 `阿里云` 到国外VPS这段的流量就可以了。所以，下面所讲的都是在国内中转服务器上配置的。当然，在本地配置也大同小异，只不过你需要链接到一个本地端口而不是中转端口罢了。

我在阿里云上使用的是 `CentOS`，而且 `Tor` 的网站还被墙了，这样，在它上面构建 `obfs4proxy` 就非常麻烦。所以我直接从我的国外VPS上拖了一个编译好的 `obfs4proxy` 可执行文件回来，然后安装一个 `golang`, 问题就解决了。

在客户端上，同样需要用到刚刚在服务端所使用的 `ptproxy` 脚本和我写的那个简单的配置文件脚本。我们继续刚刚的假设，你在服务端的 `5556` 端口上配置好了 `obfs4proxy`，现在需要在配置一个客户端。假设你需要这个客户端监听在中转服务器（或者本地）的 `5555` 端口（对，这是客户端，所以和服务端的 `5555` 一点都不会冲突）并将其收到的数据混淆后发往服务端的 `5556` 端口。

```bash
-c server-ip:5556 0.0.0.0 5555 pt-args
```

其中， `server-ip` 是服务端的IP，`pt-args` 嘛……当服务端执行脚本启动混淆后，会在控制台输出一坨这样的东西

> ===== Client config =====  
> xxxxxxxxxxxx  
> TRANSPORT_ARGS=xxxxxxxxx

那个 `TRANSPORT_ARGS` 的等号右边的值就是我们需要的 `pt-args` 。这个值是固定的，除非你在服务端的运行环境手动修改。

好了，现在客户端也已经运行好了。你在本地启动一个 `shadowsocks` 客户端，链接到这个中转服务器（或者本地计算机/路由器）的 `5555` 端口，即可使用加上了混淆的 `shadowsocks`

### 最后

我也不知道 `obfs4proxy` 能活多久，也不知道 `shadowsocks` 是否真的会被枪毙，但是在这个神奇的地方，你只能这么做。能用多久就是多久吧。

__W T F__
