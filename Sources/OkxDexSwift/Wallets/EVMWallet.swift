import Foundation
import BigInt
import web3swift
import CryptoSwift

public protocol EVMWallet: Wallet {
    func signTransaction(_ transaction: inout EthereumTransaction) async throws
    func signMessage(_ message: Data) async throws -> Data
    func sendTransaction(_ transaction: EthereumTransaction) async throws -> TransactionSendingResult
}

public class PrivateKeyWallet: EVMWallet {
    public let address: String
    public let web3: web3
    private var privateKey: Data
    public init(privateKey: Data, providerUrl: String) throws {
        guard let url = URL(string: providerUrl) else {
            throw APIError.invalidURL
        }
        self.web3 = try Web3.new(url)
        self.privateKey = privateKey
        
        guard let publicKey = Web3.Utils.privateToPublic(privateKey) else {
            throw APIError.unknown(NSError(domain: "InvalidPrivateKey", code: 0))
        }
        
        guard let address = Web3.Utils.publicToAddress(publicKey) else {
            throw APIError.unknown(NSError(domain: "InvalidPrivateKey", code: 0))
        }
        
        self.address = address.address
    }
    
    public func signTransaction(_ transaction: inout EthereumTransaction) async throws {
        switch transaction.type {
        case .Legacy:
            try Web3Signer.EIP155Signer.sign(transaction: &(transaction), privateKey: self.privateKey)
        case .EIP1559:
            try Web3Signer.EIP1559Signer.sign(transaction: &(transaction), privateKey: self.privateKey)
        }
    }
    
    public func signMessage(_ message: Data) async throws -> Data {
        let address = EthereumAddress(self.address)!
        return try web3.wallet.signPersonalMessage(message, account: address)
    }
    
    public func sendTransaction(_ transaction: EthereumTransaction) async throws -> TransactionSendingResult {
        return try web3.eth.sendRawTransaction(transaction)
    }
}
