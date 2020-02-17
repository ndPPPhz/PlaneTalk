//
//  Interface.swift
//  SendiOS
//
//  Created by Annino De Petra on 20/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

protocol NetworkInformationProvider {
	var ip: String { get }
	var broadcast: String { get }
}

struct Interface: NetworkInformationProvider {
	let name: String
	let ip: String
	let broadcast: String
}
