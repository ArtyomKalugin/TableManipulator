import UIKit

public protocol Row {
    var reuseIdentifier: String { get }
    var cellType: AnyClass { get }

    var estimatedHeight: CGFloat? { get }
    var defaultHeight: CGFloat? { get }
    var onClick: (() -> Void)? { get }
    
    var hashValue: Int { get }
    
    func configure(_ cell: UITableViewCell)
}
