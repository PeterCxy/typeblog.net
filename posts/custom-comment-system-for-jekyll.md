```
{
  "title": "给Jekyll静态博客扩展动态评论系统",
  "url": "custom-comment-system-for-jekyll",
  "date": "2015-08-05",
  "parser": "Markdown"
}
```


其实是因为 `Disqus` 被我玩坏了 （大雾）。

### 起因

各位都知道，`Jekyll` 是一个静态的博客系统。它的文章以文本形式存储，当文章更新时，通过解析模板重新生成的方式来更新页面。这样的博客对服务器的压力非常小，但同时最大的弱点也在于 `静态`，也就是无法原生实现一个评论系统。

然而评论是一个博客非常重要的功能。所以，大部分人在使用 `Jekyll` 的同时，都会配合 `Disqus` 来实现评论系统。但是我在开头说了， `Disqus` 这玩意被我玩坏了，所有的头像都处于叉烧包状态……而且毕竟使用第三方的评论系统不利于博客的自主管理。

所以，在昨天(2015年8月14日)下午，我决定，给自己的博客扩展一个动态评论系统。这不是 Yet Another, 这不是 Yet Another.

### 后端: 构想

这个暑假我在学写 `CoffeeScript`，并且已经使用 `CoffeeScript` 编写了一个 `Telegram 机器人`，写了一个叫做 `korubaku` 的用于避免回调地狱的 `nodejs` 模块。所以，我的第一想法就是使用 `nodejs` + `CoffeeScript` 来做一个后端。

至于数据库嘛......数据库......就在 `Google` 上随便敲了个 `Database`，然后开始随便选，于是就选中了 `Redis` 作为数据库系统。

一开始，我的想法是，使用一个单独的有序集合 `set` 存储所有的评论并为它们赋予唯一的ID，然后对于每个允许评论的页面，单独创建一个有序集合并且按照时间顺序存储其对应的评论ID。

这是我在开坑二十分钟内产生的简单构想。然后，我就开始着手实现这个构想。

### 后端: 实现

上面的简单构想，实现起来是非常容易的，只不过我在使用 `redis` 的时候绕了好几个圈子。一开始使用的是 `redis` 中被标为 `set` 的东西，因为我并不知道 `redis` 中还存在有序集合和无序集合的区别。于是，这样做出来的后端，返回的评论顺序是一团糟，根本不知道哪个在先哪个在后。

然后我才在 `redis` 的文档上找到了 `sorted set` 这种东西，也就是根据一个 `score` 值进行排序的有序集合。这才是我所需要的东西。这个时候我所用来标记评论的 `id` 使用的其实是 `index`，也就是它在这个数组中的位置，具体的实现是像这个样子

```coffeescript
[err, id] = yield db.zcard commentSet, ko.raw()
if err?
	id = 1
else
	id += 1
```

每次添加新数据，就先获取数据库内已有的评论数量并加1作为新评论的ID。这个逻辑存在一个潜在的问题，我在后面会提到。

接下来的问题是关于评论之间的回复关系。在博客评论的时候，无论是博主或者其他人，总会想对其他人的评论进行回复。我第一个想法是对每个评论用一个 `reply` 属性指向它所回复的评论的ID。然而，这样返回的数据，到了客户端的浏览器中，非常不便于处理，因为还需要本地解析评论之间的关系。所以不如直接在服务器返回时处理。当从数据库里面取出一条评论的时候，在把它 `push` 进准备返回的数组的同时，加入到一个 `id -> comment` 的映射里面。由于我取出的顺序是按照时间顺序，因此当一个评论的回复被取出的时候，这个评论本身一定已经在 `id -> comment` 的这个映射里面了。所以，只要通过这个映射找到父评论对象，在其 `replies` 属性中把这个回复添加进去即可。由于这里的对象是一个引用，所以在返回的数组里面的父评论对象也会即时更新。

就是像这样

```coffeescript
response = []
map = []

for r in reply
	r = parseInt r
	[err, [cmt]] = yield db.zrangebyscore commentSet, r, r, ko.raw()
	if !err? and cmt?
		cmt = JSON.parse cmt
		delete cmt.email
		cmt.id = r
		if (!cmt.reply? or !map[cmt.reply]?)
			response.push cmt
			map[r] = cmt
		else
			orig = map[cmt.reply]
			if !orig.replies?
				orig.replies = []
			orig.replies.push cmt
	else
		console.log err
```

请无视有关数据库的部分。

但这样的评论逻辑还有一个问题，就是评论的嵌套问题，必须限制嵌套的层数，否则做出来是非常难看的。本来想在服务端返回的数据里面做处理，结果后来直接在前端发来的请求上做了处理……

关于头像，我本想让用户自己上传头像，但是这样似乎又要实现一个用户系统……不是很符合我的初衷。所以我使用的是 `gravatar` 的解决方案，在每次请求的时候，检查用户提交的邮箱（其实就是往 `gravatar` 发个请求检查返回值）是否有对应的头像，有的话，就使用 `gravatar` 的头像。由于众所周知的原因，这里我使用的是 `V2EX` 对 `gravatar` 建立的 `CDN`。

这样，我的最初的后端就完成了。

### 前端: 构想

完成了后端，经过简单的测试以后，我开始着手编写前端的逻辑。

我选用的当然是 `jQuery`。我所使用的博客模板，其实也就是 [MDL](http://www.getmdl.io/) 的博客模板，里面带有几个示例评论。所以，评论的排版不需要我过多操心。

我的后端里面少了很多逻辑，比如说日期的格式化、嵌套层数限制的处理，这些都必须在前端得以解决。

我并不想破坏 `Jekyll` 作为静态博客的本质，所以我的计划是在页面加载完成后触发 `JavaScript` 再从服务端获得 `json` 格式的数据进行渲染。

### 前端: 实现

我首先实现的是页面的渲染部分。使用 `jQuery` 的POST和 `Jekyll` 提供的页面ID，可以简单地向服务器请求本页所有的评论。请求完成后，转交回调函数将其转化成 `HTML` 格式并 `append` 到容器元素内，这没什么复杂的，只是要用评论的ID标记各个添加的元素，否则没有办法进行后续处理。

然而在实现后端的时候我并没有实现评论嵌套层数的限制。所以，在实现前端的 `回复` 功能的时候，我必须对此进行处理。在后端内，我们可以看见，我使用 `reply` 属性指向一个评论所回复的评论的ID。所以，当前端从服务器得到评论列表的时候，我使用了类似的后端的方法，把已知的所有评论存储到一个 `id -> comment` 的映射里面

```coffeescript
commentCache[item.id] = item;
```

这样，在回复的时候，首先通过所点击的按钮的 `id` 属性获得用户要回复的评论ID，然后，从这个映射中找到这个评论，检查它是否是另一个评论的回复。如果是，则重定向当前回复到这个评论的父评论上，而保留一个自动生成的 `Reply to XXX` 文本，以标记用户回复的对象

```coffeescript
reply_to = $(this).attr('id');
$('#form_content').trigger('focus');
$('#form_content').val('Reply to ' + commentCache[reply_to].nick + ':');

if (commentCache[reply_to].reply && commentCache[reply_to].reply > -1) {
	reply_to = commentCache[reply_to].reply;
}
```

我使用一个全局变量 `reply_to` 来记录用户需要回复的评论ID。哦对了，还需要保留用户取消评论的能力，因为手抽点错是经常发生的。这个简单，在评论内容框的内容被删除至空的时候自动删除全局变量中所记录的要回复的评论ID。

后端也没有实现日期逻辑，所以日期是在客户端实现的，格式化为字符串后直接提交到服务端，按照客户端的日期发布评论。所以，找了个简单的日期格式化函数

```javascript
function formatDate(date) {
	var monthNames = [
		"Jan", "Feb", "Mar",
		"Apr", "May", "Jun", "Jul",
		"Aug", "Sep", "Oct",
		"Nov", "Dec"
	];

	day = date.getDate();
	monthIndex = date.getMonth();
	year = date.getFullYear();

	return monthNames[monthIndex] + ' ' + day + ', ' + year;
}
```

大家可以发现，在服务端的时候，评论的顺序是按照提交时服务端的时间排列的，而具体显示的日期则是按照客户端的时间……所以……

当然，对于 `email` 和 `nickname` 两个属性，由于一个用户不会经常改变自己的邮箱和昵称，所以我使用 `jQuery` 的 `cookies` 插件，在提交成功时保存用户的邮箱和昵称，下次加载页面直接自动填充。

在提交表单时，我注册了一个事件，直接提交到 `JavaScript` 里面进行检查后 `POST` 到服务端，然后靠浏览器的表单提交逻辑自动刷新页面。

### 部署

启动后端，使用 `nginx` 随便反代一个路径上去即可。

### 问题

##### ID

对，就是评论的ID。在上面大家看到了，我使用的是成员位置作为评论的ID。这在无并发的单线程模型下是绝对正确的，但是 `nodejs` 并不是一个阻塞式的框架，在同一时刻可能有好几个请求正在被处理，这就导致了仅仅靠获取当前评论数量的方法无法获得正确的ID。

所以，我修改了逻辑，使用提交时刻的时间戳记来进行区分。由于时间戳记以毫秒为单位，且因为 `epoll` 不可能让服务器在1毫秒同时处理两个请求，所以在这个情况下，使用时间戳记，就可以解决ID重复潜在故障。

##### 评论提交

如果仅仅依靠表单的自动刷新，不仅不优雅，还会导致可能在提交完成前就自动刷新，使用户看不见自己的评论。所以，我使用一个容器包裹了所有的评论，取消了表单的自动刷新，在提交完成以后清空父容器重新加载，这样就不需要刷新页面，也确保了请求已完成。

##### Disqus 评论迁移

我并不舍得丢下我以前的评论。所以，必须进行迁移。

好在 `Disqus` 提供了API。通过API可以获得帖子(页面)列表，而每个页面都能获取其原始链接。由我的前端代码可以发现，我在评论上使用的ID与页面URL是直接相关的，所以通过Disqus的API返回的页面链接可以构造新的ID，并通过POST将其上传到新的评论系统。

`Disqus` 的评论API没有返回作者的email，导致我的 `gravatar` 方案无法使用，所以我改成了通过作者的用户名获取 `gravatar` 提供的 `identicon`，就是根据哈希值计算的随机头像。

我写了一个python2脚本来做评论的迁移

```python
#!/usr/bin/env python
# Encoding: UTF-8

import httplib
import urllib
import json
from datetime import datetime

token = 'token-of-disqus'
key = 'key-of-disqus'

client = httplib.HTTPSConnection('disqus.com', 443, timeout = 80)
params = urllib.urlencode({
	'api_key': key,
	'forum': 'your-forum',
	'limit': '100'
})

client.request('GET', '/api/3.0/threads/list.json?' + params)

threads = json.loads(client.getresponse().read())['response']

for thread in threads:
	if thread['link'].startswith('https://your-domain'):
		post = thread['link'].replace('https://your-domain', '').replace('.html', '').replace('/', '.')

		client = httplib.HTTPSConnection('disqus.com', 443, timeout = 80)
		params = urllib.urlencode({
			'api_key': key,
			'thread': thread['id'],
			'order': 'asc',
			'limit': '100'
		})

		client.request('GET', '/api/3.0/threads/listPosts.json?' + params)

		comments = json.loads(client.getresponse().read())['response']

		cache = {}
		submitted = {}

		for comment in comments:
			date = datetime.strptime(comment['createdAt'], '%Y-%m-%dT%H:%M:%S').strftime('%b %d, %Y')
			cache[int(comment['id'])] = comment

			parent = comment['parent']

			if parent != None:
				while cache[int(parent)]['parent'] != None:
					parent = cache[parent]['parent']

			options = {
				'post': post,
				'nick': comment['author']['name'].encode('utf-8'),
				'email': comment['author']['name'].encode('utf-8'),
				'content': comment['raw_message'].encode('utf-8'),
				'date': date
			}

			headers = {
				"Content-type": "application/x-www-form-urlencoded",
				"Accept": "text/plain"
			}

			if parent != None:
				options['reply'] = submitted[int(parent)]

			params = urllib.urlencode(options)

			client = httplib.HTTPSConnection('your-domain', 443, timeout = 80)
			client.request('POST', '/path/to/your/api/newComment', params, headers)

			submitted[int(comment['id'])] = int(client.getresponse().read())
```

一样用到了和前后端里面类似的处理评论嵌套的方法。

### 总结

这样我的简单的评论系统就完成了，老的评论也已经迁移过来，除了头像不太对。当然，还有一些需要优化的地方，比如说需要加入一个垃圾过滤API，这些我也许会在以后实现。

### 源代码

后端: [node-comments](https://github.com/PeterCxy/node-comments)  
前端: [Blog](https://github.com/PeterCxy/Blog)
