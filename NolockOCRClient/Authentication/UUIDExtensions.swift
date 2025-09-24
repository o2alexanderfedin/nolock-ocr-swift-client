//
//  UUIDExtensions.swift
//  NolockOCRClient
//
//  UUID convenience extensions
//

import Foundation

public extension UUID {
    /// The nil/zero UUID (all zeros)
    static let zero = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    /// String representation of the zero UUID
    static let zeroString = "00000000-0000-0000-0000-000000000000"
}