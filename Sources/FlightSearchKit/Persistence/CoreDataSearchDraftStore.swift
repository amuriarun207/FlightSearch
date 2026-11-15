import CoreData
import Foundation

enum SearchDraftStoreError: Error, Equatable {
    case storeUnavailable
    case saveFailed
}

@MainActor
protocol SearchDraftStoring: AnyObject {
    func load() throws -> SearchDraft
    func save(_ draft: SearchDraft) throws
}

/// Saves the last trip type and airport codes so they survive a relaunch.
@MainActor
final class CoreDataSearchDraftStore: SearchDraftStoring {
    enum Location {
        case applicationSupport
        case inMemory
        case file(URL)
    }

    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    private let isReady: Bool

    init(location: Location = .applicationSupport) {
        let model = Self.makeModel()
        let container = NSPersistentContainer(name: "FlightSearchKitSearchDraft", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.shouldAddStoreAsynchronously = false
        description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        switch location {
        case .inMemory:
            description.type = NSInMemoryStoreType
        case .applicationSupport, .file:
            guard let url = Self.sqliteURL(for: location) else {
                container.persistentStoreDescriptions = [description]
                self.container = container
                self.context = container.viewContext
                self.isReady = false
                return
            }
            description.type = NSSQLiteStoreType
            description.url = url
        }

        container.persistentStoreDescriptions = [description]
        let loadState = StoreLoadState()
        container.loadPersistentStores { _, error in
            loadState.isReady = (error == nil)
        }

        let context = container.viewContext
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        self.container = container
        self.context = context
        self.isReady = loadState.isReady
    }

    func load() throws -> SearchDraft {
        guard isReady else { throw SearchDraftStoreError.storeUnavailable }
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        request.fetchLimit = 1
        guard let record = try context.fetch(request).first else {
            return .empty
        }
        return SearchDraft(
            tripType: TripType.stored(record.value(forKey: "tripType") as? String),
            originCode: Self.code(from: record, key: "originCode"),
            destinationCode: Self.code(from: record, key: "destinationCode")
        )
    }

    func save(_ draft: SearchDraft) throws {
        guard isReady else { throw SearchDraftStoreError.storeUnavailable }
        let request = NSFetchRequest<NSManagedObject>(entityName: Self.entityName)
        let existing = try context.fetch(request)
        let record = existing.first ?? NSEntityDescription.insertNewObject(
            forEntityName: Self.entityName,
            into: context
        )
        for extra in existing.dropFirst() {
            context.delete(extra)
        }
        record.setValue(draft.tripType.rawValue, forKey: "tripType")
        record.setValue(draft.originCode, forKey: "originCode")
        record.setValue(draft.destinationCode, forKey: "destinationCode")
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            throw SearchDraftStoreError.saveFailed
        }
    }

    private static let entityName = "SearchDraftRecord"

    private static func code(from record: NSManagedObject, key: String) -> String? {
        guard let value = record.value(forKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return trimmed
    }

    private static func sqliteURL(for location: Location) -> URL? {
        let url: URL?
        switch location {
        case .inMemory:
            return nil
        case .applicationSupport:
            guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                return nil
            }
            url = base
                .appendingPathComponent("FlightSearchKit", isDirectory: true)
                .appendingPathComponent("SearchDraft.sqlite")
        case .file(let fileURL):
            url = fileURL
        }
        guard let url else { return nil }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            return url
        } catch {
            return nil
        }
    }

    private static func makeModel() -> NSManagedObjectModel {
        let tripType = attribute(name: "tripType", optional: false, defaultValue: TripType.oneWay.rawValue)
        let originCode = attribute(name: "originCode", optional: true, defaultValue: nil)
        let destinationCode = attribute(name: "destinationCode", optional: true, defaultValue: nil)

        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        entity.properties = [tripType, originCode, destinationCode]

        let model = NSManagedObjectModel()
        model.entities = [entity]
        return model
    }

    private static func attribute(name: String, optional: Bool, defaultValue: String?) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = .stringAttributeType
        attribute.isOptional = optional
        attribute.defaultValue = defaultValue
        return attribute
    }
}

private final class StoreLoadState: @unchecked Sendable {
    var isReady = false
}
