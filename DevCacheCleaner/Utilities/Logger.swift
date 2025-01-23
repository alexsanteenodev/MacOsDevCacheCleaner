import Foundation

#if DEBUG
struct Logger {
    static func debug(_ message: String) {
        print("🔍 Debug:", message)
    }
    
    static func error(_ message: String, error: Error? = nil) {
        if let error = error {
            print("❌ Error:", message, "Details:", error)
        } else {
            print("❌ Error:", message)
        }
    }
    
    static func command(_ command: String, output: String?) {
        print("⚡️ Command:", command)
        if let output = output {
            print("📝 Output:", output)
        }
    }
}
#endif 