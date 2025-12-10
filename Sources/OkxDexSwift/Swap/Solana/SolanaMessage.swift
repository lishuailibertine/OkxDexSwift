//
//  SolanaMessage_V0.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/5.
//
import SolanaSwift
import Foundation
// https://github.com/solana-foundation/solana-web3.js/blob/maintenance/v1.x/src/programs/address-lookup-table/state.ts#L64
struct BorshEncoder {
  func encode<T>(_ value: T) throws -> Data where T : BorshSerializable {
    var writer = Data()
    try value.serialize(to: &writer)
    return writer
  }
}

// MARK: - Address Lookup Table Types

public struct AddressLookupTableAccount {
    public static let lookUpTableMetaSize = 56
    public let key: SolanaPublicKey
    public let state: AddressLookupTableState
    
    public init(key: SolanaPublicKey, state: AddressLookupTableState) {
        self.key = key
        self.state = state
    }
    var isActive: Bool {
        return state.deactivationSlot == UInt64.max
    }
}

extension AddressLookupTableAccount {
    public static func parse(base64Data: String, lookupTableKey: SolanaPublicKey) throws -> AddressLookupTableAccount {
        // Base64 解码
        guard let data = Data(base64Encoded: base64Data) else {
            throw ParseError.invalidBase64
        }
        let state = try BorshDecoder.decode(AddressLookupTableState.self, from: data)
        return AddressLookupTableAccount(key: lookupTableKey, state: state)
    }
    
    public enum ParseError: Error, LocalizedError {
        case invalidBase64
        case decodingFailed(Error)
        public var errorDescription: String? {
            switch self {
            case .invalidBase64:
                return "Invalid Base64 encoding"
            case .decodingFailed(let error):
                return "Borsh decoding failed: \(error.localizedDescription)"
            }
        }
    }
}

public struct AddressLookupTableState: BorshCodable {
    public let deactivationSlot: UInt64
    public let lastExtendedSlot: UInt64
    public let lastExtendedSlotStartIndex: UInt8
    public let authority: SolanaPublicKey?
    public let addresses: [SolanaPublicKey]
    
    public init(from reader: inout BinaryReader) throws {
        // 1. typeIndex (4 bytes)
        let typeIndex = try UInt32.init(from: &reader)
        guard typeIndex == 1 else {
            throw BorshDecodingError.unknownData
        }
        
        // 2. deactivation_slot (8 bytes)
        self.deactivationSlot = try UInt64.init(from: &reader)
        
        // 3. last_extended_slot (8 bytes)
        self.lastExtendedSlot = try UInt64.init(from: &reader)
        
        // 4. last_extended_slot_start_index (1 byte)
        self.lastExtendedSlotStartIndex = try UInt8.init(from: &reader)
        
        // 5. authority (Option<Pubkey>)
        let hasAuthority = try UInt8.init(from: &reader)
        if hasAuthority == 1 {
            self.authority = try SolanaPublicKey.init(from: &reader)
        } else {
            self.authority = nil
        }
        _ = try UInt16.init(from: &reader)
        var addresses: [SolanaPublicKey] = []
        let remainingBytes = reader.bytes.count - reader.cursor
        let addressCount = remainingBytes / 32
        for _ in 0..<addressCount {
            guard reader.cursor + 32 <= reader.bytes.count else {
                break
            }
            let addressBytes = Array(reader.bytes[reader.cursor..<(reader.cursor + 32)])
            reader.cursor += 32
            addresses.append(SolanaPublicKey(data: Data(addressBytes)))
        }
        self.addresses = addresses
    }

    
    public func serialize(to writer: inout Data) throws {
        try UInt32(1).serialize(to: &writer)  // typeIndex
        try deactivationSlot.serialize(to: &writer)
        try lastExtendedSlot.serialize(to: &writer)
        try lastExtendedSlotStartIndex.serialize(to: &writer)
        
        if let auth = authority {
            try UInt8(1).serialize(to: &writer)
            try auth.serialize(to: &writer)
        } else {
            try UInt8(0).serialize(to: &writer)
        }
        // padding
        try UInt16(0).serialize(to: &writer)
        try addresses.serialize(to: &writer)
    }
}
// MARK: - Helper Extensions

private extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Message V0

public struct SolanaMessage_V0: SolanaMessage {
    public var version: SolanaMessageVersion { return .v0 }
    
    public var header: SolanaMessageHeader
    public var staticAccountKeys: [SolanaPublicKey]
    public var recentBlockhash: SolanaBlockHash = .EMPTY
    public var compiledInstructions: [SolanaMessageCompiledInstruction]
    public var addressTableLookups: [SolanaMessageAddressTableLookup]?
    
    public init(
        _ instructions: [SolanaMessageInstruction],
        feePayer: SolanaPublicKey,
        addressLookupTableAccounts: [AddressLookupTableAccount]? = nil,
        recentBlockhash: SolanaBlockHash = .EMPTY
    ) throws  {
        var compiledKeys = CompiledKeys.compile(instructions: instructions, payer: feePayer)
        var addressTableLookups: [SolanaMessageAddressTableLookup] = []
        var accountKeysFromLookups: AccountKeysFromLookups = .init(readonly: [], writable: [])
        let lookupTableAccounts = addressLookupTableAccounts ?? []
        for lookupTable in lookupTableAccounts {
            if let extractResult = try compiledKeys.extractTableLookup(lookupTable: lookupTable) {
                addressTableLookups.append(extractResult.0)
                accountKeysFromLookups.writable.append(contentsOf: extractResult.1.writable)
                accountKeysFromLookups.readonly.append(contentsOf: extractResult.1.readonly)
            }
        }
        let (header, staticAccountKeys) = compiledKeys.getMessageComponents()
        let accountKeys = MessageAccountKeys(
            staticAccountKeys: staticAccountKeys,
            accountKeysFromLookups: accountKeysFromLookups
        )
        let compiledInstructions = try accountKeys.compileInstructions(instructions: instructions)
        self.header = header
        self.staticAccountKeys = staticAccountKeys
        self.compiledInstructions = compiledInstructions
        self.addressTableLookups = addressTableLookups
        self.recentBlockhash = recentBlockhash
    }
    
    // MARK: - Serialization
    
    public func serialize(to writer: inout Data) throws {
        try self.version.byte!.serialize(to: &writer)
        try self.header.serialize(to: &writer)
        try self.staticAccountKeys.serialize(to: &writer)
        try self.recentBlockhash.serialize(to: &writer)
        try self.compiledInstructions.serialize(to: &writer)
        
        if let lookups = self.addressTableLookups {
            try lookups.serialize(to: &writer)
        } else {
            try [SolanaMessageAddressTableLookup]().serialize(to: &writer)
        }
    }
    
    public init(from reader: inout BinaryReader) throws {
        let versionByte = try UInt8.init(from: &reader)
        guard versionByte == SolanaMessageVersion.v0.byte else { throw BorshDecodingError.unknownData }
        
        self.header = try .init(from: &reader)
        self.staticAccountKeys = try .init(from: &reader)
        self.recentBlockhash = try .init(from: &reader)
        self.compiledInstructions = try .init(from: &reader)
        
        let lookups: [SolanaMessageAddressTableLookup] = try .init(from: &reader)
        self.addressTableLookups = lookups.isEmpty ? nil : lookups
    }
}

// MARK: - Human Readable Extension

extension SolanaMessage_V0 {
    public func toHuman() -> Any {
        var instructions: [SolanaInstruction] = []
        for i in compiledInstructions {
            guard Int(i.programIdIndex) < self.staticAccountKeys.count else { continue }
            let programId = self.staticAccountKeys[Int(i.programIdIndex)]
            let decodeInstruction = SolanaMessage_V0.decode(programId: programId, data: i.data, signers: [])
            instructions.append(decodeInstruction)
        }
        return [
            "instructions": instructions.map({$0.toHuman()}),
            "recentBlockhash": recentBlockhash.description
        ]
    }
    
    static func decode(programId: SolanaPublicKey, data: Data, signers: [SolanaSigner]) -> SolanaInstruction {
        if programId == SolanaPublicKey.SYSTEM_PROGRAM_ID {
            if var i = try? BorshDecoder.decode(SolanaInstructionTransfer.self, from: data) {
                i.signers = signers
                return i
            }
        } else if programId == SolanaPublicKey.TOKEN_PROGRAM_ID {
            if var i = try? BorshDecoder.decode(SolanaInstructionToken.self, from: data) {
                i.signers = signers
                return i
            }
        } else if programId == SolanaPublicKey.ASSOCIATED_TOKEN_PROGRAM_ID {
            if var i = try? BorshDecoder.decode(SolanaInstructionAssociatedAccount.self, from: data){
                i.signers = signers
                return i
            }
        } else if programId == SolanaPublicKey.OWNER_VALIDATION_PROGRAM_ID {
            if var i = try? BorshDecoder.decode(SolanaInstructionAssetOwner.self, from: data) {
                i.signers = signers
                return i
            }
        } else if programId == SolanaPublicKey.TOKEN2022_PROGRAM_ID {
            if var i = try? BorshDecoder.decode(SolanaInstructionToken2022.self, from: data) {
                i.signers = signers
                return i
            }
        }
        return SolanaInstructionRaw(programId: programId, signers: signers, data: data)
    }
}
