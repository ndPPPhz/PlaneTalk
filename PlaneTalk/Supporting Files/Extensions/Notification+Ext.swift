//
//  Extensions.swift
//  SendiOS
//
//  Created by Annino De Petra on 23/02/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

extension Notification {
	/// Returns the frame of the keyboard.
	///
	/// - Note: If the keyboard is hidden due to a hardware keyboard then its
	///         height remains the same but it's just hidden offscreen with a Y offset.
	public var keyboardFrame: CGRect {
		guard let userInfo = userInfo, let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
			return .zero
		}

		return keyboardFrame
	}
}
