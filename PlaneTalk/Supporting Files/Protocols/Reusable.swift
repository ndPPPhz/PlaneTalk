//
//  Reusable.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 12/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

///Reusable protocol is useful for cells.
protocol Reusable: class {
    static var reuseIdentifier: String { get }
}


//Each cell automatically receives a default reuseIdentifier value. The type name is, in my opinion, an excellent default value for them.

extension Reusable {
    static var reuseIdentifier: String {
        // Class's name as an identifier
        return String(describing: Self.self)
    }
}
