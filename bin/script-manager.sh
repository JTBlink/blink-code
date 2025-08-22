#!/bin/bash
set -e

# aider 脚本管理器 - 精简版
# 负责环境配置、依赖安装和脚本安装管理

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AIDER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
AI_CODER_SCRIPT="$SCRIPT_DIR/ai-coder.sh"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 显示帮助信息
show_help() {
    echo "script-manager - aider 脚本管理器"
    echo ""
    echo "用法: $(basename "$0") [命令] [选项]"
    echo ""
    echo "命令:"
    echo "  check-env            检查环境配置"
    echo "  install              安装ai-coder脚本到用户路径"
    echo "  uninstall            从用户路径卸载ai-coder脚本"
    echo "  create-link          创建ai-coder软链接到系统路径"
    echo "  remove-link          移除系统路径的ai-coder软链接"
    echo "  status               显示当前安装状态"
    echo "  help                 显示此帮助信息"
    echo ""
    echo "选项:"
    echo "  -h, --help           显示此帮助信息"
    echo "  --force              强制执行操作（覆盖现有文件）"
}

# 检查Python环境
check_python() {
    if ! command -v python3 &> /dev/null; then
        print_error "未找到python3命令"; exit 1
    fi
    
    if ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
        print_error "需要Python 3.8或更高版本"; exit 1
    fi
}

# 安装依赖
install_dependencies() {
    check_python
    print_info "安装aider依赖..."
    
    if [ ! -f "$AIDER_ROOT/requirements.txt" ]; then
        print_error "未找到requirements.txt文件"; exit 1
    fi
    
    pip_cmd="pip3"
    if ! command -v pip3 &> /dev/null; then pip_cmd="pip"; fi
    
    print_info "使用requirements.txt安装所有依赖..."
    $pip_cmd install --user -r "$AIDER_ROOT/requirements.txt"
    print_success "依赖安装完成"
}

# 设置环境变量
setup_environment() {
    export PYTHONPATH="$AIDER_ROOT:${PYTHONPATH:-}"
    if [ -z "$AIDER_MODEL" ]; then export AIDER_MODEL="gpt-3.5-turbo"; fi
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
    echo "  OPENAI_API_KEY: ${OPENAI_API_KEY:+已设置}"
    echo "  ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:+已设置}"
    echo ""
    
    echo "aider源码路径: $AIDER_ROOT"
}

# 显示aider版本
show_version() {
    setup_environment
    check_python
    
    print_info "获取aider版本信息..."
    cd "$AIDER_ROOT"
    python3 -c "from aider import __version__; print(f'aider 版本: {__version__}')" 2>/dev/null || {
        print_error "无法获取版本信息，依赖可能未安装"; 
        print_info "请先运行 ai-coder.sh 让其自动安装依赖"; exit 1
    }
}

# 完整设置
full_setup() {
    check_python
    install_dependencies
    setup_environment
    print_success "aider环境设置完成！"
}

# 显示安装状态
show_status() {
    local user_link="$HOME/.local/bin/ai-coder"
    local system_link="/usr/local/bin/ai-coder"
    
    print_info "aider脚本安装状态："
    echo ""
    
    echo "源脚本: $AI_CODER_SCRIPT ($([ -f "$AI_CODER_SCRIPT" ] && echo "✓ 存在" || echo "✗ 不存在"))"
    
    echo "用户安装: $user_link"
    if [ -L "$user_link" ]; then
        echo "  状态: ✓ 已安装（软链接）"
        echo "  目标: $(readlink "$user_link")"
    elif [ -f "$user_link" ]; then
        echo "  状态: ⚠ 存在文件（非软链接）"
    else
        echo "  状态: ✗ 未安装"
    fi
    
    echo "系统安装: $system_link"
    if [ -L "$system_link" ]; then
        echo "  状态: ✓ 已安装（软链接）"
        echo "  目标: $(readlink "$system_link")"
    elif [ -f "$system_link" ]; then
        echo "  状态: ⚠ 存在文件（非软链接）"
    else
        echo "  状态: ✗ 未安装"
    fi
    
    echo "PATH检查:"
    echo "  ~/.local/bin: $([ ":$PATH:" == *":$HOME/.local/bin:"* ] && echo "✓ 在PATH中" || echo "✗ 不在PATH中")"
    echo "  /usr/local/bin: $([ ":$PATH:" == *":/usr/local/bin:"* ] && echo "✓ 在PATH中" || echo "✗ 不在PATH中")"
}

# 安装脚本到用户路径
install_user() {
    local force_install="$1"
    local target_dir="$HOME/.local/bin"
    local target_file="$target_dir/ai-coder"
    
    print_info "安装ai-coder到用户路径..."
    
    if [ ! -f "$AI_CODER_SCRIPT" ]; then
        print_error "未找到ai-coder.sh脚本"; exit 1
    fi
    
    # 创建用户bin目录（如果不存在）
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir" || { print_error "无法创建目录 $target_dir"; exit 1; }
    fi
    
    # 检查是否已存在
    if [ -e "$target_file" ]; then
        if [ "$force_install" = "true" ]; then
            rm -f "$target_file"
        elif [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$AI_CODER_SCRIPT" ]; then
            print_success "ai-coder已正确安装到用户路径"; return 0
        else
            print_error "目标文件已存在: $target_file"; exit 1
        fi
    fi
    
    # 创建软链接
    ln -s "$AI_CODER_SCRIPT" "$target_file" || { print_error "创建软链接失败"; exit 1; }
    print_success "已安装ai-coder软链接到 $target_file"
    
    # 检查PATH
    if [[ ":$PATH:" != *":$target_dir:"* ]]; then
        print_warning "$target_dir 不在PATH中"
        print_info "请将以下行添加到 ~/.bashrc 或 ~/.zshrc:"
        print_info "export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# 从用户路径卸载脚本
uninstall_user() {
    local target_file="$HOME/.local/bin/ai-coder"
    
    print_info "从用户路径卸载ai-coder..."
    
    if [ ! -e "$target_file" ]; then
        print_warning "未找到已安装的ai-coder: $target_file"; return 0
    fi
    
    rm -f "$target_file" || { print_error "删除脚本失败"; exit 1; }
    print_success "已从用户路径卸载ai-coder"
}

# 创建软链接到系统路径
create_link() {
    local force_install="$1"
    local target_dir="/usr/local/bin"
    local target_file="$target_dir/ai-coder"
    
    print_info "创建ai-coder软链接到系统路径..."
    
    if [ ! -f "$AI_CODER_SCRIPT" ]; then
        print_error "未找到ai-coder.sh脚本"; exit 1
    fi
    
    # 检查是否有sudo权限
    if [ ! -w "$target_dir" ]; then
        print_error "需要sudo权限创建软链接到 $target_dir"
        print_info "请运行: sudo $(basename "$0") create-link"
        exit 1
    fi
    
    # 检查是否已存在
    if [ -e "$target_file" ]; then
        if [ "$force_install" = "true" ]; then
            rm -f "$target_file"
        elif [ -L "$target_file" ] && [ "$(readlink "$target_file")" = "$AI_CODER_SCRIPT" ]; then
            print_success "ai-coder软链接已正确创建到系统路径"; return 0
        else
            print_error "目标文件已存在: $target_file"; exit 1
        fi
    fi
    
    # 创建软链接
    ln -s "$AI_CODER_SCRIPT" "$target_file" || { print_error "创建软链接失败"; exit 1; }
    print_success "已创建ai-coder软链接到 $target_file"
}

# 移除系统路径软链接
remove_link() {
    local target_file="/usr/local/bin/ai-coder"
    
    print_info "移除ai-coder软链接..."
    
    if [ ! -e "$target_file" ]; then
        print_warning "未找到软链接: $target_file"; return 0
    fi
    
    if [ ! -L "$target_file" ]; then
        print_error "$target_file 不是软链接，无法移除"; exit 1
    fi
    
    # 检查是否有sudo权限
    if [ ! -w "$target_file" ]; then
        print_error "需要sudo权限移除软链接 $target_file"
        print_info "请运行: sudo $(basename "$0") remove-link"
        exit 1
    fi
    
    rm -f "$target_file" || { print_error "删除软链接失败"; exit 1; }
    print_success "已移除ai-coder软链接"
}

# 主函数
main() {
    local command=""
    local force_install="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help; exit 0 ;;
            --force)
                force_install="true"; shift ;;
            check-env|install|uninstall|create-link|remove-link|status|help)
                command="$1"; shift ;;
            *)
                print_error "未知参数: $1"; exit 1 ;;
        esac
    done
    
    # 如果没有指定命令，显示帮助
    if [ -z "$command" ]; then
        show_help; exit 0
    fi
    
    # 执行相应命令
    case "$command" in
        check-env)
            setup_environment
            check_environment ;;
        install)
            install_user "$force_install" ;;
        uninstall)
            uninstall_user ;;
        create-link)
            create_link "$force_install" ;;
        remove-link)
            remove_link ;;
        status)
            show_status ;;
        help)
            show_help ;;
        *)
            print_error "未知命令: $command"; exit 1 ;;
    esac
}

# 运行主函数
main "$@"
