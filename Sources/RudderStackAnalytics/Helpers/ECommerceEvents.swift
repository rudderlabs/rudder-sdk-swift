//
//  ECommerceEvents.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 10/11/25.
//

import Foundation

/**
 * This enum class contains the names of the E-Commerce events.
 */
public enum ECommerceEvents {
    static let productsSearched = "Products Searched"
    static let productListViewed = "Product List Viewed"
    static let productListFiltered = "Product List Filtered"
    static let promotionViewed = "Promotion Viewed"
    static let promotionClicked = "Promotion Clicked"
    static let productClicked = "Product Clicked"
    static let productViewed = "Product Viewed"
    static let productAdded = "Product Added"
    static let productRemoved = "Product Removed"
    static let cartViewed = "Cart Viewed"
    static let checkoutStarted = "Checkout Started"
    static let checkoutStepViewed = "Checkout Step Viewed"
    static let checkoutStepCompleted = "Checkout Step Completed"
    static let paymentInfoEntered = "Payment Info Entered"
    static let orderUpdated = "Order Updated"
    static let orderCompleted = "Order Completed"
    static let orderRefunded = "Order Refunded"
    static let orderCancelled = "Order Cancelled"
    static let couponEntered = "Coupon Entered"
    static let couponApplied = "Coupon Applied"
    static let couponDenied = "Coupon Denied"
    static let couponRemoved = "Coupon Removed"
    static let productAddedToWishList = "Product Added to Wishlist"
    static let productRemovedFromWishList = "Product Removed from Wishlist"
    static let wishListProductAddedToCart = "Wishlist Product Added to Cart"
    static let productShared = "Product Shared"
    static let cartShared = "Cart Shared"
    static let productReviewed = "Product Reviewed"
}
