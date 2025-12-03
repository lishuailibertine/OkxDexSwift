import Foundation
import web3swift
import BigInt
import CryptoSwift
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
            let txHash = try await executeEVMTransaction(tx: tx, type: params.type)
            return formatSwapResult(txHash: txHash, routerResult: routerResult)
        } catch {
            print("Swap execution failed: \(error)")
            throw error
        }
    }
    
    private func executeEVMTransaction(tx: TransactionData, type: SwapTransactionType = .EIP1559) async throws -> String {
        let gasMultiplier = BigUInt(500) // 5x for safety
        guard let wallet = self.config.evm?.wallet as? PrivateKeyWallet else {
            throw NSError(domain: "EVMSwapExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "EVM wallet not configured"])
        }
        guard let gasLimit = BigUInt(tx.gas ?? "0") else {
            throw NSError(domain: "EVMSwapExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid gas limit"])
        }
        guard let value = BigUInt(tx.value ?? "0") else {
            throw NSError(domain: "EVMSwapExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid value"])
        }
    
        guard let toAddress = EthereumAddress(tx.to) else {
            throw NSError(domain: "EVMSwapExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid to address"])
        }
        guard let chainId = BigUInt(self.networkConfig.id) else {
            throw NSError(domain: "EVMSwapExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid chain ID"])
        }
        
        let gas = gasLimit * gasMultiplier / BigUInt(100)
        var transaction = EthereumTransaction(type: type == .EIP1559 ? .EIP1559 : .Legacy, to: toAddress, value: value, data: Data(hex: tx.data))
        transaction.gasLimit = gas
        transaction.UNSAFE_setChainID(chainId)
        switch type {
        case .EIP1559:
            let maxPriorityFeePerGas = try wallet.web3.eth.maxPriorityFeePerGas()
            let feeHistory = try wallet.web3.eth.getFeeHistory(blockCount: 20)
            var baseFeePerGas = BigUInt(0)
            for bF in feeHistory.baseFeePerGas {
                if bF > baseFeePerGas {
                    baseFeePerGas = bF
                }
            }
            transaction.maxFeePerGas = baseFeePerGas + maxPriorityFeePerGas
            transaction.maxPriorityFeePerGas = maxPriorityFeePerGas
        case .Legacy:
            transaction.gasPrice = try wallet.web3.eth.getGasPrice()
        }
        
        let nonce = try wallet.web3.eth.getTransactionCount(address: EthereumAddress(wallet.address)!, onBlock: "latest")
        transaction.nonce = nonce
        try await wallet.signTransaction(&transaction)
        let result = try await wallet.sendTransaction(transaction)
        print("EVM Transaction sent with hash: \(result.hash)")
        return result.hash
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
