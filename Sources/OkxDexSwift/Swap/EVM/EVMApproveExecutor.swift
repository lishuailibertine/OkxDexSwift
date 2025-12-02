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
        let currentAllowance = try await getAllowance(tokenAddress: tokenAddress, ownerAddress: (self.config.evm?.wallet as? PrivateKeyWallet)?.address ?? "", spenderAddress: "0xd9c500dff816a1da21a48a732d3498bf09dc9aeb")
        if currentAllowance >= BigUInt(amount, radix: 10)! {
            throw NSError(domain: "EVMApproveExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "No approval needed, current allowance is sufficient."])
        }
        // Execute approval transaction (placeholder)
        
        
        throw NSError(domain: "EVMApproveExecutor", code: 1, userInfo: [NSLocalizedDescriptionKey: "EVM approval execution not fully implemented - requires web3swift wallet integration"])
    }
    
    private func getAllowance(tokenAddress: String,
                             ownerAddress: String,
                             spenderAddress: String) async throws -> BigUInt {
        guard let evmWallet = self.config.evm?.wallet as? PrivateKeyWallet else {
            throw Web3Error.dataError
        }
        let web3contract = evmWallet.web3.contract(self.erc20ABI, at: EthereumAddress(tokenAddress)!)!
        // 调用 allowance 方法
        let result = try web3contract.read(
            "allowance",
            parameters: [EthereumAddress(ownerAddress)!, EthereumAddress(spenderAddress)!] as [AnyObject]
        )?.callPromise().wait()
        
        // 将结果转换为 BigUInt
        guard let allowance = result?["0"] as? BigUInt else {
            throw Web3Error.dataError
        }
        
        return allowance
    }

//    private func executeApprovalTransaction(tokenAddress: String, spenderAddress: String, amount: String) async throws -> String {
//        
//        
//    }
    
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
