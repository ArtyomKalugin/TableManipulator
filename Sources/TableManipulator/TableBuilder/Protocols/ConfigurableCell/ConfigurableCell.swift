import UIKit

/// Протокол настраиваемой ячейки
public protocol ConfigurableCell {
    associatedtype CellData

    static var reuseIdentifier: String { get }

    static var estimatedHeight: CGFloat? { get }

    static var defaultHeight: CGFloat? { get }

    func configure(with _: CellData)
}

public extension ConfigurableCell where Self: UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
    
    static var estimatedHeight: CGFloat? {
        return nil
    }
    
    static var defaultHeight: CGFloat? {
        return nil
    }
}
