# XBID Contracts Release Pipeline

> 状态：`ACTIVE BASELINE`  
> 日期：2026-09-01

合约 CI 的可执行 Workflow 保存在 `xbid-contracts/.github/workflows/contracts.yml`，因为 GitHub Actions 只应验证触发该 commit 的同一仓库源码。本文件定义跨仓库的基础设施与权限边界，不复制合约脚本。

## Pull Request / Main Gate

- Git submodule 递归拉取，确保 OpenZeppelin、OpenZeppelin Upgradeable、Solady 与 PRBMath 使用仓库锁定 commit；
- Foundry `v1.8.1`；
- `forge fmt --check`；
- `forge build --sizes`；
- `XBIDFactory.v1` ERC-7201 Storage Layout Snapshot + raw-slot + namespace collision gate；
- 全量 Unit、Integration、Fuzz 与 Stateful Invariant。

该 Job 不接收 RPC、Deployer Key、Safe 或 Treasury Secret，Fork 与 Testnet 部署不能混入普通 PR CI。

## Scheduled Security Gate

每日运行 `profile.ci`：Fuzz 每项 10,000 runs；Stateful Invariant 每组 1,000 runs × 100 depth。失败时阻断候选发布，并保留 seed、commit 和完整日志用于复现。

## Testnet Release Boundary

真实 Robinhood Testnet 部署保持人工批准，不由普通 push 自动触发：

1. 代码与所有 Gate 通过并固定 source commit；
2. 两人复核 Safe、48 小时 Timelock、Emergency 与 Treasury 地址；
3. 使用 `xbid-contracts/scripts/deploy-robinhood-testnet.sh` 完成默认未激活部署；
4. 提交生成的 manifest、交易哈希、部署区块与 Blockscout Verification；
5. 链上 Validator 通过后，由 Safe 提交 Timelock Batch；
6. 等待至少 48 小时，再由独立执行人激活并完成验收。

部署密钥只允许存在于隔离的 Testnet Secret Store。不得保存到此仓库、Workflow YAML、Artifact、日志、Docker Layer 或 Terraform State。

在真实角色与审批人未登记前，不创建自动部署 Job。未来若引入 OIDC/KMS Signer，仍必须保留 Environment Approval、Chain ID/Code Hash 前置校验、未激活部署、Timelock 等待期和独立链上复核。
