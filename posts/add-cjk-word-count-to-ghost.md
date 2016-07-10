```json
{
  "title": "给Ghost博客系统添加中文字数统计",
  "url": "add-cjk-word-count-to-ghost",
  "date": "2016-02-01",
  "parser": "Markdown"
}
```

我在前几篇文章中已经提及，最近我将我的博客系统切换到了 `Ghost`。我已经夸过它的不少优点，如轻量等，但现在的 `Ghost` 有个非常致命的问题，就是不支持统计中文字符数量。无论你在一篇文章里写了多少汉字，它自带的字数统计总是按照空格数量进行，也就是英语习惯。而中文的字词之间没有天然的分隔，所以这种统计自然就会不准确。不仅仅是中文，对于中日韩语言来说， `Ghost` 的这种统计方式都存在很大的问题。

### 方案

首先我在 `Ghost` 的repo里找到了 [Issue #2656](https://github.com/TryGhost/Ghost/issues/2656) 和 [Issue #3801](https://github.com/TryGhost/Ghost/issues/3801)。在这两个议题中，他们提到的解决方案是首先判定语言，然后使用对应语言的分词技术来统计单词数量。起初，我也认为这个方案是可行的，于是在 `Ghost` 源码里一番折腾。我找到了 `core/client/app/helpers/gh-count-words.js`，这里有这么一段代码

```javascript
let markdown = params[0] || '';

if (/^\s*$/.test(markdown)) {
    return '0 words';
}

let count = counter(markdown);
```

它首先判断是否为空，然后将整个编辑器的文本传递给字数统计函数进行统计。我本想从这里入手，用正则表达式提取文本中的中日韩字符数量，因为 `Ghost` 已经默认引用了 `XRegExp`, 它支持完整的 `Unicode`, 只需要

```regexp
\\p{Katakana}\\p{Hiragana}\\p{Han}\\p{Hangul}
```

就可以提取出CJK字符。统计它们的数量，如果在总长度中占某个比例或以上，就可以认为这篇文章的主要语言是中日韩的一种，然后再调用分词技术解决问题即可。

做到一半的时候，我意识到了一个非常严重的问题，那就是似乎不能使用这种方式来判断文章的主要语言。特别是对于我的这种经常贴代码的博客，一篇中文的文章中常常夹杂比中文内容更长的拉丁字符。在这种情况下，如果按照长度判断，就完全不可靠了。而如果按照后台设置的语言来决定是否使用CJK字符统计逻辑，那还存在一个问题，就是现有的分词手段的内存消耗非常恐怖，我想没有人会愿意开个博客的编辑器都要等半天让浏览器载入分词数据库……

这个时候，Orz大水群里有人告诉我，即使是在 `MS Word` 中，东亚字符也是单独被统计的，有单独的一项显示东亚字符数量。如此看来，我也不如退而求其次，当中日韩文字存在的时候，只要在字符统计处多显示一项，专门显示东亚文字的数量，也就足够达成目的了。

### Code

实际上，`Ghost` 的后台的模板和前台的模板语法几乎是一样的。在最新的 `master` 分支中，编辑器的模板被放在 `core/client/app/templates/components/gh-editor.hbs`，其中

```html
<span class="entry-word-count">{{gh-count-words value}}</span>
```

一句的作用就是调用 `core/client/app/helpers/gh-count-words.js` 这个helper来显示字符数量。于是我就仿照这个helper的做法，在这一行上面添加了一个

```html
<span class="entry-cjk-character-count">{{gh-count-cjk-characters value}}</span>
```

然后又仿照 `gh-count-words.js`, 写了一个 `gh-count-cjk-characters.js`

```javascript
import Ember from 'ember';
import counter from 'ghost/utils/cjk-character-count';

const {Helper} = Ember;

export default Helper.helper(function (params) {
    if (!params || !params.length) {
        return;
    }

    let markdown = params[0] || '';

    if (/^\s*$/.test(markdown)) {
        return '';
    }

    let count = counter(markdown);

    if (count === 0) {
        return '';
    } else {
        return count + (count === 1 ? ' CJK character' : ' CJK characters');
    }
});
```

在这个helper中，和原来的字数统计一样，真正的统计函数 `counter` 是在被引用的 `core/client/app/utils/cjk-character-count.js` 内实现的。这个实现倒是比原来的字数统计简单不少，因为原来的字数统计还要过滤掉一些特殊字符，而中日韩字符统计只需要一个正则表达式提取所有的中日韩字符就搞定了

```javascript
// jscs: disable
/* global XRegExp */

export default function (s) {
    let charCJK = new XRegExp("[\\p{Katakana}\\p{Hiragana}\\p{Han}\\p{Hangul}]", 'g');
    let cjk = s.match(charCJK);
    return cjk === null ? 0 : cjk.length;
}
```

### 效果

虽然我只是简单地在模板里添加了一行，但得益于后台的 `css`，我所添加的中日韩字符统计被很好地安排在了原有字数统计的旁边。

![screenshot](/content/images/2016/02/Screenshot_20160201_141905.png)

由于响应式支持，在移动端的效果也非常好。

### 发布

我本来想以 `Pull Request` 的形式让官方接受这个补丁，但是在我所发起的 [PR #6391](https://github.com/TryGhost/Ghost/pull/6391) 中，其开发者表示他们正在做全新的编辑器，所以现在合并似乎意义不大。因此，作为一个临时的解决方案，我 `fork` 了一份 `Ghost`，并修改了 `travis.yml`, 用 `Travis CI` 自动打包了一份修改后的 `Ghost`, 并在我的 `GitHub Releases` 上发布: https://wasu.pw/7bWE

目前最新的版本是在1月25日的主分支基础上制作的，实际上和0.7.5差距不大，却多了一些bug的修复。在 `Ghost` 完成新的编辑器并加入CJK字符统计支持之前，我将持续维护这个分支，合并来自官方的最新更新并打包发布。