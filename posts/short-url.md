```
{
  "title": "SHORT URL",
  "url": "short-url",
  "date": "2016-02-01",
  "parser": "Markdown"
}
```

<form id="url">
  <input id="original" type="text" placeholder="Long URL"/>
  <input id="submit" type="submit" value="Shorten"/>
</form>

Shortened URL: <b id="short_url">None</b>

<script src="//ajax.css.network/ajax/libs/jquery/1.10.2/jquery.min.js"></script>
<script>
  $(function() {
    $('#url').submit(function(e) {
      e.preventDefault();
      $.ajax({
        type: 'POST',
        url: 'https://wasu.pw/shorten',
        data: {
          url: $('#original').val()
        },
        success: function(res) {
          if (res.success) {
            $('#short_url').text(res.url);
            $('#original').val('');
          } else {
            $('#short_url').text(res.message);
          }
        }
      });
    });
  });
</script>

### 说明

这是由我提供的一个网址缩短服务，其主域名为 `wasu.pw`, 取 <ruby>忘<rt>わす</rt></ruby>れる 的前两个音节作为域名。该网址缩短服务采用 `wasu.pw/abcd` 作为短链格式，其中 `abcd` 为短链编号，为4位且区分大小写的字母和阿拉伯数字组成。如此计算的话，该服务共有 `62 ^ 4 = 14,776,336` 个可用短链地址。该服务的具体实现开源于 https://wasu.pw/HDCI ，服务端使用 `node.js`。我将写一篇博客专门介绍做这个服务的起因和经过。

### 使用方式

这个页面同时也是短网址生成器的页面。在上面的文本框内填入要生成短链的URL，然或戳一下按钮，如果没有出错，那么生成的短链就会出现在 `Shortened URL:` 之后。如果多次重复提交同一个链接，你将只会获得同一个短链接，即：短链接不容许重复。另外，__对短链接再次生成短链接是不被允许的__

### 问题反馈

由于服务端使用了不一定可靠的判断URL有效性的方式，所以如果出现URL有效性误判等问题，请直接在本页面下发表评论，我将在有空的时候对服务端进行修正。

### FAQs

__Q__: 为何使用强制HTTPS？
__A__: 防火防盗防劫持。