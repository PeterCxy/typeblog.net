```
{
  "title": "解决StartCom的SSL证书在Android上不被信任的问题",
  "url": "startcom-ssl-on-android",
  "date": "2014-10-07",
  "parser": "Markdown"
}
```


由于上次域名被盗的教训，我计划在shandian.us和typeblog.net启用 `https` 加密链接以防被坑。

但是学生党没那么多钱去买什么上千一年的证书，所以我采用了 <https://startssl.com> 的屌丝版SSL证书。一切配置完成后，发现在Android上访问时，无论如何都出现 `证书不被信任` 的提示。当时一下心里就凉了半截，难道屌丝的东西就是这么屌丝？

<!--more-->

后来在Google上搜索Nginx的SSL配置方法，在某篇文章里发现了这一段

> 有些浏览器不接受那些众所周知的证书认证机构签署的证书，而另外一些浏览器却接受它们。这是由于证书签发使用了一些中间认证机构，这些中间机构被众所周知的证书认证机构授权代为签发证书，但是它们自己却不被广泛认知，所以有些客户端不予识别。针对这种情况，证书认证机构提供一个证书链的包裹，用来声明众所周知的认证机构和自己的关系，需要将这个证书链包裹与服务器证书合并成一个文件。

也许 `StartCom` 的 `Class 1` 就是个中间签发机构，而Android并不认识它们。那么按照文章里提供的方法，只需要将 `StartCom` 的 `CA证书链` 合并到我的证书里面，就可以搞定了。

在 <http://www.startssl.com/certs/> 上，我找到了 `StartCom` 的证书链包裹，文件名为 `ca-bundle.crt`。下载下来以后，我就用 `Linux` 的 `cat` 指令把它们和我的证书合并

```sh
cat shandian.us.crt ca-bundle.crt > shandian.us.bundle.crt
cat typeblog.net.crt ca-bundle.crt > typeblog.net.bundle.crt
```

非常重要的一点是，执行cat命令时，自己的证书一定要放在 `ca-bundle.crt` 的前面，否则上传到服务器后会出现密钥验证错误。

现在已经生成了新的证书文件，将它们上传到服务器并启用即可。

刷新服务器配置以后，在手机上已经可以正常访问了:

![ssl](/content/images/2016/01/ssl.png)
