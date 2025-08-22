#!/bin/bash
set -e

# aider 启动脚本 (简化版)
# 专注于运行aider和参数转发，基本环境检查
# 此脚本会将所有传入参数原样转发给aider
# 如果需要传递与脚本自身参数冲突的参数给aider，可以使用 -- 分隔，例如: ai-coder.sh -- --help

# 获取脚本路径，支持软链接解析
SCRIPT_PATH="${BASH_SOURCE[0]}"

# 如果是软链接，解析真实路径
if [ -L "$SCRIPT_PATH" ]; then
    REAL_SCRIPT_PATH="$(readlink -f "$SCRIPT_PATH")"
    SCRIPT_DIR="$(cd "$(dirname "$REAL_SCRIPT_PATH")" && pwd)"
else
    SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
fi

# 设置AIDER_ROOT为项目根目录（脚本目录的上一级）
AIDER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
echo "AIDER_ROOT: $AIDER_ROOT"

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

# 检查Python环境
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "未找到python3命令"
        exit 1
    fi
    
    if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
        return 0
    else
        PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
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
}

# 安装依赖
install_dependencies() {
    print_info "安装aider依赖..."
    
    # 检查requirements.txt是否存在
    if [ ! -f "$AIDER_ROOT/requirements.txt" ]; then
        print_error "未找到requirements.txt文件"
        exit 1
    fi
    
    check_pip
    
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
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        return 1
    fi
    
    return 0
}

# 设置环境变量
setup_environment() {
    # 设置默认环境变量（如果未设置）
    export PYTHONPATH="$AIDER_ROOT:${PYTHONPATH:-}"
    
    # 如果没有设置模型，使用默认值
    if [ -z "$AIDER_MODEL" ]; then
        export AIDER_MODEL="gpt-3.5-turbo"
    fi
    
    # 检查API密钥（静默检查，仅在需要时提示）
    if [ -z "$AIDER_OPENAI_API_KEY" ] && [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
        # 不在这里输出警告，让aider自己处理
        return 0
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
    echo ""
    
    if check_dependencies; then
        print_success "所有依赖已安装"
    else
        print_warning "部分依赖缺失，请运行 '$(basename "$0") --setup' 安装"
        return 1
    fi
    
    return 0
}

# 运行aider (转发所有参数)
run_aider() {
    local args=("$@")
    
    print_info "启动aider..."
    print_info "工作目录: $(pwd)"
    print_info "传递参数: ${args[*]}"
    
    # 切换到aider源码目录并运行
    cd "$AIDER_ROOT"
    
    # 运行aider并转发所有参数
    exec python3 -m aider "${args[@]}"
}

# 完整设置
full_setup() {
    print_info "开始设置aider环境..."
    
    check_python
    install_dependencies
    setup_environment
    
    print_success "aider环境设置完成！"
    print_info "现在可以运行: $(basename "$0")"
}

# 快速依赖检查和自动安装
quick_dependency_check() {
    if ! check_dependencies &>/dev/null; then
        print_warning "检测到首次运行或依赖缺失，正在自动安装依赖..."
        full_setup
        echo ""
        return 0
    fi
    return 0
}

# 主函数
main() {
    # 添加调试信息
    print_info "当前SCRIPT_DIR: $SCRIPT_DIR"
    print_info "当前AIDER_ROOT: $AIDER_ROOT"
    print_info "检查文件: $AIDER_ROOT/aider/main.py"
    
    # 确保在正确的目录
    if [ ! -f "$AIDER_ROOT/aider/main.py" ]; then
        print_error "未找到aider源码，请确保脚本在aider项目根目录中"
        ls -la "$AIDER_ROOT" 2>/dev/null || echo "无法列出 $AIDER_ROOT 目录内容"
        ls -la "$AIDER_ROOT/aider" 2>/dev/null || echo "无法列出 $AIDER_ROOT/aider 目录内容"
        exit 1
    fi
    
    # 解析参数
    # 特殊处理：如果第一个参数是 "--"，则后面的所有参数都直接传给aider
    # 这允许用户绕过脚本自身的参数处理，将所有参数原样传递给aider
    # 例如：ai-coder.sh -- --help 会将 --help 传递给aider而不是显示脚本自身的帮助
    if [ "${1:-}" = "--" ]; then
        shift  # 移除 "--" 参数
        setup_environment
        print_info "使用 -- 模式，直接转发所有参数给aider..."
        run_aider "$@"
        exit 0
    fi
    
    # 快速检查依赖，如果缺失则自动安装
    quick_dependency_check
    
    # 设置环境并运行aider (转发所有传入参数)
    setup_environment
    print_info "转发所有参数给aider..."
    run_aider "$@"  # 转发所有参数给aider
}

# 运行主函数
main "$@"
