import Testing
@testable import GenKit

@Suite("Content Parser")
struct ContentParserTests {

    @Test("Single tag parsing")
    func testTag() async throws {
        let simpleInput = "<tag>content</tag>"
        let simpleResult = try ContentParser.shared.parse(input: simpleInput)
        
        #expect(simpleResult.contents.count == 1)
        #expect(simpleResult.first(tag: "tag")?.content == "content")
    }

    @Test("Single tag with attributes parsing")
    func testTagWithAttributes() async throws {
        let attributeInput = "<tag name=\"Tag\" id=\"1\">content</tag>"
        let attributeResult = try ContentParser.shared.parse(input: attributeInput)
        
        #expect(attributeResult.contents.count == 1)

        let attributeTag = attributeResult.first(tag: "tag")
        
        #expect(attributeTag?.content == "content")
        #expect(attributeTag?.params["name"] == "Tag")
        #expect(attributeTag?.params["id"] == "1")
    }

    @Test("Multiple tag parsing")
    func testMultipleTagsAndText() async throws {
        let mixedInput = "Text before <foo>Foo</foo> Text between <bar>Bar</bar> Text after"
        let mixedResult = try ContentParser.shared.parse(input: mixedInput)
        
        #expect(mixedResult.contents.count == 5)
        #expect(mixedResult.first(tag: "foo")?.content == "Foo")
        #expect(mixedResult.first(tag: "bar")?.content == "Bar")
    }

    @Test("Specific tag parsing")
    func testSpecificTag() async throws {
        let specificTagsInput = "<keep>Keep this</keep> <ignore>Ignore this</ignore>"
        let specificTagsResult = try ContentParser.shared.parse(input: specificTagsInput, tags: ["keep"])
        
        #expect(specificTagsResult.contents.count == 2)
        #expect(specificTagsResult.first(tag: "keep") != nil)
        #expect(specificTagsResult.first(tag: "ignore") == nil)
    }

    @Test("Nested tag parsing")
    func testNestedTags() async throws {
        let nestedInput = "<outer><inner>Nested content</inner></outer>"
        let nestedResult = try ContentParser.shared.parse(input: nestedInput)

        #expect(nestedResult.contents.count == 1)
        #expect(nestedResult.first(tag: "outer")?.content == "<inner>Nested content</inner>")
    }

    @Test("Incomplete tag parsing")
    func testHasClosingTag() async throws {
        let simpleInput = """
            Lorem ipsum
            <foo>content
            Dolor sit amet
            """
        let simpleResult = try ContentParser.shared.parse(input: simpleInput)

        #expect(simpleResult.first(tag: "foo")?.hasClosingTag == false)
    }
}
