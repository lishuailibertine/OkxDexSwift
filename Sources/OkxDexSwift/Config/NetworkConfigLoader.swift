import Foundation

/// 网络配置加载器
public class NetworkConfigLoader {
    
    /// 网络配置加载错误
    public enum LoadError: Error, LocalizedError {
        case fileNotFound
        case invalidJSON
        case decodingFailed(Error)
        
        public var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "找不到网络配置文件"
            case .invalidJSON:
                return "无效的 JSON 格式"
            case .decodingFailed(let error):
                return "解码失败: \(error.localizedDescription)"
            }
        }
    }
    
    /// 从 Bundle 加载默认网络配置
    /// - Parameters:
    ///   - bundle: Bundle 实例，默认为 module bundle
    ///   - filename: 配置文件名，默认为 "network-configs"
    /// - Returns: 网络配置字典
    /// - Throws: LoadError
    public static func loadDefaultConfigs(
        from bundle: Bundle? = nil,
        filename: String = "network-configs"
    ) throws -> NetworkConfigs {
        // 在 Swift Package 中，使用 module bundle
        let resourceBundle = bundle ?? Bundle.module
        
        guard let url = resourceBundle.url(forResource: filename, withExtension: "json") else {
            throw LoadError.fileNotFound
        }
        
        return try loadConfigs(from: url)
    }
    
    /// 从文件路径加载网络配置
    /// - Parameter path: JSON 文件路径
    /// - Returns: 网络配置字典
    /// - Throws: LoadError
    public static func loadConfigs(fromPath path: String) throws -> NetworkConfigs {
        let url = URL(fileURLWithPath: path)
        return try loadConfigs(from: url)
    }
    
    /// 从 URL 加载网络配置
    /// - Parameter url: JSON 文件 URL
    /// - Returns: 网络配置字典
    /// - Throws: LoadError
    public static func loadConfigs(from url: URL) throws -> NetworkConfigs {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let configs = try decoder.decode(NetworkConfigs.self, from: data)
            return configs
        } catch let error as DecodingError {
            throw LoadError.decodingFailed(error)
        } catch {
            throw LoadError.invalidJSON
        }
    }
    
    /// 从 JSON 字符串加载网络配置
    /// - Parameter jsonString: JSON 字符串
    /// - Returns: 网络配置字典
    /// - Throws: LoadError
    public static func loadConfigs(fromJSONString jsonString: String) throws -> NetworkConfigs {
        guard let data = jsonString.data(using: .utf8) else {
            throw LoadError.invalidJSON
        }
        
        do {
            let decoder = JSONDecoder()
            let configs = try decoder.decode(NetworkConfigs.self, from: data)
            return configs
        } catch let error as DecodingError {
            throw LoadError.decodingFailed(error)
        } catch {
            throw LoadError.invalidJSON
        }
    }
    
    /// 获取指定链的配置
    /// - Parameters:
    ///   - chainId: 链 ID
    ///   - configs: 网络配置字典
    /// - Returns: 链配置，如果不存在则返回 nil
    public static func getConfig(forChain chainId: String, from configs: NetworkConfigs) -> ChainConfig? {
        return configs[chainId]
    }
    
    /// 获取所有支持的链 ID
    /// - Parameter configs: 网络配置字典
    /// - Returns: 链 ID 数组
    public static func getSupportedChainIds(from configs: NetworkConfigs) -> [String] {
        return Array(configs.keys).sorted()
    }
}
