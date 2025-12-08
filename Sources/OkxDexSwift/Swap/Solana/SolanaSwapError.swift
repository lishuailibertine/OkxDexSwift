//
//  SolanaSwapError.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/8.
//
import Foundation
enum SolanaSwapError: DexSwapError {
    case missingData
    case missingRouterResult
    case missingDecimalInfo
    case missingTransactionData
    case invalidBlockhash
    case invalidWallet
    var domain: String {
        return "com.okx.solana.swap"  // 统一的 domain
    }
    
    var code: Int {
        switch self {
        case .missingData: return 2001
        case .missingRouterResult: return 2002
        case .missingDecimalInfo: return 2003
        case .missingTransactionData: return 2004
        case .invalidBlockhash: return 2005
        case .invalidWallet: return 2006
        }
    }
    
    var message: String {
        switch self {
        case .missingData:
            return "Invalid swap data: missing data"
        case .missingRouterResult:
            return "Invalid swap data: missing router result"
        case .missingDecimalInfo:
            return "Missing decimal information for tokens"
        case .missingTransactionData:
            return "Missing transaction data"
        case .invalidBlockhash:
            return "Invalid or expired blockhash"
        case .invalidWallet:
            return "Invalid wallet address"
        }
    }
}
