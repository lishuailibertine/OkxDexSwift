import Foundation

public class BridgeAPI {
    private let client: HTTPClient
    
    public init(client: HTTPClient) {
        self.client = client
    }
    
    public func getSupportedTokens(chainIndex: String) async throws -> APIResponse<TokenData> {
        return try await client.request(method: "GET", path: "/api/v5/dex/cross-chain/supported/tokens", params: ["chainIndex": chainIndex])
    }
    
    public func getSupportedBridges(chainIndex: String) async throws -> APIResponse<LiquidityData> {
        return try await client.request(method: "GET", path: "/api/v5/dex/cross-chain/supported/bridges", params: ["chainIndex": chainIndex])
    }
    
    public func getBridgeTokenPairs(fromChainIndex: String) async throws -> APIResponse<TokenData> {
        return try await client.request(method: "GET", path: "/api/v5/dex/cross-chain/supported/bridge-tokens-pairs", params: ["fromChainIndex": fromChainIndex])
    }
    
    public func getCrossChainQuote(params: CrossChainQuoteParams) async throws -> APIResponse<QuoteData> {
        // Validate slippage
        guard let slippageValue = Double(params.slippagePercent), slippageValue >= 0.002, slippageValue <= 0.5 else {
            throw NSError(domain: "BridgeAPI", code: 1, userInfo: [NSLocalizedDescriptionKey: "Slippage must be between 0.002 (0.2%) and 0.5 (50%)"])
        }
        
        let paramsDict = try params.toDictionary()
        return try await client.request(method: "GET", path: "/api/v5/dex/cross-chain/quote", params: paramsDict)
    }
    
    public func buildCrossChainSwap(params: CrossChainSwapParams) async throws -> APIResponse<SwapExecutionData> {
        let paramsDict = try params.toDictionary()
        return try await client.request(method: "GET", path: "/api/v5/dex/cross-chain/build-tx", params: paramsDict)
    }
}
