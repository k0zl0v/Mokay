//
//  StoreKitService.swift
//  Mokay
//
//  Created by Дмитрий Бондаренко on 07.12.24.
//

import Combine
import StoreKit

public final class StoreKitService: @unchecked Sendable {
    
    // MARK: - Types
    
    public typealias ProductStream = AsyncStream<[Product]>
    
    // MARK: - Public properties
    
    private let productsSubject: CurrentValueSubject<[Product], Never>
    private let productStorage: ProductStorage
    
    private var transactionTask: Task<Void, Never>?
    
    // MARK: - Init
    
    public init(productStorage: ProductStorage) {
        self.productStorage = productStorage
        self.productsSubject = .init([])
        
        observeTransactions()
    }
    
    deinit {
        transactionTask?.cancel()
    }
    
    // MARK: - Public methods
    
    /// Возвращает AsyncStream с обновлениями доступных продуктов.
    public func productStream() -> ProductStream {
        AsyncStream { continuation in
            Task {
                for await products in productsSubject.values {
                    continuation.yield(products)
                }
            }
        }
    }
    
    /// Загрузка списка доступных продуктов из App Store.
    /// - **Когда вызывать:**
    ///     - После создания сервиса, чтобы заранее подгрузить список доступных для покупки продуктов.
    ///     - При загрузке пэйвола.
    public func fetchProducts() async throws {
        do {
            let productIds = await productStorage.getProductIds()
            let fetchedProducts = try await Product.products(for: productIds)
            productsSubject.send(fetchedProducts)
        } catch {
            throw StoreKitServiceError.fetchProductsFailed(error)
        }
    }
    
    /// Обрабатывает покупку конкретного продукта.
    public func purhcase(_ product: Product) async throws {
        do {
            let result = try await product.purchase()
            
            switch result {
            case let .success(verificationStatus):
                switch verificationStatus {
                case let .verified(transaction):
                    await transaction.finish()
                    await updatePurchasedProducts()
                    
                case let .unverified(_, error):
                    throw StoreKitServiceError.verificationFailed(error)
                }
                
            case .pending:
                throw StoreKitServiceError.pending
                
            case .userCancelled:
                throw StoreKitServiceError.userCancelled
                
            @unknown default:
                throw StoreKitServiceError.unknown
            }
        } catch {
            throw StoreKitServiceError.transactionFailed(error)
        }
    }
    
    /// Восстанавливает ранее совершённые покупки.
    public func restorePurchases() async throws {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            throw StoreKitServiceError.restorePurchaseFailed(error)
        }
    }
    
    public func isPurchased(_ productId: String) async -> Bool {
        let product = await productStorage.getProduct(with: productId)
        return product?.isPurchased ?? false
    }
    
    // MARK: - Private methods
    
    /// Обеспечивает обработку транзакций, которые могли быть совершены на другом устройстве.
    /// Например, покупка через один Apple ID в приложении на другом устройстве.
    private func observeTransactions() {
        transactionTask = Task {
            for await transactions in Transaction.updates {
                await updatePurchasedProducts()
            }
        }
    }
    
    private func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
               continue
            }
            
            let product = StoredProductModel(
                id: transaction.productID,
                isPurchased: transaction.revocationDate == nil
            )
            await productStorage.saveProduct(product)
        }
    }
    
}

