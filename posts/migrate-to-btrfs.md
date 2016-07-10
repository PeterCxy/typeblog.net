```
{
  "title": "无聊迁移到Btrfs杂记",
  "url": "migrate-to-btrfs",
  "date": "2015-03-31",
  "parser": "Markdown"
}
```


前天，我 `小高考` (江苏学测) 完了。放假两天。回到家里感觉无聊没事做，欣然决定将我的整个磁盘迁移到 `btrfs` 上。也是打算用这两天时间来……算是在 `语数外` 三门轮番轰炸前的最后一次折腾吧。

关于 [btrfs](https://btrfs.wiki.kernel.org) 我想大家都应该了解一些。我主要看中的是 `btrfs` 的 `snapshot` 和 `subvolume` 功能，因为我使用的是滚动更新的 `gentoo`，有 `滚挂` 的风险，如果有了 `snapshot` ，一旦滚挂，只需恢复即可。

对于手抽党而言，`btrfs` 更有可能拯救你手抽破坏的各种东西……

而 `btrfs` 的转换过程才是最最痛苦的，这个我等下再吐槽了……

<!--more-->

### 准备内核

由于我使用的是 `Gentoo Linux`, 所以要手工编译内核，只需要开启 `File Systems` 下的 `Btrfs` 一项再重新编译即可。

### 转换分区

虽然 `Google` 上有很多 `Live convert` 教程，但是我真的觉得那会很危险……

我是使用的 `SystemRescueCD` 引导转换的，因为它自带 `btrfs-progs` 这个包，只消运行

```
btrfs-convert /dev/sdaX
```

即可转换。转换好了以后，所有数据仍然没有变化，只是它新建了一个 `ext2_saved` 子卷，里面保存了一个和分区以前的状态一样的镜像。

### 建立子卷、重构目录树

如果你只用 `btrfs` 的根子卷的话，那也真是浪费了……所以我是建立了子卷。

我原来的分区是对 `/` 与 `/home` 单独分区，所以我的子卷也是为它们单独建立子卷。

```
btrfs subvol create rootfs-gentoo # /
btrfs subvol create homefs-gentoo # /home
```

接下来需要把它们都mount出来，这里是 `btrfs` 的自带选项 `subvol`，可以把某几个子卷单独挂载出来，__一定要注意这个选项，我就被坑过！！！__

```
mount -t btrfs -o subvol=rootfs-gentoo,compress=lzo /mnt/gentoo
mount -t btrfs -o subvol=homefs-gentoo,compress=lzo /mnt/gentoo/home
```

然后使用 `rsync` 等工具把原系统的数据转移过去。

### 配置内核command line和fstab

要使Linux内核从btrfs子卷作为根目录启动，必须把命令行写成这样

```
root=/dev/sdaX rootfstype=btrfs rootflags=subvol=rootfs-gentoo
```

在 `fstab` 里面，你得把原来的 `ext4` 改成 `btrfs`，并且在挂载参数里面加上 `subvol=xxx`。另外，一定要把 `btrfs` 的根子卷即不加 `subvol` 挂载参数的子卷挂载出来，建议挂载到 `/mnt/pool`，否则不好操作。

然后要建立snapshot，只需切换到 `/mnt/pool`，运行 `btrfs subvol snapshot create [subvol-name] [snapshot-name]` 即可。

### 吐槽

`btrfs-convert` 太太太太太太慢！！！！！！！！！我先做测试转换了一个 `50G` 的盘用了三分钟，然后我开始转换我的磁盘，一共 `800G`，用了将近四十分钟！！！！！！！！！！！！！！！！！！！！！！

不过 `btrfs` 确实是好东西，比如说我昨天就差点手残把系统搞坏了，然后 `btrfs` 这么快就派上用场了………………
