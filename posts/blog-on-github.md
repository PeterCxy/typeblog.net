```json
{
  "title": "在GITHUB上写博客",
  "url": "blog-on-github",
  "date": "2013-08-09",
  "parser": "Markdown"
}
```


GITHUB是一个免费的代码托管平台，提供给程序员一个代码共享、托管的空间，我的LOSP项目和国外的著名的CyanogenMod等项目就是托管于GITHUB。

很多程序员都有这样一个需求，那就是为他们的项目建立一个主页。因此GITHUB就推出了这样一项服务，只要你是GITHUB的用户，就可以在GITHUB上建立自己的主页。
<!--more-->
这个功能的唯一缺点是仅支持静态页面，不过应对方法很快应运而生，那就是jekyll。这是一个用Ruby脚本语言编写的静态页面生成器，可以用来在GITHUB上生成博客等页面，而GITHUB也官方支持了这个项目，只要你上传jekyll结构的项目目录，GITHUB就会自动将其生成网站并发布。虽然它必须通过Markdown标记语言来写作，但是这对使用GITHUB的程序员们来说，并非什么难事。

当然，我并不建议你只把GITHUB用来建站，因为做人要有点节操，GITHUB PAGES是给托管在其上的项目提供的免费网页服务，并非免费空间，所以……  
要在GITHUB上建立博客，你首先需要在GITHUB上拥有一个账户。

在GITHUB上建立一个名称形如 __用户名.github.io__ 的项目后，GITHUB会自动将其识别为一个网站，并进行解析，如果其中有静态的html或符合jekyll规则以后，会自动生成网站并将其发布到 __用户名.github.io__

要使用jekyll建站，你应当在本地安装jekyll，不过，不安装也可以，因为GITHUB可以自动生成页面，只是你不能在本地调试罢了。不过，一个GIT客户端是必须的，linux下可以用apt-get或yum来安装git，Windows下也有专门的软件

jekyll网站的基础结构为  

> .  
> ./_config.yml  
> ./_layouts  
> ./_posts  
> ./_includes  
> ./index.html  
> ./_site  

这些是最基础的网站目录结构，你还可以增加更多  
\_config.yml是基础的配置文件，本站使用的配置为  
```yaml
baseurl: /
pygments: true
title: Typeblog
url: http://typeblog.net
paginate: 5
paginate_path: "page:num"
```
其余均为默认。  
baseurl是网站的根目录，pygments是一个代码高亮插件，title是网站名称，url是网址，paginate是用于配置每页显示的文章数量，paginate_path用于配置多页规则。  
基本上，你自己用，只需把这个配置小改一下即可。  
\_layouts 和 \_includes 是模板引擎的一部分，jekyll使用Liquid模板引擎。很多程序员都用这个做博客，所以你可以参考其他人的模板，fork出来进行修改。当然，喜欢我的博客，也可以fork出来修改哦。  
\_posts 文件夹中保存的是你的博客文章，文件名格式为YYYY-MM-dd-标题.d，标题必须是英文，且空格用横线替代，这并不是最终显示的标题。博客文件是Markdown格式，开头的layout: xxxx和title: xxxx 定义的是模板和标题，layout对应的模板必须在\_includes文件夹中找得到。接下来，三个横线，下面就是文章的正文，需要以markdown格式书写。这个是有教程的。  
具体的模板制作等内容不在今天阐述的范围之内，以后我会专门写几篇文章，教大家如何像我一样把WordPress模板移植给jekyll用，在这之前，你可以在GITHUB上对我的博客和主站进行fork来直接采用我移植好的模板。  
写好以后，在你本地的网站根目录，执行  
```sh
git init
git branch master
git checkout master
```
来初始化版本库。  
新建一个.gitignore文件，在其中加入  
> _site  
> _site/*  
来避免程序上传\_site这个无用的文件夹。  
然后，如果你在github上建立好了网站的project，那就可以执行  
```sh
git add -A
git commit -m "Initial commit"
git push https://github.com/用户名/用户名.github.io master
```
来部署你的站点到github。  
上传后，等待十分钟，你的网站就可以在 __用户名.github.io__ 访问到了。  
如果要绑定自己的域名，可以在根目录下新建 __CNAME__ 文件，在其中输入你的域名，然后上传，再A记录解析你的域名到 __204.232.175.78__ 即可实现绑定域名。注意，GITHUB只支持每个站点绑定 __一个__ 域名  
至此，你已经在GITHUB上建立了自己的网站，Enjoy it!
