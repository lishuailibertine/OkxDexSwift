//
//  TonSwapExecutor.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/19.
//
import Foundation
import TonSwift
import BigInt

public struct TonSwapExecutor: SwapExecutor{
    private let config: OKXConfig
    private let networkConfig: ChainConfig
    
    public init(config: OKXConfig, networkConfig: ChainConfig) {
        self.config = config
        self.networkConfig = networkConfig
    }
    
    public func executeSwap(swapData: SwapResponseData, params: SwapParams) async throws -> SwapResult {
        guard let quoteData = swapData.data?.first else {
            throw TonSwapError.missingData
        }
        guard let routerResult = quoteData.routerResult else {
            throw TonSwapError.missingRouterResult
        }
        guard let tx = quoteData.tx else {
            throw TonSwapError.missingTransactionData
        }
        
        let cellPayload = try Cell.fromBoc(serializedBoc: Data(Array(base64: tx.data)))
        let transaction = TonSwapTransaction(toAddress: tx.to,
                                             amount: BigUInt(tx.value ?? "0") ?? BigUInt(0),
                                         cellPayload: cellPayload,
                                         sendMode: 3,
                                         walletVersion: WalletVersion.v4R2)
        do {
            let signature = try await executeTonTransaction(tx: transaction)
            return formatSwapResult(signature: signature, routerResult: routerResult)
        } catch {
            print("Swap execution failed: \(error)")
            throw error
        }
    }
    
    private func executeTonTransaction(tx: TonSwapTransaction) async throws -> String {
        guard let tonWallet = self.config.ton?.wallet as? TonSwapWallet else {
            throw TonSwapError.invalidWallet
        }
        return try await tonWallet.sendTransaction(tx)
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
