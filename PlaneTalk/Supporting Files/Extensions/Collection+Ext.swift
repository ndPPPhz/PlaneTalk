//
//  Collection+Ext.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 12/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

extension Collection {
	/// Returns Whether the collection contains the given type.
	func contains<T>(elementOfType type: T.Type) -> Bool {
		return first(elementOfType: type) != nil
	}

	/// Returns the first element of the given type.
	public func first<T>(elementOfType type: T.Type) -> T? {
		return first(where: { $0 is T }) as? T
	}
}
