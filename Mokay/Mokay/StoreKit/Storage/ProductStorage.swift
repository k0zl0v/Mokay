//
//  ProductStorage.swift
//  Mokay
//
//  Created by Дмитрий Бондаренко on 07.12.24.
//

import Foundation

public actor ProductStorage {
    
    private let productStatusKey = "com.Mokay.Products"
    
    private let userDefaults: UserDefaults
    private let productIds: [String]
    
    // MARK: - Init
    
    public init(
        appGroupId: String,
        productIds: [String]
    ) {
        guard let userDefaults = UserDefaults(suiteName: appGroupId) else {
            fatalError("Failed to init UserDefaults with app group id: \(appGroupId)")
        }
        
        self.userDefaults = userDefaults
        self.productIds = productIds
    }
    
    // MARK: - Public methods
    
    public func getProductIds() -> [String] {
        return productIds
    }
    
    public func getProduct(with productId: String) -> StoredProductModel? {
        let products = loadProducts()
        return products.first { $0.id == productId }
    }
    
    public func saveProduct(_ product: StoredProductModel) {
        var storedProducts = loadProducts()
        
        if let productCopyIndex = storedProducts.firstIndex(where: { $0.id == product.id }) {
            storedProducts[productCopyIndex] = product
        } else {
            storedProducts.append(product)
        }
        
        userDefaults.set(storedProducts, forKey: productStatusKey)
    }
    
    // MARK: - Private methods
    
    private func loadProducts() -> [StoredProductModel] {
        return userDefaults.array(forKey: productStatusKey) as? [StoredProductModel] ?? []
    }
    
}
