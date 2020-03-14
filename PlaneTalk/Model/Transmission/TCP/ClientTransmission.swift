//
//  Client.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 14/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

protocol ClientTCPCommunicationDelegate: UDPCommunicationDelegate {
	func clientDidReceiveTCPText(_ text: String)
	func clientDidSendText(_ text: String)
}
