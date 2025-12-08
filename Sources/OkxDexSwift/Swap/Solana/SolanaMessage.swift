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
    public let key: SolanaPublicKey
    public let state: AddressLookupTableState
    
    public init(key: SolanaPublicKey, state: AddressLookupTableState) {
        self.key = key
        self.state = state
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

public struct AddressLookupTableState: BorshCodable{
    public let deactivationSlot: UInt64
    public let lastExtendedSlot: UInt64
    public let lastExtendedSlotStartIndex: UInt8
    public let authority: SolanaPublicKey?
    public let addresses: [SolanaPublicKey]
    private let discriminator: UInt8
    private let _padding: UInt16
    
    public init(
        discriminator: UInt8 = 1,
        deactivationSlot: UInt64 = UInt64.max,
        lastExtendedSlot: UInt64 = 0,
        lastExtendedSlotStartIndex: UInt8 = 0,
        authority: SolanaPublicKey? = nil,
        addresses: [SolanaPublicKey]
    ) {
        self.discriminator = discriminator
        self.deactivationSlot = deactivationSlot
        self.lastExtendedSlot = lastExtendedSlot
        self.lastExtendedSlotStartIndex = lastExtendedSlotStartIndex
        self.authority = authority
        self._padding = 0
        self.addresses = addresses
    }
    
    // MARK: - BorshCodable
    
    public func serialize(to writer: inout Data) throws {
        try discriminator.serialize(to: &writer)
        try deactivationSlot.serialize(to: &writer)
        try lastExtendedSlot.serialize(to: &writer)
        try lastExtendedSlotStartIndex.serialize(to: &writer)
        if let auth = authority {
            try UInt8(1).serialize(to: &writer)  // Some
            try auth.serialize(to: &writer)
        } else {
            try UInt8(0).serialize(to: &writer)  // None
        }
        try _padding.serialize(to: &writer)
        try addresses.serialize(to: &writer)
    }
    
    public init(from reader: inout BinaryReader) throws {
        // 1. discriminator
        self.discriminator = try .init(from: &reader)
        guard discriminator == 1 else {
            throw BorshDecodingError.unknownData
        }
        self.deactivationSlot = try .init(from: &reader)
        self.lastExtendedSlot = try .init(from: &reader)
        self.lastExtendedSlotStartIndex = try .init(from: &reader)
        let hasAuthority = try UInt8.init(from: &reader)
        if hasAuthority == 1 {
            self.authority = try .init(from: &reader)
        } else {
            self.authority = nil
        }
        self._padding = try .init(from: &reader)
        self.addresses = try .init(from: &reader)
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
        feePayer: SolanaPublicKey? = nil,
        addressLookupTableAccounts: [AddressLookupTableAccount]? = nil
    ) throws {
        // First, build the basic message structure
        var tempSigners = [SolanaSigner]()
        tempSigners.append(contentsOf: instructions.flatMap({ $0.accounts }))
        tempSigners.append(contentsOf: instructions.map({ SolanaSigner(publicKey: $0.programId) }))
        
        // Deduplication
        var signers = [SolanaSigner]()
        for s in tempSigners {
            if let i = signers.firstIndex(of: s) {
                signers[i].isSigner = signers[i].isSigner || s.isSigner
                signers[i].isWritable = signers[i].isWritable || s.isWritable
            } else {
                signers.append(s)
            }
        }
        
        // Sorted
        signers = signers.sorted(by: <)
        
        // Move fee payer to the front
        if let payer = feePayer, let i = signers.map({ $0.publicKey }).firstIndex(of: payer), i > 0 {
            signers.remove(at: i)
            signers.insert(SolanaSigner(publicKey: payer, isSigner: true, isWritable: true), at: 0)
        }
        
        // If no lookup tables, use simple compilation
        guard let lookupTables = addressLookupTableAccounts, !lookupTables.isEmpty else {
            throw NSError.init(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Address lookup tables are required for V0 message optimization"])
        }
        
        // With lookup tables - extract and optimize
        
        
        // Helper function to find signer by public key
        func findSigner(_ pubkey: SolanaPublicKey) -> SolanaSigner? {
            return signers.first(where: { $0.publicKey == pubkey })
        }
        
        // Process lookup tables
        var addressTableLookups: [SolanaMessageAddressTableLookup] = []
        var accountsInLookupTables: [SolanaPublicKey] = []
        
        for lookupTable in lookupTables {
            var writableIndexes: [UInt8] = []
            var readonlyIndexes: [UInt8] = []
            
            for (lookupIndex, lookupAddress) in lookupTable.state.addresses.enumerated() {
                guard let signer = findSigner(lookupAddress) else {
                    continue
                }
                
                // Signers cannot be in lookup tables
                if signer.isSigner {
                    continue
                }
                
                if signer.isWritable {
                    writableIndexes.append(UInt8(lookupIndex))
                } else {
                    readonlyIndexes.append(UInt8(lookupIndex))
                }
                
                accountsInLookupTables.append(lookupAddress)
            }
            
            if !writableIndexes.isEmpty || !readonlyIndexes.isEmpty {
                addressTableLookups.append(
                    SolanaMessageAddressTableLookup(
                        accountKey: lookupTable.key,
                        writableIndexes: writableIndexes,
                        readonlyIndexes: readonlyIndexes
                    )
                )
            }
        }
        
        // Build new static account keys (excluding those in lookup tables)
        var newStaticAccountKeys: [SolanaPublicKey] = []
        var accountIndexMapping: [(key: SolanaPublicKey, index: Int)] = []
        
        // Add all signers first
        for signer in signers where signer.isSigner {
            accountIndexMapping.append((key: signer.publicKey, index: newStaticAccountKeys.count))
            newStaticAccountKeys.append(signer.publicKey)
        }
        
        // Add non-signers not in lookup tables
        for signer in signers where !signer.isSigner {
            let isInLookup = accountsInLookupTables.contains(where: { $0 == signer.publicKey })
            if !isInLookup {
                accountIndexMapping.append((key: signer.publicKey, index: newStaticAccountKeys.count))
                newStaticAccountKeys.append(signer.publicKey)
            }
        }
        
        // Add lookup table accounts to index mapping
        var lookupTableAccountIndex = newStaticAccountKeys.count
        for lookupTable in addressTableLookups {
            let lookupTableState = lookupTables.first(where: { $0.key == lookupTable.accountKey })?.state
            
            for index in lookupTable.writableIndexes {
                if let address = lookupTableState?.addresses[safe: Int(index)] {
                    accountIndexMapping.append((key: address, index: lookupTableAccountIndex))
                    lookupTableAccountIndex += 1
                }
            }
            
            for index in lookupTable.readonlyIndexes {
                if let address = lookupTableState?.addresses[safe: Int(index)] {
                    accountIndexMapping.append((key: address, index: lookupTableAccountIndex))
                    lookupTableAccountIndex += 1
                }
            }
        }
        
        // Helper to find new index
        func findNewIndex(_ pubkey: SolanaPublicKey) -> Int? {
            return accountIndexMapping.first(where: { $0.key == pubkey })?.index
        }
        
        // Compile instructions with new indexes
        var newCompiledInstructions: [SolanaMessageCompiledInstruction] = []
        for instruction in instructions {
            guard let newProgramIdIndex = findNewIndex(instruction.programId) else {
                throw NSError(
                    domain: "SolanaMessageV0",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Program ID not found in account index map"]
                )
            }
            
            var newAccountKeyIndexes: [UInt8] = []
            for account in instruction.accounts {
                guard let newIndex = findNewIndex(account.publicKey) else {
                    throw NSError(
                        domain: "SolanaMessageV0",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Account key not found in account index map"]
                    )
                }
                newAccountKeyIndexes.append(UInt8(newIndex))
            }
            
            let data = try BorshEncoder().encode(instruction.data)
            newCompiledInstructions.append(
                SolanaMessageCompiledInstruction(
                    programIdIndex: UInt8(newProgramIdIndex),
                    accountKeyIndexes: newAccountKeyIndexes,
                    data: data
                )
            )
        }
        
        // Recalculate header
        var newNumReadonlySignedAccounts = 0
        var newNumReadonlyUnsignedAccounts = 0
        
        for pubkey in newStaticAccountKeys {
            if let signer = findSigner(pubkey) {
                if signer.isSigner && !signer.isWritable {
                    newNumReadonlySignedAccounts += 1
                } else if !signer.isSigner && !signer.isWritable {
                    newNumReadonlyUnsignedAccounts += 1
                }
            }
        }
        let numSigners = signers.filter({ $0.isSigner }).count
        self.header = SolanaMessageHeader(
            numRequiredSignatures: UInt8(numSigners),
            numReadonlySignedAccounts: UInt8(newNumReadonlySignedAccounts),
            numReadonlyUnsignedAccounts: UInt8(newNumReadonlyUnsignedAccounts)
        )
        self.staticAccountKeys = newStaticAccountKeys
        self.compiledInstructions = newCompiledInstructions
        self.addressTableLookups = addressTableLookups.isEmpty ? nil : addressTableLookups
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
