import Foundation
import SolanaSwift
import Base58Swift
/// Solana swap executor using SolanaSwift
public class SolanaSwapExecutor: SwapExecutor {
    private let config: OKXConfig
    private let networkConfig: ChainConfig
    
    public init(config: OKXConfig, networkConfig: ChainConfig) {
        self.config = config
        self.networkConfig = networkConfig
    }
    
    public func executeSwap(swapData: SwapResponseData, params: SwapParams) async throws -> SwapResult {
        guard let quoteData = swapData.data?.first else {
            throw SolanaSwapError.missingData
        }
        
        guard let routerResult = quoteData.routerResult else {
            throw SolanaSwapError.missingRouterResult
        }
        
        // Validate token information
        guard !routerResult.fromToken.decimal.isEmpty, !routerResult.toToken.decimal.isEmpty else {
            throw SolanaSwapError.missingDecimalInfo
        }
        
        guard let txData = quoteData.tx?.data else {
            throw SolanaSwapError.missingTransactionData
        }
        
        do {
            let signature = try await executeSolanaTransaction(txData: txData)
            return formatSwapResult(signature: signature, routerResult: routerResult)
        } catch {
            print("Swap execution failed: \(error)")
            throw error
        }
    }
    
    private func executeSolanaTransaction(txData: String) async throws -> String {
        guard let solanaWallet = self.config.solana?.wallet as? SolanaPrivateKeyWallet else {
            throw SolanaSwapError.invalidWallet
        }
        let recentBlockhash = try await solanaWallet.rpcProvider.getLatestBlockhash(opts: [.commitment(.finalized)]).blockhash
        let dataBytes = Base58.bytesFromBase58(txData)
        let data = Data(bytes:dataBytes, count: dataBytes.count)
        let versionedTransaction = try BorshDecoder.decode(SolanaSignedVersionedTransaction.self, from: data).transaction
        var messagevo = versionedTransaction.message as! SolanaMessageV0
        messagevo.recentBlockhash = SolanaBlockHash(base58String: recentBlockhash)!
        let vTransaction = try solanaWallet.signTransaction(SolanaVersionedTransaction(message: messagevo))
        let result = try await solanaWallet.sendTransaction(try vTransaction.serializeAndBase58())
        return result
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
