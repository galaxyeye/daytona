galaxyeye: 给我linux下设置代理ip的命令

GitHub Copilot: 我来为您提供Linux下设置代理IP的常用命令。以下是几种不同场景下的代理设置方法：

## 1. 临时环境变量设置（当前会话有效）

```bash
# HTTP代理
export http_proxy=http://host.docker.internal:10809
export https_proxy=http://host.docker.internal:10809

# 如果代理需要认证
export http_proxy=http://username:password@host.docker.internal:10809
export https_proxy=http://username:password@host.docker.internal:10809

# SOCKS代理
export http_proxy=socks5://host.docker.internal:10809
export https_proxy=socks5://host.docker.internal:10809

# 设置不使用代理的地址
export no_proxy=localhost,127.0.0.1,.local
```

## 2. 永久环境变量设置

```bash
# 编辑用户配置文件
nano ~/.bashrc
# 或
nano ~/.profile

# 在文件末尾添加以下内容：
export http_proxy=http://host.docker.internal:10809
export https_proxy=http://host.docker.internal:10809
export no_proxy=localhost,127.0.0.1,.local

# 使配置生效
source ~/.bashrc
```

## 3. 系统级代理设置

```bash
# 编辑系统环境变量文件
sudo nano /etc/environment

# 添加内容：
http_proxy="http://host.docker.internal:10809"
https_proxy="http://host.docker.internal:10809"
no_proxy="localhost,127.0.0.1,.local"
```

## 4. 特定应用的代理设置

### APT包管理器（Ubuntu/Debian）

```bash
# 创建APT代理配置
sudo nano /etc/apt/apt.conf.d/95proxies

# 添加内容：
Acquire::http::Proxy "http://host.docker.internal:10809";
Acquire::https::Proxy "http://host.docker.internal:10809";
```

### YUM包管理器（CentOS/RHEL）

```bash
# 编辑YUM配置
sudo nano /etc/yum.conf

# 添加内容：
proxy=http://host.docker.internal:10809
proxy_username=username
proxy_password=password
```

### Git代理设置

```bash
# 设置Git HTTP代理
git config --global http.proxy http://host.docker.internal:10809
git config --global https.proxy http://host.docker.internal:10809

# 设置Git SOCKS代理
git config --global http.proxy socks5://host.docker.internal:10809
git config --global https.proxy socks5://host.docker.internal:10809

# 取消Git代理设置
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### Wget代理设置

```bash
# 创建wget配置文件
nano ~/.wgetrc

# 添加内容：
http_proxy = http://host.docker.internal:10809
https_proxy = http://host.docker.internal:10809
use_proxy = on
```

### Curl代理设置

```bash
# 临时使用代理
curl --proxy http://host.docker.internal:10809 http://example.com

# 创建curl配置文件
nano ~/.curlrc

# 添加内容：
proxy = http://host.docker.internal:10809
```

## 5. 查看和测试代理设置

```bash
# 查看当前代理设置
echo $http_proxy
echo $https_proxy

# 测试代理连接
curl --proxy http://host.docker.internal:10809 http://httpbin.org/ip

# 测试当前网络IP
curl http://httpbin.org/ip
```

## 6. 取消代理设置

```bash
# 取消临时代理设置
unset http_proxy
unset https_proxy
unset no_proxy

# 或者设置为空
export http_proxy=""
export https_proxy=""
```

## 使用示例

假设您的代理服务器IP是 `192.168.1.100`，端口是 `8080`：

```bash
# 设置HTTP代理
export http_proxy=http://192.168.1.100:8080
export https_proxy=http://192.168.1.100:8080

# 测试代理是否生效
curl http://httpbin.org/ip
```

请根据您的具体需求选择合适的设置方法。如果是临时使用，推荐使用环境变量方式；如果需要永久生效，建议修改配置文件。
