# Aider 启动脚本使用说明

`aider.sh` 是一个用于启动 aider 的便捷脚本，它可以自动处理依赖安装、环境配置和源码运行。

## 功能特性

- ✅ 自动检查和安装所需依赖
- ✅ 环境变量配置检查
- ✅ 彩色日志输出
- ✅ 首次运行自动设置
- ✅ 支持传递所有aider原生参数
- ✅ 使用系统Python环境（无虚拟环境）

## 快速开始

### 1. 首次使用

```bash
# 给脚本添加执行权限（如果还没有的话）
chmod +x aider.sh

# 查看帮助信息
./aider.sh --help

# 检查环境配置
./aider.sh --check-env

# 手动安装依赖（可选，首次运行会自动执行）
./aider.sh --setup
```

### 2. 日常使用

```bash
# 启动aider（当前目录）
./aider.sh

# 编辑特定文件
./aider.sh file1.py file2.py

# 使用特定模型
./aider.sh --model gpt-4

# 启动GUI模式
./aider.sh --gui

# 查看aider版本
./aider.sh --version
```

## 环境配置

脚本会自动读取以下环境变量（按优先级排序）：

### API配置
- `AIDER_OPENAI_API_KEY` - OpenAI API密钥
- `AIDER_OPENAI_API_BASE` - OpenAI API基础URL
- `ANTHROPIC_API_KEY` - Anthropic API密钥
- `OPENAI_API_KEY` - 标准OpenAI密钥（备用）

### 模型配置
- `AIDER_MODEL` - 默认使用的模型

### 示例配置

在 `~/.bashrc` 中添加：

```bash
# aider配置
export AIDER_MODEL="openai/360-qwen3-coder-480b-a35b"
export AIDER_OPENAI_API_KEY="your-api-key"
export AIDER_OPENAI_API_BASE="http://llm.api.zyuncs.com/v1/"
```

## 脚本选项

| 选项 | 说明 |
|------|------|
| `-h, --help` | 显示帮助信息 |
| `--setup` | 安装依赖到用户目录 |
| `--check-env` | 检查环境配置和依赖状态 |
| `--version` | 显示aider版本信息 |

## 工作原理

1. **环境检查**: 检查Python版本（需要3.8+）和pip工具
2. **依赖管理**: 检查关键依赖，缺失时使用 `pip install --user` 安装
3. **环境配置**: 设置PYTHONPATH和读取环境变量
4. **启动aider**: 使用 `python -m aider` 运行

## 依赖安装

脚本会自动检查并安装以下关键依赖：
- `litellm` - LLM接口库
- `prompt-toolkit` - 命令行界面
- `GitPython` - Git操作
- `rich` - 丰富的终端输出
- `PyYAML` - YAML配置文件支持
- `requests` - HTTP请求库

所有依赖都安装到用户目录（`~/.local/lib/python*/site-packages/`），不影响系统Python环境。

## 目录结构

```
blink-code/
├── aider.sh              # 启动脚本
├── aider/                # aider源码
├── requirements.txt      # 完整依赖列表
└── README-aider-launcher.md  # 本说明文档
```

## 故障排除

### 依赖安装失败

```bash
# 手动重新安装依赖
./aider.sh --setup

# 检查pip和python3是否正确安装
python3 --version
pip3 --version
```

### API密钥问题

```bash
# 检查环境变量配置
./aider.sh --check-env

# 确保在.bashrc或.env文件中正确设置了API密钥
```

### Python版本问题

```bash
# 检查Python版本
python3 --version

# 需要Python 3.8或更高版本
```

### 权限问题

如果遇到权限问题，确保用户目录可写：

```bash
# 检查用户site-packages目录
python3 -m site --user-site

# 如果目录不存在，会自动创建
```

## 高级用法

### 使用.env文件

在项目根目录创建 `.env` 文件：

```bash
AIDER_MODEL=gpt-4
AIDER_OPENAI_API_KEY=your-key-here
AIDER_OPENAI_API_BASE=https://api.openai.com/v1
```

### 自定义依赖

如果需要额外的Python包，可以使用：

```bash
pip3 install --user package_name
```

### 查看安装的包

```bash
pip3 list --user
```

## 环境信息

使用 `./aider.sh --check-env` 查看详细环境信息：

- Python版本和路径
- 环境变量配置
- aider源码路径
- Python包安装路径
- 依赖安装状态

## 注意事项

1. 首次运行会自动安装依赖，可能需要几分钟时间
2. 脚本需要在aider项目根目录中运行
3. 确保有网络连接以下载Python包
4. 依赖安装到用户目录，不需要sudo权限
5. 不使用虚拟环境，直接使用系统Python环境

## 更新

当aider源码更新时，可能需要更新依赖：

```bash
# 重新检查和安装依赖
./aider.sh --setup
```

如果需要更新已安装的包：

```bash
pip3 install --user --upgrade litellm prompt-toolkit GitPython rich PyYAML requests
```

---

如有问题，请检查脚本输出的错误信息，或运行 `./aider.sh --check-env` 诊断环境配置。
