//
//  AddressLookupTableAccount.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/12.
//
import Foundation
import SolanaSwift

// https://github.com/solana-foundation/solana-web3.js/blob/maintenance/v1.x/src/programs/address-lookup-table/state.ts#L64
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
