import Foundation

public class OKXDexClient {
    public let config: OKXConfig
    private let httpClient: HTTPClient
    
    public let dex: DexAPI
    public let bridge: BridgeAPI
    
    public init(config: OKXConfig) {
        self.config = config
        self.httpClient = HTTPClient(config: config)
        self.dex = DexAPI(client: httpClient, config: config)
        self.bridge = BridgeAPI(client: httpClient)
    }
}
