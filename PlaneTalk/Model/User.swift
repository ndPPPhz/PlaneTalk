//
//  User.swift
//  SendiOS
//
//  Created by Annino De Petra on 23/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

struct User {
	let IP: String
	var nickname: String? = nil

	mutating func changeNickname(_ newNickname: String) {
		self.nickname = newNickname
	}
}
