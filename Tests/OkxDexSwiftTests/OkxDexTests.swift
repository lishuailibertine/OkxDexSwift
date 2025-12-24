//
//  OkxDexTests.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/12.
//

import Testing
import CryptoSwift
import Foundation
import SolanaSwift
import TonSwift
@testable import OkxDexSwift

func client_okx() -> OKXDexClient {
    let config = OKXConfig(apiKey: "apiKey", secretKey: "secretKey", apiPassphrase: "apiPassphrase", projectId: "projectId")
    return OKXDexClient(config: config)
}

// EVM
@Test func evmQuote_okx() async throws {
    let param = QuoteParams(chainIndex: "56", fromTokenAddress: "fromTokenAddress", toTokenAddress: "toTokenAddress", amount: "1000000", slippagePercent: "20")
    let result = try await client().dex.getQuote(params: param)
    print(result)
}

@Test func suppertedEvmChains_okx() async throws {
    let result = try await client().dex.getChainData(chainIndex: "56")
    print(result)
}

@Test func getAllTokens_okx() async throws {
    let result = try await client().dex.getTokens(chainIndex: "56")
    print(result)
}

@Test func getLiquidity_okx() async throws {
    let result = try await client().dex.getLiquidity(chainIndex: "56")
    print(result)
}

@Test func approve_okx() async throws {
    let client = client()
    var config = client.config
    config.networks = try NetworkConfigLoader.loadDefaultConfigs()
    config.evm = try EVMConfig(wallet: PrivateKeyWallet(privateKey: Data(hex: ""), providerUrl: "https://bsc-dataseed.binance.org"))
    client.updateConfig(config)
    let executor = EVMApproveExecutor(config: config, networkConfig: ChainConfig(id: "56", explorer: "", defaultSlippage: "", maxSlippage: ""))
    let txHash = try await executor.handleTokenApproval(chainIndex: "56", tokenAddress: "tokenAddress", amount: "1")
    print("Approval transaction hash: \(txHash)")
}

@Test func swapData_okx() async throws {
    let client = client()
    var config = client.config
    config.networks = try NetworkConfigLoader.loadDefaultConfigs()
    config.evm = try EVMConfig(wallet: PrivateKeyWallet(privateKey: Data(hex: "privateKey"), providerUrl: "https://bsc-dataseed.binance.org"))
    client.updateConfig(config)
    
    let swapParam = SwapParams(chainIndex: "56", fromTokenAddress: "fromTokenAddress", toTokenAddress: "toTokenAddress", amount: "100000000000000", userWalletAddress: (client.config.evm?.wallet as? PrivateKeyWallet)?.address ?? "", slippagePercent: "0.081", autoSlippage: true, maxAutoSlippagePercent: "50", type: .Legacy)
    let result = try await client.dex.executeSwap(params: swapParam, type: .evm)
    print("Swap transaction hash: \(result)")
}

// Solana

@Test func solanaQuote_okx() async throws {
    let param = QuoteParams(chainIndex: "501", fromTokenAddress: "fromTokenAddress", toTokenAddress: "toTokenAddress", amount: "1000000", slippagePercent: "0.5", dexIds: "277", directRoute: true, feePercent: "5")
    let result = try await client().dex.getQuote(params: param)
    print(result)
}

// 设置分佣
@Test func solanaSwapData_okx() async throws {
    let client = client()
    let result = try await client.dex.getSwapData(params: SwapParams(chainIndex: "501", fromTokenAddress: "fromTokenAddress", toTokenAddress: "toTokenAddress", amount: "1000000", userWalletAddress:"", slippagePercent: "0.05", feePercent: "0.0001"))
    print(result)
}

@Test func solanaSwapInstructions_okx() async throws {
    let client = client()
    var config = client.config
    config.networks = try NetworkConfigLoader.loadDefaultConfigs()
    config.solana = try SolanaConfig(wallet:  SolanaPrivateKeyWallet(privateKey: "privateKey", endpoint: "https://solana-rpc.publicnode.com"))
    client.updateConfig(config)
    let swapParam = SwapParams(chainIndex: "501", fromTokenAddress: "fromTokenAddress", toTokenAddress: "toTokenAddress", amount: "1000000", userWalletAddress: "userWalletAddress", slippagePercent: "0.5")
    let result = try await client.dex.executeSolanaSwapInstructionsLocal(params: swapParam)
    print("Swap transaction hash: \(result.transactionId), explorer URL: \(result.explorerUrl)")
}

@Test func solanaSwapTransation_okx() async throws {
    let client = client()
    var config = client.config
    config.networks = try NetworkConfigLoader.loadDefaultConfigs()
    config.solana = try SolanaConfig(wallet:  SolanaPrivateKeyWallet(privateKey: "privateKey", endpoint: "https://solana-rpc.publicnode.com"))
    client.updateConfig(config)
    let swapParam = SwapParams(chainIndex: "501", fromTokenAddress: "fromTokenAddress", toTokenAddress: "toTokenAddress", amount: "1000000", userWalletAddress: "userWalletAddress", slippagePercent: "0.5")
    let result = try await client.dex.executeSwap(params: swapParam, type: .solana)
    print("Swap transaction hash: \(result.transactionId), explorer URL: \(result.explorerUrl)")
}

@Test func suiSwapTransacton_okx() async throws {
    let client = client()
    var config = client.config
    config.networks = try NetworkConfigLoader.loadDefaultConfigs()
    config.sui  = try SuiConfig(wallet: SuiWallet(secretKey: Data(hex: "secretKey"), signType: .ED25519, url: "https://fullnode.mainnet.sui.io:443"))
    client.updateConfig(config)
    let swapParam = SwapParams(chainIndex: "784", fromTokenAddress: "fromTokenAddress", toTokenAddress: "toTokenAddress", amount: "1000000", userWalletAddress: "userWalletAddress", slippagePercent: "0.5")
    let result = try await client.dex.executeSwap(params: swapParam, type: .sui)
    print("Swap transaction hash: \(result.transactionId), explorer URL: \(result.explorerUrl)")
}


@Test func tonSwapTransacton_okx() async throws {
    let client = client()
    var config = client.config
    config.networks = try NetworkConfigLoader.loadDefaultConfigs()
    config.ton = try TonConfig(wallet: TonSwapWallet(mnemonics: "mnemonics", client: TonClient(url: URL(string: "https://toncenter.com")!, apiKey: ""), walletVersion: .v4R2))
    client.updateConfig(config)
    let swapParam = SwapParams(chainIndex: "607", fromTokenAddress: "EQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAM9c", toTokenAddress: "EQCxE6mUtQJKFnGfaROTKOt1lZbDiiX1kCixRv7Nw2Id_sDs", amount: "1000", userWalletAddress: "userWalletAddress", slippagePercent: "0.5")
    let result = try await client.dex.executeSwap(params: swapParam, type: .ton)
    print("Swap transaction hash: \(result.transactionId), explorer URL: \(result.explorerUrl)")
}
