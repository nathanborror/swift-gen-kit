import Testing
@testable import GenKit

@Suite("Prompt Tests")
struct PromptTests {

    @Test("Prompt")
    func testPrompt() async throws {
        let prompt = try Prompt("""
            ---
            model: meta/llama4
            config:
                maxOutputTokens: 400
            input:
                schema:
                    name: string
                    datetime?: string
                default:
                    datetime: 2025-01-02
            output:
                schema:
                    type: object
                    properties:
                        name:
                            type: string
            ---
            
            This is my prompt.
            """)

        // Instructions
        #expect(prompt.instructions == "This is my prompt.")

        // Model
        #expect(prompt.model == "llama4")
        #expect(prompt.service == "meta")

        // Config
        #expect(prompt.config?.maxOutputTokens == 400)

        // Input
        #expect(prompt.input?.schema["name"] == "string")
        #expect(prompt.input?.schema["datetime?"] == "string")
        #expect(prompt.input?.default?["datetime"] == "2025-01-02")

        // Output
        guard case let .object(_, _, _, _, _, _, properties, _, _) = prompt.output?.schema else {
            fatalError("bad output")
        }
        #expect(properties.count == 1)
    }

    @Test("Prompt with many dividers")
    func testPromptDividers() async throws {
        let prompt = try Prompt("""
            ---
            model: meta/llama4
            ---
            
            Section 1
            ---
            Section 2
            ---
            Section 3
            """)

        #expect(prompt.instructions == "Section 1\n---\nSection 2\n---\nSection 3")
    }

    @Test("Prompt with default values")
    func testPromptDefaults() throws {
        let prompt = try Prompt("""
            ---
            model: meta/llama4
            input:
                schema:
                    datetime?: string
                default:
                    datetime: 2025-01-02
            ---
            
            The current date is {{datetime}}.
            """)

        let output1 = try prompt.render()
        let output2 = try prompt.render(["datetime": .string("2025-01-01")])

        #expect(output1 == "The current date is 2025-01-02.")
        #expect(output2 == "The current date is 2025-01-01.")
    }

    @Test("Prompt without settings")
    func testPromptWithoutSettings() throws {
        let prompt = try Prompt("""
            This is my prompt.
            """)
        
        #expect(prompt.instructions == "This is my prompt.")
        #expect(try prompt.render() == "This is my prompt.")
    }
}
