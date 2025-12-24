import Foundation
import web3swift
// DexAPIError.swift
enum DexAPIError: Error, LocalizedError {
    // 参数验证错误
    case missingSlippage
    case invalidSlippage(value: String)
    case missingMaxAutoSlippage
    case missingChainIndex
    
    // 数据错误
    case emptyInstructionData
    case networkConfigNotFound(chainIndex: String)
    
    var domain: String {
        return "com.okx.dex.api"
    }
    var code: Int {
        switch self {
        case .missingSlippage: return 4001
        case .invalidSlippage: return 4002
        case .missingMaxAutoSlippage: return 4003
        case .missingChainIndex: return 4004
        case .emptyInstructionData: return 4005
        case .networkConfigNotFound: return 4006
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .missingSlippage:
            return "Either slippagePercent or autoSlippage must be provided"
        case .invalidSlippage(let value):
            return "Slippage must be between 0 and 1, got: \(value)"
        case .missingMaxAutoSlippage:
            return "maxAutoSlippagePercent must be provided when autoSlippage is enabled"
        case .missingChainIndex:
            return "chainIndex is required"
        case .emptyInstructionData:
            return "Empty instruction data from API"
        case .networkConfigNotFound(let chainIndex):
            return "Network configuration not found for chain \(chainIndex)"
        }
    }
}

public enum SwapExecutorType {
    case evm
    case solana
    case sui
    case ton
}
// 在 DexAPI 类中添加
private extension DexAPI {
    /// 验证滑点参数
    func validateSlippageParams(_ params: SwapParams) throws {
        // 检查是否提供了滑点参数
        guard params.slippagePercent != nil || params.autoSlippage == true else {
            throw DexAPIError.missingSlippage
        }
        
        // 验证滑点值范围
        if let slippagePercent = params.slippagePercent {
            guard let slippageValue = Double(slippagePercent),
                  slippageValue >= 0,
                  slippageValue <= 1 else {
                throw DexAPIError.invalidSlippage(value: slippagePercent)
            }
        }
        
        // 检查自动滑点的最大值
        if params.autoSlippage == true && params.maxAutoSlippagePercent == nil {
            throw DexAPIError.missingMaxAutoSlippage
        }
    }
}

public class DexAPI {
    public let client: HTTPClient
    public let config: OKXConfig
    
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
//        try validateSlippageParams(params)
        let paramsDict = try params.toDictionary()
        return try await client.request(method: "GET", path: "/api/v6/dex/aggregator/swap", params: paramsDict)
    }
    
    public func getTokens(chainIndex: String) async throws -> APIResponse<TokenData> {
        return try await client.request(method: "GET", path: "/api/v6/dex/aggregator/all-tokens", params: ["chainIndex": chainIndex])
    }
    
    public func getSolanaSwapInstruction(params: SwapParams) async throws -> APIResponseSingle<SolanaSwapInstructionData> {
        try validateSlippageParams(params)
        let paramsDict = try params.toDictionary()
        return try await client.request(method: "GET", path: "/api/v6/dex/aggregator/swap-instruction", params: paramsDict)
    }
    
    public func getSolanaSwapInstructionFromLocal(
           bundle: Bundle? = nil,
           filename: String = "swap-instruction"
       ) throws -> SolanaSwapInstructionData {
           let resourceBundle = bundle ?? Bundle.module
           guard let url = resourceBundle.url(forResource: filename, withExtension: "json") else {
               throw NSError(domain: "DexAPI", code: 404, userInfo: [NSLocalizedDescriptionKey: "File \(filename).json not found in bundle"])
           }
           let data = try Data(contentsOf: url)
           struct APIResponseWrapper: Codable {
               let code: String
               let msg: String
               let data: SolanaSwapInstructionData
           }
           let decoder = JSONDecoder()
           let response = try decoder.decode(APIResponseWrapper.self, from: data)
           
           return response.data
       }
    
    // MARK: - Swap Execution
    
    public func executeSwap(params: SwapParams, type: SwapExecutorType) async throws -> SwapResult {
        guard let chainIndex = params.chainIndex else {
            throw DexAPIError.missingChainIndex
        }
        
        let swapData = try await getSwapData(params: params)
        let networkConfig = try getNetworkConfig(chainIndex: chainIndex)
        var executor: SwapExecutor
        switch type {
        case .evm:
            executor = EVMSwapExecutor(config: config, networkConfig: networkConfig)
        case .solana:
            executor = SolanaSwapExecutor(config: config, networkConfig: networkConfig)
        case .sui:
            executor = SuiSwapExecutor(config: config, networkConfig: networkConfig)
        case .ton:
            executor = TonSwapExecutor(config: config, networkConfig: networkConfig)
        }
        return try await executor.executeSwap(swapData: swapData, params: params)
    }
    
    public func executeSolanaSwapInstructions(params: SwapParams) async throws -> SwapResult {
        guard let chainIndex = params.chainIndex else {
            throw DexAPIError.missingChainIndex
        }
        
        let instructionResp = try await getSolanaSwapInstruction(params: params)
        guard let instructionData = instructionResp.data else {
            throw DexAPIError.emptyInstructionData
        }
        
        let networkConfig = try getNetworkConfig(chainIndex: chainIndex)
        let executor = SolanaInstructionExecutor(config: config, networkConfig: networkConfig)
        return try await executor.executeInstructions(instrData: instructionData)
    }
    
    public func executeSolanaSwapInstructionsLocal(params: SwapParams) async throws -> SwapResult {
        guard let chainIndex = params.chainIndex else {
            throw DexAPIError.missingChainIndex
        }
        let instructionData = try getSolanaSwapInstructionFromLocal()
        let networkConfig = try getNetworkConfig(chainIndex: chainIndex)
        let executor = SolanaInstructionExecutor(config: config, networkConfig: networkConfig)
        return try await executor.executeInstructions(instrData: instructionData)
    }
    
    public func executeApproval(params: ApproveTokenParams) async throws -> (transactionHash: String, explorerUrl: String) {
        let networkConfig = try getNetworkConfig(chainIndex: params.chainIndex)
        // Create the approve executor
        let executor =  EVMApproveExecutor(config: config, networkConfig: networkConfig)
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
            throw DexAPIError.networkConfigNotFound(chainIndex: chainIndex)
        }
        return networkConfig
    }
}
