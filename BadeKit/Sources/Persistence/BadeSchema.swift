import Foundation
import SwiftData

/// The store's shape, version 1. Every schema change from here on adds a version beside this one
/// and a stage to the plan, so a phone that already holds data has a documented way forward.
///
/// Nothing about the current shape changes by naming it: this is where versioning starts, not a
/// migration in itself.
enum BadeSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [SubscriptionRecord.self, ObservedRateRecord.self, OfficialRateRecord.self]
    }
}

/// Empty of stages while there is one version, and the reason the next one is a stage rather than a
/// crash. Additive changes — a new model, a new optional property — need no stage at all; anything
/// that moves or reinterprets existing data needs one written here.
enum BadeMigrations: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [BadeSchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
