#!/bin/bash
set -e

# aider 启动脚本
# 通过源码运行 aider，自动处理依赖和环境配置

# 获取脚本路径，支持软链接解析
SCRIPT_PATH="${BASH_SOURCE[0]}"

# 如果是软链接，解析真实路径
if [ -L "$SCRIPT_PATH" ]; then
    echo "检测到软链接: $SCRIPT_PATH"
    REAL_SCRIPT_PATH="$(readlink -f "$SCRIPT_PATH")"
    echo "解析真实路径: $REAL_SCRIPT_PATH"
    SCRIPT_DIR="$(cd "$(dirname "$REAL_SCRIPT_PATH")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
fi

AIDER_ROOT="$SCRIPT_DIR"
echo "aider 根目录: $AIDER_ROOT"
# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "blink-code - aider 启动脚本"
    echo ""
    echo "用法:"
    echo "  $(basename "$0") [选项] [aider参数...]"
    echo ""
    echo "选项:"
    echo "  -h, --help           显示此帮助信息"
    echo "  --setup              安装依赖（仅首次运行需要）"
    echo "  --check-env          检查环境配置"
    echo "  --version            显示aider版本"
    echo "  --gui                启动GUI模式"
    echo "  --model MODEL        指定模型"
    echo ""
    echo "系统管理:"
    echo "  --install            安装脚本到用户路径"
    echo "  --uninstall          从用户路径卸载脚本"
    echo "  --create-link        创建软链接到系统路径"
    echo "  --remove-link        移除系统路径软链接"
    echo ""
    echo "示例:"
    echo "  $(basename "$0")                   # 启动aider"
    echo "  $(basename "$0") --setup          # 安装依赖"
    echo "  $(basename "$0") --install        # 安装到用户目录"
    echo "  $(basename "$0") --gui            # 启动GUI模式"
    echo "  $(basename "$0") --model gpt-4    # 使用指定模型启动"
    echo "  $(basename "$0") file1.py file2.py # 编辑指定文件"
    echo ""
    echo "环境变量配置:"
    echo "  AIDER_MODEL                    - 默认模型"
    echo "  AIDER_OPENAI_API_KEY          - OpenAI API密钥"
    echo "  AIDER_OPENAI_API_BASE         - OpenAI API基础URL"
    echo "  ANTHROPIC_API_KEY             - Anthropic API密钥"
}

# 检查Python环境
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "未找到python3命令"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
        print_info "Python版本: $PYTHON_VERSION ✓"
    else
        print_error "需要Python 3.8或更高版本，当前版本: $PYTHON_VERSION"
        exit 1
    fi
}

# 检查pip工具
check_pip() {
    if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
        print_error "未找到pip命令，请安装pip"
        exit 1
    fi
    
    # 优先使用pip3
    if command -v pip3 &> /dev/null; then
        PIP_CMD="pip3"
    else
        PIP_CMD="pip"
    fi
    
    print_info "使用pip命令: $PIP_CMD"
}

# 安装依赖
install_dependencies() {
    print_info "安装aider依赖..."
    
    # 检查requirements.txt是否存在
    if [ ! -f "$AIDER_ROOT/requirements.txt" ]; then
        print_error "未找到requirements.txt文件"
        exit 1
    fi
    
    # 使用requirements.txt安装依赖
    print_info "使用requirements.txt安装所有依赖..."
    $PIP_CMD install --user -r "$AIDER_ROOT/requirements.txt"
    print_success "依赖安装完成"
}

# 检查依赖是否已安装
check_dependencies() {
    local missing_deps=()
    
    # 检查关键依赖
    if ! python3 -c "import importlib_resources" 2>/dev/null; then
        missing_deps+=("importlib-resources")
    fi
    
    if ! python3 -c "import litellm" 2>/dev/null; then
        missing_deps+=("litellm")
    fi
    
    if ! python3 -c "import prompt_toolkit" 2>/dev/null; then
        missing_deps+=("prompt_toolkit")
    fi
    
    if ! python3 -c "import git" 2>/dev/null; then
        missing_deps+=("GitPython")
    fi
    
    if ! python3 -c "import rich" 2>/dev/null; then
        missing_deps+=("rich")
    fi
    
    if ! python3 -c "import oslex" 2>/dev/null; then
        missing_deps+=("oslex")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_warning "缺少依赖: ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# 设置环境变量
setup_environment() {
    # 从.bashrc中读取已配置的环境变量（如果存在）
    if [ -f "$HOME/.bashrc" ]; then
        # 检查是否已配置aider相关环境变量
        if grep -q "AIDER_" "$HOME/.bashrc"; then
            print_info "检测到.bashrc中的aider配置"
        fi
    fi
    
    # 设置默认环境变量（如果未设置）
    export PYTHONPATH="$AIDER_ROOT:${PYTHONPATH:-}"
    
    # 如果没有设置模型，使用默认值
    if [ -z "$AIDER_MODEL" ]; then
        export AIDER_MODEL="gpt-3.5-turbo"
        print_info "使用默认模型: $AIDER_MODEL"
    else
        print_info "使用配置的模型: $AIDER_MODEL"
    fi
    
    # 检查API密钥
    if [ -z "$AIDER_OPENAI_API_KEY" ] && [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
        print_warning "未检测到API密钥，请确保已设置相应的环境变量"
        print_info "可设置的环境变量："
        print_info "  - AIDER_OPENAI_API_KEY 或 OPENAI_API_KEY"
        print_info "  - ANTHROPIC_API_KEY"
        print_info "  - 或在.env文件中配置"
    fi
}

# 检查环境配置
check_environment() {
    print_info "检查环境配置..."
    
    echo "Python信息:"
    echo "  版本: $(python3 --version)"
    echo "  路径: $(which python3)"
    echo ""
    
    echo "环境变量:"
    echo "  AIDER_MODEL: ${AIDER_MODEL:-未设置}"
    echo "  AIDER_OPENAI_API_KEY: ${AIDER_OPENAI_API_KEY:+已设置}"
    echo "  AIDER_OPENAI_API_BASE: ${AIDER_OPENAI_API_BASE:-未设置}"
    echo "  OPENAI_API_KEY: ${OPENAI_API_KEY:+已设置}"
    echo "  ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:+已设置}"
    echo ""
    
    echo "aider源码路径: $AIDER_ROOT"
    echo "Python包安装路径: $(python3 -m site --user-site)"
    
    if check_dependencies; then
        print_success "所有依赖已安装"
    else
        print_warning "部分依赖缺失，请运行 '$(basename "$0") --setup' 安装"
    fi
}

# 运行aider
run_aider() {
    local args=("$@")
    
    print_info "启动aider..."
    print_info "工作目录: $(pwd)"
    
    # 切换到aider源码目录并运行
    cd "$AIDER_ROOT"
    
    # 运行aider
    exec python3 -m aider "${args[@]}"
}

# 完整设置
full_setup() {
    print_info "开始设置aider环境..."
    
    check_python
    check_pip
    install_dependencies
    setup_environment
    
    print_success "aider环境设置完成！"
    print_info "现在可以运行: $(basename "$0")"
}

# 检查安装权限
check_install_permission() {
    local target_dir="$1"
    if [ ! -w "$target_dir" ] && [ ! -w "$(dirname "$target_dir")" ]; then
        return 1
    fi
    return 0
}


# 安装脚本到用户路径
install_user() {
    local target_dir="$HOME/.local/bin"
    local target_file="$target_dir/blink-code"
    local script_path="$AIDER_ROOT/blink-code.sh"
    
    print_info "安装blink-code到用户路径..."
    
    # 创建用户bin目录（如果不存在）
    if [ ! -d "$target_dir" ]; then
        print_info "创建目录: $target_dir"
        mkdir -p "$target_dir" || {
            print_error "无法创建目录 $target_dir"
            exit 1
        }
    fi
    
    # 检查是否已存在
    if [ -e "$target_file" ]; then
        if [ -L "$target_file" ]; then
            print_warning "软链接已存在: $target_file"
            print_info "当前链接目标: $(readlink "$target_file")"
            print_info "删除现有链接..."
            rm -f "$target_file"
        else
            print_error "目标文件已存在且不是软链接: $target_file"
            exit 1
        fi
    fi
    
    # 创建软链接到目标位置
    print_info "创建软链接: $target_file -> $script_path"
    ln -s "$script_path" "$target_file" || {
        print_error "创建软链接失败"
        exit 1
    }
    
    print_success "已安装blink-code软链接到 $target_file"
    print_info "现在可以在任何地方运行: blink-code"
    
    # 检查PATH
    if [[ ":$PATH:" != *":$target_dir:"* ]]; then
        print_warning "$target_dir 不在PATH中"
        print_info "请将以下行添加到 ~/.bashrc 或 ~/.zshrc:"
        print_info "export PATH=\"\$HOME/.local/bin:\$PATH\""
        print_info "然后运行: source ~/.bashrc"
    fi
}

# 从用户路径卸载脚本
uninstall_user() {
    local target_dir="$HOME/.local/bin"
    local target_file="$target_dir/blink-code"
    
    print_info "从用户路径卸载blink-code..."
    
    if [ ! -f "$target_file" ]; then
        print_warning "未找到已安装的blink-code: $target_file"
        exit 0
    fi
    
    # 删除脚本文件
    print_info "删除 $target_file"
    rm -f "$target_file" || {
        print_error "删除脚本失败"
        exit 1
    }
    
    print_success "已从用户路径卸载blink-code"
}

# 创建软链接到系统路径
create_link() {
    local target_dir="/usr/local/bin"
    local target_file="$target_dir/blink-code"
    local script_path="$AIDER_ROOT/blink-code.sh"
    
    print_info "创建blink-code软链接到系统路径..."
    
    # 检查是否有sudo权限
    if ! check_install_permission "$target_dir"; then
        print_error "需要sudo权限创建软链接到 $target_dir"
        print_info "请运行: sudo $(basename "$0") --create-link"
        exit 1
    fi
    
    # 检查目标目录是否存在
    if [ ! -d "$target_dir" ]; then
        print_info "创建目录: $target_dir"
        mkdir -p "$target_dir" || {
            print_error "无法创建目录 $target_dir"
            exit 1
        }
    fi
    
    # 检查是否已存在
    if [ -e "$target_file" ]; then
        if [ -L "$target_file" ]; then
            print_warning "软链接已存在: $target_file"
            print_info "当前链接目标: $(readlink "$target_file")"
            print_info "删除现有链接..."
            rm -f "$target_file"
        else
            print_error "目标文件已存在且不是软链接: $target_file"
            exit 1
        fi
    fi
    
    # 创建软链接
    print_info "创建软链接: $target_file -> $script_path"
    ln -s "$script_path" "$target_file" || {
        print_error "创建软链接失败"
        exit 1
    }
    
    print_success "已创建blink-code软链接到 $target_file"
    print_info "现在可以在任何地方运行: blink-code"
    
    # 检查PATH
    if [[ ":$PATH:" != *":$target_dir:"* ]]; then
        print_warning "$target_dir 不在PATH中，请确保将其添加到PATH"
    fi
}

# 移除系统路径软链接
remove_link() {
    local target_dir="/usr/local/bin"
    local target_file="$target_dir/blink-code"
    
    print_info "移除blink-code软链接..."
    
    if [ ! -e "$target_file" ]; then
        print_warning "未找到软链接: $target_file"
        exit 0
    fi
    
    if [ ! -L "$target_file" ]; then
        print_error "$target_file 不是软链接，无法移除"
        exit 1
    fi
    
    # 检查是否有sudo权限
    if ! check_install_permission "$target_dir"; then
        print_error "需要sudo权限移除软链接 $target_file"
        print_info "请运行: sudo $(basename "$0") --remove-link"
        exit 1
    fi
    
    # 删除软链接
    print_info "删除软链接 $target_file"
    rm -f "$target_file" || {
        print_error "删除软链接失败"
        exit 1
    }
    
    print_success "已移除blink-code软链接"
}

# 主函数
main() {
    # 确保在正确的目录
    if [ ! -f "$AIDER_ROOT/aider/main.py" ]; then
        print_error "未找到aider源码，请确保脚本在aider项目根目录中"
        exit 1
    fi
    
    # 解析参数
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        --setup)
            full_setup
            exit 0
            ;;
        --check-env)
            setup_environment
            check_environment
            exit 0
            ;;
        --version)
            setup_environment
            cd "$AIDER_ROOT"
            python3 -c "from aider import __version__; print(__version__)" 2>/dev/null || echo "无法获取版本信息，请先运行 --setup"
            exit 0
            ;;
        --install)
            install_user
            exit 0
            ;;
        --uninstall)
            uninstall_user
            exit 0
            ;;
        --create-link)
            create_link
            exit 0
            ;;
        --remove-link)
            remove_link
            exit 0
            ;;
        *)
            # 检查是否首次运行
            if ! check_dependencies &>/dev/null; then
                print_warning "检测到首次运行或依赖缺失"
                print_info "正在自动安装依赖..."
                full_setup
                echo ""
            fi
            
            # 设置环境并运行aider
            setup_environment
            run_aider "$@"
            ;;
    esac
}

# 运行主函数
main "$@"
