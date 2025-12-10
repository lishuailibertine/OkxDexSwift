import Foundation
import SolanaSwift
public typealias AccountKeysFromLookups = LoadedAddresses

public struct LoadedAddresses {
    var readonly: [SolanaPublicKey]
    var writable: [SolanaPublicKey]

    public init(readonly: [SolanaPublicKey], writable: [SolanaPublicKey]) {
        self.readonly = readonly
        self.writable = writable
    }
}

public struct MessageAccountKeys {
    public var staticAccountKeys: [SolanaPublicKey]
    public var accountKeysFromLookups: AccountKeysFromLookups?

    public init(
        staticAccountKeys: [SolanaPublicKey],
        accountKeysFromLookups: AccountKeysFromLookups? = nil
    ) {
        self.staticAccountKeys = staticAccountKeys
        self.accountKeysFromLookups = accountKeysFromLookups
    }

    public var keySegments: [[SolanaPublicKey]] {
        var keySegments = [staticAccountKeys]
        if let accountKeysFromLookups = accountKeysFromLookups {
            keySegments.append(accountKeysFromLookups.writable)
            keySegments.append(accountKeysFromLookups.readonly)
        }

        return keySegments
    }

    public subscript(index: Int) -> SolanaPublicKey? {
        var index = index
        for keySegment in keySegments {
            if index < keySegment.count {
                return keySegment[index]
            } else {
                index -= keySegment.count
            }
        }
        return nil
    }

    public var count: Int {
        keySegments.reduce([], +).count
    }

    public func compileInstructions(
        instructions: [SolanaMessageInstruction]
    ) throws -> [SolanaMessageCompiledInstruction] {
        if count > UInt8.max {
            return []
        }
        var keyIndexMap: [String: Int] = [:]
        keySegments
            .reduce([], +).enumerated()
            .forEach { index, key in
                keyIndexMap[key.address] = index
            }

        func findKeyIndex(key: SolanaPublicKey) throws -> Int {
            if let keyIndex = keyIndexMap[key.address] {
                return keyIndex
            }
            throw SolanaSwapError.missingData
        }

        return try instructions.map { (instruction: SolanaMessageInstruction) in
            var data = Data()
            try instruction.data.serialize(to: &data)
            return try SolanaMessageCompiledInstruction.init(programIdIndex: UInt8(findKeyIndex(key: instruction.programId)), accountKeyIndexes: instruction.accounts.map { meta in try UInt8(findKeyIndex(key: meta.publicKey))}, data: data)
        }
    }
}
