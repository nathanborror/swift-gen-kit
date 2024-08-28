import Foundation

public func patch(string: String?, with patch: String?) -> String? {
    if let string {
        return string + (patch ?? "")
    } else {
        return patch
    }
}
