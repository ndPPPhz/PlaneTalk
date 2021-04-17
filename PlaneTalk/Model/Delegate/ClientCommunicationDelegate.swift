//
//  Client.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 14/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

protocol ClientCommunicationDelegate: AnyObject {
	func clientDidReceiveMessage(_ text: String)
	func clientDidSendMessage(_ text: String)
}

protocol ClientConnectionDelegate: AnyObject {
	func clientDidLoseConnectionWithServer()
}
