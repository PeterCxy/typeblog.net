```
{
  "title": "小记触摸版CWM Recovery的制作",
  "url": "record-making-cwm-touch",
  "date": "2013-07-21",
  "parser": "Markdown"
}
```


众所周知，坑爹的CWM Touch木有开放源代码……  
但是我不甘心，我要给米1做触摸Recovery。  
于是在Github上寻找，一直没有找到开源的。  
无意间在深度OS的GITHUB上找到了一部分的触摸源代码。  

看这个commit：<https://github.com/ShenduOS/android_bootable_recovery/commit/19866163c49297d1e6e6348d2db2aa38cac7ce55>  
cherry-pick过来，编译，发现只能支持触摸按键操作，而且还不能触摸。  
经过一番调试，把触摸消息事件号改为50，终于可以正常触摸了。可是感觉很不爽，只能用触摸按键操作。  
但是既然触摸按键可以了，为什么全屏触摸不可以呢？  
首先，要做一个全触摸的recovery，需要增大菜单项距离。  
于是添加了一个EXT_HEIGHT常量，定义为3倍字符高度。<br />
编译，发现顶部空白巨大。<br />
我认为这只是菜单需要一个偏移量。<br />
于是新增常量：<br />
```c
#define MENU_OFFSET -2
```
然后在draw_screen_locked函数中修改，在绘制菜单项的代码行中，所有坐标都加上一个MENU_OFFSET，得以解决。<br />
但是又有一个问题，底部日志会超过限制高度。这个好办，MAX_ROWS一改搞定。<br />
接下来还有一个重大BUG，选择ZIP界面的菜单会超出屏幕距离。<br />
这个就要搜索赋值max_menu_rows变量的地方（是变量，不是常量），然后强制赋值即可。<br />
接下来可以增加触摸选择菜单的代码了。<br />
然后要在ui.c的触摸部分加入一段代码，用于判断触摸区域是否在菜单内，菜单区域的代码可以在绘制函数中找到。<br />
至此，触摸Recovery基本完美，你还可以自己制作一个滑动翻页功能，这里不再多说。<br />
