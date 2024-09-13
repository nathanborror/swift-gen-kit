import XCTest
@testable import GenKit

final class ContentParserTests: XCTestCase {

    func testTag() throws {
        let simpleInput = "<tag>content</tag>"
        let simpleResult = try ContentParser.shared.parse(input: simpleInput)
        
        XCTAssertEqual(simpleResult.contents.count, 1)
        XCTAssertEqual(simpleResult.first(tag: "tag")?.content, "content")
    }
    
    func testTagWithAttributes() throws {
        let attributeInput = "<tag name=\"Tag\" id=\"1\">content</tag>"
        let attributeResult = try ContentParser.shared.parse(input: attributeInput)
        
        XCTAssertEqual(attributeResult.contents.count, 1)
        
        let attributeTag = attributeResult.first(tag: "tag")
        
        XCTAssertEqual(attributeTag?.content, "content")
        XCTAssertEqual(attributeTag?.params["name"], "Tag")
        XCTAssertEqual(attributeTag?.params["id"], "1")
    }
    
    func testMultipleTagsAndText() throws {
        let mixedInput = "Text before <foo>Foo</foo> Text between <bar>Bar</bar> Text after"
        let mixedResult = try ContentParser.shared.parse(input: mixedInput)
        
        XCTAssertEqual(mixedResult.contents.count, 5)
        XCTAssertEqual(mixedResult.first(tag: "foo")?.content, "Foo")
        XCTAssertEqual(mixedResult.first(tag: "bar")?.content, "Bar")
    }
    
    func testSpecificTag() throws {
        let specificTagsInput = "<keep>Keep this</keep> <ignore>Ignore this</ignore>"
        let specificTagsResult = try ContentParser.shared.parse(input: specificTagsInput, tags: ["keep"])
        
        XCTAssertEqual(specificTagsResult.contents.count, 2)
        XCTAssertNotNil(specificTagsResult.first(tag: "keep"))
        XCTAssertNil(specificTagsResult.first(tag: "ignore"))
    }
    
    func testNestedTags() throws {
        let nestedInput = "<outer><inner>Nested content</inner></outer>"
        let nestedResult = try ContentParser.shared.parse(input: nestedInput)
        XCTAssertEqual(nestedResult.contents.count, 1)
        XCTAssertEqual(nestedResult.first(tag: "outer")?.content, "<inner>Nested content</inner>")
    }
}
