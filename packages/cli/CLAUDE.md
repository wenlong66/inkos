# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 常用命令

除非特别说明，以下命令都从仓库根目录执行。

- `npx pnpm --filter @actalk/inkos build`
- `npx pnpm --filter @actalk/inkos test`
- `npx pnpm --filter @actalk/inkos typecheck`
- `npx pnpm --filter @actalk/inkos exec vitest run src/__tests__/cli-integration.test.ts`
- `npx pnpm --filter @actalk/inkos exec vitest run src/__tests__/tui-command.test.ts`

`packages/cli` 带有 `prebuild` 和 `pretypecheck` 钩子，会先构建 `@actalk/inkos-core`，所以即使你只在跑 CLI 命令，`core` 的改动也可能直接影响结果。

## 在 monorepo 中的职责

`packages/cli` 是 `@actalk/inkos-core` 的用户入口层。它本身不拥有写作管线逻辑；它的职责是解析用户输入、加载项目配置、创建 `PipelineRunner`，然后把执行交给 `core`。

这个包主要包含三类入口：
- 传统 Commander 子命令
- 基于 Ink 的 TUI
- 自然语言 interaction / agent 入口

## 重要入口文件

- `src/index.ts` —— 可执行入口
- `src/program.ts` —— 顶层命令注册
- `src/commands/*` —— 各命令处理器
- `src/utils.ts` —— 通用配置加载与 runner bootstrap
- `src/tui/*` —— Ink UI 与 session 管理
- `src/interaction/*` —— CLI 侧的共享交互工具装配

## 命令通常如何流转

大多数命令处理器都会走类似路径：
1. 确定当前项目根目录
2. 加载有效配置
3. 创建 `PipelineRunner`
4. 调用 `core` 中的 planning、writing、auditing、revising、export 等方法

如果行为异常，先确认问题是在这个包里的命令包装层，还是在底层 `core` 调用链。

## TUI / interaction 说明

TUI 不是另一套独立的写作实现。它和其他壳层共享同一套 interaction runtime 与 pipeline 行为。

如果某个问题同时能在 `inkos interact` 和 TUI 中复现，应优先去看 `packages/core` 里的共享 interaction runtime，而不是先改 TUI 组件。
