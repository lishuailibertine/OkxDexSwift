//
//  SolanaMessage_V0.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/5.
//
import SolanaSwift
import Foundation
// MARK: - Message V0
public struct SolanaV0Message: SolanaMessage {
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

extension SolanaV0Message {
    public func toHuman() -> Any {
        var instructions: [SolanaInstruction] = []
        for i in compiledInstructions {
            guard Int(i.programIdIndex) < self.staticAccountKeys.count else { continue }
            let programId = self.staticAccountKeys[Int(i.programIdIndex)]
            let decodeInstruction = SolanaV0Message.decode(programId: programId, data: i.data, signers: [])
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
