//import Foundation
//import SolanaSwift
//
//public protocol SolanaWallet: Wallet {
//    func signTransaction(_ transaction: Transaction) async throws -> Transaction
//    func signMessage(_ message: Data) async throws -> Data
//}
//
//public class SolanaPrivateKeyWallet: SolanaWallet {
//    public let address: String
//    private let account: Account
//    private let solana: Solana
//    
//    public init(privateKey: String, endpoint: String) async throws {
//        // Initialize Solana instance
//        let apiEndpoint = APIEndPoint(address: endpoint, network: .mainnetBeta)
//        self.solana = Solana(router: NetworkingRouter(endpoint: apiEndpoint))
//        
//        // Initialize account
//        // Assuming privateKey is base58 string or hex
//        // SolanaSwift usually takes [UInt8] or base58 string
//        self.account = try await Account(secretKey: Data(base64Encoded: privateKey)!, ignorePublicKey: false) // Placeholder initialization
//        self.address = account.publicKey.base58EncodedString
//    }
//    
//    public func signTransaction(_ transaction: Transaction) async throws -> Transaction {
//        var tx = transaction
//        try await tx.sign(signers: [account])
//        return tx
//    }
//    
//    public func signMessage(_ message: Data) async throws -> Data {
//        // SolanaSwift signing logic
//        return try await account.sign(data: message)
//    }
//}
