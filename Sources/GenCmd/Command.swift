import Foundation
import ArgumentParser
import GenKit
import SharedKit

@main
struct Command: AsyncParsableCommand {
    
    static var configuration = CommandConfiguration(
        abstract: "A utility for interacting with GenKit.",
        version: "0.0.1",
        subcommands: []
    )
}
