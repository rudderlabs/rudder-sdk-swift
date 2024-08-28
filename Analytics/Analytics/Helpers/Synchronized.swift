//
//  Synchronized.swift
//  Analytics
//
//  Created by Satheesh Kannan on 27/08/24.
//

import Foundation

@propertyWrapper
public final class Synchronized<T> {
    var value: T
    
    private var lock = pthread_rwlock_t()

    public init(wrappedValue value: T) {
        pthread_rwlock_init(&lock, nil)
        self.value = value
    }

    deinit {
        pthread_rwlock_destroy(&lock)
    }
    
    public var wrappedValue: T {
        get {
            pthread_rwlock_rdlock(&lock)
            defer { pthread_rwlock_unlock(&lock) }
            return value
        }
        set {
            pthread_rwlock_wrlock(&lock)
            value = newValue
            pthread_rwlock_unlock(&lock)
        }
    }
}
