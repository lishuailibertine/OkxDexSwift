import Foundation // 原生OrderedDictionary依赖Foundation，必须导入
public struct OrderedDictionary<Key: Hashable, Value> {
    private var keys: [Key] = []
    private var values: [Key: Value] = [:]
    private var keySet: Set<Key> = []
    
    // 下标访问
    subscript(key: Key) -> Value? {
        get { values[key] }
        set {
            if let newValue = newValue {
                if !keySet.contains(key) {
                    keys.append(key)
                    keySet.insert(key)
                }
                values[key] = newValue
            } else {
                keys.removeAll(where: { $0 == key })
                values.removeValue(forKey: key)
                keySet.remove(key)
            }
        }
    }
    
    // 遍历方法
    func forEach(_ body: (Key, Value) throws -> Void) rethrows {
        try keys.forEach { key in
            if let value = values[key] {
                try body(key, value)
            }
        }
    }
    
    // 过滤方法（适配原有filter逻辑）
    func filter(_ isIncluded: (Key, Value) throws -> Bool) rethrows -> OrderedDictionary<Key, Value> {
        var result = OrderedDictionary<Key, Value>()
        try keys.forEach { key in
            if let value = values[key], try isIncluded(key, value) {
                result[key] = value
            }
        }
        return result
    }
    
    // 移除值方法
    mutating func removeValue(forKey key: Key) {
        keys.removeAll(where: { $0 == key })
        values.removeValue(forKey: key)
        keySet.remove(key)
    }
    
    // 键值对映射（适配map(\.key)）
    func map<T>(_ transform: (Key, Value) throws -> T) rethrows -> [T] {
        try keys.compactMap { key in
            if let value = values[key] {
                return try transform(key, value)
            }
            return nil
        }
    }
    
    // 只读属性
    var allKeys: [Key] { keys }
    var allValues: [Value] { keys.compactMap { values[$0] } }
    var count: Int { keys.count }
}
