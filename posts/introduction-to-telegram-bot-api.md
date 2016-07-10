```json
{
  "title": "Telegram Bot API 折腾记",
  "url": "introduction-to-telegram-bot-api",
  "date": "2015-07-14",
  "parser": "Markdown"
}
```



从 2015年6月24日 以后，`Telegram` 正式开始提供开放的 [机器人平台](https://core.telegram.org/bots)。实际上在这之前，`Telegram` 上已经有大量的 `Bots` 存在，只不过它们多数是使用 `telegram-cli` 实现的。但是这些机器人不能够与 `Telegram` 客户端的UI交互，不能够弹出可选项之类，而且也不能设置是否允许加入群组、是否能够查看所有消息等。而机器人平台具有一些特殊的API接口，比如说能够自定义用户可见的选项、可以在Telegram客户端中添加一个命令菜单等等。更重要的是，机器人API采用的是简单的 `http(s)` 协议，而不需要像以前那样自己实现一套 `MTProto`.

我自己也早就想要做一个玩具，正好碰上Telegram开放机器人平台，欣然决定开坑写一个Telegram机器人。这篇文章也许又是一个备忘吧……

<!--more-->

### 机器人之父

`Telegram` 上有一个叫做 `@BotFather` 的用户，是用来管理机器人的一个机器人账户。通过它的 `/newbot` 命令，可以创建新的机器人，创建成功后它会发送一个 `API Token` 过来，需要妥善保管。它的其他命令主要用于设置机器人有关信息，比如关于信息、隐私权限等等。而如果丢失或者泄漏了 `API Token`，可以通过 `/revoke` 指令来重新生成。

### 初始化

创建机器人以后，你就可以通过设定的用户名查询到机器人并发起会话了。但是仅仅这样的话机器人是不会有任何反应的，我们还需要一个服务器，并使用服务端程序对Telegram机器人进行初始化。首先，Telegram的所有对机器人开放的API的URL前缀都是

> https://api.telegram.org/bot<token\>/

在这个URL后面加上要调用的API方法名称即可。所有API方法均支持 `GET` 和 `POST`

首先我们要初始化机器人，让Telegram将机器人所收到的消息转发到服务器上。`Telegram` 支持两种方式，第一种是机器人服务器主动向Telegram发送查询请求，第二种是机器人服务器被动接受Telegram发来的请求。而我比较喜欢的是第二种，即使用 `WebHook` 的模式。按照官方的推荐做法，我们可以在服务器上监听像这样的URL

> https://yourdomain/some/path/<token\>

必须是 __HTTPS__! 且不支持自己签的证书。

由于只有你和 `Telegram` 知道你的API Token，所以这样的URL可以很好地避免莫名其妙的请求。接下来你只需要向 `Telegram Bot API` 的 `setWebhook` 方法 (上面的URL前缀加上 `setWebhook`)提交 `url` 参数指向这个URL即可。

由于我选择的是 `CoffeeScript`，所以我使用的是 `restify` 模块作服务端，监听了一个非 `443` 端口，并通过 `nginx` 作前端将一个 `https` 的URL重定向到了这个端口上，这样就解决了 `restify` 不支持 `HTTPS` 的问题。

### 处理

当初始化完成以后，所有的消息都会被重定向到你向 `setWebhook` 提交的url上。其请求中包含被官方称为 `Message` 的一个对象。由于我使用的是 `CoffeeScript`, 因而只需要在 `restify` 的回调中使用 `JSON.parse` 即可将其反序列化转换为一个可以使用的对象。

`Message.text` 属性是用户或群组发来的消息内容。我们知道，机器人都是有很多命令的，而Telegram并没有自动将它们解析为 `命令+参数` 的模式。所以我自己用 `CoffeeScript` 写了一个解析命令的函数

```
exports.parse = (cmd) ->
	options = []
	arr = cmd.split(" ")
	opt = ""
	concat = no
	for str, i in arr
		continue if str == ""

		if str.startsWith '"'
			concat = yes
			str = str[1..]
		else if str.endsWith '"'
			concat = no
			options.push opt + str[0..-2]
			opt = ""
			continue

		if !concat
			options.push str
		else
			opt += str + " "
	options
```

这个函数优先按空格分割参数，如果发现含有英文双引号的参数，则自动匹配前后双引号，将引号内的算作一个参数整体传回。传回的是一个数组，第一项应当为指令，其他的都是参数。Telegram要求机器人指令的开头为 `/` ，所以应当检测数组的第一个成员是否为 `/` 开头，如果是的话，则交给具体函数处理。

另外，当机器人在群组内的时候，命令应当变成这样 `/cmd@bot_name` ，以此区分不同的机器人，防止互相冲突。所以，在判断命令的时候，要这样处理一下。

```
isCommand = (arg, cmd) ->
	if (arg.indexOf '@') > 0
		[command, username] = arg.split '@'
		command == cmd and username == config.name
	else
		arg == cmd
```

这个函数比较 `arg` 和 `cmd` ，当 `arg` 中含有 `@` 的时候，则分别比较 `@` 符号前后，如果前面与对应命令相同，后面跟机器人的用户名相同，则返回真，否则为假。

我推荐的是采用类似 `restify` 的 `router` 模式，即让所有实现功能的模块将其有关信息注册到一个数组里面，然后由一个主函数根据用户提交的命令和其参数个数转发到各个实现模块，就像这样

```
handleMessage = (msg) ->
	console.log "Handling message " + msg.message_id
	options = parser.parse msg.text
	cmd = if options[0].startsWith '/' then options[0][1...] else ''
	console.log 'Command: ' + cmd
	handled = no
	for r in routes
		if isCommand cmd, r.command
			if r.numArgs >= 0 and r.numArgs >= options.length - 1 >= r.numArgs - r.optArgs
				result = reflekt.parse r.handler
				args = { "#{result[0]}": msg }
				for option, i in options[1...]
					args[result[i + 1]] = option
				console.log args
				reflekt.call r.handler, args
			else if r.numArgs < 0
				r.handler msg, options[1...]
			else
				console.log 'Wrong usage of ' + cmd
				telegram.sendMessage msg.chat.id, "Wrong usage. Consult the /help command for help."
			handled = yes
			break
	if !handled
		console.log 'Nothing done for ' + cmd
```

这里用到了 `reflekt` 这个 `npm` 模块，用于调用参数不定的函数，而不是直接将参数数组传入。这样的代码读起来更加清晰。当然，对于没有定义参数限制的功能实现，目前我的做法还是将参数数组直接传入。

### 模块化

我上面也说了，我做的是一个基于 `nodejs` 和 `CoffeeScript` 的机器人。这种动态语言的优点是很多模块都可以在运行时实时加载。而我上面的代码也已经做好了模块化的准备，剩下的只是要把不同的模块分割到不同的包里去罢了。

`nodejs` 中 `require('package_name')` 可以实时加载其他包，所以我使用一个配置文件，在启动时根据配置文件使用 `require` 模块将用户所要求的各个模块读入，并调用其 `setup` 函数。通过该函数，主程序将模块运行需要的对象传入，比如说 `Telegram API` 的对象等等。`setup` 函数返回一个数组，是关于其能够实现的函数的名称、描述及对应的回调函数等等。主程序收到以后，将其加入对应的 `route` 数组中，当收到指令时执行转发。

最初的实现要求 `setup` 函数不仅仅返回其参数个数，还要返回参数列表。但是有了 `reflekt` 模块以后，主程序可以直接从其回调函数中读取参数列表，从而 `setup` 函数可以不用返回参数名称列表而只要返回总参数个数和可选参数个数即可。

这样的话，所有的配置都可以通过一个文件完成，而功能的扩展也许也只需要几行代码的事情，甚至随手写一个 `.js` 也可以载入作为模块调用。

### 多进程

当时我的机器人加入了一些超时操作以后，发现操作经常被阻塞而致使无响应。后来使用了 `nodejs` 内置的 `cluster` 模块，只要 `fork` 出几个子进程让它们并行处理请求，就可以减少阻塞的情况的发生。

### 示例

我已经初步完成了一个可扩展的 `Telegram` 机器程序，可以在

[GitHub](https://github.com/PeterCxy/telegram-bot-coffee)  
[npmjs](https://www.npmjs.com/package/telegram-bot-coffee)

看到。`Telegram` 上也运行着使用该模块的机器人，比如说我的 `@PeterCxyBot` ，欢迎调戏。
