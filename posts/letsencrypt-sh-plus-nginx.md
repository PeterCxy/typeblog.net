```json
{
  "title": "使用 LetsEncrypt.sh + Nginx 实现SSL证书自动签发/续签",
  "url": "letsencrypt-sh-plus-nginx",
  "date": "2016-05-30",
  "parser": "Markdown",
  "cover": "https://files.typeblog.net/blog/legacy/images/2016/05/Internet2.jpg",
  "tags": ["Tech", "Linux", "Security"]
}
```

随着运营商劫持、政府网络监控行为的加强，`HTTPS` 在今年已经几乎成为了网站的标配。吾辈之前使用的一直是 `COMODO PositiveSSL Wildcard`, 但是这证书的价格，已经到了我今年很可能续不起命的地步。本来想着高考完以后把它换成单域名的 `PositiveSSL` 算了，但是我这个人呢，喜欢瞎折腾，经常弄出一大堆子域名，而且我又开启了全部子域名的 `HSTS`，因而使用这种证书的话成本可不太低。我之前尝试过使用 `LetsEncrypt` 的证书，但是无奈他家的官方客户端对于 `Nginx` 的支持……实在是太简陋而无法使用。作为忠实 `Nginx` 信徒，要我去使用 `Apache`, 是不太可能的。当然，之前我也使用过 `Caddy` 的自动签发证书功能，但是 `Caddy` 相比 `Nginx`，功能还是太简陋，我总不至于在 `Caddy` 后面再套一层 `Nginx` 吧？！

不过今天我找到了 `LetsEncrypt` 的另一个客户端

[letsencrypt.sh](https://github.com/lukas2511/letsencrypt.sh)

这是用 `Bash` 写的客户端，符合核心价值观，~~很清真~~，而且可定制性非常高。我初步看一了一下文档以后，发现这非常尊重我的决定权，没有任何钦定的感觉。使用这个脚本，加上一定的配置，应该就可以完成 `LetsEncrypt` 证书的自动签发和续期了。

### 准备

首先使用 `git` 把那个 `repository` 克隆下来

```bash
git clone https://github.com/lukas2511/letsencrypt.sh
cd letsencrypt.sh
```

接下来的所有操作都假定在该目录内进行

### 配置

创建文件 `config`

```bash
#!/bin/bash

CA="https://acme-staging.api.letsencrypt.org/directory"
CHALLENGETYPE="http-01"
CERTDIR="${BASEDIR}/certs"
HOOK="${BASEDIR}/hook.sh"
CONTACT_EMAIL='you@example.com'
WELLKNOWN="/tmp/acme-wellknown"

mkdir -p $WELLKNOWN
chmod -R 777 $WELLKNOWN
```

注意，在这个配置中，`CA` 暂时被指定到了一个测试用的地址，这是为了防止配置失败导致证书数量超限。稍后配置好后我们会将它指向到正确的地址。

你应该把 `CONTACT_EMAIL` 指向自己的邮箱。

如果需要签发 `ECC` 证书，只要加一行

```bash
KEY_ALGO="secp384r1"
```

这个配置文件将自动创建 `/tmp/acme-wellknown`, 用来存储验证域名所有权需要的文件。我一开始想要采用 `DNS验证`, 但是发现这实在太过复杂，而 `HTTP` 要简单得多。当然，你也可以修改这个路径，但是等会儿的 `Nginx` 配置也将要作出对应的修改。

接下来我们需要配置 `Nginx` 让它能够接受  `HTTP` 验证请求。

### Nginx

`LetsEncrypt` 在签发证书前将对你的域名发送请求以验证你对域名的所有权。刚刚我们也已经让脚本把验证需要的文件存储到 `/tmp/acme-wellknown` 里面。一个简单的做法是，对于每一个域名，让 `Nginx` 自动把到 `/.well-known/acme-challenge` 下的请求转移到 `/tmp/acme-wellknown`，但是，当域名很多的时候，这将会非常麻烦，因而这不是一个好主意。所以，我们需要一个更好的方案。

在一个开启了 `HSTS` 的服务器上，任何 `HTTP` 请求只有一个作用，就是 `301` 永久跳转到 `HTTPS` 下。当 `Nginx` 配置中同一个 `server` 同时监听了 `80` 和 `443 ssl` 的时候，`Nginx` 将自动完成跳转工作。为了实现域名验证，我们只能将 `80` 分开监听，重新设置跳转规则。

首先，删除所有域名下的 `80` 端口监听。然后新建一个 `server` 配置

```nginx
server {
    listen 80 default_server;
    location /.well-known/acme-challenge {
        alias /tmp/acme-wellknown;
    }
    location / {
        rewrite ^(.*)$ https://$host$request_uri permanent;
    }
}
```

这个默认配置做了两件事

1. 将目标是 `/.well-known/acme-challenge` 的请求全部转移到 `/tmp/acme-wellknown`
2. 将其他请求全部重写到对应网站的 `https` 地址

因为这是默认配置，所以它将对任意域名起作用。这样，`Nginx` 已经可以用作域名验证了 

### hook.sh

然而，就算完成了以上两步，签发后的证书还是不能自动被配置到服务器上。对于这种问题，我暂时没有找到一个非常完美的解决方案 -- 我是极度反对用脚本重写 `nginx.conf` 的。所以我决定使用脚本自动生成一个只包含 `SSL` 配置的部分配置文件，然后 `include` 到完整的配置文件里即可。

所以我们需要一个 `hook.sh`  -- 根据我们前面的配置，这个 `hook.sh` 会在特定的时候自动被 `letsencrypt.sh` 调用

```bash
#!/usr/bin/env bash
CONF_DIR="/path/to/somewhere"

function deploy_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
}

function clean_challenge {
    local DOMAIN="${1}" TOKEN_FILENAME="${2}" TOKEN_VALUE="${3}"
}

function deploy_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}" TIMESTAMP="${6}"
    local CONF="$CONF_DIR/$DOMAIN.conf"
    if [[ -e "$CONF" ]]; then
        rm -rf "$CONF"
    fi
    echo "ssl_certificate $FULLCHAINFILE;" >> $CONF
    echo "ssl_certificate_key $KEYFILE;" >> $CONF
    echo "ssl_protocols TLSv1 TLSv1.1 TLSv1.2;" >> $CONF
    echo "ssl_ciphers HIGH:!aNULL:!MD5;" >> $CONF
}

function unchanged_cert {
    local DOMAIN="${1}" KEYFILE="${2}" CERTFILE="${3}" FULLCHAINFILE="${4}" CHAINFILE="${5}"
}

HANDLER=$1; shift; $HANDLER $@
```

你需要把 `CONF_DIR` 变量的内容改为一个具体的目录的完整路径。对应的配置文件将存储在这里。

当证书签发成功后，函数 `deploy_cert` 将被调用。在这个函数中，我们将自动创建一个 `$DOMAIN.conf`，在里面写入对应域名的证书配置。注意，如果一个证书包含了多个域名，那么这个证书的文件名将是那个主要域名。

要使用证书，只要在 `Nginx` 配置里面加入

```nginx
include /path/to/somewhere/domain.conf;
```

其中 `/path/to/somewhere/` 与 `CONF_DIR` 一致，`domain` 与主域名一致。

### 测试

创建 `domains.txt`, 在里面输入你要签发证书的域名。一行表示一个证书，如果一个证书需要包含多个域名，请在一行内使用空格隔开。每行的第一个域名将作为证书的主要域名。

然后就可以执行测试了 --

```bash
./letsencrypt.sh -c
```

如果执行成功，我们就可以退出测试模式了。把 `config` 中的 `CA` 改为

```bash
CA="https://acme-v01.api.letsencrypt.org/directory"
```

接下来，删除 `certs` 与 `private_key.*`, 重新执行

```bash
./letsencrypt.sh -c
```

即可获取有效的证书。接下来在 `Nginx` 中引用配置文件即可。

### 自动续期

我选择使用 `systemd-timer` 实现。

`letsencrypt.service`

```ini
[Unit]
Description=LetsEncrypt

[Service]
Type=oneshot
User=your_user
ExecStart=/path/to/letsencrypt/letsencrypt.sh
WorkingDirectory=/path/to/letsencrypt
```

`letsencrypt.timer`

```ini
[Unit]
Description=Daily LE Task

[Timer]
OnBootSec=15min
OnUnitActiveSec=1d

[Install]
WantedBy=timers.target
```

然后执行

```bash
systemctl start letsencrypt.timer
systemctl enable letsencrypt.timer
```

即可每日自动检测是否需要续期。

啊，还是要注意替换那些 `PLACEHOLDER` 哟呜。