# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 常用命令

除非特别说明，以下命令都从仓库根目录执行。

- `npx pnpm --filter @actalk/inkos-core build`
- `npx pnpm --filter @actalk/inkos-core test`
- `npx pnpm --filter @actalk/inkos-core typecheck`
- `npx pnpm --filter @actalk/inkos-core exec vitest run src/__tests__/models.test.ts`
- `npx pnpm --filter @actalk/inkos-core exec vitest run src/__tests__/models.test.ts -t "测试名"`

## 在 monorepo 中的职责

`packages/core` 是产品行为的唯一事实来源。`packages/cli` 和 `packages/studio` 都调用这个包，而不是各自重复实现领域逻辑。

这个包负责：
- 项目 / 书籍 / 章节模型
- 基于文件系统的状态持久化
- LLM provider 解析与有效配置合成
- 多 Agent 写作管线
- CLI / TUI / Studio 共享的自然语言交互运行时
- daemon 调度与自动化

## 关键子系统

### Pipeline 编排

`src/pipeline/runner.ts` 是排查端到端写作行为时最先该看的文件。它负责协调 planning、context compose、draft、audit、revise、导入导出和状态落盘。

如果某个用户可见的写作命令行为异常，最终通常都会追到 `PipelineRunner`。

### 文件系统状态

`src/state/manager.ts` 管理项目布局与持久化，负责：
- 读写 `inkos.json`
- 定位 `books/<bookId>/`
- 管理 runtime 产物与 truth files
- 写锁控制

这个应用是 filesystem-first，而不是 DB-first。新增持久化路径前，应先看这里是否已经覆盖同类职责。

### 配置解析

`src/utils/effective-llm-config.ts` 与 `src/utils/llm-env.ts` 定义了项目配置、env 文件、运行时环境变量和 CLI 覆盖参数如何合成。

重要点：Studio 和 CLI 的有效配置解析方式并不相同。

### 共享交互运行时

`inkos interact`、TUI 和 Studio 的自然语言交互都复用了 `src/interaction/*`。如果同一个问题同时出现在多个壳层，通常根因在这里，而不是某个壳层自己的 UI/命令代码。

## 测试关注点

Core 的测试覆盖面很广，且偏行为验证。排查问题时可以优先从这些入口切：
- `src/__tests__/pipeline-runner-memory-sync.test.ts` —— pipeline 与结构化状态交互
- `src/__tests__/config-loader.test.ts` —— 配置 / env 解析
- `src/__tests__/session-transcript*.test.ts` —— interaction transcript / session 行为
- `src/__tests__/verify-service.test.ts` —— provider 校验流程

涉及跨壳层行为的修改，优先先在这里验证，再去看 CLI 或 Studio 包装层。
