//
//  ChatMessage.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 12/03/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import Foundation

struct ChatMessage {
	let text: String
	let sender: String
	let isMe: Bool
}

enum MessageType {
	// Full text refers to the all protocol string sent whereas the content is the actualy typed text
	case text(fullText: String, content: String, senderAlias: String)
	case nicknameChangeRequest(nickname: String)
}
