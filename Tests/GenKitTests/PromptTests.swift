import XCTest
@testable import GenKit

final class PromptTests: XCTestCase {

    func testParser() throws {
        let str = """
        ---
        model: meta/llama4
        input:
            schema:
                name: string
                datetime?: string
        ---
        
        This is my prompt.
        """

        let prompt = try Prompt(str)

        XCTAssertEqual(prompt.model, "llama4")
        XCTAssertEqual(prompt.service, "meta")
        XCTAssertEqual(prompt.instructions, "This is my prompt.")
        XCTAssertEqual(prompt.input?.schema.keys.contains("name"), true)
        XCTAssertEqual(prompt.input?.schema.keys.contains("datetime?"), true)
    }
}
