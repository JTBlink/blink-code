# Aider 发布流程

本文档描述了 Aider 项目的发布流程，包括 aider-chat 和 aider-install 两个包的发布步骤。

## 概述

Aider 项目包含两个主要的发布组件：

1. **aider-chat** - 主要的 Aider 应用程序包
2. **aider-install** - 用于简化 Aider 安装过程的辅助包

每个组件都有自己的发布流程和脚本。

## 先决条件

在开始发布过程之前，请确保：

- 您拥有 Aider 代码库的写入权限
- 您拥有 PyPI 的上传权限
- 已安装以下工具：
  - Python 3.8+
  - pip
  - git
  - build
  - twine

## 发布 aider-chat

### 自动发布流程

使用 `scripts/release.sh` 脚本可以自动化 aider-chat 的发布流程：

```bash
./scripts/release.sh <版本号>
```

例如：

```bash
./scripts/release.sh 1.2.3
```

这个脚本会：

1. 运行 `versionbump.py` 脚本更新版本号并创建 git 标签
2. 运行 `update-history.py` 脚本更新 HISTORY.md 文件
3. 触发 GitHub Actions 工作流程：
   - 构建 Python 包并发布到 PyPI
   - 构建 Docker 镜像并推送到 DockerHub

### 手动发布流程

如果需要手动发布，请按照以下步骤：

1. 更新版本号：

   ```bash
   python scripts/versionbump.py <版本号>
   ```

2. 更新发布历史：

   ```bash
   python scripts/update-history.py
   ```

3. 等待 GitHub Actions 工作流完成发布。

## 发布 aider-install

aider-install 是一个独立的 Python 包，使用 `scripts/release-aider-install.sh` 脚本发布：

```bash
./scripts/release-aider-install.sh <版本号>
```

例如：

```bash
./scripts/release-aider-install.sh 1.2.3
```

这个脚本会：

1. 创建临时目录用于构建 aider-install 包
2. 准备必要的文件：
   - Python 源代码文件
   - setup.py
   - pyproject.toml
   - README.md
   - LICENSE
3. 构建 Python 包
4. 上传到 PyPI

## 版本号规范

Aider 使用语义化版本控制（[SemVer](https://semver.org/)），格式为 `X.Y.Z`：

- **X**: 主版本号 - 不兼容的 API 更改
- **Y**: 次版本号 - 向后兼容的功能添加
- **Z**: 修订号 - 向后兼容的问题修复

## 发布后检查

发布完成后，建议执行以下检查：

1. 确认 PyPI 上的版本已更新：
   - https://pypi.org/project/aider-chat/
   - https://pypi.org/project/aider-install/

2. 确认 Docker 镜像已更新：
   - https://hub.docker.com/r/YOURDOCKERHUB/aider/tags
   - https://hub.docker.com/r/YOURDOCKERHUB/aider-full/tags

3. 验证安装是否正常工作：
   ```bash
   pip install aider-chat==<版本号>
   aider --version
   ```

4. 验证 aider-install 是否正常工作：
   ```bash
   pip install aider-install==<版本号>
   aider-install
   ```

## 发布周期

Aider 没有固定的发布周期，通常在以下情况下发布新版本：

- 重要功能完成
- 关键 bug 修复
- 安全更新

## 紧急修复

对于需要紧急修复的问题：

1. 创建修复提交并合并到 main 分支
2. 使用 `scripts/release.sh` 发布新的补丁版本
3. 在 HISTORY.md 中注明这是一个紧急修复版本

## 其他注意事项

- aider-chat 和 aider-install 的版本号可以不同步，但建议保持一致以避免混淆
- 每次发布后，应在相关社区和渠道（如 Discord、Twitter）通知用户
- 考虑更新官方文档网站以反映新版本的变化
