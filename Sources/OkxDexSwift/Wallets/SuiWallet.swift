//
//  SuiWallet.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/12.
//
import Foundation
import SuiSwift
import PromiseKit
import Combine
public typealias LocalSuiTransactionBlockResponse = SuiTransactionBlockResponse
extension LocalSuiTransactionBlockResponse: @unchecked @retroactive Sendable {}

public protocol SuiWalletProtocol {
    func signMessage(_ message: Data) throws -> SuiExecuteTransactionBlock
    func signTransaction(_ transactionBuilder: SuiTransactionBuilder) throws -> SuiExecuteTransactionBlock
    func signTransactionData(_ data: SuiTransactionData) throws -> SuiExecuteTransactionBlock
    func sendTransaction(model: SuiExecuteTransactionBlock) async throws -> LocalSuiTransactionBlockResponse
}

public class SuiWallet: SuiWalletProtocol {
    private var secretKey: Data
    private var signType: SuiSignatureScheme
    public var rpc: SuiJsonRpcProvider
    public var address: String
    public init(secretKey: Data, signType: SuiSignatureScheme, url: String) throws{
        self.secretKey = secretKey
        self.signType = signType
        let keypair = try SuiWallet.keyPairClass(signType: signType).init(key: secretKey)
        self.address = try keypair.getPublicKey().toSuiAddress().value
        self.rpc = SuiJsonRpcProvider(url: URL(string: url)!)
    }
    public func signMessage(_ message: Data) throws -> SuiExecuteTransactionBlock {
        let keypair = try SuiWallet.keyPairClass(signType: signType).init(key: secretKey)
        var serializeData = Data()
        try VarData(message).serialize(to: &serializeData)
        let signedBlock = try serializeData.signTxnBytesWithKeypair(keypair: keypair, scope: .PersonalMessage)
        return signedBlock
    }
    
    public func signTransaction(_ transactionBuilder: SuiTransactionBuilder) throws -> SuiExecuteTransactionBlock {
        let keypair = try SuiWallet.keyPairClass(signType: signType).init(key: secretKey)
        return try transactionBuilder.signWithKeypair(keypair: keypair)
    }
    
    public func signTransactionData(_ data: SuiTransactionData) throws -> SuiExecuteTransactionBlock {
        let keypair = try SuiWallet.keyPairClass(signType: signType).init(key: secretKey)
        var serializedTx = Data()
        try data.serialize(to: &serializedTx)
        return try serializedTx.signTxnBytesWithKeypair(keypair: keypair)
    }

    public func sendTransaction(model: SuiExecuteTransactionBlock) async throws -> LocalSuiTransactionBlockResponse {
        return try await withCheckedThrowingContinuation { continuation in
            self.rpc.executeTransactionBlock(model: model)
                .done { response in
                    continuation.resume(returning: response)
                }
                .catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    public func getReferenceGasPrice() async throws -> UInt64 {
        return try await withCheckedThrowingContinuation { continuation in
            self.rpc.getReferenceGasPrice()
                .done { response in
                    continuation.resume(returning: UInt64(response.description)!)
                }
                .catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    static func keyPairClass(signType: SuiSignatureScheme) throws -> SuiKeypair.Type {
        switch signType{
        case .ED25519:
            return SuiEd25519Keypair.self
        case .Secp256k1:
            return SuiSecp256k1Keypair.self
        // 后续可能支持
        case .BLS:
            throw SuiError.KeypairError.InvalidSignatureScheme
        }
    }
}
