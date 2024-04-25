//
//  BaseTableViewController.swift
//
//
//  Created by user on 25.04.2024.
//

import Foundation

import Foundation
import UIKit
import SnapKit

/// Базовый класс для работы с таблицей
public class BaseTableViewController: UIViewController {
    
    var tableDirector: TableDirector
    var tableView: UITableView
    
    init() {
        tableView = UITableView()
        tableDirector = TableDirector(tableView: tableView, requestModel: nil)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        tableView = UITableView()
        tableDirector = TableDirector(tableView: tableView, requestModel: nil)
        
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let sections = updateSections()
        tableDirector.append(sections: sections)
        tableDirector.reload()
    }
    
    public func updateSections() -> [TableSection] {
        // Override
        []
    }
}
