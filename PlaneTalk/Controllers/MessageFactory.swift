//
//  MessageFactory.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 12/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

struct Message {
	let text: String
	let senderIP: String
}

class MessageFactory {
	enum Constant {
		static let serverDiscovery = "CHAT-SERVER-DISCOVERY"
		static let serverResponse = "CHAT-SERVER-RESPONSE-"
		static let separator = "-/-"
	}

	private let device: Device
	
	init(device: Device) {
		self.device = device
	}

	func generateServerOwnMessage(from text: String) -> String {
		return [text, device.ip].joined(separator: Constant.separator)
	}

	func generateClientMessageToBeSent(from text: String, senderIP: String) -> String {
		return [text, senderIP].joined(separator: Constant.separator)
	}

	func receivedUDPMessage(_ text: String, from senderIP: String) -> Message {
		return Message(text: text, senderIP: senderIP)
	}

	var serverBroadcastAuthenticationResponse: String {
		return Constant.serverResponse + device.ip
	}

	var discoveryMessage: String {
		return Constant.serverDiscovery
	}

	var serverBroadcastAuthenticationResponseTemplate: String {
		return Constant.serverResponse
	}
}
