# 构建脚本已移动

Docker 镜像构建脚本已移动到新位置：

**新位置：** `docker/publish/`

这样可以将所有 Docker 相关的文件（Dockerfile、构建脚本等）集中在 `docker` 目录下，便于管理和维护。

## 使用方法

```bash
# 进入新的构建目录
cd docker/publish

# 查看帮助
make help

# 构建镜像
make build

# 或直接使用脚本
./build-and-push.sh --help
```

详细使用说明请查看 `docker/publish/README.md`。
