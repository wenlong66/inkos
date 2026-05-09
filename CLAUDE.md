# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 常用命令

这个仓库统一使用 `npx pnpm ...`。当前环境里 `pnpm` 不一定全局可用，但 `npx pnpm` 可正常工作。

### 工作区级命令
- `npx pnpm install`
- `npx pnpm build` —— 构建所有 workspace 包
- `npx pnpm test` —— 运行所有包的测试
- `npx pnpm typecheck` —— 运行所有包的类型检查
- `npx pnpm --filter @actalk/inkos-core test`
- `npx pnpm --filter @actalk/inkos test`
- `npx pnpm --filter @actalk/inkos-studio test`

### 运行单个测试
- `npx pnpm --filter @actalk/inkos-core exec vitest run src/__tests__/models.test.ts`
- `npx pnpm --filter @actalk/inkos-core exec vitest run src/__tests__/models.test.ts -t "测试名"`
- `npx pnpm --filter @actalk/inkos-studio exec vitest run src/api/server.test.ts`
- `npx pnpm --filter @actalk/inkos exec vitest run src/__tests__/cli-integration.test.ts`

### Studio / 本地启动
- `npx pnpm run start:studio` —— 通过 CLI 入口启动已构建的 Studio
- `start-studio-windows.cmd` —— Windows 下先 build 再启动
- `run-studio-windows.cmd` —— Windows 下直接启动，不重新构建

## Monorepo 架构

这是一个 PNPM workspace，核心包都在 `packages/*` 下：

- `packages/core` —— 应用运行时与领域逻辑的唯一事实来源
- `packages/cli` —— 基于 Commander 的 CLI，以及基于 Ink 的 TUI 外壳
- `packages/studio` —— React/Vite 前端 + Hono API 的 Web 外壳

理解这个仓库时，应默认 `packages/core` 才是真正的产品逻辑；`cli` 和 `studio` 主要是对 `core` 的适配层。

### Core 运行时模型

核心编排类是 `PipelineRunner`。CLI 和 Studio 的高层写作流程最终都会落到这里，包含：

- 章节 planning / compose 输入治理
- 草稿生成、审计、修订
- 导入 / 导出流程
- 运行时状态同步

核心持久化层是 `StateManager`。它负责整个项目的文件系统布局，包括：

- `inkos.json` 作为项目主配置
- `.inkos/secrets.json` 保存 Studio 管理的 API Key
- `books/<bookId>/...` 保存书籍、章节、runtime 产物与 truth files
- `.write.lock` 写锁

跨文件追踪问题时，优先从 `PipelineRunner` 和 `StateManager` 开始，而不是先看 CLI 或前端表现层。

### CLI / TUI 层

`packages/cli` 是对 `core` 的薄封装：

- `src/index.ts` 是可执行入口
- `src/program.ts` 负责注册顶层命令
- 各命令模块通常会加载配置、构造 `PipelineRunner`，再调用 `@actalk/inkos-core`
- TUI 与自然语言交互也复用 `core` 中的共享 interaction runtime

如果某个 CLI 命令行为不对，先判断问题是在命令包装层，还是在它调用的 `core` 方法里。

### Studio 层

`packages/studio` 也是 `core` 的一层外壳，而不是独立的后端领域模型：

- React/Vite 客户端负责工作台 UI
- Hono 服务端暴露 `/api/v1/...` 路由
- SSE 用于日志和实时进度推送
- 服务端 handler 会实例化 `StateManager` / `PipelineRunner`，直接复用与 CLI 相同的项目状态

调试 Studio 问题时，要同时看两端：Hono 路由处理逻辑，以及 React hook/store 的消费路径。

## 配置模型

这个仓库的配置是分层的，而且 CLI 与 Studio 的行为并不完全相同。

CLI 可以叠加：
- 项目级 `inkos.json`
- 全局 `~/.inkos/.env`
- 项目级 `.env`
- 当前进程环境变量
- CLI 命令行参数

Studio 则更偏向项目内的 service 配置和 `.inkos/secrets.json`。不要假设 `INKOS_LLM_*` 环境变量会像 CLI 一样直接影响 Studio 运行时。

## 项目边界与运行数据

当前工作目录会被视为项目根目录；很多命令默认以 `process.cwd()` 作为当前 InkOS 项目。

当这个仓库本身被当作项目运行时，根目录里的重要运行数据包括：
- `inkos.json`
- `.inkos/secrets.json`
- `books/`
- `radar/`
- `inkos.log` 以及 daemon 相关产物

## 包级 CLAUDE 文件

继续工作前，也要顺手查看：
- `packages/core/CLAUDE.md`
- `packages/cli/CLAUDE.md`
- `packages/studio/CLAUDE.md`
