import Foundation

public enum PersonalAppIdentity {
    public static let bundleIdentifier = "com.adinschmidt.openusage"
    static let legacyBundleIdentifier = "com.robinebers.openusage"

    static var keychainPrefix: String {
        Bundle.main.bundleIdentifier ?? bundleIdentifier
    }
}
