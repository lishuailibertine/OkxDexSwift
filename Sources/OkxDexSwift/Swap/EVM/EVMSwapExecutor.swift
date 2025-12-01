import Foundation
import web3swift
import BigInt

/// EVM swap executor using web3swift
public class EVMSwapExecutor: SwapExecutor {
    private let config: OKXConfig
    private let networkConfig: ChainConfig
    private let defaultGasMultiplier = BigInt(150) // 1.5x
    
    public init(config: OKXConfig, networkConfig: ChainConfig) {
        self.config = config
        self.networkConfig = networkConfig
    }
    
    public func executeSwap(swapData: SwapResponseData, params: SwapParams) async throws -> SwapResult {
        guard let quoteData = swapData.data?.first else {
            throw NSError(domain: "EVMSwapExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid swap data: missing data"])
        }
        
        guard let routerResult = quoteData.routerResult else {
            throw NSError(domain: "EVMSwapExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid swap data: missing router result"])
        }
        
        guard let tx = quoteData.tx else {
            throw NSError(domain: "EVMSwapExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing transaction data"])
        }
        
        do {
            let txHash = try await executeEVMTransaction(tx: tx)
            return formatSwapResult(txHash: txHash, routerResult: routerResult)
        } catch {
            print("Swap execution failed: \(error)")
            throw error
        }
    }
    
    private func executeEVMTransaction(tx: TransactionData) async throws -> String {
        // This is a placeholder implementation
        // In a real implementation, you would:
        // 1. Create a web3swift transaction from tx data
        // 2. Sign it with the wallet
        // 3. Send it to the network
        // 4. Wait for confirmation
        // 5. Return the transaction hash
        
        // For now, return a placeholder
        throw NSError(domain: "EVMSwapExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "EVM transaction execution not fully implemented - requires web3swift wallet integration"])
    }
    
    private func formatSwapResult(txHash: String, routerResult: RouterResult) -> SwapResult {
        let fromDecimals = Int(routerResult.fromToken.decimal) ?? 0
        let toDecimals = Int(routerResult.toToken.decimal) ?? 0
        
        let fromAmount = Double(routerResult.fromTokenAmount) ?? 0
        let toAmount = Double(routerResult.toTokenAmount) ?? 0
        
        let displayFromAmount = String(format: "%.6f", fromAmount / pow(10, Double(fromDecimals)))
        let displayToAmount = String(format: "%.6f", toAmount / pow(10, Double(toDecimals)))
        
        return SwapResult(
            success: true,
            transactionId: txHash,
            explorerUrl: "\(networkConfig.explorer)/\(txHash)",
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
