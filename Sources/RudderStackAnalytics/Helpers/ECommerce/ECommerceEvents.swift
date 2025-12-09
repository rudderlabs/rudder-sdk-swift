//
//  ECommerceEvents.swift
//  RudderStackAnalytics
//
//  Created by Vishal Gupta on 10/11/25.
//

import Foundation

// swiftlint:disable missing_docs
/**
 * This enum class contains the names of the E-Commerce events.
 */
public enum ECommerceEvents {
    public static let productsSearched = "Products Searched"
    public static let productListViewed = "Product List Viewed"
    public static let productListFiltered = "Product List Filtered"
    public static let promotionViewed = "Promotion Viewed"
    public static let promotionClicked = "Promotion Clicked"
    public static let productClicked = "Product Clicked"
    public static let productViewed = "Product Viewed"
    public static let productAdded = "Product Added"
    public static let productRemoved = "Product Removed"
    public static let cartViewed = "Cart Viewed"
    public static let checkoutStarted = "Checkout Started"
    public static let checkoutStepViewed = "Checkout Step Viewed"
    public static let checkoutStepCompleted = "Checkout Step Completed"
    public static let paymentInfoEntered = "Payment Info Entered"
    public static let orderUpdated = "Order Updated"
    public static let orderCompleted = "Order Completed"
    public static let orderRefunded = "Order Refunded"
    public static let orderCancelled = "Order Cancelled"
    public static let couponEntered = "Coupon Entered"
    public static let couponApplied = "Coupon Applied"
    public static let couponDenied = "Coupon Denied"
    public static let couponRemoved = "Coupon Removed"
    public static let productAddedToWishList = "Product Added to Wishlist"
    public static let productRemovedFromWishList = "Product Removed from Wishlist"
    public static let wishListProductAddedToCart = "Wishlist Product Added to Cart"
    public static let productShared = "Product Shared"
    public static let cartShared = "Cart Shared"
    public static let productReviewed = "Product Reviewed"
}
// swiftlint:enable missing_docs
