import Foundation
import Testing

@testable import NotchHubCore

struct ShelfItemTests {
    @Test
    func codableRoundTripPreservesPersistentFields() throws {
        let item = ShelfItem(
            id: UUID(uuidString: "122A45ED-8A76-4E32-9069-93D6B3564DB2")!,
            bookmarkData: Data([0x01, 0x02, 0x03]),
            displayName: "Report.pdf",
            isDirectory: false
        )

        let encoded = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(ShelfItem.self, from: encoded)

        #expect(decoded == item)
    }
}
