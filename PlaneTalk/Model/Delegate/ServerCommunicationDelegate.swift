//
//  TCP.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 14/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

protocol ServerCommunicationDelegate: AnyObject {
	func serverDidSendItsText(_ text: String)
	func serverDidSendClientText(_ text: String, senderIP: String)
}
