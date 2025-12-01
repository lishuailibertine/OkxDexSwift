import Foundation
import web3swift
import BigInt

/// EVM token approval executor
public class EVMApproveExecutor {
    private let config: OKXConfig
    private let networkConfig: ChainConfig
    private let httpClient: HTTPClient
    private let defaultGasMultiplier = BigInt(150) // 1.5x
    
    // ERC20 ABI for approval
    private let erc20ABI = """
    [
        {
            "constant": true,
            "inputs": [
                { "name": "_owner", "type": "address" },
                { "name": "_spender", "type": "address" }
            ],
            "name": "allowance",
            "outputs": [{ "name": "", "type": "uint256" }],
            "type": "function"
        },
        {
            "constant": false,
            "inputs": [
                { "name": "_spender", "type": "address" },
                { "name": "_value", "type": "uint256" }
            ],
            "name": "approve",
            "outputs": [{ "name": "", "type": "bool" }],
            "type": "function"
        }
    ]
    """
    
    public init(config: OKXConfig, networkConfig: ChainConfig) {
        self.config = config
        self.networkConfig = networkConfig
        self.httpClient = HTTPClient(config: config)
    }
    
    public func handleTokenApproval(chainIndex: String, tokenAddress: String, amount: String) async throws -> String{
        let dexContractAddress = try await getDexContractAddress(chainIndex: chainIndex, tokenAddress: tokenAddress, amount: amount)
        
        // Check current allowance (placeholder)
        // In real implementation, check allowance using web3swift
        
        // Execute approval transaction (placeholder)
        throw NSError(domain: "EVMApproveExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "EVM approval execution not fully implemented - requires web3swift wallet integration"])
    }
    
    private func getDexContractAddress(chainIndex: String, tokenAddress: String, amount: String) async throws -> String {
        do {
            let response: APIResponse<ApproveTransactionData> = try await httpClient.request(
                method: "GET",
                path: "/api/v6/dex/aggregator/approve-transaction",
                params: [
                    "chainIndex": chainIndex,
                    "tokenContractAddress": tokenAddress,
                    "approveAmount": amount
                ]
            )
            
            guard let dexContractAddress = response.data?.first?.dexContractAddress else {
                throw NSError(domain: "EVMApproveExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "No dex contract address found for chain \(chainIndex)"])
            }
            return dexContractAddress
        } catch {
            print("Error getting dex contract address: \(error)")
            throw error
        }
    }
}
