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

        XCTAssertEqual(prompt.model, "meta/llama4")
        XCTAssertEqual(prompt.instructions, "This is my prompt.")
        XCTAssertEqual(prompt.input?.schema.keys.contains("name"), true)
        XCTAssertEqual(prompt.input?.schema.keys.contains("datetime?"), true)

//        if case let .object(_, _, _, _, _, _, properties, _, _) = prompt.input {
//            XCTAssertTrue(properties.keys.contains("name"))
//        } else {
//            fatalError("missing input")
//        }
    }
}
