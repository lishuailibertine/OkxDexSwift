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
        let currentAllowance = try await getAllowance(tokenAddress: tokenAddress, ownerAddress: (self.config.evm?.wallet as? PrivateKeyWallet)?.address ?? "", spenderAddress: dexContractAddress)
        if currentAllowance >= BigUInt(amount)! {
            throw EVMSwapError.invalidApproval(reason: "No approval needed, current allowance is sufficient.")
        }
        // Execute approval transaction (placeholder)
        let hash = try await self.executeApprovalTransaction(tokenAddress: tokenAddress, spenderAddress: dexContractAddress, amount: amount)
        return hash
    }
    
    private func getAllowance(tokenAddress: String,
                             ownerAddress: String,
                             spenderAddress: String) async throws -> BigUInt {
        guard let _tokenAddress = EthereumAddress(tokenAddress),
              let _spenderAddress = EthereumAddress(spenderAddress),
              let _ownerAddress = EthereumAddress(ownerAddress),
              let evmWallet = self.config.evm?.wallet as? PrivateKeyWallet else {
            throw Web3Error.dataError
        }
        let web3contract = evmWallet.web3.contract(self.erc20ABI, at: _tokenAddress)!
        // 调用 allowance 方法
        let result = try web3contract.read(
            "allowance",
            parameters: [_ownerAddress, _spenderAddress] as [AnyObject]
        )?.callPromise().wait()
        
        // 将结果转换为 BigUInt
        guard let allowance = result?["0"] as? BigUInt else {
            throw Web3Error.dataError
        }
        
        return allowance
    }

    private func executeApprovalTransaction(tokenAddress: String, spenderAddress: String, amount: String, type: EVMTransactionType = .Legacy) async throws -> String {
        guard let _tokenAddress = EthereumAddress(tokenAddress),
              let _spenderAddress = EthereumAddress(spenderAddress),
              let wallet = self.config.evm?.wallet as? PrivateKeyWallet else {
            throw Web3Error.dataError
        }
        guard let chainId = BigUInt(self.networkConfig.id) else {
            throw EVMSwapError.invalidChainId
        }
        let contract = EthereumContract(self.erc20ABI, at: _tokenAddress)
        guard let approveData = contract?.method("approve", parameters: [_spenderAddress, BigUInt(amount)!] as [AnyObject])!.data else {
            throw EVMSwapError.invalidApproval(reason: "Failed to create approval data")
        }
        var transaction = EthereumTransaction(type: .Legacy, to: _tokenAddress, value: BigUInt(0), data: approveData)
        transaction.gasLimit = BigUInt(100000)
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
        return result.hash
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
                throw EVMSwapError.invalidApproval(reason: "Failed to get DEX contract address")
            }
            return dexContractAddress
        } catch {
            print("Error getting dex contract address: \(error)")
            throw error
        }
    }
}
