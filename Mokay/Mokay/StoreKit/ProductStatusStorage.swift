//
//  ProdactStatusStorage.swift
//  Mokay
//
//  Created by Дмитрий Бондаренко on 07.12.24.
//

import Foundation

public final class ProductStatusStorage {
    
    // MARK: - Private properties
    
    private let userDefaults: UserDefaults
    private let productStatusKey = "ProductStatusKey"
    
    // MARK: - Init
    
    init(appGroupId: String) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            fatalError("Failed to init UserDefaults with app group id: \(appGroupId)")
        }
        
        self.userDefaults = userDefaults
    }
    
    // MARK: - Public methods
    
    public func isProductPurchased(productId: String) -> Bool {
        let currentStatuses = loadProductStatuses()
        return currentStatuses[productId] ?? false
    }
    
    public func saveProductStatus(
        productID: String,
        isPurchased: Bool
    ) {
        var currentStatuses = loadProductStatuses()
        currentStatuses[productID] = isPurchased
        userDefaults.set(currentStatuses, forKey: productStatusKey)
    }
    
    // MARK: - Private methods
    
    private func loadProductStatuses() -> [String: Bool] {
        return userDefaults.dictionary(forKey: productStatusKey) as? [String: Bool] ?? [:]
    }
    
}
