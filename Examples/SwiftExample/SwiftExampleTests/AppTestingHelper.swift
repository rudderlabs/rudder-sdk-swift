//
//  AppTestingHelper.swift
//  SwiftExampleTests
//
//  Created by Satheesh Kannan on 01/05/25.
//

import UIKit

// MARK: - Given_When_Then
func given(_ description: String = "", closure: () -> Void) {
    if !description.isEmpty { print("Given \(description)") }
    closure()
}

func when(_ description: String = "", closure: () -> Void) {
    if !description.isEmpty { print("When \(description)") }
    closure()
}

func then(_ description: String = "", closure: () -> Void) {
    if !description.isEmpty { print("Then \(description)") }
    closure()
}
