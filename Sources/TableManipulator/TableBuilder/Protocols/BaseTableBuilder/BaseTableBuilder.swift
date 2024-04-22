import Foundation

/// Протокол для создания секций таблицы
public protocol BaseTableBuilder {
    func makeSections() -> [TableSection]
}
