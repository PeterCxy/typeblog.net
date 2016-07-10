```json
{
  "title": "使用git push命令提交到gerrit",
  "url": "use-git-push-to-push-to-gerrit",
  "date": "2013-10-07",
  "parser": "Markdown"
}
```


Gerrit是一款被Android开源项目广泛采用的code review(代码审核)系统。以前一直以为必须用repo上传，今天因为偷懒，想用git直接推上去，没想到居然成功了。。

先尝试直接用git push http://review.xxx.xxx/xxx/xxx master:master ，发现返回rejected，查看通知发现是不支持直接推送到主分支。
<!--more-->
那么怎么办呢？当时没仔细看清楚通知，试了好多分支名称都不能推送，最后发现，通知告诉我要推送到refs/for下面的分支。

这样就容易了：

```sh
git push 远程地址 本地分支:refs/for/远程分支
```

轻松搞定。
