//
//  SolanaSwapInstructionConverter.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/8.
//
import Foundation
import SolanaSwift

public struct RawInstructionData: BorshCodable {
    public let bytes: [UInt8]
    
    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    public init(data: Data) {
        self.bytes = [UInt8](data)
    }
    
    public func serialize(to writer: inout Data) throws {
        writer.append(self.bytes, count: self.bytes.count)
    }
    
    public init(from reader: inout BinaryReader) throws {
        self.bytes = try .init(from: &reader)
    }
}

extension SolanaSwapInstructionData {
    public func toMessageInstructions() throws -> [SolanaMessageInstruction] {
        var instructions: [SolanaMessageInstruction] = []
        for item in instructionLists {
            guard let programId = SolanaPublicKey(base58String: item.programId) else {
                throw ConversionError.invalidProgramId(item.programId)
            }
            var accounts: [SolanaSigner] = []
            for account in item.accounts {
                guard let publicKey = SolanaPublicKey(base58String: account.pubkey) else {
                    throw ConversionError.invalidPublicKey(account.pubkey)
                }
                let signer = SolanaSigner(
                    publicKey: publicKey,
                    isSigner: account.isSigner,
                    isWritable: account.isWritable
                )
                accounts.append(signer)
            }
            guard let data = Data(base64Encoded: item.data) else {
                throw ConversionError.invalidBase64Data
            }
            let instructionData = RawInstructionData(data: data)
            let instruction = SolanaMessageInstruction(
                programId: programId,
                accounts: accounts,
                data: instructionData
            )
            instructions.append(instruction)
        }
        return instructions
    }
    
    /// 转换错误
    public enum ConversionError: Error, LocalizedError {
        case invalidProgramId(String)
        case invalidPublicKey(String)
        case invalidBase64Data
        
        public var errorDescription: String? {
            switch self {
            case .invalidProgramId(let id):
                return "Invalid program ID: \(id)"
            case .invalidPublicKey(let key):
                return "Invalid public key: \(key)"
            case .invalidBase64Data:
                return "Invalid Base64 encoded data"
            }
        }
    }
}

extension SolanaSwapInstructionData {
    public func createV0Message(
        feePayer: SolanaPublicKey,
        recentBlockhash: SolanaBlockHash,
        lookupTables: [AddressLookupTableAccount]? = nil
    ) throws -> SolanaV0Message {
        let instructions = try self.toMessageInstructions()
        var message = try SolanaV0Message(
            instructions,
            feePayer: feePayer,
            addressLookupTableAccounts: lookupTables
        )
        message.recentBlockhash = recentBlockhash
        return message
    }
}
