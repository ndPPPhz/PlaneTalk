//
//  ViewDataConfigurable.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 12/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

protocol ViewDataConfigurable {
	associatedtype ViewData: Equatable
	func configure(with viewData: ViewData)
}
