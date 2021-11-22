//
//  FixedSize.swift
//  VirtualApple
//
//  Created by Saagar Jha on 11/22/21.
//

import AppKit

extension NSView {
	func disableResizing() {
		for orientation: NSLayoutConstraint.Orientation in [.vertical, .horizontal] {
			setContentHuggingPriority(.required, for: orientation)
			setContentCompressionResistancePriority(.required, for: orientation)
		}
	}
}

extension NSStackView {
	convenience init(fixedSizeViews: [NSView]) {
		self.init(views: fixedSizeViews)
		for view in views {
			view.disableResizing()
		}
		distribution = .fillProportionally
		fitContents()
	}
	
	func fitContents() {
		setHuggingPriority(.defaultHigh, for: .vertical)
		setHuggingPriority(.defaultHigh, for: .horizontal)
	}
}
