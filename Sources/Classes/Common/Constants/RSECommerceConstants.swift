//
//  RSECommerceConstants.swift
//  RudderStack
//
//  Created by Pallab Maiti on 15/11/21.
//  Copyright © 2021 Rudder Labs India Pvt Ltd. All rights reserved.
//

import Foundation

// Events
@objc open class RSECommerceConstants: NSObject {
    @objc public static let ECommProductsSearched = "Products Searched"
    @objc public static let ECommProductListViewed = "Product List Viewed"
    @objc public static let ECommProductListFiltered = "Product List Filtered"
    @objc public static let ECommPromotionViewed = "Promotion Viewed"
    @objc public static let ECommPromotionClicked = "Promotion Clicked"
    @objc public static let ECommProductClicked = "Product Clicked"
    @objc public static let ECommProductViewed = "Product Viewed"
    @objc public static let ECommProductAdded = "Product Added"
    @objc public static let ECommProductRemoved = "Product Removed"
    @objc public static let ECommCartViewed = "Cart Viewed"
    @objc public static let ECommCheckoutStarted = "Checkout Started"
    @objc public static let ECommCheckoutStepViewed = "Checkout Step Viewed"
    @objc public static let ECommCheckoutStepCompleted = "Checkout Step Completed"
    @objc public static let ECommPaymentInfoEntered = "Payment Info Entered"
    @objc public static let ECommOrderUpdated = "Order Updated"
    @objc public static let ECommOrderCompleted = "Order Completed"
    @objc public static let ECommOrderRefunded = "Order Refunded"
    @objc public static let ECommOrderCancelled = "Order Cancelled"
    @objc public static let ECommCouponEntered = "Coupon Entered"
    @objc public static let ECommCouponApplied = "Coupon Applied"
    @objc public static let ECommCouponDenied = "Coupon Denied"
    @objc public static let ECommCouponRemoved = "Coupon Removed"
    @objc public static let ECommProductAddedToWishList = "Product Added to Wishlist"
    @objc public static let ECommProductRemovedFromWishList = "Product Removed from Wishlist"
    @objc public static let ECommWishListProductAddedToCart = "Wishlist Product Added to Cart"
    @objc public static let ECommProductShared = "Product Shared"
    @objc public static let ECommCartShared = "Cart Shared"
    @objc public static let ECommProductReviewed = "Product Reviewed"
    
    // Parameter names
    @objc public static let KeyQuery = "query"
    @objc public static let KeyPrice = "price"
    @objc public static let KeyProductId = "product_id"
    @objc public static let KeyCategory = "category"
    @objc public static let KeyCurrency = "currency"
    @objc public static let KeyListId = "list_id"
    @objc public static let KeyProducts = "products"
    @objc public static let KeyWishlistId = "wishlist_id"
    @objc public static let KeyWishlistName = "wishlist_name"
    @objc public static let KeyQuantity = "quantity"
    @objc public static let KeyCartId = "cart_id"
    @objc public static let KeyCheckoutId = "checkout_id"
    @objc public static let KeyTotal = "total"
    @objc public static let KeyRevenue = "revenue"
    @objc public static let KeyOrderId = "order_id"
    @objc public static let KeySorts = "sorts"
    @objc public static let KeyFilters = "filters"
    @objc public static let KeyCouponId = "coupon_id"
    @objc public static let KeyCouponName = "coupon_name"
    @objc public static let KeyDiscount = "discount"
    @objc public static let KeyReason = "reason"
    @objc public static let KeyShareVia = "share_via"
    @objc public static let KeyShareMessage = "share_message"
    @objc public static let KeyRecipient = "recipient"
    @objc public static let KeyReviewId = "review_id"
    @objc public static let KeyReviewBody = "review_body"
    @objc public static let KeyRating = "rating"
}
