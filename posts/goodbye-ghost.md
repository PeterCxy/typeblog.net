```json
{
  "title": "再见，Ghost",
  "url": "goodbye-ghost",
  "date": "2016-07-11",
  "cover": "https://oa3o2340x.qnssl.com/journey.jpg",
  "tags": ["Tech", "Blog"],
  "parser": "Markdown"
}
```

### 旧爱

我切换到 Ghost 这个博客引擎，其实也没有很久的时间。当时切换到 Ghost，主要原因是 Jekyll 这样的博客引擎没有一个好用的网页编辑器或者客户端，而当时的我还是高中生，经常需要在手机上编辑并发布博客。而 Ghost 恰好有一个好用的网页前端，所以我当时就决定把博客迁移到 Ghost 平台上。

但是 Ghost 也存在相当多的问题

* 插件系统较为鸡肋，难以扩展
* 服务端不能执行代码高亮，代码高亮需要在客户端执行
* 不能自定义主题的参数，导致不修改主题文件难以实现自定义
* 编辑器不自带 Markdown 语法高亮

再加上我现在已经可以使用电脑写作，使用手机的时间大大减少，这就是换一个博客系统的好时机了。

### 新欢？

我曾经是 Jekyll 的用户，当时使用中比较蛋疼的一个问题就是自动更新与缓存刷新 —— 因为那是纯静态博客，所以必须再单独实现一个服务来监听更新并同步。虽然说博客这种东西本身静态和动态就没什么大的差别，但是我还是更倾向于「半动态」的博客，这样也更便于实现插件系统。

而我又恰好正在为「手生」烦恼 —— 整个高三没写几句代码，突然放暑假，想要填上自己的那些坑，却猛然发现自己已经不习惯于写代码，对着 IDE 无从下手。博客系统这种东西，说复杂，也没什么复杂的地方，倒不如就此机会自己开个坑，也好练练手，满足一下自己的「虚荣心」，咱也不指望会有其他人使用我写的博客系统了……

一个博客系统，无非就这样几个部分

* HTTP 服务器
* 渲染引擎
* 模板引擎
* RSS生成器

至于评论系统，我暂时觉得依赖 Disqus 还不是什么大问题。这几个部分，我稍微思考了一下，发现并没有什么特别难做的 —— 毕竟我的目标并不是完全从头造一遍轮子。HTTP 服务完全可以依赖 express.js 之类的现成框架，模板引擎可以使用 Handlebars.js —— 这可以极大地方便我把 Ghost 的模板直接移植过来。所以，说开坑，我就这么开坑了。

这个博客系统坑的名字就叫 Typeblog，和本博客的名字一样，因为这个名字具有特殊的含义。下文中如不作特殊说明， Typeblog 均指该博客系统。

### 存储结构

按照我的设计，一个博客应该是一个目录 —— 与博客程序独立的目录。这个目录应该同时是一个 npm 包，即含有 package.json。这个包通过依赖的形式把 Typeblog 安装至自己的 node_modules 下。Typeblog 程序有一个主可执行文件 `typeblog`（当使用 npm 安装时，它将会位于 `node_modules/.bin/typeblog`），执行即代表启动该博客。程序将会自动载入当前目录下（博客根目录）的 config.json 作为配置文件。这个 config.json 应该具有类似这样的结构

```json
{
  "title": "MyBlog",
  "description": "Just my blog",
  "url": "http://example.com",
  "plugins": [
    "..."
  ],
  "posts": [
    "posts/post1.md",
    "posts/post2.md"
  ]
}
```

其中配置的值和键的语义相符，我就不一一解释了。其中 posts 字段下的是一个文件路径数组，里面指定的是相对于博客根目录（即程序工作目录）的路径。程序启动和重载时将载入这些路径上的文章，至于解析过程稍后会提及。这里需要提前说明的是，该数组是一个有序数组，排序靠前的文章在最终生成的博客中也将靠前（因为我受够了按日期自动排序的博客系统 —— 不是所有的文章都能按日期排序！）

同时，博客程序还会监听这个 config.json 的改动（使用 `chokidar` 实现），一旦发生改动，程序将自动触发配置重载，同时重载文章列表。这主要是为了方便本地调试。在服务器端，我们将采用其他方式触发配置的重载。

### 插件系统

我这个博客程序，非常重要的一部分就是插件。我的计划是，渲染引擎中的大部分将使用插件的形式呈现，包括文章格式解析， Markdown 解析，代码高亮等。这就要求我在一开始就考虑到插件的存在。

于是呢，我设计了一个插件基类

```coffeescript
class Plugin
  constructor: ->
    registerPlugin @

plugins = []
registerPlugin = (plugin) ->
  plugins.push plugin
```

当一个继承了 `Plugin` 类的子类被实例化时，它就会自动被加入这里的数组 `plugins`。子类需要实现它们自己可以实现的方法。当主程序需要调用一个支持插件的方法时，它将使用这个过程

```coffeescript
callPluginMethod = (name, args) ->
  for p in plugins
    if p[name]? and (typeof p[name] is 'function')
      [ok, promise] = p[name].apply @, args
      return promise if ok
  [ok, promise] = defaultPlugin[name].apply @, args
  return promise if ok
  throw new Error "No plugin for #{name} found"
```

将会遍历整个 `plugins` 数组，寻找含有需要的方法的插件类实现。当找到以后，程序将试图调用这个方法。方法的返回值是 `[ok, promise]` 的形式，如果 ok 为真，表示该方法支持当前的输入，此时 promise 将不会为 null，这个 promise 将会在方法内容执行完成后完成，它将直接作为这个函数的返回值返回。如果 ok 为假，表示该方法不支持当前输入，于是程序将继续搜寻其他支持该输入的实现。如果循环已经结束而没有任何实现被找到，程序将使用默认的实现。这个默认实现是在一开始就被实例化的，它默认被载入，不属于 `plugins` 数组，提供所有已知的插件方法的默认实现。

这种机制主要是考虑到类似这种需要

```json
[
  "posts/my-blog.rst",
  "posts/hello-blog.md",
  "some-remote://xxxxx.md"
]
```

同一个博客中出现了不同格式的文章，还有不同的存储后端 —— 有的文章甚至存在于远端。这就需要实现同一个方法的插件能够互相分工各司其职。

在刚刚的 config.json 中，大家也能看见我专门安排了一个 plugins 字段。当程序启动或重载时，将执行这样一个过程来载入全部插件

```coffeescript
loadPlugins = (config) ->
  return if not config.plugins?
  config.plugins.forEach (it) ->
    if it.startsWith 'npm://'
      require it.replace 'npm://', ''
    else
      require "#{process.cwd()}/#{it}"
```

如果以 `npm://` 开头，程序将作为一个 npm 包来载入这个插件，否则将作为相对于当前路径的单个文件来载入。插件是可以直接使用 CoffeeScript 编写的 —— 博客程序已经载入了 `coffee-script/register`。

当然，这里还存在一个问题，就是被载入的插件无法载入它的父模块 `plugins`。而在这个父模块里，我将必须的依赖及 `Plugin` 基类都作为 module.exports 导出了。这就十分尴尬了。于是我使用了一个小小的 hack

```coffeescript
require.cache['plugin'] = module # Enable this to be directly required
Module = require 'module'
realResolve = Module._resolveFilename
Module._resolveFilename = (request, parent) ->
  if request is 'plugin'
    return 'plugin'
  realResolve request, parent
```

将这个模块强制加入 `require.cache` 并替换 `_resolveFilename` 方法使其不会找不到模块。于是，在其他插件中，只需要 `require 'plugin'` 即可载入这个父模块，也就能够继承基类了。

### 文章格式

完成了插件系统，下面就该提供文章格式解析的默认实现了。

当载入文章时，程序将会调用插件系统的 `parsePost` 方法，这个方法只有一个参数，就是文件的原始内容。默认实现中，文章的头部应该包含文章的元数据。因为我自己多数时候使用 Markdown 格式写作，所以我提供了兼容 Markdown 的默认元数据格式，即类似这样

```markdown
\`\`\`json
{
  "title": "再见，Ghost",
  "url": "goodbye-ghost",
  "date": "2016-07-11",
  "tags": ["Tech", "Blog"],
  "parser": "Markdown"
}
\`\`\`
```

这样，在解析文章时，只需要找到这一个代码块，然后使用 `JSON.parse` 解析元数据即可。

```coffeescript
  parsePost: (content) ->
    end = content.indexOf '```\n'
    return [false, null] if not (content.startsWith('```json') and end > 0)
    start = '```json'.length + 1

    promise = Promise.try ->
      json = content[start...end]
      data = JSON.parse json
      data.content = content[end + '```'.length...].trim()
      return data
    .then (data) ->
      if not (data.title? and data.date?)
        throw new Error 'You must provide at least `title` and `date`'
      if not data.parser?
        data.parser = 'Default'
      if not data.url?
        data.url = encodeURIComponent data.title
      if not data.template?
        data.template = "post"
      return data
    .then (data) ->
      data.date = new Date data.date
      return data
```

这个 `parser` 指定的是解析程序，我将稍后解释。

所有的文章载入和解析的过程，都是在程序启动和重载的过程中完成的，不会在每次请求时执行，这是因为文章的内容一般不会随意变化，除非被触发重载事件。然而，模板的渲染却是在每次请求时实时执行的 —— 因为有的插件可能需要实时影响渲染的结果。

### 解析器

解析好元数据以后，程序会把剩下的内容丢给元数据中指定的解析器。所有的解析器都是插件方法，格式是 `parseContent#{parser_name}`。比如说 Markdown 的解析方法就是 `parseMarkdown`。对于未指定解析器的文章，程序提供了一个默认解析器 `parseContentDefault`

```coffeescript
  parseContentDefault: (content) ->
    promise = Promise.try ->
      return content # Do no change on the content
    return [true, promise]
```

而我自己实现的 typeblog-markdown 插件则提供了一个 Markdown 解析器 （基于 marked）

```coffeescript
{Plugin, dependencies, callPluginMethod} = require 'plugin'
{Promise} = dependencies
marked = require 'marked'

marked.setOptions highlight: (code, lang, cb) ->
  callPluginMethod 'highlight', [code, lang]
    .then (result) -> cb null, result
    .catch (err) -> cb null, code

class MarkdownPlugin extends Plugin
  parseContentMarkdown: (content) ->
    promise = new Promise (resolve, reject) ->
      marked content, (err, result) ->
        if err?
          reject err
        else
          resolve result

    return [true, promise]

  highlight: (code, lang) ->
    return [true, Promise.try ->
      return code
    ]

module.exports = new MarkdownPlugin
```

这个插件又需要一个名为 `highlight` 的插件方法。这个插件方法的作用是给代码块加上高亮。这个插件里提供了一个默认实现，就是什么也不支持的默认实现。要真正实现高亮需要再载入实现了 `highlight` 方法的插件。注意，为了覆盖这个默认实现，所载入的代码高亮插件必须在这个 Markdown 解析插件之前载入，即在 `plugins` 列表中位于 `(npm://)typeblog-markdown` 之前。我自己也实现了一个基于 `highlight.js` 的代码高亮插件，大家可以在文章尾部的 GitHub 仓库中找到。

### 主题引擎

主题引擎我采用了 Handlebars.js ，以便于移植我给 Ghost 做的主题。所有的主题文件都存放于博客根目录的 template 目录下，该目录的结构

```
/
- /assets
- - .....
- /partials
- - .....
- default.hbs
- index.hbs
- post.hbs
```

其中 `{default,index,post}.hbs` 是必须的。`assets` 目录会被映射到 `blog_url/assets` ，可用于存放 css 等。 partials 目录下的 .hbs 文件会在启动时被注册为 Handlebars 的 partial。同样，为了调试方便，当这个目录的文件有改动时，主题引擎会自动重载。不过，主题的重载支持是有限的，要完全刷新主题，还是最好重启。

default.hbs 是最后被渲染的，它是博客所有页面共享的框架，包含头部和尾部。index.hbs 和 post.hbs 都是具体页面的模板。渲染首页、首页的分页、Tag 页面和 Tag 页面的分页时，程序将调用 index.hbs 作为模板，它将被传递这样的上下文

```json
{
  "blog": {
    "title": "..",
    "description": "..",
    "url": "..",
    "isHome": true
  },
  "firstPage": true,
  "lastPage": false,
  "nextPage": "/page/2",
  "prevPage": "",
  "curPage": 1
}
```

而当渲染具体文章时，它将被传递这样的上下文

```json
{
  "blog": {
    "title": "..",
    "description": "..",
    "url": "..",
    "isHome": true
  },
  "post": {
    "...": "..."
  }
}
```

其中 `post` 就是文章的元数据，加上 `content` 字段即文章的解析后的内容。当 post 或 index 渲染完成后，其内容将被作为 content 字段传递给 default.hbs 作最后的渲染，它将收到这样的上下文

```json
{
  "blog": {
    "title": "..",
    "description": "..",
    "url": "..",
    "isHome": true
  },
  "content": "...",
  "pageContext": {
    "...": "..."
  }
}
```

其中 pageContext 是当前页面的上下文，即刚才传给 index 或 post 的上下文对象。

另外，如果在 config.json 里面定义了 template_arguments 字段，那么这个字段会被传递到所有模板的上下文里，字段名称为 arguments。在文章元数据里定义的其他扩展字段也会被原样传递到 post.hbs 的上下文中。

默认我也提供了几个 helper, 包括用于引用 asset 并通过 md5 后缀强制更新浏览器缓存的 helper 和格式化日期的 helper 等。大家还是直接去 GitHub 仓库里面看。

### 其他

至于 RSS，我直接使用了 node-rss 来生成。

在搭建我自己的博客的时候，我又实现了两个（可能）只有我自己会用到的插件，比如一个 `chinese-cdn` 插件用于把 Google Fonts 和 cdnjs 等资源替换到国内 CDN，和一个 `github-webhook` 用于接收 GitHub 的更新通知并重载博客。这些插件都可以在本博客的仓库 <https://github.com/PeterCxy/typeblog.net> 看到。

我自己移植了一个主题 [typeblog-diaspora](https://github.com/PeterCxy/typeblog-diaspora) 使用，就是之前移植的 `ghost-diaspora` 的修改版。这个主题需要在 config.json 的 template_arguments 内定义如下字段

* `cover`: 博客的封面
* `disqus_username`: Disqus 用户名
* `navigation`: 博客主导航。是一个数组，每个成员都应该有 label 和 url 两个属性
* `social`: 社交链接。同样是数组，每个成员都有 url 和 icon 两个属性。其中 icon 是 material-design-icons 中的图标名称（去掉 mdi- ）

每篇文章的元数据中也可以指定每篇文章自己的封面。详细的配置方式还是请看我的博客配置。

该博客系统以 WTFPL 开源于 <https://github.com/PeterCxy/Typeblog>。另外，目前没有什么文档，如果有人真的想要使用这个博客引擎的话，我将会在有空的时候逐步完成文档。当然，你也可以直接联系 Telegram 上的 @PeterCxy 也就是我，我可以直接回答你的问题。