# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 常用命令

除非特别说明，以下命令都从仓库根目录执行。

- `npx pnpm --filter @actalk/inkos-studio build`
- `npx pnpm --filter @actalk/inkos-studio test`
- `npx pnpm --filter @actalk/inkos-studio typecheck`
- `npx pnpm --filter @actalk/inkos-studio exec vitest run src/api/server.test.ts`
- `npx pnpm --filter @actalk/inkos-studio exec vitest run src/App.test.tsx`

本地 Windows 启动优先使用仓库根目录脚本：
- `start-studio-windows.cmd` —— build + run
- `run-studio-windows.cmd` —— 只运行

包内的 `dev` 脚本使用了 Unix 风格环境变量赋值和后台执行写法，适合类 Unix shell，不适合直接在原生 Windows `cmd.exe` 里跑。

## 在 monorepo 中的职责

`packages/studio` 是 `@actalk/inkos-core` 的 Web 工作台外壳。

它由两部分组成：
- React/Vite 客户端
- 调用 `core` 的 Hono API 服务端

Studio 没有独立的后端领域模型。服务端会实例化 `StateManager` 和 `PipelineRunner`，直接操作与 CLI、daemon 相同的项目文件。

## 重要入口文件

- `src/main.tsx` / `src/App.tsx` —— 客户端入口
- `src/api/index.ts` —— 服务端启动入口
- `src/api/server.ts` —— Hono 路由、编排逻辑、SSE 广播
- `src/hooks/use-api.ts` —— 客户端 API 封装
- `src/hooks/use-sse.ts` —— 实时事件流消费

## 需要记住的数据流

一个典型的 Studio 功能通常会跨越前后端两侧：
1. React UI 调用 `/api/v1/...`
2. Hono 路由读取项目状态并调用 `core`
3. 服务端可能通过 SSE 推送进度 / 日志
4. 客户端 hook/store 更新 UI

调试 Studio 行为时，要同时沿着路由处理逻辑和客户端 hook/store 的消费路径往下看。

## 配置细节

Studio 在运行时会优先使用项目内的 service 配置和 `.inkos/secrets.json`。不要假设 `INKOS_LLM_*` 环境变量在这里会和 CLI 模式下表现一致。
