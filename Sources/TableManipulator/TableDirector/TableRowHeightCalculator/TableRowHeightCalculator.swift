import UIKit

final public class TableRowHeightCalculator {
    
    // MARK: - Private properties

    private(set) weak var tableView: UITableView?
    private var prototypes = [String: UITableViewCell]()
    private var cachedHeights = [Int: CGFloat]()
    private var separatorHeight = 1 / UIScreen.main.scale
    
    // MARK: - Life cycle
    
    public init(tableView: UITableView?) {
        self.tableView = tableView
    }
    
    // MARK: - Methods
    
    public func height(forRow row: Row, at indexPath: IndexPath) -> CGFloat {
        guard let tableView = tableView else { return 0 }

        let hash = row.hashValue ^ Int(tableView.bounds.size.width).hashValue

        if let height = cachedHeights[hash] {
            return height
        }

        var prototypeCell = prototypes[row.reuseIdentifier]
        if prototypeCell == nil {

            prototypeCell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier)
            prototypes[row.reuseIdentifier] = prototypeCell
        }

        guard let cell = prototypeCell else { return 0 }
        
        cell.prepareForReuse()
        row.configure(cell)
        
        cell.bounds = CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: cell.bounds.height)
        cell.setNeedsLayout()
        cell.layoutIfNeeded()

        let height = cell.contentView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height + (tableView.separatorStyle != .none ? separatorHeight : 0)

        cachedHeights[hash] = height

        return height
    }

    public func estimatedHeight(forRow row: Row, at indexPath: IndexPath) -> CGFloat {

        guard let tableView = tableView else { return 0 }

        let hash = row.hashValue ^ Int(tableView.bounds.size.width).hashValue

        if let height = cachedHeights[hash] {
            return height
        }

        if let estimatedHeight = row.estimatedHeight , estimatedHeight > 0 {
            return estimatedHeight
        }

        return UITableView.automaticDimension
    }

    public func invalidate() {
        cachedHeights.removeAll()
    }
}
