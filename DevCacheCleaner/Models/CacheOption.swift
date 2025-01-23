import Foundation

struct CacheOption: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let cleanAction: (() async throws -> Void)?
    var isSelected: Bool = false
    var isAvailable: Bool = true
    var error: String?
} 