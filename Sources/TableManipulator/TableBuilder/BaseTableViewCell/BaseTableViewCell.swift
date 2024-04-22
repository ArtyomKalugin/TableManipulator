import UIKit

/// Базовый класс ячейки таблицы
public class BaseTableViewCell: UITableViewCell {
    
    // MARK: - Life cycle
    
    public override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addViews()
        configureAppearance()
        configureLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Methods

    func addViews() {
        // Override
    }

    func configureAppearance() {
        // Override
    }

    func configureLayout() {
        // Override
    }
}
