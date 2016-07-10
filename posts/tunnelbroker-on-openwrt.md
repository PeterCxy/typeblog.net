```
{
  "title": "在OpenWRT上配置HE IPv6隧道的正确姿势",
  "url": "tunnelbroker-on-openwrt",
  "date": "2015-01-04",
  "parser": "Markdown"
}
```


自从前两天把我的破极路由刷成 `OpenWRT (Barrier Breaker)` 以后，就各种折腾，先是挂上 `Shadowsocks` ，然后是多拨，但是没成功。昨天突然想起来以前申请过一个 `Tunnelbroker` 即 `HE` 的ipv6隧道，于是决定在OpenWRT上折腾一下。

首先必须说明，目前我在网上看见的所谓配置 `OpenWRT` 通过IPv6上网的方法基本有效，但在对动态IP即PPPoE拨号上网的支持上几乎全军覆没，包括OpenWRT自带的自动更新隧道IP的接口也不起作用，我猜测是 `Tunnelbroker` 的API有变动导致的。

因此，这篇文章算是对那些教程的一个补充。

<!--more-->

### 准备

1. 前往 <http://tunnelbroker.net> 创建一个IPv6隧道，服务器推荐选择亚洲区域的
2. 在OpenWRT上通过opkg或刷机的方式安装IPv6支持及 `6in4` 软件包
3. 安装 `Radvd` 及其LuCI界面
3. 更换支持IPv6的DNS服务器，例如 8.8.8.8

### 配置

方便起见，我推荐大家直接使用 `LuCI` 控制面板操作。

1. 进入 `Network -> Interfaces` 新建一个接口，选择 `6in4` 协议，确认后对照 `Tunnelbroker` 那边的隧道信息填写表单，本地IP可以留空不写
2. __不建议勾选Dynamic Tunnel一项，因为它没有用，尽管有的教程说它有用___
3. 切换到 `Firewall Settings` 标签页，选中 `wan` 一组，然后保存
4. 进入 `Radvd` 的控制面板，把能勾的全都勾上保存即可

### PPPoE用户配置

由于天朝大部分用户使用 `PPPoE` 上网，获取的是动态IP地址，而IPv6隧道要求两端IP都是明确的，这也是创建隧道时要填写本地IP的原因。现在服务器IP是确定的，因此我们必须设法动态更新本地IP。

幸好，`Tunnelbroker` 提供了方便的API接口

>  https://ipv4.tunnelbroker.net/nic/update?hostname=<TUNNEL_ID\>

其中， `<TUNNEL_ID>` 为隧道的编号，在网页上可以查到。使用该API需要登录，用户名为官网用户名，密码为隧道页面的 `Advanced` 标签下可以查到的 `Update Key`。下文中我们以 `<ID>` 代替隧道编号， `<USR>` 代替用户名，`<PWD>` 代替更新密钥。

我前面已经说过，OpenWRT自带的那个更新接口已经失效了，不知道是什么原因。但是，别忘了OpenWRT是智能路由器系统，因此我们可以自己解决这个问题。

我的解决方法是使用shell脚本

```bash
#!/bin/bash
sleep 5
curl -k -u <USR>:<PWD> https://ipv4.tunnelbroker.net/nic/update?hostname=<ID>
```

我把这个脚本保存在 `/etc/he.sh`, 然后在 `/lib/netifd/ppp-up` 里面加入 `sh /etc/he.sh`, 这样就可以在每次拨号成功以后自动更新隧道端点IP了。

解释一下上面那个脚本， `sleep` 用来等待一定时间以防失败， `curl` 的参数 `-k` 用于忽略SSL证书(因为OpenWRT内置的信任证书很少)， `-u` 用于自动登录。

同时，建议用 `nslookup` 查询 `ipv4.tunnelbroker.net` 的IP地址，加入 `/etc/hosts`，防止由DNS解析失败带来的更新出错。如果你挂了shadowsocks，还应该把这个IP放进 `ignore.list` 里面，否则无法正常更新IP。如果有强迫症，还可以把隧道对端IP也加入shadowsocks的白名单里面，虽然这样做没什么用。

### 测试

保存所有配置，重启路由器，待拨号成功以后，打开 <https://ipv6.google.com> ，能访问则成功。

经测试，IPv6隧道的速度并不是很快，适用于增加bigger。但是由于目前某wall在IPv6并没有很大作用，所以这倒是可以做一些羞羞的事情。同时，IPv6地址资源多到炸裂，隧道会直接给你分配一个 `/64` 地址块，难道你不觉得可以用来......?

### 后记

`TunnelBroker` 现已确认被 `万里长城` 所屏蔽。蜡烛。
