//
//  Toolbar.swift
//  VirtualApple
//
//  Created by Saagar Jha on 11/22/21.
//

import AppKit

enum ToolbarIdentifiers: String, CaseIterable {
	case settings
	case toggleState

	var toolbarItemIdentifier: NSToolbarItem.Identifier {
		.init(rawValue)
	}

	init?(_ rawValue: NSToolbarItem.Identifier) {
		self.init(rawValue: rawValue.rawValue)
	}
}

extension WindowController: NSToolbarDelegate {
	func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return ToolbarIdentifiers.allCases.map(\.toolbarItemIdentifier)
	}

	func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
		return toolbarAllowedItemIdentifiers(toolbar)
	}

	func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
		let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
		switch ToolbarIdentifiers(itemIdentifier)! {
			case .settings:
				toolbarItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")
				toolbarItem.label = "Settings"
				toolbarItem.target = viewController
				toolbarItem.action = #selector(viewController.openSettings(_:))
			case .toggleState:
				toolbarItem.image = NSImage(systemSymbolName: "play", accessibilityDescription: "Run")
				toolbarItem.label = "Run"
				toolbarItem.target = viewController
				toolbarItem.action = #selector(ViewController.toggleState(_:))
		}
		return toolbarItem
	}
}
