#!/bin/bash
echo "=== Docker 容器代理测试 ==="
echo "HTTP Proxy: ${http_proxy:-未设置}"
echo "HTTPS Proxy: ${https_proxy:-未设置}"
echo "No Proxy: ${no_proxy:-未设置}"
echo ""

echo "测试连接..."
if command -v curl >/dev/null; then
    echo "当前 IP:"
    curl -s --max-time 10 ipinfo.io/ip || echo "连接失败"
    echo ""
    echo "测试 Google 连接:"
    curl -I -s --max-time 10 https://www.google.com | head -1 || echo "连接失败"
else
    echo "curl 未安装，跳过网络测试"
fi
