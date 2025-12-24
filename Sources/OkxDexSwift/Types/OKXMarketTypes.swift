//
//  OKXMarketTypes.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/23.
//
import Foundation

/// 支持的区块链信息数据模型
public struct OKXSupportedChain: Codable {
    /// 区块链索引
    public let chainIndex: String
    /// 区块链名称
    public let chainName: String
    /// 区块链图标链接
    public let chainLogoUrl: String
    /// 区块链符号
    public let chainSymbol: String
    public init(chainIndex: String, chainName: String, chainLogoUrl: String, chainSymbol: String) {
        self.chainIndex = chainIndex
        self.chainName = chainName
        self.chainLogoUrl = chainLogoUrl
        self.chainSymbol = chainSymbol
    }
}

/// 代币市场价格数据模型
public struct OKXMarketPriceResponse: Codable {
    /// 区块链索引
    public let chainIndex: String
    /// 代币合约地址
    public let tokenContractAddress: String
    /// 价格更新时间戳
    public let time: String
    /// 代币当前价格（USD）
    public let price: String
}

public struct OKXMarketPriceRequest: Codable {
    /// 区块链索引
    public let chainIndex: String
    /// 代币合约地址
    public let tokenContractAddress: String
    public init(chainIndex: String, tokenContractAddress: String) {
        self.chainIndex = chainIndex
        self.tokenContractAddress = tokenContractAddress
    }
}

public struct OKXSearchRequest: Codable {
    /// 搜索关键词
    public let search: String
    public let chains: String
    public init(search: String, chains: String) {
        self.search = search
        self.chains = chains
    }
}
    
/// 单个代币详情模型
public struct OKXTokenItem: Codable {
    /// 链索引（如 "1"=以太坊主网，"10"=Optimism 链）
    public let chainIndex: String
    /// 价格涨跌幅（如 "1.02" 表示涨1.02%，空字符串表示无数据）
    public let change: String
    /// 代币小数位数（如 "18"、"9"，需根据业务场景决定是否转 Int）
    public let decimal: String
    /// 区块链浏览器链接（查看代币详情的URL）
    public let explorerUrl: String
    /// 持币人数（空字符串表示无数据）
    public let holders: String
    /// 流动性（数值字符串，需根据业务场景决定是否转 Double）
    public let liquidity: String
    /// 市值（数值字符串，需根据业务场景决定是否转 Double）
    public let marketCap: String
    /// 代币当前价格（数值字符串，需根据业务场景决定是否转 Double）
    public let price: String
    /// 代币标签信息（如社区是否认可）
    public let tagList: OKXTokenTag
    /// 代币合约地址（唯一标识）
    public let tokenContractAddress: String
    /// 代币Logo图片URL
    public let tokenLogoUrl: String
    /// 代币名称（如 "Wrapped Ether"）
    public let tokenName: String
    /// 代币符号（如 "WETH"）
    public let tokenSymbol: String
}

/// 代币标签模型（标记代币的特殊属性）
public struct OKXTokenTag: Codable {
    /// 是否为社区认可代币（true=认可，false=未认可）
    public let communityRecognized: Bool
}

public struct OKXBaseInfoRequest: Codable {
    /// 区块链索引
    public let chainIndex: String
    /// 代币合约地址
    public let tokenContractAddress: String
    public init(chainIndex: String, tokenContractAddress: String) {
        self.chainIndex = chainIndex
        self.tokenContractAddress = tokenContractAddress
    }
}
     
/// 单个代币信息模型
public struct OKXTokenBaseInfoItem: Codable {
    public let chainIndex: String
    public let decimal: String
    public let tagList: OKXTokenTag
    public let tokenContractAddress: String
    public let tokenLogoUrl: String
    public let tokenName: String
    public let tokenSymbol: String
}

public struct OKXBalanceSupportedChain: Codable {
    public let name: String
    public let logoUrl: String
    public let shortName: String
    public let chainIndex: String
}

// 获取地址下全量代币和 Defi 资产总余额。
public struct OKXAddressBalanceRequest: Codable {
    public let address: String
    public let chains: String
    // 0：查询所有资产总余额，包括代币和 defi 资产  1：只查代币总余额 2：只查 defi 总余额
    public let assetType: String?
    // 是否过滤风险空投代币和貔貅盘代币。默认过滤
    public let excludeRiskToken: Bool?
    public init(address: String, chains: String, assetType: String? = nil, excludeRiskToken: Bool? = nil) {
        self.address = address
        self.chains = chains
        self.assetType = assetType
        self.excludeRiskToken = excludeRiskToken
    }
}

public struct OKXAddressBalanceResponse: Codable {
    public let totalValue: String
}

// 查询地址持有的多个链或指定链的代币 余额列表。
public struct OKXAddressTokenBalanceRequest: Codable {
    public let address: String
    public let chains: String
    // 是否过滤风险空投代币和貔貅盘代币。默认过滤
    public let excludeRiskToken: Bool?
    public init(address: String, chains: String, excludeRiskToken: Bool? = nil) {
        self.address = address
        self.chains = chains
        self.excludeRiskToken = excludeRiskToken
    }
}

public struct OKXAddressTokenBalanceResponse: Codable {
    public let tokenAssets: [OKXAddressTokenBalanceItem]
}

public struct OKXAddressTokenBalanceItem: Codable {
    public let chainIndex: String
    public let tokenContractAddress: String
    public let symbol: String
    public let balance: String
    public let tokenPrice: String
    public let isRiskToken: Bool
    public let rawBalance: String?
    public let address: String
}

// 查询地址下指定代币的余额。
public struct OKXSpecificTokenBalanceRequest: Codable {
    public let address: String
    public let tokenContractAddresses: [OKXTokenBalanceItem]
    public init(address: String, tokenContractAddresses: [OKXTokenBalanceItem]) {
        self.address = address
        self.tokenContractAddresses = tokenContractAddresses
    }
}

public struct OKXTokenBalanceItem: Codable {
    public let chainIndex: String
    public let tokenContractAddress: String
    public init(chainIndex: String, tokenContractAddress: String) {
        self.chainIndex = chainIndex
        self.tokenContractAddress = tokenContractAddress
    }
}

// 查询地址维度下的6个月内的交易历史，按时间倒序排列。
public struct OKXTransactionsHistoryRequest: Codable {
    public let address: String
    public let chains: String
    // 1：传""代表查询对应链的主链币 2：传具体的代币合约地址，代表查询对应的代币 3：不传，代表查询主链币和所有代币
    public let tokenContractAddress: String?
    public let begin: String?
    public let end: String?
    public let cursor: String?
    public let limit: String?
    public init(address: String, chains: String, tokenContractAddress: String? = nil, begin: String? = nil, end: String? = nil, cursor: String? = nil, limit: String? = nil) {
        self.address = address
        self.chains = chains
        self.tokenContractAddress = tokenContractAddress
        self.begin = begin
        self.end = end
        self.cursor = cursor
        self.limit = limit
    }
}

public struct OKXTransactionsHistoryResponse: Codable {
    public let cursor: String
    public let transactions: [OKXTransactionsHistoryItem]
}

public struct OKXTransactionsHistoryItem: Codable {
    public let chainIndex: String
    public let txHash: String
    public let methodId: String
    public let nonce: String
    public let txTime: String
    public let from: [OKXTransactionsHistoryFromItem]
    public let to: [OKXTransactionsHistoryFromItem]
    public let tokenContractAddress: String
    public let amount: String
    public let symbol: String
    public let txFee: String
    public let txStatus: String
    public let hitBlacklist: Bool
    public let itype: String
}

public struct OKXTransactionsHistoryFromItem: Codable {
    public let address: String
    public let amount: String
}

//根据 txHash 查询6个月内的某个交易的详情。

public struct OKXTransactionDetailRequest: Codable {
    public let chainIndex: String
    public let txHash: String
    public let itype: String?
    public init(chainIndex: String, txHash: String, itype: String? = nil) {
        self.chainIndex = chainIndex
        self.txHash = txHash
        self.itype = itype
    }
}

public struct OKXTransactionDetailResponse: Codable {
    // 链的唯一标识
    public let chainIndex: String
    // 交易发生的区块高度
    public let height: String
    public let txTime: String
    public let txhash: String
    // 1:pending 确认中 2:success：成功 3:fail：失败
    public let txStatus: String
    public let txFee: String
    public let amount: String
    public let symbol: String
    public let fromDetails: [OKXTransactionDetailFromItem]
    public let toDetails: [OKXTransactionDetailToItem]
    public let internalTransactionDetails: [OKXInternalTransactionDetailItem]
    public let tokenTransferDetails: [OKXTokenTransferDetailsItem]
    public let l1OriginHash: String
}

public struct OKXTransactionDetailFromItem: Codable {
    public let address: String
    public let vinIndex: String
    public let preVoutIndex: String
    public let txHash: String
    public let isContract: Bool
    public let amount: String
}

public struct OKXTransactionDetailToItem: Codable {
    public let address: String
    public let voutIndex: String
    public let isContract: Bool
    public let amount: String
}

public struct OKXInternalTransactionDetailItem: Codable {
    public let from: String
    public let to: String
    public let amount: String
    public let isFromContract: Bool
    public let isToContract: Bool
    public let txStatus: String
}

public struct OKXTokenTransferDetailsItem: Codable {
    public let from: String
    public let to: String
    public let amount: String
    public let tokenContractAddress: String
    public let symbol: String
    public let isFromContract: Bool
    public let isToContract: Bool
}
