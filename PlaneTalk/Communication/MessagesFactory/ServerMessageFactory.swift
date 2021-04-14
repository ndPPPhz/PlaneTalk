//
//  ServerMessageFactory.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 16/04/2021.
//  Copyright © 2021 Annino De Petra. All rights reserved.
//

import Foundation

protocol ServerMessageFactoryInterface {
	func generateServerMessage(from text: String) -> String
	func generateClientMessage(from text: String, senderIP: IP) -> String
}

final class ServerMessageFactory: ServerMessageFactoryInterface {
	enum Constant {
		static let separator = "-/-"
	}

	private let serverIP: String

	init(serverIP: String) {
		self.serverIP = serverIP
	}

	func generateServerMessage(from text: String) -> String {
		return [serverIP, text].joined(separator: Constant.separator)
	}

	func generateClientMessage(from text: String, senderIP: IP) -> String {
		return [senderIP, text].joined(separator: Constant.separator)
	}
}
