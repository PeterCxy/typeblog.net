```json
{
  "title": "获取Android网速的另一种方法",
  "url": "another-way-to-get-android-traffic-info",
  "date": "2013-08-12",
  "parser": "Markdown"
}
```


之前，在LOSP4.2上使用的是Android自带的接口来实现获取网速并显示在通知栏，可是到了4.3以后发现这个接口无论如何，返回值都是-1，无奈之下只得另寻办法

功夫不负有心人，我还是找到了一个方法。在Linux中， __/proc/net/dev__ 这个路径，保存了当前网络的所有状态，我们把它用cat命令读取出来，格式是这样的：
<!--more-->
> Inter-|   Receive                                                |  Transmit  
>  face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed  
>     lo:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  
> dummy0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  
> rmnet0:    1386      33    0   33    0     0          0         0    17664     120    0    0    0     0       0          0  
> rmnet1:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  
> rmnet2:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  
> rmnet3:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  
> rmnet4:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  
> rmnet5:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  
> rmnet6:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  
> rmnet7:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  
>   sit0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  
> ip6tnl0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0  

可以看到，这个文件中保存的信息，首列是设备名，这个我们可以忽略，第一列是接收到的总流量。

这不就是我们苦苦寻觅的东西吗？既然Android自带的取总流量接口函数返回-1，那我们可以直接读取设备来获取啊！

说干就干，在 __Traffic.java__ 中新增一个函数：
```java
  private int getTotalReceivedBytes() {
    String line;
    String[] segs;
    int received = 0;
    int i;
    int tmp = 0;
    boolean isNum;
    try {
      FileReader fr = new FileReader("/proc/net/dev");
      BufferedReader in = new BufferedReader(fr, 500);
      while ((line = in.readLine()) != null) {
        line = line.trim();
        if (line.startsWith("rmnet") || line.startsWith("eth") || line.startsWith("wlan")) {
          segs = line.split(":")[1].split(" ");
          for (i = 0; i < segs.length; i++) {
            isNum = true;
            try {
              tmp = Integer.parseInt(segs[i]);
            } catch (Exception e) {
              isNum = false;
            }
            if (isNum == true) {
              received = received + tmp;
              break;
            }
          }
        }
      }
    } catch (IOException e) {
      return -1;
    }
    return received;
  }
```

解释一下，上面这段代码的作用是，用 __FileReader__ 类来打开 __/proc/net/dev__ 文件，然后用 __BufferedReader__ 类来逐行读取该文件，如果行的开头为 __rmnet__ （移动数据） 或 __eth__ 或 __wlan__ （WIFI），那么就读取该行冒号之后的文本，再以空格分割文本，然后读取首个不为0的数值，最后返回获取到的总数据，该数据包含了本次WIFI和移动数据的所有流量。

然后，只需要再写一段代码，每隔一段时间读取一次总流量，然后用本次和前一次的差除以间隔时间来获取平均速度，再换算为 __K/s__ __M/s__ 等单位，显示即可。

这算是一个变通的方法来实现获取网速吧，已测试没有问题，可以放心使用。
