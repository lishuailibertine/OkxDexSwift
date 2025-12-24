import Foundation
// MARK: - Base Token Info

public struct TokenInfo: Codable {
    public let decimal: String
    public let isHoneyPot: Bool
    public let taxRate: String
    public let tokenContractAddress: String
    public let tokenSymbol: String
    public let tokenUnitPrice: String
}

// MARK: - Token List

public struct TokenListResponse: Codable {
    public let decimals: String
    public let tokenContractAddress: String
    public let tokenLogoUrl: String?
    public let tokenName: String?
    public let tokenSymbol: String
}

public typealias TokenInfoList = TokenInfo
public typealias TokenListInfo = TokenListResponse

// MARK: - DEX Protocol and Router

public struct DexProtocol: Codable {
    public let dexName: String
    public let percent: String
}

public struct SubRouterInfo: Codable {
    public let dexProtocol: [DexProtocol]
    public let fromToken: TokenInfo
    public let toToken: TokenInfo
}

public struct DexRouter: Codable {
    public let dexProtocol: DexProtocol
    public let fromToken: TokenInfo
    public let fromTokenIndex: String
    public let toToken: TokenInfo
    public let toTokenIndex: String
}

// MARK: - Router Result

public struct RouterResult: Codable {
    public let chainIndex: String
    public let contextSlot: Int?
    public let dexRouterList: [DexRouter]
    public let estimateGasFee: String
    public let fromToken: TokenInfo
    public let toToken: TokenInfo
    public let fromTokenAmount: String
    public let toTokenAmount: String
    public let priceImpactPercent: String
    public let router: String
    public let swapMode: String
    public let tradeFee: String
}

// MARK: - Transaction Data

public struct TransactionData: Codable {
    public let data: String
    public let from: String
    public let gas: String?
    public let gasPrice: String
    public let maxPriorityFeePerGas: String
    public let maxSpendAmount: String
    public let minReceiveAmount: String
    public let signatureData: [String]
    public let slippagePercent: String
    public let to: String
    public let value: String?
}

// MARK: - Quote Data

public struct QuoteData: Codable {
    public let chainIndex: String
    public let contextSlot: Int?
    public let dexRouterList: [DexRouter]
    public let estimateGasFee: String
    public let fromToken: TokenInfo
    public let toToken: TokenInfo
    public let fromTokenAmount: String
    public let toTokenAmount: String
    public let priceImpactPercent: String
    public let router: String
    public let swapMode: String
    public let tradeFee: String
    public let routerResult: RouterResult?
    public let tx: TransactionData?
}

// MARK: - Liquidity and Chain Data

public struct LiquidityData: Codable {
    public let id: String
    public let name: String
    public let logo: String
}

public struct TokenData: Codable {
    public let decimals: String
    public let tokenContractAddress: String
    public let tokenLogoUrl: String
    public let tokenName: String
    public let tokenSymbol: String
}

public struct ChainData: Codable {
    public let chainIndex: Int
    public let chainName: String
    public let dexTokenApproveAddress: String?
}

// MARK: - Swap Response

public struct SwapExecutionData: Codable {
    public let routerResult: RouterResult?
    public let tx: TransactionData?
}

public struct SwapResponseData: Codable {
    public let data: [SwapExecutionData]?
    public let code: String
    public let msg: String
}

// MARK: - API Response

public struct APIResponse<T: Codable>: Codable {
    public let code: String
    public let msg: String
    public let data: [T]?
}

public struct APIResponseSingle<T: Codable>: Codable {
    public let code: String
    public let msg: String
    public let data: T?
}

// MARK: - Configuration

public struct ChainConfig: Codable {
    public let id: String
    public let explorer: String
    public let defaultSlippage: String
    public let maxSlippage: String
    public let computeUnits: Int?
    public let confirmationTimeout: Int?
    public let maxRetries: Int?
    public let dexContractAddress: String?
    
    public init(id: String, explorer: String, defaultSlippage: String, maxSlippage: String, computeUnits: Int? = nil, confirmationTimeout: Int? = nil, maxRetries: Int? = nil, dexContractAddress: String? = nil) {
        self.id = id
        self.explorer = explorer
        self.defaultSlippage = defaultSlippage
        self.maxSlippage = maxSlippage
        self.computeUnits = computeUnits
        self.confirmationTimeout = confirmationTimeout
        self.maxRetries = maxRetries
        self.dexContractAddress = dexContractAddress
    }
}

public typealias NetworkConfigs = [String: ChainConfig]

public struct SolanaConfig {
    public let wallet: SolanaWallet?
    public init(wallet: SolanaWallet?) {
        self.wallet = wallet
    }
}

public struct EVMConfig {
    public let wallet: EVMWallet?
    public init(wallet: EVMWallet?) {
        self.wallet = wallet
    }
}

public struct SuiConfig {
    public let wallet: SuiWallet?
    public init(wallet: SuiWallet?) {
        self.wallet = wallet
    }
}

public struct TonConfig {
    public let wallet: TonSwapWallet?
    public init(wallet: TonSwapWallet?) {
        self.wallet = wallet
    }
}

public struct OKXConfig {
    public let apiKey: String
    public let secretKey: String
    public let apiPassphrase: String
    public let projectId: String
    public let baseUrl: String
    public let timeout: TimeInterval?
    public let maxRetries: Int?
    public var networks: NetworkConfigs?
    public var solana: SolanaConfig?
    public var evm: EVMConfig?
    public var sui: SuiConfig?
    public var ton: TonConfig?
    public init(apiKey: String, secretKey: String, apiPassphrase: String, projectId: String, baseUrl: String = "https://web3.okx.com", networks: NetworkConfigs? = nil, timeout: TimeInterval? = nil, maxRetries: Int? = nil) {
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.apiPassphrase = apiPassphrase
        self.projectId = projectId
        self.baseUrl = baseUrl
        self.networks = networks
        self.timeout = timeout
        self.maxRetries = maxRetries
    }
}

// MARK: - Request Params

public struct BaseParams: Codable {
    public let chainIndex: String?
    public let fromTokenAddress: String
    public let toTokenAddress: String
    public let amount: String
    public let userWalletAddress: String?
    public let dexIds: String?
    public let directRoute: Bool?
    public let priceImpactProtectionPercent: String?
    public let feePercent: String?
}

public enum EVMTransactionType: UInt8, Codable {
    case Legacy = 0x00
    case EIP1559 = 0x02
}

public struct SwapParams: Codable {
    public let chainIndex: String?
    public let fromTokenAddress: String
    public let toTokenAddress: String
    public let amount: String
    public let userWalletAddress: String?
    public let slippagePercent: String?
    public let autoSlippage: Bool?
    public let maxAutoSlippagePercent: String?
    public let swapReceiverAddress: String?
    public let fromTokenReferrerWalletAddress: String?
    public let toTokenReferrerWalletAddress: String?
    public let positiveSlippagePercent: String?
    public let gasLimit: String?
    public let gasLevel: String?
    public let computeUnitPrice: String?
    public let computeUnitLimit: String?
    public let callDataMemo: String?
    public let dexIds: String?
    public let directRoute: Bool?
    public let priceImpactProtectionPercent: String?
    public let feePercent: String?
    public let type: EVMTransactionType
    public init(chainIndex: String? = nil, fromTokenAddress: String, toTokenAddress: String, amount: String, userWalletAddress: String? = nil, slippagePercent: String? = nil, autoSlippage: Bool? = nil, maxAutoSlippagePercent: String? = nil, swapReceiverAddress: String? = nil, fromTokenReferrerWalletAddress: String? = nil, toTokenReferrerWalletAddress: String? = nil, positiveSlippagePercent: String? = nil, gasLimit: String? = nil, gasLevel: String? = nil, computeUnitPrice: String? = nil, computeUnitLimit: String? = nil, callDataMemo: String? = nil, dexIds: String? = nil, directRoute: Bool? = nil, priceImpactProtectionPercent: String? = nil, feePercent: String? = nil, type: EVMTransactionType = .EIP1559) {
        self.chainIndex = chainIndex
        self.fromTokenAddress = fromTokenAddress
        self.toTokenAddress = toTokenAddress
        self.amount = amount
        self.userWalletAddress = userWalletAddress
        self.slippagePercent = slippagePercent
        self.autoSlippage = autoSlippage
        self.maxAutoSlippagePercent = maxAutoSlippagePercent
        self.swapReceiverAddress = swapReceiverAddress
        self.fromTokenReferrerWalletAddress = fromTokenReferrerWalletAddress
        self.toTokenReferrerWalletAddress = toTokenReferrerWalletAddress
        self.positiveSlippagePercent = positiveSlippagePercent
        self.gasLimit = gasLimit
        self.gasLevel = gasLevel
        self.computeUnitPrice = computeUnitPrice
        self.computeUnitLimit = computeUnitLimit
        self.callDataMemo = callDataMemo
        self.dexIds = dexIds
        self.directRoute = directRoute
        self.priceImpactProtectionPercent = priceImpactProtectionPercent
        self.feePercent = feePercent
        self.type = type
    }
}

public struct QuoteParams: Codable {
    public let chainIndex: String?
    public let fromTokenAddress: String
    public let toTokenAddress: String
    public let amount: String
    public let slippagePercent: String
    public let userWalletAddress: String?
    public let dexIds: String?
    public let directRoute: Bool?
    public let priceImpactProtectionPercent: String?
    public let feePercent: String?
    public init(chainIndex: String? = nil, fromTokenAddress: String, toTokenAddress: String, amount: String, slippagePercent: String, userWalletAddress: String? = nil, dexIds: String? = nil, directRoute: Bool? = false, priceImpactProtectionPercent: String? = nil, feePercent: String? = nil) {
        self.chainIndex = chainIndex
        self.fromTokenAddress = fromTokenAddress
        self.toTokenAddress = toTokenAddress
        self.amount = amount
        self.slippagePercent = slippagePercent
        self.userWalletAddress = userWalletAddress
        self.dexIds = dexIds
        self.directRoute = directRoute
        self.priceImpactProtectionPercent = priceImpactProtectionPercent
        self.feePercent = feePercent
    }
}

// MARK: - Swap Result

public struct SwapResult {
    public let success: Bool
    public let transactionId: String
    public let explorerUrl: String
    public let details: SwapDetails?
    
    public struct SwapDetails {
        public let fromToken: TokenDetails
        public let toToken: TokenDetails
        public let priceImpact: String
        
        public struct TokenDetails {
            public let symbol: String
            public let amount: String
            public let decimal: String
        }
    }
}

// MARK: - Approve

public struct ApproveTokenParams: Codable {
    public let chainIndex: String
    public let tokenContractAddress: String
    public let approveAmount: String
    
    public init(chainIndex: String, tokenContractAddress: String, approveAmount: String) {
        self.chainIndex = chainIndex
        self.tokenContractAddress = tokenContractAddress
        self.approveAmount = approveAmount
    }
}

public struct ApproveTransactionData: Codable {
    public let dexContractAddress: String
}

// MARK: - Gas and Transaction

public struct GasLimitParams: Codable {
    public let chainIndex: String
    public let fromAddress: String
    public let toAddress: String
    public let txAmount: String?
    public let extJson: ExtJson?
    
    public struct ExtJson: Codable {
        public let inputData: String?
    }
}

public struct GasLimitData: Codable {
    public let gasLimit: String
}

public struct GasPriceData: Codable {
    public let normal: String
    public let min: String
    public let max: String
    public let supporteip1559: Bool
    public let eip1559Protocol: EIP1559Protocol?
    public let priorityFee: PriorityFee?
    
    public struct EIP1559Protocol: Codable {
        public let suggestBaseFee: String
        public let baseFee: String
        public let proposePriorityFee: String
        public let safePriorityFee: String
        public let fastPriorityFee: String
    }
    
    public struct PriorityFee: Codable {
        public let proposePriorityFee: String
        public let safePriorityFee: String
        public let fastPriorityFee: String
        public let extremePriorityFee: String
    }
}

public struct BroadcastTransactionParams: Codable {
    public let signedTx: String
    public let chainIndex: String
    public let address: String
    public let extraData: String?
    public let enableMevProtection: Bool?
    public let jitoSignedTx: String?
}

public struct BroadcastTransactionData: Codable {
    public let orderId: String
    public let txHash: String
}

public struct TransactionOrdersParams: Codable {
    public let address: String
    public let chainIndex: String
    public let txStatus: String?
    public let orderId: String?
    public let cursor: String?
    public let limit: String?
}

public struct TransactionOrder: Codable {
    public let chainIndex: String
    public let orderId: String
    public let address: String
    public let txHash: String
    public let txStatus: String
    public let failReason: String
}

public struct TransactionOrdersData: Codable {
    public let cursor: String
    public let orders: [TransactionOrder]
}

// MARK: - Solana Specific

public struct SolanaInstructionAccount: Codable {
    public let isSigner: Bool
    public let isWritable: Bool
    public let pubkey: String
}

public struct SolanaInstructionItem: Codable {
    public let data: String
    public let accounts: [SolanaInstructionAccount]
    public let programId: String
}

public struct SolanaSwapInstructionData: Codable {
    public let addressLookupTableAccount: [String]
    public let instructionLists: [SolanaInstructionItem]
    public let routerResult: RouterResult
    public let tx: SolanaTx
    
    public struct SolanaTx: Codable {
        public let from: String
        public let minReceiveAmount: String
        public let slippagePercent: String
        public let to: String
    }
}

// MARK: - Bridge Types

public struct CrossChainQuoteParams: Codable {
    public let fromChainIndex: String
    public let toChainIndex: String
    public let fromTokenAddress: String
    public let toTokenAddress: String
    public let amount: String
    public let slippagePercent: String
    
    public init(fromChainIndex: String, toChainIndex: String, fromTokenAddress: String, toTokenAddress: String, amount: String, slippagePercent: String) {
        self.fromChainIndex = fromChainIndex
        self.toChainIndex = toChainIndex
        self.fromTokenAddress = fromTokenAddress
        self.toTokenAddress = toTokenAddress
        self.amount = amount
        self.slippagePercent = slippagePercent
    }
}

public struct CrossChainSwapParams: Codable {
    public let fromChainIndex: String
    public let toChainIndex: String
    public let fromTokenAddress: String
    public let toTokenAddress: String
    public let amount: String
    public let slippagePercent: String
    public let userWalletAddress: String
    public let receiveAddress: String?
    
    public init(fromChainIndex: String, toChainIndex: String, fromTokenAddress: String, toTokenAddress: String, amount: String, slippagePercent: String, userWalletAddress: String, receiveAddress: String? = nil) {
        self.fromChainIndex = fromChainIndex
        self.toChainIndex = toChainIndex
        self.fromTokenAddress = fromTokenAddress
        self.toTokenAddress = toTokenAddress
        self.amount = amount
        self.slippagePercent = slippagePercent
        self.userWalletAddress = userWalletAddress
        self.receiveAddress = receiveAddress
    }
}

// MARK: - Helper Extensions

extension Encodable {
    func toDictionary() throws -> [String: String] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError(domain: "EncodingError", code: 0)
        }
        return dictionary.compactMapValues { value in
            if let boolValue = value as? Bool {
                return boolValue ? "true" : "false"
            }
            return "\(value)"
        }
    }
    func toBody() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
}
