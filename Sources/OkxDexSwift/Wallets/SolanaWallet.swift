import Foundation
import SolanaSwift
import Base58Swift
public protocol SolanaWallet: Wallet {
    func signTransaction(_ transaction: SolanaVersionedTransaction) throws -> SolanaSignedVersionedTransaction
    func signMessage(_ message: Data) throws -> Data
    func sendTransaction(_ base58: String) async throws -> String
}

public class SolanaPrivateKeyWallet: SolanaWallet {
    public let address: String
    private let secretKey: Data
    public let rpcProvider: SolanaRPCProvider
    public init(privateKey: String, endpoint: String) throws {
        // Initialize Solana instance
        let sercet = privateKey.base58DecodedData
        guard sercet.count == 64 else {
            throw APIError.unknown(NSError(domain: "InvalidPrivateKey", code: 0))
        }
        self.secretKey = privateKey.base58DecodedData
        let keypair = try SolanaKeyPair(secretKey: secretKey)
        self.address = keypair.publicKey.address
        guard let url = URL(string: endpoint) else {
            throw APIError.invalidURL
        }
        self.rpcProvider = SolanaRPCProvider(url: url)
        
    }
    
    public func signTransaction(_ transaction: SolanaVersionedTransaction) throws -> SolanaSignedVersionedTransaction {
        var tx = transaction
        return try tx.sign(keypair: SolanaKeyPair(secretKey: self.secretKey))
    }
    
    public func signMessage(_ message: Data) throws -> Data {
        return SolanaSignature(data: try SolanaKeyPair(secretKey: self.secretKey).signDigest(messageDigest: message)).data
    }
    
    public func sendTransaction(_ base58: String) async throws -> String {
        return try await self.rpcProvider.sendTransaction(encodedString: base58)
    }
}
