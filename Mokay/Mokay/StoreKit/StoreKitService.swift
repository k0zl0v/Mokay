//
//  StoreKitService.swift
//  Mokay
//
//  Created by Дмитрий Бондаренко on 07.12.24.
//

import Combine
import StoreKit

@MainActor
public final class StoreKitService: ObservableObject {
    
    // MARK: - Public properties
    
    @Published var products: [Product] = []
    
    // MARK: - Private properties
    
    private let productStatusStorage: ProductStatusStorage
    private let productIds: [String]
    
    private var updateTask: Task<Void, Never>? = nil
    
    // MARK: - Init
    
    public init(
        productStatusStorage: ProductStatusStorage,
        productIds: [String]
    ) {
        self.productStatusStorage = productStatusStorage
        self.productIds = productIds
        
        updateTask = observeTransactionUpdates()
    }
    
    deinit {
        updateTask?.cancel()
    }
    
    // MARK: - Public methods
    
    public func fetchProducts() async throws {
        do {
            self.products = try await Product.products(for: productIds)
        } catch {
            throw error
        }
    }
    
    public func purhcase(_ product: Product) async throws {
        do {
            let result = try await product.purchase()
            
            switch result {
            case let .success(verificationStatus):
                switch verificationStatus {
                case let .verified(transaction):
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                    
                case let .unverified(_, error):
                    throw error
                }
                
            case .pending:
                break
                
            case .userCancelled:
                throw StoreKitError.userCancelled
                
            @unknown default:
                throw StoreKitError.unknown
            }
        } catch {
            throw error
        }
    }
    
    public func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
               continue
            }
            
            productStatusStorage.saveProductStatus(
                productID: transaction.productID,
                isPurchased: transaction.revocationDate == nil
            )
        }
    }
    
    public func restorePurchases() async throws {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            throw error
        }
    }
    
    public func isPurchased(_ product: MokayProductProtocol) -> Bool {
        productStatusStorage.isProductPurchased(productId: product.productId)
    }
    
    // MARK: - Private methods
    
    private func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await _ in Transaction.updates {
                await self?.updatePurchasedProducts()
            }
        }
    }
    
}

