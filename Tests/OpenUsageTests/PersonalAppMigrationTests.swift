import XCTest
@testable import OpenUsage

@MainActor
final class PersonalAppMigrationTests: XCTestCase {
    private func migrate(
        defaults: UserDefaults, values: [String: Any], source: any CredentialVault, target: any CredentialVault,
        sourceHubs: any HubKeyVault = InMemoryHubKeyVault(), targetHubs: any HubKeyVault = InMemoryHubKeyVault()
    ) async -> PersonalAppMigration.Outcome {
        await PersonalAppMigration.run(defaults: defaults, sourceValues: values, sourceVault: source, targetVault: target,
                                       sourceHubKeys: sourceHubs, targetHubKeys: targetHubs)
    }

    func testCopiesCredentialsAndLayoutOnceWithoutTouchingTheOldSignInOrReplacingLaterEdits() async throws {
        let defaults = isolatedDefaults()
        let account = Account(kind: .claude, label: "Personal")
        let source = InMemoryCredentialVault()
        let target = InMemoryCredentialVault()
        let old = AccountCredential.oauth(OAuthTokens(accessToken: "old-access", refreshToken: "old-refresh"))
        try source.save(old, for: account.id)
        let values: [String: Any] = [AccountStore.storageKey: try JSONEncoder().encode([account]),
                                     "menuBarHiddenAccountIDs": ["openrouter@1"], "compactProviderIcons": true]
        let outcome = await migrate(defaults: defaults, values: values, source: source, target: target)
        XCTAssertEqual(outcome.copied, 1)
        XCTAssertEqual(outcome.failed, 0)
        XCTAssertEqual(try target.load(account.id), old)
        XCTAssertEqual(try source.load(account.id), old)
        XCTAssertEqual(AccountStore.load(from: defaults).accounts, [account])
        XCTAssertEqual(defaults.stringArray(forKey: "menuBarHiddenAccountIDs"), ["openrouter@1"])

        try target.update(.apiKey("new-personal-key"), for: account.id)
        defaults.set(false, forKey: "compactProviderIcons")
        _ = await migrate(defaults: defaults, values: values, source: source, target: target)
        XCTAssertEqual(try target.load(account.id), .apiKey("new-personal-key"))
        XCTAssertFalse(defaults.bool(forKey: "compactProviderIcons"))
    }

    func testARefusedReadIsNotRetriedOnLaunchAndKeepsTheAccountForSigningInAgain() async throws {
        let defaults = isolatedDefaults()
        let account = Account(kind: .claude, label: "Work")
        let source = FailingVault()
        let target = InMemoryCredentialVault()
        try source.save(.apiKey("old"), for: account.id)
        source.loadError.value = KeychainVaultError.status(-128)
        let values: [String: Any] = [AccountStore.storageKey: try JSONEncoder().encode([account])]

        let outcome = await migrate(defaults: defaults, values: values, source: source, target: target)
        XCTAssertEqual(outcome.failed, 1)
        source.loadError.value = nil
        _ = await migrate(defaults: defaults, values: values, source: source, target: target)
        XCTAssertNil(try target.load(account.id), "a later launch must not ask the old Keychain again")
        XCTAssertEqual(AccountStore.load(from: defaults).accounts, [account])
        XCTAssertEqual(try source.load(account.id), .apiKey("old"))
    }

    func testARefusedDestinationWriteKeepsTheSourceAndDoesNotClaimSuccess() async throws {
        let defaults = isolatedDefaults()
        let account = Account(kind: .openrouter, label: "OpenRouter")
        let source = InMemoryCredentialVault()
        let target = FailingVault()
        try source.save(.apiKey("key"), for: account.id)
        target.saveError.value = KeychainVaultError.status(-25293)
        let outcome = await migrate(defaults: defaults, values: [AccountStore.storageKey: try JSONEncoder().encode([account])],
                                    source: source, target: target)
        XCTAssertEqual(outcome.copied, 0)
        XCTAssertEqual(outcome.failed, 1)
        XCTAssertEqual(try source.load(account.id), .apiKey("key"))
        XCTAssertNil(try target.load(account.id))
    }

    func testAnExistingPersonalAccountListIsNeverOverwrittenOrImportedInto() async throws {
        let defaults = isolatedDefaults()
        let personal = Account(kind: .codex, label: "New")
        defaults.set(try JSONEncoder().encode([personal]), forKey: AccountStore.storageKey)
        let old = Account(kind: .claude, label: "Old")
        let source = InMemoryCredentialVault()
        try source.save(.apiKey("old"), for: old.id)
        let target = InMemoryCredentialVault()
        let outcome = await migrate(defaults: defaults, values: [AccountStore.storageKey: try JSONEncoder().encode([old])],
                                    source: source, target: target)
        XCTAssertEqual(outcome.copied, 0)
        XCTAssertEqual(AccountStore.load(from: defaults).accounts, [personal])
        XCTAssertNil(try target.load(old.id))
    }

    func testHubKeysKeepTheirBoundAddressWhenCopied() async throws {
        let defaults = isolatedDefaults()
        let hub = CLIProxyHub(url: URL(string: "https://hub.example.com")!)
        let source = InMemoryHubKeyVault()
        let target = InMemoryHubKeyVault()
        let key = HubKey(key: "management-key", url: hub.url)
        try source.save(key, for: hub.id)
        let outcome = await migrate(
            defaults: defaults, values: [AccountStore.hubsStorageKey: try JSONEncoder().encode([hub])],
            source: InMemoryCredentialVault(), target: InMemoryCredentialVault(), sourceHubs: source, targetHubs: target
        )
        XCTAssertEqual(outcome.copied, 1)
        XCTAssertEqual(try target.load(hub.id), key)
        XCTAssertEqual(try source.load(hub.id), key)
    }

    func testAnExistingPersonalCredentialIsNeverReplacedWithAnOlderUpstreamToken() async throws {
        let defaults = isolatedDefaults()
        let account = Account(kind: .claude, label: "Personal")
        let source = InMemoryCredentialVault()
        let target = InMemoryCredentialVault()
        try source.save(.apiKey("old-token"), for: account.id)
        try target.save(.apiKey("renewed-token"), for: account.id)
        let outcome = await migrate(defaults: defaults, values: [AccountStore.storageKey: try JSONEncoder().encode([account])],
                                    source: source, target: target)
        XCTAssertEqual(outcome.failed, 0)
        XCTAssertEqual(try target.load(account.id), .apiKey("renewed-token"))
    }

    func testAnInterruptedOldKeychainPromptIsNotRepeatedOnTheNextLaunch() async throws {
        let defaults = isolatedDefaults()
        let account = Account(kind: .claude, label: "Personal")
        let marker = "account:\(account.id.uuidString)"
        defaults.set(try JSONEncoder().encode([account]), forKey: AccountStore.storageKey)
        defaults.set(true, forKey: PersonalAppMigration.settingsCopiedKey)
        defaults.set([marker], forKey: PersonalAppMigration.attemptedKey)
        defaults.set([marker], forKey: PersonalAppMigration.failedKey)
        let source = InMemoryCredentialVault()
        try source.save(.apiKey("old-token"), for: account.id)
        let target = InMemoryCredentialVault()
        let outcome = await migrate(defaults: defaults, values: [:], source: source, target: target)
        XCTAssertEqual(outcome.failed, 1)
        XCTAssertNil(try target.load(account.id))
    }
}
