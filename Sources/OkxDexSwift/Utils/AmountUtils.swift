import Foundation

/// Convert lamports to SOL
/// - Parameter lamports: Amount in lamports (1 SOL = 1e9 lamports)
/// - Returns: Amount in SOL
public func lamportsToSol(_ lamports: String) -> Double {
    guard let lamportsNum = Double(lamports) else { return 0 }
    return lamportsNum / 1e9
}

public func lamportsToSol(_ lamports: Int) -> Double {
    return Double(lamports) / 1e9
}

/// Convert SOL to lamports
/// - Parameter sol: Amount in SOL
/// - Returns: Amount in lamports
public func solToLamports(_ sol: String) -> String {
    guard let solNum = Double(sol) else { return "0" }
    return String(Int(solNum * 1e9))
}

public func solToLamports(_ sol: Double) -> String {
    return String(Int(sol * 1e9))
}
