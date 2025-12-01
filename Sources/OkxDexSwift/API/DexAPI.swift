import Foundation
import web3swift

public class DexAPI {
    private let client: HTTPClient
    private let config: OKXConfig
    
    public init(client: HTTPClient, config: OKXConfig) {
        self.client = client
        self.config = config
    }
    
    // MARK: - Aggregator Endpoints
    
    public func getQuote(params: QuoteParams) async throws -> APIResponse<QuoteData> {
        let paramsDict = try params.toDictionary()
        return try await client.request(method: "GET", path: "/api/v6/dex/aggregator/quote", params: paramsDict)
    }
    
    public func getLiquidity(chainIndex: String) async throws -> APIResponse<LiquidityData> {
        return try await client.request(method: "GET", path: "/api/v6/dex/aggregator/get-liquidity", params: ["chainIndex": chainIndex])
    }
    
    public func getChainData(chainIndex: String) async throws -> APIResponse<ChainData> {
        return try await client.request(method: "GET", path: "/api/v6/dex/aggregator/supported/chain", params: ["chainIndex": chainIndex])
    }
    
    public func getSwapData(params: SwapParams) async throws -> SwapResponseData {
        // Validate slippage parameters
        if params.slippagePercent == nil && params.autoSlippage != true {
            throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Either slippagePercent or autoSlippage must be provided"])
        }
        
        if let slippagePercent = params.slippagePercent {
            guard let slippageValue = Double(slippagePercent), slippageValue >= 0, slippageValue <= 1 else {
                throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Slippage must be between 0 and 1"])
            }
        }
        
        if params.autoSlippage == true && params.maxAutoSlippagePercent == nil {
            throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "maxAutoSlippagePercent must be provided when autoSlippage is enabled"])
        }
        
        let paramsDict = try params.toDictionary()
        return try await client.request(method: "GET", path: "/api/v6/dex/aggregator/swap", params: paramsDict)
    }
    
    public func getTokens(chainIndex: String) async throws -> APIResponse<TokenData> {
        return try await client.request(method: "GET", path: "/api/v6/dex/aggregator/all-tokens", params: ["chainIndex": chainIndex])
    }
    
    public func getSolanaSwapInstruction(params: SwapParams) async throws -> APIResponseSingle<SolanaSwapInstructionData> {
        if params.slippagePercent == nil && params.autoSlippage != true {
            throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Either slippagePercent or autoSlippage must be provided"])
        }
        
        if let slippagePercent = params.slippagePercent {
            guard let slippageValue = Double(slippagePercent), slippageValue >= 0, slippageValue <= 1 else {
                throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Slippage must be between 0 and 1"])
            }
        }
        
        if params.autoSlippage == true && params.maxAutoSlippagePercent == nil {
            throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "maxAutoSlippagePercent must be provided when autoSlippage is enabled"])
        }
        
        let paramsDict = try params.toDictionary()
        return try await client.request(method: "GET", path: "/api/v6/dex/aggregator/swap-instruction", params: paramsDict)
    }
    
    // MARK: - Swap Execution
    
    public func executeSwap(params: SwapParams) async throws -> SwapResult {
        guard let chainIndex = params.chainIndex else {
            throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "chainIndex is required"])
        }
        
        let swapData = try await getSwapData(params: params)
        let networkConfig = try getNetworkConfig(chainIndex: chainIndex)
        
        let executor = try SwapExecutorFactory.createExecutor(chainIndex: chainIndex, config: config, networkConfig: networkConfig)
        return try await executor.executeSwap(swapData: swapData, params: params)
    }
    
    public func executeSolanaSwapInstructions(params: SwapParams) async throws -> SwapResult {
        guard let chainIndex = params.chainIndex else {
            throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "chainIndex is required"])
        }
        
        let instructionResp = try await getSolanaSwapInstruction(params: params)
        guard let instructionData = instructionResp.data else {
            throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Empty instruction data from API"])
        }
        
        let networkConfig = try getNetworkConfig(chainIndex: chainIndex)
        let executor = SolanaInstructionExecutor(config: config, networkConfig: networkConfig)
        return try await executor.executeInstructions(instrData: instructionData)
    }
    
    public func executeApproval(params: ApproveTokenParams) async throws -> (transactionHash: String, explorerUrl: String) {
        let networkConfig = try getNetworkConfig(chainIndex: params.chainIndex)
        
        // Get the DEX approval address from supported chains
        let chainsData = try await getChainData(chainIndex: params.chainIndex)
        guard let dexTokenApproveAddress = chainsData.data?.first?.dexTokenApproveAddress else {
            throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "No dex contract address found for chain \(params.chainIndex)"])
        }
        
        // Create the approve executor
        let executor = try SwapExecutorFactory.createApproveExecutor(chainIndex: params.chainIndex, config: config, networkConfig: networkConfig)
        
        // Execute approval
        let result = try await executor.handleTokenApproval(chainIndex: params.chainIndex, tokenAddress: params.tokenContractAddress, amount: params.approveAmount)
        
        return (
            transactionHash: result,
            explorerUrl: ""
        )
    }
    
    // MARK: - Gas and Transaction Methods
    
    public func getGasPrice(chainIndex: String) async throws -> APIResponse<GasPriceData> {
        return try await client.request(method: "GET", path: "/api/v5/dex/pre-transaction/gas-price", params: ["chainIndex": chainIndex])
    }
    
    // MARK: - Helper Methods
    
    private func getNetworkConfig(chainIndex: String) throws -> ChainConfig {
        guard let networkConfig = config.networks?[chainIndex] else {
            throw NSError(domain: "DexAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network configuration not found for chain \(chainIndex)"])
        }
        return networkConfig
    }
}
