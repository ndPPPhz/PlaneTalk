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
		static let newNicknameString = "%@ is %@"
		static let nicknameRegex = "^/name: ([0-z]{4,})$"
	}

	private var nicknames: [IP: String] = [:]
	private let device: NetworkDevice
	
	init(device: NetworkDevice) {
		self.device = device
	}

	// MARK: - TCP
	func generateServerMessage(from text: String) -> MessageType {
		if let newNickname = checkPossibleChangeNicknameRegex(in: text) {
			nicknames[device.ip] = newNickname
			let content = String(format: Constant.newNicknameString, device.ip, newNickname)
			return .nicknameChangeRequest(fullText: [newNickname, content].joined(separator: Constant.separator) , content: content)
		} else {
			let senderAlias = nicknames[device.ip] ?? device.ip
			return .text(fullText: [senderAlias,text].joined(separator: Constant.separator), content: text, senderAlias: senderAlias)
		}
	}

	func generateClientMessage(from text: String, senderIP: IP) -> MessageType {
		if let newNickname = checkPossibleChangeNicknameRegex(in: text) {
			nicknames[senderIP] = newNickname
			let content = String(format: Constant.newNicknameString, senderIP, newNickname)
			return .nicknameChangeRequest(fullText: [newNickname, content].joined(separator: Constant.separator) , content: content)
		} else {
			let senderAlias = nicknames[senderIP] ?? senderIP
			return .text(fullText: [senderAlias, text].joined(separator: Constant.separator), content: text, senderAlias: senderAlias)
		}
	}

	// MARK: - UDP
	func receivedUDPMessage(_ text: String, from senderIP: String) -> Message {
		return Message(text: text, senderIP: senderIP)
	}

	func receivedUDPText(_ text: String) -> Message {
		let splitted = text.components(separatedBy: Constant.separator)
		guard splitted.count > 1 else {
			assertionFailure("Missing field")
			return Message(text: text, senderIP: "!!")
		}
		
		return Message(text: splitted[1], senderIP: splitted[0])
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
