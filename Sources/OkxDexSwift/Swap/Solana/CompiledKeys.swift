import Foundation
import SolanaSwift
import OrderedCollections
public struct CompiledKeyMeta {
    public var isSigner: Bool
    public var isWritable: Bool
    public var isInvoked: Bool

    public init(isSigner: Bool, isWritable: Bool, isInvoked: Bool) {
        self.isSigner = isSigner
        self.isWritable = isWritable
        self.isInvoked = isInvoked
    }
}
public typealias KeyMetaMap = OrderedDictionary<String, CompiledKeyMeta>
public struct CompiledKeys {
    public var payer: SolanaPublicKey
    public var keyMetaMap: KeyMetaMap

    public init(payer: SolanaPublicKey, keyMetaMap: KeyMetaMap) {
        self.payer = payer
        self.keyMetaMap = keyMetaMap
    }

    public mutating func extractTableLookup(lookupTable: AddressLookupTableAccount) throws -> (SolanaMessageAddressTableLookup, AccountKeysFromLookups)? {
        let (writableIndexes, drainedWritableKeys) = try drainKeysFoundInLookupTable(
            lookupTableEntries: lookupTable.state.addresses
        ) { keyMeta in
            !keyMeta.isSigner && !keyMeta.isInvoked && keyMeta.isWritable
        }

        let (readonlyIndexes, drainedReadonlyKeys) = try drainKeysFoundInLookupTable(
            lookupTableEntries: lookupTable.state.addresses
        ) { keyMeta in
            !keyMeta.isSigner && !keyMeta.isInvoked && !keyMeta.isWritable
        }

        if writableIndexes.count == 0, readonlyIndexes.count == 0 {
            return nil
        }
        return (
            .init(
                accountKey: lookupTable.key,
                writableIndexes: writableIndexes,
                readonlyIndexes: readonlyIndexes
            ),
            .init(
                readonly: drainedReadonlyKeys,
                writable: drainedWritableKeys
            )
        )
    }

    internal mutating func drainKeysFoundInLookupTable(
        lookupTableEntries: [SolanaPublicKey],
        keyMetaFilter: (CompiledKeyMeta) -> Bool
    ) throws -> ([UInt8], [SolanaPublicKey]) {
        var lookupTableIndexes: [UInt8] = []
        var drainedKeys: [SolanaPublicKey] = []
        keyMetaMap.forEach { address, keyMeta in
            if keyMetaFilter(keyMeta) {
                let key = SolanaPublicKey(base58String: address)!
                let lookupTableIndex = lookupTableEntries.firstIndex(of: key)
                if let lookupTableIndex = lookupTableIndex {
                    lookupTableIndexes.append(UInt8(lookupTableIndex))
                    drainedKeys.append(key)
                    keyMetaMap.removeValue(forKey: address)
                }
            }
        }
        return (lookupTableIndexes, drainedKeys)
    }

    func getMessageComponents() -> (SolanaMessageHeader, [SolanaPublicKey]) {
        let writableSigners = keyMetaMap.filter { _, meta in
            meta.isSigner && meta.isWritable
        }
        let readonlySigners = keyMetaMap.filter { _, meta in
            meta.isSigner && !meta.isWritable
        }

        let writableNonSigners = keyMetaMap.filter { _, meta in
            !meta.isSigner && meta.isWritable
        }

        let readonlyNonSigners = keyMetaMap.filter { _, meta in
            !meta.isSigner && !meta.isWritable
        }

        let header = SolanaMessageHeader(
            numRequiredSignatures: UInt8(writableSigners.count + readonlySigners.count),
            numReadonlySignedAccounts: UInt8(readonlySigners.count),
            numReadonlyUnsignedAccounts: UInt8(readonlyNonSigners.count)
        )
        var staticAccountKeys: [SolanaPublicKey] = []
        staticAccountKeys.append(contentsOf: try! writableSigners.map { address, _ in
            guard let key = SolanaPublicKey(base58String: address) else {
                throw NSError(domain: "CompiledKeys", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效的Base58地址：\(address)"])
            }
            return key
        })
        staticAccountKeys.append(contentsOf: try! readonlySigners.map { address, _ in
            guard let key = SolanaPublicKey(base58String: address) else {
                throw NSError(domain: "CompiledKeys", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效的Base58地址：\(address)"])
            }
            return key
        })
        staticAccountKeys.append(contentsOf: try! writableNonSigners.map { address, _ in
            guard let key = SolanaPublicKey(base58String: address) else {
                throw NSError(domain: "CompiledKeys", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效的Base58地址：\(address)"])
            }
            return key
        })
        staticAccountKeys.append(contentsOf: try! readonlyNonSigners.map { address, _ in
            guard let key = SolanaPublicKey(base58String: address) else {
                throw NSError(domain: "CompiledKeys", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效的Base58地址：\(address)"])
            }
            return key
        })
        return (header, staticAccountKeys)
    }
    // 排序去重
    static func compile(instructions: [SolanaMessageInstruction], payer: SolanaPublicKey) -> Self {
            // 关键修改5：OrderedDictionary初始化适配
            var keyMetaMap: KeyMetaMap = OrderedDictionary()
            let getOrInsertDefault: (SolanaPublicKey, (inout CompiledKeyMeta) -> Void) -> CompiledKeyMeta = { pubKey, callback in
                let address = pubKey.address
                if var keyMeta = keyMetaMap[address] {
                    callback(&keyMeta)
                    keyMetaMap[address] = keyMeta
                    return keyMeta
                } else {
                    var keyMeta = CompiledKeyMeta(
                        isSigner: false,
                        isWritable: false,
                        isInvoked: false
                    )
                    callback(&keyMeta)
                    keyMetaMap[address] = keyMeta
                    return keyMeta
                }
            }
            
            _ = getOrInsertDefault(payer) { meta in
                meta.isSigner = true
                meta.isWritable = true
            }
            for ix in instructions {
                _ = getOrInsertDefault(ix.programId) { meta in meta.isInvoked = true }
                for accountMeta in ix.accounts {
                    _ = getOrInsertDefault(accountMeta.publicKey) { meta in
                        meta.isSigner = meta.isSigner || accountMeta.isSigner
                        meta.isWritable = meta.isWritable || accountMeta.isWritable
                    }
                }
            }
            
            return .init(payer: payer, keyMetaMap: keyMetaMap)
        }
}
