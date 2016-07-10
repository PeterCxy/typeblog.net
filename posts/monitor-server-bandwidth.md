```json
{
  "title": "监控服务器网络状态",
  "url": "monitor-server-bandwidth",
  "date": "2015-08-12",
  "parser": "Markdown"
}
```


通过 `rrdtool` 和 `crontab`

我很早就想在服务器上跑一个软件来监测服务器当前的状态，特别是流量/带宽信息。但是，我之前使用的一直是国外的VPS，它们的流量不是无限，就是 `1T` 以上，以中国的国际带宽，基本上不可能在一个月之内用完这么多流量。然而，在不久以前，由于电信的国际带宽陷入炸裂状态，我使用 `阿里云` 的青岛节点做了一个中转，选择的是按流量计费的方式。由于国内的流量费再也不是白菜价，所以我急需一个流量统计的方式，顺便还应该可以监控一下从 `阿里云` 到我的国外VPS的延迟和丢包。

### 寻找

`crontab` 是肯定要用到的。我在 `阿里云` 上使用的是 `CentOS 7`，官方源里面有一个 `cronie`，这就是我所使用的 `crontab` 实现了。

然而关于绘图工具，我一直在纠结。本来想自己写一个脚本来绘图，但是我实在是懒，而且数据的保存还是一个大问题。后来在微博上看见别人做的统计图很好，是使用 `rrdtool` 绘制的。而事实上， `rrd` 还是一种统计数据归档的手段。

[rrdtool](http://oss.oetiker.ch/rrdtool/) 呃，据说还是个标准来着……

不管怎么样，就是它了。

### 创建数据源

这里我需要统计的是服务端某个端口的流入和流出流量。我并不希望通过什么其他软件来获得流量统计，因为 `iptables` 本身已经带有这个功能。只需要在头部插入两条规则

```bash
iptables -I INPUT -d your-server-ip -p tcp --dport your-port
iptables -I OUTPUT -s your-server-ip -p tcp --sport your-port
```

如果你要监控的端口不是 `tcp` 协议的话，只要把上面的 `tcp` 都换成 `udp` 就是了。以下我全都默认是 `tcp` 协议。

这样，`iptables` 会自动统计通过这两条规则的数据包和它们的大小。这就是我们所需要统计在数据库里面的东西。

接下来需要创建数据库，你需要先安装好 `rrdtool`。我以一个 `bash` 脚本的形式展示

```bash
#!/bin/bash

rrdtool create $1 \
		DS:in:COUNTER:600:U:U \
		DS:out:COUNTER:600:U:U \
		RRA:AVERAGE:0.5:1:576   \
		RRA:AVERAGE:0.5:6:720   \
		RRA:AVERAGE:0.5:24:720  \
		RRA:AVERAGE:0.5:288:730
```

这个脚本需要一个参数，就是要创建的数据库的路径 `your-db.rrd`, 然后创建了两个数据源，一个是 `in`，即输入流量，一个是 `out`，即输出流量，这两个都是计数器类型，即一直增加不会减少的。`RRA` 所定义的是归档，和每次归档的间隔与类型。所有归档的类型都是平均值。

当每次数据更新的时候，只需要调用

```bash
rrdtool update -t in:out $DB N:$in:$out
```

就可以更新数据源。

每次更新数据源的时候，`rrd` 会自动计算两次的差值，并按照我们上面定义的 `AVERAGE` 方法来计算平均值。所以，我们所输入的字节大小实际上会变成实际的网速。

那么接下来的问题就是获取数据更新了。`iptables -n -v -L` 的输出格式似乎更加适合人类阅读而不是通过脚本来截取。不过，`iptables-save -c` 指令可以将目前统计到的数据包全部显示在输出结果中，就像这样

> [packets:bytes] -A INPUT .....

这样就可以通过 `sed` 截取。每次 `cron job` 执行的时候，先通过 `iptables-save -c` 获得当前状态，然后用 `grep` 截取你所需要的那一条规则，比如说上面那个就要截取

```bash
iptables-save -c | grep -- "-A \(INPUT\|OUTPUT\)" \
	grep -- "\(-d\|-s\) " | grep -- '\(--dport\|--sport\) your-port'
```

由于 `INPUT` 链在 `OUTPUT` 链之前，所以这样的输出可以保证输入数据在输出数据之前

接下来通过 `sed` 规则

```bash
sed -r 's/\[([0-9]*):([0-9]*).*/:\2/' | xargs echo | sed 's/ //g' )
```

可以输出形如

> :input_bytes:output_bytes

的数据。这样在加入数据库的时候，只需要

> rrdtool update -t in:out $DB N$data

就可以了。

将做好的数据更新脚本丢进 `crontab` 里面，每5分钟执行一次。

### 图形生成

当数据积累到一定的程度以后，就可以生成图像了。

```bash
rrdtool graph $GRAPH -w 700 -h 300 --start -5h \
        DEF:RawIn=$DB:in:AVERAGE \
        DEF:RawOut=$DB:out:AVERAGE \
        VDEF:TotalIn=RawIn,TOTAL \
        VDEF:TotalOut=RawOut,TOTAL \
        CDEF:NegIn=RawIn,-1,* \
        CDEF:Zero=RawIn,0,* \
        VDEF:MaxOut=RawOut,MAXIMUM \
        VDEF:MaxIn=NegIn,MINIMUM \
        LINE2:NegIn#0000ff:"Input Rate" \
        LINE2:RawOut#0080ff:"Output Rate" \
        LINE1:MaxOut#aa00df:"Max Output Rate" \
        LINE1:MaxIn#227865:"Max Input Rate" \
        LINE1:Zero#555555:"Zero line" \
        COMMENT:'\n' \
        GPRINT:TotalIn:"Total Input\:%.2lf%s" \
        COMMENT:'\n' \
        GPRINT:TotalOut:"Total Output\:%.2lf%s"
```

其中， `$GRAPH` 指向输出的 `png` 图片，`$DB` 指向数据库路径。`-5h` 说明这是生成最近5小时的统计图。实际上这里面的定义都非常好理解。不过，里面我为了绘制 `x轴`，即 `y=0`，我使用了一个方法，就是这一行

> CDEF:Zero=RawIn,0,*

因为 `rrdtool` 不支持绘制不在数据库里面的数据，所以我就通过计算的方式，随便把哪个数据乘以0,就可以得到 `0` 这个数值以便绘制了。

另外，在这张图里面，我把输入值都乘了 `-1`

> CDEF:NegIn=RawIn,-1,*

这样的好处是x轴的上方和下方分别代表输入和输出，以便阅读。

我还通过 `MAXIMUM` 绘制了最大值和最小值的直线。通过 `VDEF` 的 `TOTAL` 方法，我们可以得到当前时段内的总流量，然后可以用 `GPRINT` 绘制到底部。（事实上目的不就是这个么= =）

另外，因为是平均值，所以绘制出来的图像实际上表示的是过去每个时间段内的输入/输出的平均速度。

### 效果

![peter-ss](https://o92gap2xr.qnssl.com/typeblog/content/images/2016/01/peter-ss.png)

这是我用上面的方法统计得到的阿里云中转的 `shadowsocks` 流量。

### 其他

使用类似的方法，我们还可以统计得到某服务器到另一服务器的 `ping` 延迟和丢包率图。不过，这种情况下，我们就不能像上面一样使用 `COUNTER` 数据类型加上 `AVERAGE` 这个统计方法，而是应该使用 `GAUGE` 数据类型加上 `LAST` 统计。在绘图的时候，你还需要通过 `--right-axis` 系列参数创建一个对应的第二个y轴，以显示丢包率的数据轴，具体效果：

![ping](https://o92gap2xr.qnssl.com/typeblog/content/images/2016/01/ping.png)

这是我统计得到的阿里云青岛节点到 `ConoHa` 日本节点的数据。

### 参考

[RRDtool](http://oss.oetiker.ch/rrdtool/)  
[Network Statistics with iptables and rrdtool](http://fabiobaltieri.com/2012/01/14/network-statistics-with-iptables-and-rrdtool/)
