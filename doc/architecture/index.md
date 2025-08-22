# Aider 架构文档索引

## 文档概述

本目录包含了Aider项目的架构文档，目的是帮助开发者、贡献者和用户理解Aider的内部工作机制、设计决策和扩展方式。

## 可用文档

| 文档 | 描述 |
|------|------|
| [README.md](README.md) | 主要架构文档，包含架构概述、核心组件、数据流、技术决策等详细内容 |
| [components.md](components.md) | 组件图和数据流图，使用Mermaid图表可视化Aider的架构 |

## 主要内容导航

### 架构概述
- [架构概述](README.md#1-架构概述)
- [系统上下文图](README.md#11-系统上下文图)
- [架构原则](README.md#12-架构原则)

### 核心组件
- [入口点 (main.py)](README.md#21-入口点-mainpy)
- [模型管理 (models.py)](README.md#22-模型管理-modelspy)
- [代码生成器 (coders/)](README.md#23-代码生成器-coders)
- [Git集成 (repo.py)](README.md#24-git集成-repopy)
- [输入/输出处理 (io.py)](README.md#25-输入输出处理-iopy)
- [命令系统 (commands.py)](README.md#26-命令系统-commandspy)
- [代码库映射 (repomap.py)](README.md#27-代码库映射-repomappy)

### 数据流与工作流程
- [启动流程](README.md#31-启动流程)
- [消息处理流程](README.md#32-消息处理流程)
- [编辑应用流程](README.md#33-编辑应用流程)

### 技术决策
- [编辑格式选择](README.md#41-编辑格式选择)
- [模型选择](README.md#42-模型选择)
- [Git集成设计](README.md#43-git集成设计)
- [上下文管理策略](README.md#44-上下文管理策略)

### 扩展点
- [添加新模型](README.md#51-添加新模型)
- [创建新的编辑格式](README.md#52-创建新的编辑格式)
- [添加新命令](README.md#53-添加新命令)

### 其他主题
- [性能考虑](README.md#6-性能考虑)
- [安全和隐私](README.md#7-安全和隐私)
- [未来发展方向](README.md#8-未来发展方向)

## 可视化组件

### 组件关系图
- [核心组件关系图](components.md#核心组件关系图)
- [数据流向图](components.md#数据流向图)
- [模块依赖图](components.md#模块依赖图)

## 如何贡献

如果您发现文档中的错误或有改进建议，请通过以下方式贡献：

1. 提交Issue描述问题或建议
2. 提交Pull Request修复或改进文档
3. 联系Aider维护团队讨论更大的文档变更

---

*本索引由Aider团队维护。最后更新: 2025/8/22*
