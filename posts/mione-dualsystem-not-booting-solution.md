```
{
  "title": "小米1自编译ROM系统二启动和data挂载解决方案",
  "url": "mione-dualsystem-not-booting-solution",
  "date": "2013-06-26",
  "parser": "Markdown"
}
```


前段时间开始研究小米的自编译ROM，遇到一个很大的问题，就是系统二刷入以后卡白米。秋叶随风说修复了这个问题，但依然不能用。  
经过研究发现，ramdisk里面，init.mione.syspart_system1.rc的第一行是on emmc-fs，而在cm10.1中并未定义emmc，导致系统二启动时不能正确触发启动事件。  

删除emmc，测试，发现系统二启动正常，但系统不能自动调用mount_ext4.sh，导致澳网CWM的双挂载data功能无效。  
于是继续折腾：  
首先屏蔽掉init.mione.rc里面挂载/data和/cache的语句，然后在init.mione.syspart_system.rc和init.mione.syspart_system1.rc中，加入如下语句：  
```sh
exec /system/bin/sh /system/bin/mount_ext4.sh /dev/block/platform/msm_sdcc.1/by-name/userdata /data
exec /system/bin/sh /system/bin/mount_ext4.sh /dev/block/platform/msm_sdcc.1/by-name/cache /cache
```
这两句代码的作用是，在启动时执行mount_ext4.sh来挂载/data和/cache。  
刷机测试，启动正常。原以为一切ok，结果，重启的时候发现了问题。  
这样修改以后，一重启，系统就会格式化掉/data和/cache。。holy。。自动三清？！  
问题肯定在mount_ext4.sh里面。  
打开mount_ext4.sh查看后发现，该脚本调用了dumpe2fs来判断data分区是否是ext格式，不是就格式化，但现在，ROM中并无该dumpe2fs命令，导致系统每次都格式化了  
去掉这一段，一切正常，oh yeah.
