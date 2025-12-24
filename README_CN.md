# OkxDexSwift

A Swift library for interacting with OKX DEX aggregator, supporting multi-chain decentralized exchange functionalities.

## 概述

OkxDexSwift 是一个基于 Swift 语言开发的 OKX DEX 聚合器客户端库，支持多区块链网络的去中心化交易所（DEX）功能集成。该库提供了便捷的 API 接口，用于与 OKX DEX 服务进行交互，实现代币兑换、流动性查询、报价获取等核心功能，适用于 iOS 和 macOS 平台。

## 核心功能

### 多链支持
- **EVM 兼容链**：以太坊、币安智能链（BSC）、Polygon、Arbitrum、Optimism 等
- **Solana**：完整支持 Solana DEX 操作，包含地址查找表（Address Lookup Table）优化
- **Sui**：集成 Sui 区块链的去中心化交易功能
- 预配置 20+ 区块链网络的参数设置（详见 `Resources/network-configs.json`）

### DEX 核心功能
- 获取实时代币兑换报价（支持自定义滑点）
- 执行跨链代币兑换交易
- EVM 链的代币授权管理
- 查询支持的代币、链和流动性池信息

### 技术亮点
- 采用 Swift 的 `async/await` 实现异步操作，支持现代并发模型
- 类型安全的 API 交互，配合完善的错误处理机制
- 使用私钥钱包进行安全的交易签名
- 可配置的 Gas 设置和交易参数
- 支持 EVM 链的 EIP-1559 和 Legacy 交易类型

## 安装

### Swift Package Manager

在 `Package.swift` 的依赖中添加：

```swift
.package(url: "https://github.com/lishuailibertine/OkxDexSwift.git", from: "1.0.0")
```

然后将 "OkxDexSwift" 添加到目标的依赖项中。

## 依赖项

- [swift-collections](https://github.com/apple/swift-collections) - 提供有序集合支持
- [web3swift](https://github.com/mathwallet/web3swift) - EVM 链交互支持
- [SolanaSwift](https://github.com/mathwallet/SolanaSwift) - Solana 链交互支持
- [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) - 加密算法支持
- [SuiSwift](https://github.com/lishuailibertine/SuiSwift) - Sui 链交互支持

## 使用示例

### 初始化客户端

```swift
import OkxDexSwift

let config = OKXConfig(
    apiKey: "你的API密钥", 
    secretKey: "你的密钥",
    apiPassphrase: "你的API密码",
    projectId: "你的项目ID"
)
let client = OKXDexClient(config: config)
```

### 获取兑换报价

```swift
let params = QuoteParams(
    chainIndex: "56", // BSC 链索引
    fromTokenAddress: "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c", // BNB 地址
    toTokenAddress: "0xe9e7cea3dedca5984780bafc599bd69add087d56", // BUSD 地址
    amount: "1000000000000000000", // 1 BNB（以 wei 为单位）
    slippagePercent: "0.5" // 0.5% 滑点
)

do {
    let quote = try await client.dex.getQuote(params: params)
    print("预估输出: \(quote.data.first?.routerResult?.toTokenAmount ?? "0")")
} catch {
    print("获取报价失败: \(error.localizedDescription)")
}
```

### 执行兑换（EVM 链）

```swift
// 配置 EVM 链钱包
var clientConfig = client.config
clientConfig.evm = try EVMConfig(
    wallet: PrivateKeyWallet(
        privateKey: Data(hex: "你的私钥"),
        providerUrl: "https://bsc-dataseed.binance.org"
    )
)
client.updateConfig(clientConfig)

// 准备兑换参数
let swapParams = SwapParams(
    chainIndex: "56",
    fromTokenAddress: "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c",
    toTokenAddress: "0xe9e7cea3dedca5984780bafc599bd69add087d56",
    amount: "1000000000000000000",
    userWalletAddress: client.config.evm?.wallet.address ?? "",
    slippagePercent: "0.5",
    type: .EIP1559
)

do {
    let result = try await client.dex.executeSwap(params: swapParams)
    print("兑换成功！交易哈希: \(result.transactionId)")
    print("浏览器地址: \(result.explorerUrl)")
} catch {
    print("兑换失败: \(error.localizedDescription)")
}
```

### 执行兑换（Solana）

```swift
// 配置 Solana 钱包
var clientConfig = client.config
clientConfig.solana = try SolanaConfig(
    wallet: SolanaPrivateKeyWallet(
        privateKey: "你的私钥",
        endpoint: "https://solana-rpc.publicnode.com"
    )
)
client.updateConfig(clientConfig)

// 准备兑换参数
let swapParams = SwapParams(
    chainIndex: "501", // Solana 链索引
    fromTokenAddress: "源代币 mint 地址",
    toTokenAddress: "目标代币 mint 地址",
    amount: "1000000", // 代币数量（最小单位）
    userWalletAddress: "你的 Solana 钱包地址",
    slippagePercent: "0.5"
)

do {
    let result = try await client.dex.executeSwap(params: swapParams)
    print("Solana 兑换成功！交易哈希: \(result.transactionId)")
} catch {
    print("Solana 兑换失败: \(error.localizedDescription)")
}
```

## 错误处理

库中定义了特定的错误类型用于不同操作：

- `DexAPIError`：与 API 交互相关的错误（无效参数、数据缺失等）
- `EVMSwapError`：EVM 链兑换特定错误
- `SolanaSwapError`：Solana 兑换特定错误
- `ConversionError`：数据转换过程中的错误（无效公钥等）

所有错误均遵循 `LocalizedError` 协议，提供用户友好的错误信息。

## 支持的网络

OkxDexSwift 包含预配置的网络支持（链索引）：

- Solana (501)
- Sui (784)
- 以太坊 (1)
- BSC (56)
- Polygon (137)
- Arbitrum (42161)
- Optimism (10)
- Avalanche (43114)
- 更多网络（完整列表见 `Resources/network-configs.json`）

每个网络配置包含浏览器 URL、默认滑点设置和交易参数。

## 许可证

OkxDexSwift 基于 MIT 许可证开源。详见 [LICENSE](LICENSE) 文件。

## 免责声明

本库按"原样"提供，不提供任何担保。在生产环境中使用本库之前，请务必了解区块链交易涉及的风险。区块链上的交易是不可逆的。
