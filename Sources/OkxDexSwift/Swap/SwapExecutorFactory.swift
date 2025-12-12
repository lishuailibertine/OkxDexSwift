import Foundation

/// Factory for creating appropriate swap executors based on chain index
public class SwapExecutorFactory {
    
    /// Create a swap executor for the given chain
    public static func createExecutor(chainIndex: String, config: OKXConfig, networkConfig: ChainConfig) throws -> SwapExecutor {
        switch chainIndex {
        case "501": // Solana
            return SolanaSwapExecutor(config: config, networkConfig: networkConfig)
        case "784":
            return SuiSwapExecutor(config: config, networkConfig: networkConfig)
        case "196", // X Layer
             "1", // Ethereum
             "137", // Polygon
             "146", // Sonic
             "8453", // Base
             "10", // Optimism
             "42161", // Arbitrum
             "56", // Binance Smart Chain
             "100", // Gnosis
             "169", // Manta Pacific
             "250", // Fantom Opera
             "324", // zkSync Era
             "1101", // Polygon zkEVM
             "5000", // Mantle
             "43114", // Avalanche C-Chain
             "25", // Cronos
             "534352", // Scroll
             "59144", // Linea
             "1088", // Metis
             "1030", // Conflux
             "81457", // Blast
             "7000", // Zeta Chain
             "66": // OKT Chain
            return EVMSwapExecutor(config: config, networkConfig: networkConfig)
        default:
            throw NSError(domain: "SwapExecutorFactory", code: 1, userInfo: [NSLocalizedDescriptionKey: "Chain \(chainIndex) not supported for swap execution"])
        }
    }
    
    /// Create an approve executor for EVM chains
    public static func createApproveExecutor(chainIndex: String, config: OKXConfig, networkConfig: ChainConfig) throws -> EVMApproveExecutor {
        switch chainIndex {
        case "196", // X Layer
             "1", // Ethereum
             "137", // Polygon
             "146", // Sonic
             "8453", // Base
             "10", // Optimism
             "42161", // Arbitrum
             "56", // Binance Smart Chain
             "100", // Gnosis
             "169", // Manta Pacific
             "250", // Fantom Opera
             "324", // zkSync Era
             "1101", // Polygon zkEVM
             "5000", // Mantle
             "43114", // Avalanche C-Chain
             "25", // Cronos
             "534352", // Scroll
             "59144", // Linea
             "1088", // Metis
             "1030", // Conflux
             "81457", // Blast
             "7000", // Zeta Chain
             "66": // OKT Chain
            return EVMApproveExecutor(config: config, networkConfig: networkConfig)
        default:
            throw NSError(domain: "SwapExecutorFactory", code: 1, userInfo: [NSLocalizedDescriptionKey: "Chain \(chainIndex) not supported for approve execution"])
        }
    }
}
