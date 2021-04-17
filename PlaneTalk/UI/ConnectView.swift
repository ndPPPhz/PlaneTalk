//
//  ConnectView.swift
//  PlaneTalk
//
//  Created by Annino De Petra on 17/04/2021.
//  Copyright © 2021 Annino De Petra. All rights reserved.
//

import UIKit

final class ConnectView: UIView, ViewDataConfigurable {
	struct ViewData: Equatable {
		struct ButtonViewData: Equatable {
			static func == (lhs: ConnectView.ViewData.ButtonViewData, rhs: ConnectView.ViewData.ButtonViewData) -> Bool {
				return lhs.title == rhs.title && lhs.color == rhs.color && lhs.backgroundColor == rhs.backgroundColor
			}

			var title: String
			var color: UIColor
			var backgroundColor: UIColor
			var tapHanlder: (() -> Void)?
		}

		var searchButtonViewData: ButtonViewData
		var serverButtonViewData: ButtonViewData
	}

	@IBOutlet private var searchServerButton: UIButton!
	@IBOutlet private var activityIndicator: UIActivityIndicatorView!
	@IBOutlet private var becomeServerButton: UIButton!

	private var searchActionHandler: (() -> Void)?
	private var serverActionHandler: (() -> Void)?

	func configure(with viewData: ViewData) {
		let searchButtonViewData = viewData.searchButtonViewData
		searchServerButton.setTitle(searchButtonViewData.title, for: .normal)
		searchServerButton.backgroundColor = searchButtonViewData.backgroundColor
		searchServerButton.setTitleColor(searchButtonViewData.color, for: .normal)
		searchServerButton.addTarget(self, action: #selector(didTapSearchButton), for: .primaryActionTriggered)
		searchActionHandler = searchButtonViewData.tapHanlder

		let serverButtonViewData = viewData.serverButtonViewData
		becomeServerButton.setTitle(serverButtonViewData.title, for: .normal)
		becomeServerButton.backgroundColor = serverButtonViewData.backgroundColor
		becomeServerButton.setTitleColor(serverButtonViewData.color, for: .normal)
		becomeServerButton.addTarget(self, action: #selector(didTapServerButton), for: .primaryActionTriggered)
		serverActionHandler = serverButtonViewData.tapHanlder
	}

	func showActivityIndicator(_ shouldShow: Bool) {
		shouldShow ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
	}

	@objc private func didTapSearchButton() {
		searchActionHandler?()
	}

	@objc private func didTapServerButton() {
		serverActionHandler?()
	}
}
