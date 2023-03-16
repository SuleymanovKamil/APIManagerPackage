//
//  Locale+acceptLanguage.swift
//  FaceFitness
//
//  Created by Denis Kutlubaev on 31.01.2023.
//

import Foundation

public extension Locale {
    var acceptLanguage: String {
        identifier.replacingOccurrences(of: "_", with: "-")
    }
}
