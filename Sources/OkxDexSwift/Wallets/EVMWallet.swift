import Foundation
import BigInt
import web3swift


public protocol EVMWallet: Wallet {
    func signTransaction(_ transaction: EthereumTransaction) async throws -> Data
    func signMessage(_ message: Data) async throws -> Data
    func sendTransaction(_ transaction: EthereumTransaction) async throws -> TransactionSendingResult
}

//public class PrivateKeyWallet: EVMWallet {
//    public let address: String
//    private let web3: Web3
//    private let keystore: EthereumKeystoreV3
//    
//    public init(privateKey: String, providerUrl: String) throws {
//        guard let data = Data.fromHex(privateKey) else {
//            throw APIError.unknown(NSError(domain: "InvalidPrivateKey", code: 0))
//        }
//        
//        guard let url = URL(string: providerUrl) else {
//            throw APIError.invalidURL
//        }
//        let provider = Web3HttpProvider(url, network: .Mainnet)
//        self.web3 = Web3.ne
//        
//        let keystore = try EthereumKeystoreV3(privateKey: data)!
//        self.keystore = keystore
//        
//        let manager = KeystoreManager([keystore])
//        self.web3.addKeystoreManager(manager)
//        
//        self.address = keystore.addresses?.first?.address ?? ""
//    }
//    
//    public func signTransaction(_ transaction: EthereumTransaction) async throws -> Data {
//        // web3swift signing implementation
//        // This is a placeholder as actual signing depends on web3swift version specifics
//        return Data()
//    }
//    
//    public func signMessage(_ message: Data) async throws -> Data {
//        let address = EthereumAddress(self.address)!
//        return try web3.wallet.signPersonalMessage(message, account: address)
//    }
//    
//    public func sendTransaction(_ transaction: EthereumTransaction) async throws -> TransactionSendingResult {
//        var tx = transaction
//        return try await web3.eth.sendTransaction(tx)
//    }
//}
