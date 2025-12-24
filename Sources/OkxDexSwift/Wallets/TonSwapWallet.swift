//
//  TonWallet.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/19.
//
import Foundation
import TonSwift
import BigInt
import Combine
public struct TonSwapTransaction {
    public var toAddress: String
    public var tokenAddress: String?
    public var amount: BigUInt
    public var stringPayload: String?
    public var cellPayload: Cell?
    public var dataPayload: Data?
    public var cellStateInit: Cell?
    public var sendMode: Int
    public var sequo: Int64 = 0
    public var walletVersion: WalletVersion = WalletVersion.v4R2
    public var payloadType: PayloadType = .cell
    
    public enum PayloadType {
        case string
        case data
        case cell
    }
}

public protocol TonWalletProtocol {
    func signTransaction(_ transaction: TonSwapTransaction) throws -> ExternalMessage
    func sendTransaction(_ transaction: TonSwapTransaction) async throws -> String
}

public class TonSwapWallet: TonWalletProtocol {
    private var keyPair: TonKeypair
    private var client: TonClient
    public let address: String
    public init(mnemonics: String, client: TonClient, walletVersion: WalletVersion) throws{
        self.keyPair = try TonKeypair(mnemonics: mnemonics)
        self.client = client
        let contract = try TonWallet(walletVersion: walletVersion, options: Options(publicKey: self.keyPair.publicKey, wc: Int64(0))).create()
        self.address = try contract.getAddress().toString(isUserFriendly: true, isUrlSafe: true, isBounceable: false)
    }
    public func signTransaction(_ transaction: TonSwapTransaction) throws -> TonSwift.ExternalMessage {
        let contract: WalletContract = try TonWallet(walletVersion: transaction.walletVersion, options: Options(publicKey: keyPair.publicKey)).create() as! WalletContract
        switch transaction.payloadType {
        case .string:
            let signedMessage = try contract.createSignedTransferMessagePayloadString(secretKey: keyPair.secretKey,
                                                                                      address: transaction.toAddress,
                                                                                      amount: BigInt(transaction.amount),
                                                                                      seqno: transaction.sequo,
                                                                                      payload: transaction.stringPayload ?? "",
                                                                                      stateInit: transaction.cellStateInit)
            return signedMessage
        case .data:
            let signedMessage = try contract.createSignedTransferMessagePayloadData(secretKey: keyPair.secretKey,
                                                                                    address: transaction.toAddress,
                                                                                    amount: BigInt(transaction.amount), seqno: transaction.sequo,
                                                                                    payload: transaction.dataPayload ?? Data(),
                                                                                    stateInit: transaction.cellStateInit)
            return signedMessage
        case .cell:
            let signedMessage = try contract.createSignedTransferMessagePayloadCell(secretKey: keyPair.secretKey,
                                                                                    address: transaction.toAddress,
                                                                                    amount: BigInt(transaction.amount), seqno: transaction.sequo,
                                                                                    payload: transaction.cellPayload!,
                                                                                    stateInit: transaction.cellStateInit)
            return signedMessage
        }
    }
    
   public func sendTransaction(_ transaction: TonSwapTransaction) async throws -> String {
        var tx = transaction
        tx.sequo = try await getSeqno(address: address)
        let signedTx = try signTransaction(tx)
        return try await self.sendTransaction(base64: signedTx.message.toBocBase64(hasIdx: false))
    }
    
    public func sendTransaction(base64: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            self.client.sendBoc(base64: base64)
                .done { response in
                    continuation.resume(returning: response)
                }
                .catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
    private func getSeqno(address: String) async throws -> Int64 {
        return try await withCheckedThrowingContinuation { continuation in
            self.client.getSeqno(address: address)
                .done { response in
                    continuation.resume(returning: Int64(response.description)!)
                }
                .catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }
    
}
