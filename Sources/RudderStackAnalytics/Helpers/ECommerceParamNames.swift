//
//  ECommerceParamNames.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 10/11/25.
//

import Foundation

/**
 * This enum class contains the names of the parameters that are used in the E-Commerce events.
 */
public enum ECommerceParamNames {
    static let query = "query"
    static let price = "price"
    static let productId = "product_id"
    static let category = "category"
    static let currency = "currency"
    static let listId = "list_id"
    static let products = "products"
    static let wishlistId = "wishlist_id"
    static let wishlistName = "wishlist_name"
    static let quantity = "quantity"
    static let cartId = "cart_id"
    static let checkoutId = "checkout_id"
    static let total = "total"
    static let revenue = "revenue"
    static let orderId = "order_id"
    static let sorts = "sorts"
    static let filters = "filters"
    static let couponId = "coupon_id"
    static let couponName = "coupon_name"
    static let discount = "discount"
    static let reason = "reason"
    static let shareVia = "share_via"
    static let shareMessage = "share_message"
    static let recipient = "recipient"
    static let reviewId = "review_id"
    static let reviewBody = "review_body"
    static let rating = "rating"
}
