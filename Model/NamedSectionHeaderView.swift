//  NamedSectionHeaderView.swift
//  Habits
//  Created by bumpagram on 11/6/24.
// “following code that provides the required initializers and sets up the view with its one label subview and associated constraints.


import UIKit

class NamedSectionHeaderView: UICollectionReusableView {
        
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = UIFont.boldSystemFont(ofSize: 17)
        return label
    }()
    
    // 4 properties to handle 2 vertical constraints
    var _handleCenterYConstraint: NSLayoutConstraint?
    var handleCenterYConstraint: NSLayoutConstraint {
        if _handleCenterYConstraint == nil {
            _handleCenterYConstraint = nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        }
        return _handleCenterYConstraint!
    }
    
    var _handleTopYConstraint: NSLayoutConstraint?
    var handleTopYConstraint: NSLayoutConstraint {
        if _handleTopYConstraint == nil {
            _handleTopYConstraint = nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        }
        return _handleTopYConstraint!
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")  // надо указать если перезаписываешь init frame. требование компилятора.
        super.init(coder: coder)
        setupView()
    }
    
    
    private func setupView() {
        backgroundColor = .systemGray4
        addSubview(nameLabel)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            //nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
         
        alignLabelToYCenter()
    }
    
    
    func alignLabelToTop() {
        // to toggle vertical constraints
        handleTopYConstraint.isActive = true
        handleCenterYConstraint.isActive = false
    }
    
    func alignLabelToYCenter() {
        // to toggle vertical constraints
        handleTopYConstraint.isActive = false
        handleCenterYConstraint.isActive = true
    }
    
   
    
}
