//
//  SuiSwapExecutor.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/12.
//
import Foundation
import SuiSwift
import BigInt

public struct SuiSwapExecutor: SwapExecutor {
    
    private let config: OKXConfig
    private let networkConfig: ChainConfig
    private let DEFAULT_GAS_BUDGET = BigInt(50000000) // 1.5x
    
    public init(config: OKXConfig, networkConfig: ChainConfig) {
        self.config = config
        self.networkConfig = networkConfig
    }
    
    public func executeSwap(swapData: SwapResponseData, params: SwapParams) async throws -> SwapResult {
        guard let quoteData = swapData.data?.first else {
            throw SuiSwapError.missingData
        }
        
        guard let routerResult = quoteData.routerResult else {
            throw SuiSwapError.missingRouterResult
        }
        guard let txData = quoteData.tx?.data else {
            throw SuiSwapError.missingTransactionData
        }
        
        do {
            let signature = try await executeSuiTransaction(txData: txData)
            return formatSwapResult(signature: signature, routerResult: routerResult)
        } catch {
            print("Swap execution failed: \(error)")
            throw error
        }
    }
    
    private func executeSuiTransaction(txData: String) async throws -> String {
        guard let suiWallet = self.config.sui?.wallet as? SuiWallet else {
            throw SuiSwapError.invalidWallet
        }
        var reader = BinaryReader(bytes: Array(base64: txData))
        let tx = try SuiTransactionData(from: &reader)
        var txBlock: SuiTransactionData
        switch tx {
        case .V1(let suiTransactionDataV1):
            var v1tx = suiTransactionDataV1
            v1tx.gasData.price = try await suiWallet.getReferenceGasPrice()
            v1tx.gasData.budget = UInt64(DEFAULT_GAS_BUDGET.description)!
            txBlock = SuiTransactionData.V1(v1tx)
        }
        let executeTransactionBlock = try suiWallet.signTransactionData(txBlock)
        return try await suiWallet.sendTransaction(model: executeTransactionBlock).digest.value
    }
    
    private func formatSwapResult(signature: String, routerResult: RouterResult) -> SwapResult {
        let fromDecimals = Int(routerResult.fromToken.decimal) ?? 0
        let toDecimals = Int(routerResult.toToken.decimal) ?? 0
        
        let fromAmount = Double(routerResult.fromTokenAmount) ?? 0
        let toAmount = Double(routerResult.toTokenAmount) ?? 0
        
        let displayFromAmount = String(format: "%.6f", fromAmount / pow(10, Double(fromDecimals)))
        let displayToAmount = String(format: "%.6f", toAmount / pow(10, Double(toDecimals)))
        
        return SwapResult(
            success: true,
            transactionId: signature,
            explorerUrl: "\(networkConfig.explorer)/\(signature)",
            details: SwapResult.SwapDetails(
                fromToken: SwapResult.SwapDetails.TokenDetails(
                    symbol: routerResult.fromToken.tokenSymbol,
                    amount: displayFromAmount,
                    decimal: routerResult.fromToken.decimal
                ),
                toToken: SwapResult.SwapDetails.TokenDetails(
                    symbol: routerResult.toToken.tokenSymbol,
                    amount: displayToAmount,
                    decimal: routerResult.toToken.decimal
                ),
                priceImpact: routerResult.priceImpactPercent
            )
        )
    }
}
