//
//  EVMSwapError.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/8.
//
import Foundation

public enum EVMSwapError: DexSwapError {
    case missingData
    case missingTransactionData
    case invalidGasLimit
    case insufficientBalance
    case missingRouterResult
    case contractCallFailed(reason: String)
    case invalidWallet
    case invalidValue
    case invalidAddress
    case invalidChainId
    case invalidApproval(reason: String)
    public var domain: String {
        return "com.okx.evm.swap"  // EVM 的 domain
    }
    
    public var code: Int {
        switch self {
        case .missingData: return 3001
        case .missingTransactionData: return 3002
        case .invalidGasLimit: return 3003
        case .insufficientBalance: return 3004
        case .missingRouterResult: return 3005
        case .contractCallFailed: return 3006
        case .invalidWallet: return 3007
        case .invalidValue: return 3008
        case .invalidAddress: return 3009
        case .invalidChainId: return 3010
        case .invalidApproval: return 3011
        }
    }
    
    public var message: String {
        switch self {
        case .missingData:
            return "Invalid swap data: missing data"
        case .missingTransactionData:
            return "Missing transaction data"
        case .invalidGasLimit:
            return "Invalid gas price"
        case .insufficientBalance:
            return "Insufficient balance for transaction"
        case .missingRouterResult:
            return "Missing router result"
        case .contractCallFailed(let reason):
            return "Contract call failed: \(reason)"
        case .invalidWallet:
            return "Invalid wallet"
        case .invalidValue:
            return "Invalid value"
        case .invalidAddress:
            return "Invalid address"
        case .invalidChainId:
            return "Invalid chain ID"
        case .invalidApproval(let reason):
            return "Invalid approval: \(reason)"
        }
    }
}
