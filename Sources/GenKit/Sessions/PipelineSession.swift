//import Foundation
//
//public class PipelineSession {
//    public static let shared = PipelineSession()
//    
//    public func completion(_ request: Pipeline.Request, runLoopLimit: Int = 10) async throws -> Pipeline.Response {
//        var pipelineResponse = Pipeline.Response(steps: [])
//        
//        for step in request.steps {
//            let instructions = PromptTemplate(step.instructions, with: step.inputs)
//            
//            var req = ChatSessionRequest(service: step.service, model: step.model)
//            req.with(history: [.user(content: instructions)])
//            
//            let resp = try await ChatSession.shared.completion(req)
//            let stepCompletion = Pipeline.Response.Step(
//                instructions: instructions,
//                inputs: step.inputs,
//                outputs: step.outputs,
//                messages: resp.messages
//            )
//            pipelineResponse.steps.append(stepCompletion)
//            
//            // TODO: Extract the expected output variables 
//        }
//        
//        return pipelineResponse
//    }
//}
//
//public struct Pipeline {
//    
//    public struct Request: Sendable {
//        public var steps: [Step]
//        
//        public struct Step: Sendable {
//            public var service: ChatService
//            public var model: Model
//            public var instructions: String
//            public var inputs: [String: String]
//            public var outputs: [String: String]
//        }
//    }
//    
//    public struct Response: Codable, Sendable {
//        public var steps: [Step]
//        
//        public struct Step: Codable, Sendable {
//            public var instructions: String
//            public var inputs: [String: String]
//            public var outputs: [String: String]
//            public var messages: [Message]
//        }
//    }
//}
//
//enum PipelineSessionError: Error {
//    case unknown
//}
