import Foundation
public protocol DexSwapError: Error, LocalizedError {
    var domain: String { get }
    var code: Int { get }
    var message: String { get }
}
extension DexSwapError {
    public var errorDescription: String? {
        return message
    }
}
/// Protocol defining the interface for swap executors
public protocol SwapExecutor {
    /// Execute a swap transaction
    func executeSwap(swapData: SwapResponseData, params: SwapParams) async throws -> SwapResult
    
    /// Handle token approval (optional, only for EVM chains)
    func handleTokenApproval(chainIndex: String, tokenAddress: String, amount: String) async throws -> String?
}

// Default implementation for handleTokenApproval
extension SwapExecutor {
    public func handleTokenApproval(chainIndex: String, tokenAddress: String, amount: String) async throws -> String? {
        return nil
    }
}
