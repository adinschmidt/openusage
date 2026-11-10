import Foundation

@MainActor
enum PersonalAppMigration {
    static let completedKey = "personalMigration.v1.completed"
    static let settingsCopiedKey = "personalMigration.v1.settingsCopied"
    static let attemptedKey = "personalMigration.v1.attempted"
    static let failedKey = "personalMigration.v1.failed"
    static let copiedCountKey = "personalMigration.v1.copiedCredentials"

    struct Outcome {
        var copied = 0
        var failed = 0
    }

    static func onFirstLaunch() async -> Outcome {
        guard Bundle.main.bundleIdentifier == PersonalAppIdentity.bundleIdentifier,
              !UserDefaults.standard.bool(forKey: completedKey) else { return Outcome() }
        let legacy = PersonalAppIdentity.legacyBundleIdentifier
        let source = UserDefaults.standard.persistentDomain(forName: legacy) ?? [:]
        let outcome = await run(
            defaults: .standard, sourceValues: source,
            sourceVault: KeychainCredentialVault(service: legacy + ".accounts"),
            targetVault: KeychainCredentialVault(),
            sourceHubKeys: KeychainHubKeyVault(service: legacy + ".cliproxy-hubs"),
            targetHubKeys: KeychainHubKeyVault()
        )
        // Keep the user's telemetry choice without reusing upstream's installation identifier.
        if let enabled = UserDefaults(suiteName: legacy + ".telemetry")?.object(forKey: "enabled"),
           TelemetryRecorder.suite.object(forKey: "enabled") == nil {
            TelemetryRecorder.suite.set(enabled, forKey: "enabled")
        }
        return outcome
    }

    static func run(
        defaults: UserDefaults, sourceValues: [String: Any],
        sourceVault: any CredentialVault, targetVault: any CredentialVault,
        sourceHubKeys: any HubKeyVault, targetHubKeys: any HubKeyVault
    ) async -> Outcome {
        guard !defaults.bool(forKey: completedKey) else { return Outcome() }
        if !defaults.bool(forKey: settingsCopiedKey) {
            // An already configured personal app must never be replaced with an older upstream account list.
            guard defaults.data(forKey: AccountStore.storageKey) == nil else {
                defaults.set(true, forKey: completedKey)
                return Outcome()
            }
            for (key, value) in sourceValues where defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
            defaults.set(true, forKey: settingsCopiedKey)
        }
        let accounts = AccountStore.load(from: defaults).accounts
        let hubs = defaults.data(forKey: AccountStore.hubsStorageKey)
            .flatMap { try? JSONDecoder().decode([CLIProxyHub].self, from: $0) } ?? []
        var attempted = Set(defaults.stringArray(forKey: attemptedKey) ?? [])
        var failed = Set(defaults.stringArray(forKey: failedKey) ?? [])
        var outcome = Outcome()
        for account in accounts where account.hub == nil {
            let marker = "account:\(account.id.uuidString)"
            guard attempted.insert(marker).inserted else { continue }
            // Record before asking the old Keychain, so a refusal or interrupted prompt isn't repeated on launch.
            defaults.set(attempted.sorted(), forKey: attemptedKey)
            failed.insert(marker)
            defaults.set(failed.sorted(), forKey: failedKey)
            do {
                let copied = try await loadOffMainActor {
                    guard try targetVault.load(account.id) == nil else { return false }
                    guard let credential = try sourceVault.load(account.id) else { throw CredentialVaultError.missingCredential }
                    try targetVault.save(credential, for: account.id)
                    return true
                }
                if copied { outcome.copied += 1 }
                failed.remove(marker)
                defaults.set(failed.sorted(), forKey: failedKey)
                if copied { defaults.set(defaults.integer(forKey: copiedCountKey) + 1, forKey: copiedCountKey) }
            } catch {
                failed.insert(marker)
                AppLog.warn(.auth, "An account sign-in could not be copied; sign in again from its account page.")
            }
        }
        for hub in hubs {
            let marker = "hub:\(hub.id.uuidString)"
            guard attempted.insert(marker).inserted else { continue }
            defaults.set(attempted.sorted(), forKey: attemptedKey)
            failed.insert(marker)
            defaults.set(failed.sorted(), forKey: failedKey)
            do {
                let copied = try await loadOffMainActor {
                    guard try targetHubKeys.load(hub.id) == nil else { return false }
                    guard let key = try sourceHubKeys.load(hub.id) else { throw CredentialVaultError.missingCredential }
                    try targetHubKeys.save(key, for: hub.id)
                    return true
                }
                if copied { outcome.copied += 1 }
                failed.remove(marker)
                defaults.set(failed.sorted(), forKey: failedKey)
                if copied { defaults.set(defaults.integer(forKey: copiedCountKey) + 1, forKey: copiedCountKey) }
            } catch {
                failed.insert(marker)
                AppLog.warn(.auth, "A hub key could not be copied; replace its management key from Accounts.")
            }
        }
        outcome.failed = failed.count
        defaults.set(failed.sorted(), forKey: failedKey)
        defaults.set(true, forKey: completedKey)
        AppLog.notice(.auth, "Personal app migration finished: \(outcome.copied) credentials copied, \(outcome.failed) need sign-in.")
        return outcome
    }
}
