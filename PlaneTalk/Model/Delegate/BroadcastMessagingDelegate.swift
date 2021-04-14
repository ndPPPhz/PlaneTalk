//
//  UDP.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 14/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

protocol BroadcastMessagingDelegate: AnyObject {
	func deviceDidReceiveBroadcastMessage(_ text: String, from sender: String)
}
