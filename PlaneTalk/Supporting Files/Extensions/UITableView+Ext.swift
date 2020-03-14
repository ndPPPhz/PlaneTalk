//
//  UITableView+Ext.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 12/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

extension UITableView {

    /// UITableView extensions for the cells that conform to the Reusable protocol
    ///
    /// - Parameter indexPath: the indexPath of the cell
    /// - Returns: the reusable cell
    func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath)  -> T  {
        return dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
}

extension UITableViewCell : Reusable {}
