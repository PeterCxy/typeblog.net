```json
{
  "title": "小米1原生4.1更换内核后usb调试问题的解决",
  "url": "mione-fix-adb-on-jb",
  "date": "2013-06-14",
  "parser": "Markdown"
}
```


米1的原生4.1很久没有更新过了，很多原生党会喜欢。但是bug太多，很多人通过替换v5内核的方法解决，但是带来了新的问题，就是usb调试不能用（不能连接电脑）

这个问题归根结底是v5的奇葩adbd导致的。因此可以通过解包内核替换adbd解决，但因为最近内核更新频繁，这个方法会非常繁琐，因此我有一个新方法。  
首先，解包ROM，解包原生4.1内核，提取其中sbin文件夹内的adbd放到/system/sbin里面（这个目录是需要建立的），然后，编辑/system/etc/init.qcom.post_boot.sh，在代码正文前一行（注意必须在那一坨注释之后）加入代码  

```sh
sh /system/etc/init.adbd.sh
```
然后，在etc下建立init.adbd.sh，键入以下代码  
```sh
#!/system/bin/sh
su
mount -o remount rw /
cd /sbin
rm adbd
busybox cp /system/sbin/adbd adbd
busybox cp /system/sbin/adbd replaced
busybox chmod 0777 adbd
pid=`busybox pgrep adbd`
kill $pid
```
打包ROM，刷机，看看是不是已经能够连接豌豆荚等程序了？  
本方法的要求是ROM带有busybox，不过原生4.1默认就带的，所以应该没有问题，严格按照本方法操作不会出现问题，也不可能导致变砖。
