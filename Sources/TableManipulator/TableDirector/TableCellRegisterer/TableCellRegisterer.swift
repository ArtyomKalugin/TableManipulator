import UIKit

final public class TableCellRegisterer {
    
    // MARK: - Private properties

    private var registeredIds = Set<String>()
    private weak var tableView: UITableView?
    
    // MARK: - Life cycle
    
    init(tableView: UITableView?) {
        self.tableView = tableView
    }
    
    // MARK: - Methods
    
    func register(cellType: AnyClass, forCellReuseIdentifier reuseIdentifier: String) {
        if registeredIds.contains(reuseIdentifier) {
            return
        }
        
        if tableView?.dequeueReusableCell(withIdentifier: reuseIdentifier) != nil {
            registeredIds.insert(reuseIdentifier)
            return
        }
        
        let bundle = Bundle(for: cellType)
        
        if let _ = bundle.path(forResource: reuseIdentifier, ofType: "nib") {
            tableView?.register(UINib(nibName: reuseIdentifier, bundle: bundle), forCellReuseIdentifier: reuseIdentifier)
        } else {
            tableView?.register(cellType, forCellReuseIdentifier: reuseIdentifier)
        }
        
        registeredIds.insert(reuseIdentifier)
    }
}
