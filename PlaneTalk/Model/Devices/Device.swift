//
//  Device.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 14/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

final class Device: BroadcastDevice {
	var ip: String
	var broadcastIP: String
	
	// Client udp broadcast socket
	var udp_broadcast_message_socket: Int32 = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
	// Server udp reception socket
	var udp_reception_message_socket: Int32 = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)

	// The kqueue for all the udp events
	lazy var udpEventsKQueue: Int32 = kqueue()

	weak var roleGrantDelegate: GrantRoleDelegate?
	weak var udpCommunicationDelegate: UDPCommunicationDelegate?

	init(ip: String, broadcastIP: String) {
		self.ip = ip
		self.broadcastIP = broadcastIP
	}
}
