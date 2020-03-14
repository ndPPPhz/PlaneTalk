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
		static let nicknameRegex = "^/name: ([0-z]{4,})$"
	}

	private let device: NetworkDevice
	
	init(device: NetworkDevice) {
		self.device = device
	}

	// MARK: - TCP
	func generateServerMessage(from text: String) -> MessageType {
		if let newNickname = checkPossibleChangeNicknameRegex(in: text) {
			return .nicknameChangeRequest(nickname: newNickname)
		} else {
			return .text(fullText: [text, device.ip].joined(separator: Constant.separator), content: text, senderAlias: device.ip)
		}
	}

	func generateClientMessage(from text: String, senderIP: String) -> MessageType {
		if let newNickname = checkPossibleChangeNicknameRegex(in: text) {
			return .nicknameChangeRequest(nickname: newNickname)
		} else {
			return .text(fullText: [text, senderIP].joined(separator: Constant.separator), content: text, senderAlias: senderIP)
		}
	}

	// MARK: - UDP
	func receivedUDPMessage(_ text: String, from senderIP: String) -> Message {
		return Message(text: text, senderIP: senderIP)
	}

	func getTextAndServer(from text: String) -> Message {
		let splitted = text.components(separatedBy: Constant.separator)
		guard splitted.count > 1 else {
			return Message(text: text, senderIP: "!!")
		}
		
		return Message(text: splitted[0], senderIP: splitted[1])
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

	//MARK: - Regex
	private func checkPossibleChangeNicknameRegex(in string: String) -> String? {
		let regexRange = NSRange(string.startIndex..., in: string)

		guard
			let regex = try? NSRegularExpression(pattern: Constant.nicknameRegex),
			let match = regex.matches(in: string, range: regexRange).first
		else {
			return nil
		}

		let matchRange = match.range(at: 1)

		guard matchRange != NSRange(location: NSNotFound, length: 0) else {
			print("Regex error")
			return nil
		}
		let nickname = (string as NSString).substring(with: matchRange)
		return nickname
	}
}
