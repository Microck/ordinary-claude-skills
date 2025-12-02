---
name: software-crypto-web3
description: Production-grade blockchain and Web3 development with Solidity (Ethereum/EVM), Rust (Solana), CosmWasm (Cosmos), including smart contract architecture, security patterns, gas optimization, testing strategies, DeFi protocols, and deployment workflows.
---

# Blockchain & Web3 Development Skill — Quick Reference

This skill equips blockchain developers with execution-ready patterns for building secure, gas-optimized smart contracts and decentralized applications. Claude should apply these patterns when users ask for smart contract development, DeFi protocols, NFT implementations, security audits, or Web3 architecture.

**Modern Best Practices**: Security-first development, formal verification, comprehensive testing (unit, integration, fork, invariant), gas optimization, upgradeable contracts, multi-chain deployment, and battle-tested DeFi patterns.

---

## Quick Reference

| Task | Tool/Framework | Command | When to Use |
|------|----------------|---------|-------------|
| Solidity Development | Hardhat/Foundry | `npx hardhat init` or `forge init` | Ethereum/EVM smart contracts |
| Solana Programs | Anchor | `anchor init` | Solana blockchain development |
| Cosmos Contracts | CosmWasm | `cargo generate --git cosmwasm-template` | Cosmos ecosystem contracts |
| TON Contracts | Tact/FunC + Blueprint | `npm create ton@latest` | TON blockchain development |
| Testing (Solidity) | Foundry/Hardhat | `forge test` or `npx hardhat test` | Unit, fork, invariant tests |
| Security Audit | Slither/Mythril/Echidna | `slither .` | Static analysis, fuzzing |
| Gas Optimization | Foundry Gas Snapshots | `forge snapshot` | Benchmark and optimize gas |
| Deployment | Hardhat Deploy/Forge Script | `npx hardhat deploy` | Mainnet/testnet deployment |
| Verification | Etherscan API | `npx hardhat verify` | Source code verification |
| Upgradeable Contracts | OpenZeppelin Upgrades | `@openzeppelin/hardhat-upgrades` | Proxy-based upgrades |

# When to Use This Skill

Claude should invoke this skill when a user requests:

- Smart contract development (Solidity, Rust, CosmWasm)
- DeFi protocol implementation (AMM, lending, staking, yield farming)
- NFT and token standards (ERC20, ERC721, ERC1155, SPL tokens)
- DAO governance systems
- Cross-chain bridges and interoperability
- Gas optimization and storage patterns
- Smart contract security audits
- Testing strategies (Foundry, Hardhat, Anchor)
- Oracle integration (Chainlink, Pyth)
- Upgradeable contract patterns (proxies, diamonds)
- Web3 frontend integration (ethers.js, web3.js, @solana/web3.js)
- Blockchain indexing (The Graph, subgraphs)
- MEV protection and flashbots
- Layer 2 scaling solutions (Optimism, Arbitrum, zkSync)
- **Backend crypto integration** (.NET/C#, multi-provider architecture, CQRS)
- Webhook handling and signature validation (Fireblocks, custodial providers)
- Event-driven architecture with Kafka for crypto payments
- Transaction lifecycle management and monitoring
- Wallet management (custodial vs non-custodial)

## Decision Tree: Blockchain Platform Selection

```text
Project needs: [Use Case]
    ├─ EVM-compatible smart contracts?
    │   ├─ Complex testing needs → Foundry (Solidity tests, fuzzing, gas snapshots)
    │   ├─ TypeScript ecosystem → Hardhat (plugins, TypeScript, Ethers.js)
    │   └─ Enterprise features → NestJS + Hardhat
    │
    ├─ High throughput/low fees?
    │   ├─ Rust-based → Solana (Anchor framework, 50k+ TPS)
    │   ├─ EVM L2 → Arbitrum/Optimism (Ethereum security, lower gas)
    │   └─ Telegram integration → TON (Tact/FunC contracts)
    │
    ├─ Interoperability across chains?
    │   ├─ Cosmos ecosystem → CosmWasm (IBC protocol)
    │   ├─ Multi-chain DeFi → LayerZero or Wormhole
    │   └─ Bridge development → Custom bridge contracts
    │
    ├─ Token standard implementation?
    │   ├─ Fungible tokens → ERC20 (OpenZeppelin), SPL Token (Solana)
    │   ├─ NFTs → ERC721/ERC1155 (OpenZeppelin), Metaplex (Solana)
    │   └─ Semi-fungible → ERC1155 (gaming, fractionalized NFTs)
    │
    ├─ DeFi protocol development?
    │   ├─ AMM/DEX → Uniswap V3 fork or custom (x*y=k, concentrated liquidity)
    │   ├─ Lending → Compound/Aave fork (collateralized borrowing)
    │   └─ Staking/Yield → Custom reward distribution contracts
    │
    ├─ Upgradeable contracts required?
    │   ├─ Transparent Proxy → OpenZeppelin (admin/user separation)
    │   ├─ UUPS → Gas-efficient (upgrade logic in implementation)
    │   └─ Diamond Standard → Modular functionality (EIP-2535)
    │
    └─ Backend integration?
        ├─ .NET/C# → Multi-provider architecture (see Backend Integration Patterns)
        ├─ Node.js → Ethers.js/Web3.js + Prisma
        └─ Python → Web3.py + FastAPI
```

**Chain-Specific Considerations:**

- **Ethereum/EVM**: Security-first, higher gas costs, largest ecosystem
- **Solana**: Performance-first, Rust required, lower fees
- **Cosmos**: Interoperability-first, IBC native, growing ecosystem
- **TON**: Telegram-first, async contracts, unique architecture

See [resources/](resources/) for chain-specific best practices.

---

## Navigation

**Resources**

- [resources/blockchain-best-practices.md](resources/blockchain-best-practices.md) — Universal blockchain patterns and security
- [resources/backend-integration-best-practices.md](resources/backend-integration-best-practices.md) — .NET/C# crypto integration patterns (CQRS, Kafka, multi-provider)
- [resources/solidity-best-practices.md](resources/solidity-best-practices.md) — Solidity/EVM-specific guidance
- [resources/rust-solana-best-practices.md](resources/rust-solana-best-practices.md) — Solana + Anchor patterns
- [resources/cosmwasm-best-practices.md](resources/cosmwasm-best-practices.md) — Cosmos/CosmWasm guidance
- [resources/ton-best-practices.md](resources/ton-best-practices.md) — TON contracts (Tact/Fift/FunC) and deployment
- [../software-security-appsec/resources/smart-contract-security-auditing.md](../software-security-appsec/resources/smart-contract-security-auditing.md) — Smart contract audit workflows and tools (see software-security-appsec skill)
- [README.md](README.md) — Folder overview and usage notes
- [data/sources.json](data/sources.json) — Curated external references per chain

**Templates**
- Ethereum/EVM: [templates/ethereum/template-solidity-hardhat.md](templates/ethereum/template-solidity-hardhat.md), [templates/ethereum/template-solidity-foundry.md](templates/ethereum/template-solidity-foundry.md)
- Solana: [templates/solana/template-rust-anchor.md](templates/solana/template-rust-anchor.md)
- Cosmos: [templates/cosmos/template-cosmwasm.md](templates/cosmos/template-cosmwasm.md)
- TON: [templates/ton/template-tact-blueprint.md](templates/ton/template-tact-blueprint.md), [templates/ton/template-func-blueprint.md](templates/ton/template-func-blueprint.md)
- Bitcoin: [templates/bitcoin/template-bitcoin-core.md](templates/bitcoin/template-bitcoin-core.md)

**Related Skills**

- [../software-security-appsec/SKILL.md](../software-security-appsec/SKILL.md) — Security hardening, threat modeling, OWASP vulnerabilities
- [../software-architecture-design/SKILL.md](../software-architecture-design/SKILL.md) — System decomposition, modularity, dependency design
- [../ops-devops-platform/SKILL.md](../ops-devops-platform/SKILL.md) — Infrastructure, CI/CD, observability for blockchain nodes
- [../software-backend/SKILL.md](../software-backend/SKILL.md) — API integration with smart contracts, RPC nodes, indexers
- [../quality-resilience-patterns/SKILL.md](../quality-resilience-patterns/SKILL.md) — Resilience, circuit breakers, retry logic for chains
- [../software-code-review/SKILL.md](../software-code-review/SKILL.md) — Code review patterns and quality gates
- [../foundation-api-design/SKILL.md](../foundation-api-design/SKILL.md) — RESTful design for Web3 APIs and dApp backends

---

## Operational Playbooks
- [resources/operational-playbook.md](resources/operational-playbook.md) — Smart contract architecture, security-first workflows, and platform-specific patterns
