```json
{
  "title": "给博客添加手机浏览支持",
  "url": "add-support-mobile",
  "date": "2013-08-21",
  "parser": "Markdown"
}
```


我博客用的这个模板本来不是响应式的，在手机上浏览的时候会有很多错位和越界的问题，非常难受。因为马上要开学了，不能让自己都看着难受（你懂的），所以，必须做个响应式支持了。  
各位都知道我的前端功底很烂……不过不要紧，不就是一个响应式模板么，能用就行。  
度娘半天，找到关于响应式的一些资料，其实是很简单……

各位都知道，HTML中，引用css的方法是使用 __link__ 标签，而该标签支持一个属性 __media__ ，该属性的作用就是判断当前浏览器的条件是否符合，如果符合才调用该CSS。  
所以，只须这样：

```html
<link rel="stylesheet" media="all and (min-width: 1024px)" type="text/css" href="style.css" />
<link rel="stylesheet" media="all and (max-width: 1024px)" type="text/css" href="style-mobile.css" />
```

就可以让网页引用正确的模板啦。  
然后，把你网站原本的css拷贝一份，改名style-mobile.css，在其中修改加入兼容手机的部分，比如隐藏侧边栏，隐藏手机不兼容或者无用的内容。还需要改一下js，让部分不兼容的代码在分辨率小的时候不要执行。

现在我的博客已经开启手机兼容，各位可以用手机试试效果了，也可以在我的 __GITHUB__ 上 __fork__ 一份自己回去修改。
