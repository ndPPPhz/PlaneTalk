//
//  BroadcastMessageFactory.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 16/04/2021.
//  Copyright © 2021 Annino De Petra. All rights reserved.
//

import Foundation

protocol BroadcastMessageFactoryInterface {
	static var discoveryString: String { get }
	static var discoveryResponse: String { get }
}

protocol BroadcastMessageInterpreter {
	static func isValidBroadcastText(_ text: String) -> BroadcastMessageType?
}

enum BroadcastMessageType {
	case serverDiscovery
	case serverResponse
}

final class BroadcastMessageFactory: BroadcastMessageFactoryInterface, BroadcastMessageInterpreter {
	private enum Constant {
		static let serverDiscovery = "CHAT-SERVER-DISCOVERY"
		static let serverResponse = "CHAT-SERVER-RESPONSE"
	}

	static var discoveryString: String {
		return Constant.serverDiscovery
	}

	static var discoveryResponse: String {
		return Constant.serverResponse
	}

	static func isValidBroadcastText(_ text: String) -> BroadcastMessageType? {
		switch text {
		case Constant.serverDiscovery:
			return .serverDiscovery
		case Constant.serverResponse:
			return .serverResponse
		default:
			return nil
		}
	}
}
