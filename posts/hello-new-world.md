```json
{
  "title": "Hello New World!",
  "url": "hello-new-world",
  "date": "2014-02-16",
  "parser": "Markdown"
}
```


又是一个全新的开始。  
受够了GitHub的龟速和对jekyll的限制，我决定使用VPS来搭建jekyll站点。此时，微博上的 @比尔盖子V 赞助我了一个VPS上的子帐号。  
Jekyll是基于ruby的，所以用子帐号搭建毫无压力。  
<!--more-->

{% highlight sh %}
gem install jekyll
{% endhighlight %}

这样jekyll就可用了。  
之后，用git clone把GitHub上的网站都clone下来，在每一个目录里都执行jekyll build，用符号链接把所有的网站的_site目录，也就是jekyll build生成的目录，链接到用户根目录下。  
然后就简单了，编辑nginx配置文件，将域名一一指向这些目录即可。  
为了与GitHub保持同步，我写了一个简单的脚本。  

{% highlight sh %}
#!/bin/bash
while true ; do
    cd path-to-your-website
    git pull # 获取最新更新
    jekyll build # 生成站点
    sleep 600 # 等待10分钟
done
{% endhighlight %}

用screen命令创建一个新会话，在里面运行这个脚本即可。
