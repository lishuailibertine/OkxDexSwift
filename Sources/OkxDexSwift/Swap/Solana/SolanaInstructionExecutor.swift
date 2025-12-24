import Foundation
import SolanaSwift

/// Solana instruction-based swap executor
public class SolanaInstructionExecutor {
    private let config: OKXConfig
    private let networkConfig: ChainConfig
    
    public init(config: OKXConfig, networkConfig: ChainConfig) {
        self.config = config
        self.networkConfig = networkConfig
    }
    
    public func executeInstructions(instrData: SolanaSwapInstructionData) async throws -> SwapResult {
        guard let solanaWallet = self.config.solana?.wallet as? SolanaPrivateKeyWallet else {
            throw SolanaSwapError.invalidWallet
        }
        var lookupTables = [AddressLookupTableAccount]()
        let recentBlockhash = try await solanaWallet.rpcProvider.getLatestBlockhash(opts: [.commitment(.finalized)]).blockhash
        for accountPublicKeyStr in instrData.addressLookupTableAccount {
            let tablekey = SolanaPublicKey(base58String: accountPublicKeyStr)!
            let result = try await solanaWallet.rpcProvider.getAccountInfo(account: tablekey, opts: [.encoding(.base64)])
            if let values = result?.data.value as? [String] {
                lookupTables.append(try AddressLookupTableAccount.parse(base64Data: values[0], lookupTableKey: tablekey))
            }
        }
        let _instructionLists = try instrData.toMessageInstructions()
        let v_message = try SolanaV0Message(_instructionLists, feePayer: SolanaPublicKey(base58String: solanaWallet.address)!, addressLookupTableAccounts: lookupTables, recentBlockhash: SolanaBlockHash(base58String: recentBlockhash)!)
        let vTransaction = try solanaWallet.signTransaction(SolanaVersionedTransaction(message: v_message))
        let result = try await solanaWallet.sendTransaction(try vTransaction.serializeAndBase58())
        let router = instrData.routerResult;
        return self.formatSwapResult(signature: result, routerResult: router)
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
