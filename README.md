# OkxDexSwift [中文](./README_CN.md)

A Swift library for interacting with OKX DEX aggregator, supporting multi-chain decentralized exchange functionalities.

## Overview

OkxDexSwift is a Swift framework that enables seamless integration with OKX DEX services, providing developers with a unified interface to interact with decentralized exchanges across multiple blockchain networks. The library abstracts the complexities of different blockchain protocols, allowing for easy implementation of token swaps, liquidity queries, and cross-chain operations.

## Key Features

### Multi-Chain Support
- **EVM-compatible blockchains**: Ethereum, BSC, Polygon, Arbitrum, Optimism, etc.
- **Solana**: Full support for Solana DEX operations with Address Lookup Table optimization.
- **Sui**: Integration with Sui blockchain for decentralized exchange functionalities.
- Pre-configured network settings for 20+ blockchains (see `Resources/network-configs.json`).

### Core DEX Functionality
- Get real-time token swap quotes with configurable slippage.
- Execute token swaps across supported blockchains.
- Token approval management for EVM-based chains.
- Query supported tokens, chains, and liquidity pools.

### Technical Highlights
- Asynchronous operations using Swift's `async/await` for modern concurrency.
- Type-safe API interactions with comprehensive error handling.
- Secure transaction signing using private key wallets.
- Configurable gas settings and transaction parameters.
- Support for both EIP-1559 and Legacy transactions on EVM chains.

## Installation

### Swift Package Manager

Add the following to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/lishuailibertine/OkxDexSwift.git", from: "1.0.0")
```

Then add "OkxDexSwift" to your target's dependencies.

## Dependencies

- [swift-collections](https://github.com/apple/swift-collections) - For ordered collections
- [web3swift](https://github.com/mathwallet/web3swift) - EVM chain interactions
- [SolanaSwift](https://github.com/mathwallet/SolanaSwift) - Solana chain interactions
- [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) - Cryptographic functions
- [SuiSwift](https://github.com/lishuailibertine/SuiSwift) - Sui chain interactions

## Usage Example

### Initializing the Client

```swift
import OkxDexSwift

let config = OKXConfig(
    apiKey: "your-api-key", 
    secretKey: "your-secret-key",
    apiPassphrase: "your-passphrase",
    projectId: "your-project-id"
)
let client = OKXDexClient(config: config)
```

### Getting a Swap Quote

```swift
let params = QuoteParams(
    chainIndex: "56", // BSC chain index
    fromTokenAddress: "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c", // BNB
    toTokenAddress: "0xe9e7cea3dedca5984780bafc599bd69add087d56", // BUSD
    amount: "1000000000000000000", // 1 BNB in wei
    slippagePercent: "0.5" // 0.5% slippage
)

do {
    let quote = try await client.dex.getQuote(params: params)
    print("Estimated output: \(quote.data.first?.routerResult?.toTokenAmount ?? "0")")
} catch {
    print("Error getting quote: \(error.localizedDescription)")
}
```

### Executing a Swap (EVM Chain)

```swift
// Configure wallet for EVM chain
var clientConfig = client.config
clientConfig.evm = try EVMConfig(
    wallet: PrivateKeyWallet(
        privateKey: Data(hex: "your-private-key"),
        providerUrl: "https://bsc-dataseed.binance.org"
    )
)
client.updateConfig(clientConfig)

// Prepare swap parameters
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
    print("Swap successful! Tx hash: \(result.transactionId)")
    print("Explorer: \(result.explorerUrl)")
} catch {
    print("Swap failed: \(error.localizedDescription)")
}
```

### Executing a Swap (Solana)

```swift
// Configure wallet for Solana
var clientConfig = client.config
clientConfig.solana = try SolanaConfig(
    wallet: SolanaPrivateKeyWallet(
        privateKey: "your-private-key",
        endpoint: "https://solana-rpc.publicnode.com"
    )
)
client.updateConfig(clientConfig)

// Prepare swap parameters
let swapParams = SwapParams(
    chainIndex: "501", // Solana chain index
    fromTokenAddress: "from-token-mint-address",
    toTokenAddress: "to-token-mint-address",
    amount: "1000000", // Token amount in smallest unit
    userWalletAddress: "your-solana-wallet-address",
    slippagePercent: "0.5"
)

do {
    let result = try await client.dex.executeSwap(params: swapParams)
    print("Solana swap successful! Tx hash: \(result.transactionId)")
} catch {
    print("Solana swap failed: \(error.localizedDescription)")
}
```

## Error Handling

The library defines specific error types for different operations:

- `DexAPIError`: Errors related to API interactions (invalid parameters, missing data, etc.)
- `EVMSwapError`: Errors specific to EVM chain swaps
- `SolanaSwapError`: Errors specific to Solana swaps
- `ConversionError`: Errors during data conversion (invalid public keys, etc.)

All errors conform to `LocalizedError` for user-friendly messages.

## License

OkxDexSwift is available under the MIT license. See the [LICENSE](LICENSE) file for more details.

## Disclaimer

This library is provided as-is, without any warranty. Always ensure you understand the risks involved with blockchain transactions before using this library in production. Transactions on the blockchain are irreversible.
