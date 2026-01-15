import Foundation
import CoreData

// MARK: - WordMapper

public struct WordMapper {
    // MARK: - Domain Entity -> Managed Object
    
    public static func toManagedObject(_ word: Word, context: NSManagedObjectContext) -> WordEntity {
        let entity = WordEntity(context: context)
        entity.id = word.id
        entity.jpText = word.jpText
        entity.reading = word.reading
        entity.primaryMeaning = word.meaning
        entity.sourceType = word.sourceType?.rawValue
        entity.sourceText = word.sourceText
        entity.sourceLink = word.sourceLink
        entity.isFavorite = word.isFavorite
        entity.createdAt = word.createdAt
        entity.updatedAt = word.updatedAt
        entity.deletedAt = word.deletedAt
        
        return entity
    }
    
    // MARK: - Managed Object -> Domain Entity
    
    public static func toDomain(_ entity: WordEntity) -> Word {
        let sourceType = entity.sourceType.flatMap { SourceType(rawValue: $0) }
        
        return Word(
            id: entity.id!,
            jpText: entity.jpText!,
            reading: entity.reading,
            meaning: entity.primaryMeaning!,
            sourceType: sourceType,
            sourceText: entity.sourceText,
            sourceLink: entity.sourceLink,
            isFavorite: entity.isFavorite,
            createdAt: entity.createdAt ?? Date(),
            updatedAt: entity.updatedAt ?? Date(),
            deletedAt: entity.deletedAt,
            autoFill: AutoFillStatus(status: .none) // CoreData에는 저장하지 않음 (메모리 전용)
        )
    }
    
    // MARK: - Update Managed Object
    
    public static func update(_ entity: WordEntity, with word: Word, context: NSManagedObjectContext) {
        entity.jpText = word.jpText
        entity.reading = word.reading
        entity.primaryMeaning = word.meaning
        entity.sourceType = word.sourceType?.rawValue
        entity.sourceText = word.sourceText
        entity.sourceLink = word.sourceLink
        entity.isFavorite = word.isFavorite
        entity.updatedAt = word.updatedAt
        entity.deletedAt = word.deletedAt
    }
}
