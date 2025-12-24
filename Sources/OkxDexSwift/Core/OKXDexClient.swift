import Foundation

public class OKXDexClient {
    public var config: OKXConfig
    private var httpClient: HTTPClient
    
    public var dex: DexAPI
    public var bridge: BridgeAPI
    
    public init(config: OKXConfig) {
        self.config = config
        self.httpClient = HTTPClient(config: config)
        self.dex = DexAPI(client: httpClient, config: config)
        self.bridge = BridgeAPI(client: httpClient)
    }
    
    public func updateConfig(_ config: OKXConfig) {
        self.config = config
        self.httpClient = HTTPClient(config: config)
        self.dex = DexAPI(client: httpClient, config: config)
        self.bridge = BridgeAPI(client: httpClient)
    }
}
