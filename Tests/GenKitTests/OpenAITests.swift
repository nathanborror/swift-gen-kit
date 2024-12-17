import XCTest
@testable import OpenAI
@testable import GenKit

final class OpenAITests: XCTestCase {

    func testStreamingDecoder() throws {
        let output1 = """
            {
                "id":"chatcmpl-123",
                "object":"chat.completion.chunk",
                "created":1694268190,
                "model":"gpt-4o-mini", 
                "system_fingerprint": "fp_44709d6fcb", 
                "choices":[
                    {
                        "index":0,
                        "delta":{
                            "role":"assistant",
                            "content":"",
                            "tool_calls": [
                                {
                                    "index": 0,
                                    "id": "call_abc123",
                                    "type": "function",
                                    "function": {
                                        "name": "get_current_weather",
                                        "arguments": "{"
                                    }
                                }
                            ]
                        },
                        "logprobs":null,
                        "finish_reason":null
                    }
                ]
            }
            """

        let output2 = """
            {
                "id":"chatcmpl-123",
                "object":"chat.completion.chunk",
                "created":1694268190,
                "model":"gpt-4o-mini", 
                "system_fingerprint": "fp_44709d6fcb", 
                "choices":[
                    {
                        "index":0,
                        "delta":{
                            "role":"assistant",
                            "content":"",
                            "tool_calls": [
                                {
                                    "index": 0,
                                    "id": "call_abc123",
                                    "type": "function",
                                    "function": {
                                        "name": "get_current_weather",
                                        "arguments": "\\"location\\": \\"Seattle, WA\\"}"
                                    }
                                }
                            ]
                        },
                        "logprobs":null,
                        "finish_reason":null
                    }
                ]
            }
            """

        let resp1 = try JSONDecoder().decode(OpenAI.ChatStreamResponse.self, from: output1.data(using: .utf8)!)
        let resp2 = try JSONDecoder().decode(OpenAI.ChatStreamResponse.self, from: output2.data(using: .utf8)!)

        var message = GenKit.Message(role: .assistant, content: [])
        message.patch(with: resp1)
        message.patch(with: resp2)

        XCTAssertEqual(message.toolCalls!.count, 1)
        XCTAssertEqual(message.toolCalls!.first!.function.arguments, "{\"location\": \"Seattle, WA\"}")
    }
}
