//
//  StoreKitServiceError.swift
//  Mokay
//
//  Created by Дмитрий Бондаренко on 09.12.24.
//

public enum StoreKitServiceError: Error {
    
    /// Покупка отменена пользователем.
    case userCancelled
    
    /// Покупка ожидает подтверждения.
    case pending
    
    /// Ошибка верификации при совершении покупки.
    case verificationFailed(Error)
    
    /// Общая ошибка совершения покупки.
    case unknown
    
    /// Ошибка транзакции при совершении покупки.
    case transactionFailed(Error)
    
    /// Ошибка получения списка продуктов.
    case fetchProductsFailed(Error)
    
    /// Ошибка восстановления покупок.
    case restorePurchaseFailed(Error)
    
}
