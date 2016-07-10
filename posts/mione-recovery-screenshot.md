```
{
  "title": "米1/1s Recovery截图教程",
  "url": "mione-recovery-screenshot",
  "date": "2013-07-18",
  "parser": "Markdown"
}
```


首先你要找到一个ffmpeg，Windows下可以找到ffmpeg.exe，放到C:\Windows\system32，Linux下直接apt-get install ffmpeg.  
然后你得有adb，不会就百度。  

启动到recovery，切换到你要截图的页面  
执行命令行：  
Windows下：cd C:\  
Linux下：cd ~/桌面  
然后：  
```sh
adb pull /dev/graphics/fb0
ffmpeg -vframes 1 -vcodec rawvideo -f rawvideo -pix_fmt rgb565 -s 480x854 -i fb0 -f image2 -vcodec png image.png
```
