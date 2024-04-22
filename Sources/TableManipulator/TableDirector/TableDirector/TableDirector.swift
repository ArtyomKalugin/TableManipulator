import UIKit

/// Класс для управления таблицей
open class TableDirector: NSObject {
    
    // MARK: - Private properties
    
    private var cellRegisterer: TableCellRegisterer?
    private var requestManager: TableRequestManager?
    public private(set) var rowHeightCalculator: TableRowHeightCalculator?
    private var sectionsIndexTitlesIndexes: [Int]?
    
    // MARK: - Properties
    
    open private(set) weak var tableView: UITableView?
    open fileprivate(set) var sections = [TableSection]()
    
    open var isEmpty: Bool {
        return sections.isEmpty
    }
    
    // MARK: - Life cycle
    
    public init(
        tableView: UITableView,
        requestModel: TableRequestModel?,
        shouldUseAutomaticCellRegistration: Bool = true,
        cellHeightCalculator: TableRowHeightCalculator?
    ) {
        super.init()
        
        if shouldUseAutomaticCellRegistration {
            cellRegisterer = TableCellRegisterer(tableView: tableView)
        }
        
        if let requestModel = requestModel {
            requestManager = TableRequestManager(requestModel: requestModel)
        }
        
        self.rowHeightCalculator = cellHeightCalculator
        self.tableView = tableView
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
    }
    
    public convenience init(
        tableView: UITableView,
        requestModel: TableRequestModel?,
        shouldUseAutomaticCellRegistration: Bool = true,
        shouldUsePrototypeCellHeightCalculation: Bool = false
    ) {
        let heightCalculator: TableRowHeightCalculator? = shouldUsePrototypeCellHeightCalculation
            ? TableRowHeightCalculator(tableView: tableView)
            : nil
        
        self.init(
            tableView: tableView,
            requestModel: requestModel,
            shouldUseAutomaticCellRegistration: shouldUseAutomaticCellRegistration,
            cellHeightCalculator: heightCalculator
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private
    
    private func row(at indexPath: IndexPath) -> Row? {
        if indexPath.section < sections.count && indexPath.row < sections[indexPath.section].rows.count {
            return sections[indexPath.section].rows[indexPath.row]
        }
        return nil
    }
    
    // MARK: - Public
    
    open func reload() {
        tableView?.reloadData()
    }
    
    open override func responds(to selector: Selector) -> Bool {
        return super.responds(to: selector) == true
    }
    
    open override func forwardingTarget(for selector: Selector) -> Any? {
        return super.forwardingTarget(for: selector)
    }
    
    @discardableResult
    open func invokeOnClick(
        cell:  UITableViewCell?,
        indexPath: IndexPath
    ) -> (() -> Void)? {
            guard let row = row(at: indexPath) else { return nil }
            
            return row.onClick
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension TableDirector: UITableViewDataSource, UITableViewDelegate {
    public func tableView(
        _ tableView: UITableView,
        sectionForSectionIndexTitle title: String,
        at index: Int
    ) -> Int {
        return sectionsIndexTitlesIndexes?[index] ?? 0
    }
    
    public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var indexTitles = [String]()
        var indexTitlesIndexes = [Int]()
        sections.enumerated().forEach { index, section in
            
            if let title = section.indexTitle {
                indexTitles.append(title)
                indexTitlesIndexes.append(index)
            }
        }
        if !indexTitles.isEmpty {
            
            sectionsIndexTitlesIndexes = indexTitlesIndexes
            return indexTitles
        }
        sectionsIndexTitlesIndexes = nil
        return nil
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        let onClick = invokeOnClick(cell: cell, indexPath: indexPath)
        
        if let onClick = onClick {
            onClick()
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < sections.count else { return nil }
        
        return sections[section].headerView
    }
    
    open func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard section < sections.count else { return nil }
        
        return sections[section].footerView
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < sections.count else { return 0 }
        
        let section = sections[section]
        return section.headerHeight
            ?? section.headerView?.frame.size.height
            ?? UITableView.automaticDimension
    }
    
    open func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard section < sections.count else { return 0 }
        
        let section = sections[section]
        return section.footerHeight
            ?? section.footerView?.frame.size.height
            ?? UITableView.automaticDimension
    }
    
    open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < sections.count else { return nil }
        
        return sections[section].headerTitle
    }
    
    open func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section < sections.count else { return nil }
        
        return sections[section].footerTitle
    }
    
    open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        if rowHeightCalculator != nil {
            cellRegisterer?.register(cellType: row.cellType, forCellReuseIdentifier: row.reuseIdentifier)
        }
        
        var height: CGFloat = .zero
        let lock = DispatchSemaphore(value: .zero)
        DispatchQueue.global().async { [weak self] in
            height = row.defaultHeight
                ?? row.estimatedHeight
                ?? self?.rowHeightCalculator?.estimatedHeight(forRow: row, at: indexPath)
                ?? UITableView.automaticDimension
            
            lock.signal()
        }
        
        lock.wait()
        return height
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        if rowHeightCalculator != nil {
            cellRegisterer?.register(cellType: row.cellType, forCellReuseIdentifier: row.reuseIdentifier)
        }
        
        var height: CGFloat = .zero
        let lock = DispatchSemaphore(value: .zero)
        DispatchQueue.global().async { [weak self] in
            height = row.defaultHeight
                ?? self?.rowHeightCalculator?.height(forRow: row, at: indexPath)
                ?? UITableView.automaticDimension
            
            lock.signal()
        }
        
        lock.wait()
        return height
    }
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < sections.count else { return 0 }
        
        return sections[section].numberOfRows
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        
        cellRegisterer?.register(cellType: row.cellType, forCellReuseIdentifier: row.reuseIdentifier)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        
        if cell.frame.size.width != tableView.frame.size.width {
            cell.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: cell.frame.size.height)
            cell.layoutIfNeeded()
        }
        
        row.configure(cell)
        
        return cell
    }
}

// MARK: - Sections manipulation

extension TableDirector {
    
    @discardableResult
    public func append(section: TableSection) -> Self {
        append(sections: [section])
        
        return self
    }
    
    @discardableResult
    public func append(sections: [TableSection]) -> Self {
        self.sections.append(contentsOf: sections)
        
        return self
    }
    
    @discardableResult
    public func append(rows: [Row]) -> Self {
        append(section: TableSection(rows: rows))
        
        return self
    }
    
    @discardableResult
    public func insert(section: TableSection, atIndex index: Int) -> Self {
        sections.insert(section, at: index)
        
        return self
    }
    
    @discardableResult
    public func replaceSection(at index: Int, with section: TableSection) -> Self {
        if index < sections.count {
            sections[index] = section
        }
        
        return self
    }
    
    @discardableResult
    public func delete(sectionAt index: Int) -> Self {
        sections.remove(at: index)
        
        return self
    }

    @discardableResult
    public func remove(sectionAt index: Int) -> Self {
        return delete(sectionAt: index)
    }
    
    @discardableResult
    public func clear() -> Self {
        rowHeightCalculator?.invalidate()
        sections.removeAll()
        
        return self
    }
}

// MARK: - Requests

extension TableDirector {
    public func makeRequest<ResponseModelType: Decodable>(
        success: @escaping ((_ responseModel: ResponseModelType?) -> Void),
        failure: @escaping (NSError) -> Void
    ) {
        requestManager?.start(success: success, failure: failure)
    }
    
    public func stopPolling() {
        requestManager?.stopPolling()
    }
    
    public func makeResultRequestAfterPolling<ResponseModelType: Decodable>(
        success: @escaping ((_ responseModel: ResponseModelType?) -> Void),
        failure: @escaping (NSError) -> Void
    ) {
        requestManager?.makeResultRequestAfterPolling(
            success: success,
            failure: failure
        )
    }
}
