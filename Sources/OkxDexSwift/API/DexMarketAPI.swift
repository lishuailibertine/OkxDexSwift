//
//  DexMarketAPI.swift
//  OkxDexSwift
//
//  Created by li shuai on 2025/12/23.
//
import Foundation
extension DexAPI {
    // https://web3.okx.com/api/v6/dex/market/supported/chain
    public func getSupportedChains() async throws -> APIResponse<OKXSupportedChain> {
        return try await client.request(method: "GET", path: "/api/v6/dex/market/supported/chain", params: [:])
    }
    
    // POST https://web3.okx.com/api/v6/dex/market/price
    public func getMarketPrice(requests: [OKXMarketPriceRequest]) async throws -> APIResponse<OKXMarketPriceResponse> {
        let body = try requests.toBody()
        return try await client.request(method: "POST", path: "/api/v6/dex/market/price", body: body)
    }
    
    // https://web3.okx.com/api/v6/dex/market/token/search
    public func searchTokens(request: OKXSearchRequest) async throws -> APIResponse<OKXTokenItem> {
        let params = try request.toDictionary()
        return try await client.request(method: "GET", path: "/api/v6/dex/market/token/search", params: params)
    }
    
    // https://web3.okx.com/api/v6/dex/market/token/basic-info
    public func getTokenBasicInfo(requests: [OKXBaseInfoRequest]) async throws -> APIResponse<OKXTokenBaseInfoItem> {
        let body = try requests.toBody()
        return try await client.request(method: "POST", path: "/api/v6/dex/market/token/basic-info", body: body)
    }
    
    // https://web3.okx.com/api/v6/dex/balance/supported/chain
    public func getSupportedBalanceChains() async throws -> APIResponse<OKXBalanceSupportedChain> {
        return try await client.request(method: "GET", path: "/api/v6/dex/balance/supported/chain", params: [:])
    }
    
    // 获取地址下全量代币和 Defi 资产总余额。https://web3.okx.com/api/v6/dex/balance/total-value-by-address
    public func getAddressBalance(request: OKXAddressBalanceRequest) async throws -> APIResponse<OKXAddressBalanceResponse> {
        let params = try request.toDictionary()
        return try await client.request(method: "GET", path: "/api/v6/dex/balance/total-value-by-address", params: params)
    }
    
    // 查询地址持有的多个链或指定链的代币 余额列表。
    // https://web3.okx.com/api/v6/dex/balance/all-token-balances-by-address
    public func getAddressTokenBalances(request: OKXAddressTokenBalanceRequest) async throws -> APIResponse<OKXAddressTokenBalanceResponse> {
        let params = try request.toDictionary()
        return try await client.request(method: "GET", path: "/api/v6/dex/balance/all-token-balances-by-address", params: params)
    }
    
    // 查询地址下指定代币的余额。
    // https://web3.okx.com/api/v6/dex/balance/token-balances-by-address
    public func getAddressSpecificTokenBalance(request: OKXSpecificTokenBalanceRequest) async throws -> APIResponse<OKXAddressTokenBalanceResponse> {
        let body = try request.toBody()
        return try await client.request(method: "POST", path: "/api/v6/dex/balance/token-balances-by-address", body: body)
    }
    
    // 查询地址维度下的6个月内的交易历史，按时间倒序排列
    // https://web3.okx.com/api/v6/dex/post-transaction/transactions-by-address
    public func getAddressTransactionHistory(request: OKXTransactionsHistoryRequest) async throws -> APIResponse<OKXTransactionsHistoryResponse> {
        let params = try request.toDictionary()
        return try await client.request(method: "GET", path: "/api/v6/dex/post-transaction/transactions-by-address", params: params)
    }
    
    //根据 txHash 查询6个月内的某个交易的详情。
    // https://web3.okx.com/api/v6/dex/post-transaction/transaction-detail-by-txhash
    public func getTransactionDetailByHash(request: OKXTransactionDetailRequest) async throws -> APIResponse<OKXTransactionDetailResponse> {
        let params = try request.toDictionary()
        return try await client.request(method: "GET", path: "/api/v6/dex/post-transaction/transaction-detail-by-txhash", params: params)
    }
}
