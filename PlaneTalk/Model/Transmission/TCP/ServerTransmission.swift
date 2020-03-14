//
//  TCP.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 14/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

protocol ServerTCPCommunicationDelegate: UDPCommunicationDelegate {
	func serverWantsToSendTCPText(_ text: String) -> MessageType
	func serverDidReceiveClientTCPText(_ text: String, senderIP: String) -> MessageType

	func serverDidSendText(_ text: String)
	func serverDidSendClientText(_ text: String, senderAlias: String)
	func serverDidSendInformationText(_ text: String)
}
