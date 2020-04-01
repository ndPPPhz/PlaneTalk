//
//  UIChatTableView.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 01/04/2020.
//  Copyright © 2020 Annino De Petra. All rights reserved.
//

import UIKit

final class UIChatTableView: UITableView {

	private var reloadDataCompletionBlock: (() -> Void)?

	override func layoutSubviews() {
		super.layoutSubviews()
		reloadDataCompletionBlock?()
		reloadDataCompletionBlock = nil
	}

	func reloadDataWithCompletion(completion: @escaping () -> Void) {
	  reloadDataCompletionBlock = completion
	  self.reloadData()
	}
}
