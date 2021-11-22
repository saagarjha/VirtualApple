//
//  Menu.swift
//  VirtualApple
//
//  Created by Saagar Jha on 11/22/21.
//

import AppKit

let NSRecentDocumentsMenuName = unsafeBitCast(dlsym(dlopen(nil, RTLD_LAZY), "NSRecentDocumentsMenuName"), to: UnsafePointer<NSString>?.self)!.pointee

@objc protocol _NSMenu {
	var _menuName: NSString { get @objc(_setMenuName:) set }
}

@objc protocol _NSSavePanel {
	var _showNewDocumentButton: Bool { get @objc(_setShowNewDocumentButton:) set }
}

extension NSMenu {
	convenience init(title: String? = nil, items: [NSMenuItem]?) {
		defer {
			items.flatMap {
				self.items = $0
			}
		}
		guard let title = title else {
			self.init()
			return
		}
		self.init(title: title)
	}
}

extension NSMenuItem {
	convenience init(submenuTitle: String, items: [NSMenuItem]?) {
		self.init(title: submenuTitle, action: nil, keyEquivalent: "")
		submenu = NSMenu(title: submenuTitle, items: items)
	}
	
	convenience init(title: String, action: Selector? = nil, keyEquivalent: String = "", keyEquivalentModifierMask: NSEvent.ModifierFlags? = nil, tag: Int? = nil) {
		self.init(title: title, action: action, keyEquivalent: keyEquivalent)
		keyEquivalentModifierMask.flatMap {
			self.keyEquivalentModifierMask = $0
		}
		tag.flatMap {
			self.tag = $0
		}
	}
}

extension AppDelegate {
	static func setupMenu() {
		let appName = Bundle.main.infoDictionary!["CFBundleName"]! as! String
		let servicesMenuItem = NSMenuItem(submenuTitle: "Services", items: nil)
		let openRecentMenuItem = NSMenuItem(submenuTitle: "Open Recent", items: [
			NSMenuItem(title: "Clear Menu", action: #selector(NSDocumentController.clearRecentDocuments(_:)))
		])
		let windowMenuItem = NSMenuItem(submenuTitle: "Window", items: [
			NSMenuItem(title: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m"),
			NSMenuItem(title: "Zoom", action: #selector(NSWindow.zoom(_:))),
			NSMenuItem.separator(),
			NSMenuItem(title: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:))),
		])
		NSApp.servicesMenu = servicesMenuItem.submenu
		unsafeBitCast(openRecentMenuItem.submenu, to: _NSMenu.self)._menuName = NSRecentDocumentsMenuName
		NSApp.windowsMenu = windowMenuItem.submenu
		NSApp.mainMenu = NSMenu(items: [
			NSMenuItem(submenuTitle: appName, items: [
				NSMenuItem(title: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""),
				NSMenuItem.separator(),
				servicesMenuItem,
				NSMenuItem.separator(),
				NSMenuItem(title: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"),
				NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h", keyEquivalentModifierMask: [.command, .option]),
				NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:))),
				NSMenuItem.separator(),
				NSMenuItem(title: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"),
			]),
			NSMenuItem(submenuTitle: "File", items: [
				NSMenuItem(title: "New…", action: #selector(NSDocumentController.newDocument(_:)), keyEquivalent: "n"),
				NSMenuItem(title: "Open…", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o"),
				openRecentMenuItem,
				NSMenuItem.separator(),
				NSMenuItem(title: "Run", action: #selector(ViewController.run(_:)), keyEquivalent: "r"),
				NSMenuItem(title: "Stop", action: #selector(ViewController.stop(_:)), keyEquivalent: "."),
				NSMenuItem.separator(),
				NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"),
			]),
			NSMenuItem(submenuTitle: "Edit", items: [
				NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"),
				NSMenuItem(title: "Undo", action: Selector(("redo:")), keyEquivalent: "Z"),
				NSMenuItem.separator(),
				NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"),
				NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"),
				NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"),
				NSMenuItem(title: "Paste and Match Style", action: #selector(NSText.paste(_:)), keyEquivalent: "V", keyEquivalentModifierMask: [.command, .option]),
				NSMenuItem(title: "Delete", action: #selector(NSText.delete(_:))),
				NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"),
				NSMenuItem.separator(),
				NSMenuItem(submenuTitle: "Find", items: [
					NSMenuItem(title: "Find…", action: #selector(NSResponder.performTextFinderAction(_:)), keyEquivalent: "f", tag: NSTextFinder.Action.showFindInterface.rawValue),
					NSMenuItem(title: "Find and Replace…", action: #selector(NSResponder.performTextFinderAction(_:)), keyEquivalent: "f", keyEquivalentModifierMask: [.command, .option], tag: NSTextFinder.Action.replaceAndFind.rawValue),
					NSMenuItem(title: "Find Next", action: #selector(NSResponder.performTextFinderAction(_:)), keyEquivalent: "g", tag: NSTextFinder.Action.nextMatch.rawValue),
					NSMenuItem(title: "Find Previous", action: #selector(NSResponder.performTextFinderAction(_:)), keyEquivalent: "G", tag: NSTextFinder.Action.previousMatch.rawValue),
					NSMenuItem(title: "Use Selection for Find", action: #selector(NSResponder.performTextFinderAction(_:)), keyEquivalent: "e", tag: NSTextFinder.Action.setSearchString.rawValue),
					NSMenuItem(title: "Jump to Selection", action: #selector(NSResponder.centerSelectionInVisibleArea(_:)), keyEquivalent: "j"),
				]),
				NSMenuItem(submenuTitle: "Spelling and Grammar", items: [
					NSMenuItem(title: "Show Spelling and Grammar", action: #selector(NSTextCheckingController.showGuessPanel(_:)), keyEquivalent: ":"),
					NSMenuItem(title: "Check Document Now", action: #selector(NSTextCheckingController.checkSpelling(_:)), keyEquivalent: ";"),
					NSMenuItem(title: "Check Spelling While Typing", action: #selector(NSTextView.toggleContinuousSpellChecking(_:))),
					NSMenuItem(title: "Correct Spelling Automatically", action: #selector(NSTextView.toggleAutomaticSpellingCorrection(_:))),
				]),
				NSMenuItem(submenuTitle: "Substitutions", items: [
					NSMenuItem(title: "Show Substitutions", action: #selector(NSTextCheckingController.orderFrontSubstitutionsPanel(_:))),
					NSMenuItem.separator(),
					NSMenuItem(title: "Smart Copy/Paste", action: #selector(NSTextView.toggleSmartInsertDelete(_:))),
					NSMenuItem(title: "Smart Quotes", action: #selector(NSTextView.toggleAutomaticQuoteSubstitution(_:))),
					NSMenuItem(title: "Smart Dashes", action: #selector(NSTextView.toggleAutomaticDashSubstitution(_:))),
					NSMenuItem(title: "Smart Links", action: #selector(NSTextView.toggleAutomaticLinkDetection(_:))),
					NSMenuItem(title: "Data Detectors", action: #selector(NSTextView.toggleAutomaticDataDetection(_:))),
					NSMenuItem(title: "Text Replacement", action: #selector(NSTextView.toggleAutomaticTextReplacement(_:))),
				]),
				NSMenuItem(submenuTitle: "Transformations", items: [
					NSMenuItem(title: "Make Upper Case", action: #selector(NSResponder.uppercaseWord(_:))),
					NSMenuItem(title: "Make Lower Case", action: #selector(NSResponder.lowercaseWord(_:))),
					NSMenuItem(title: "Capitalize", action: #selector(NSResponder.capitalizeWord(_:))),
				]),
				NSMenuItem(submenuTitle: "Speech", items: [
					NSMenuItem(title: "Start Speaking", action: #selector(NSSpeechSynthesizer.startSpeaking(_:))),
					NSMenuItem(title: "Stop Speaking", action: #selector(NSTextView.stopSpeaking(_:))),
				]),
			]),
			NSMenuItem(submenuTitle: "View", items: [
				NSMenuItem(title: "Show Toolbar", action: #selector(NSWindow.toggleToolbarShown(_:)), keyEquivalent: "t", keyEquivalentModifierMask: [.command, .option]),
				NSMenuItem(title: "Customize Toolbar…", action: #selector(NSToolbar.runCustomizationPalette(_:))),
				NSMenuItem.separator(),
			]),
			windowMenuItem,
			NSMenuItem(submenuTitle: "Help", items: [
				NSMenuItem(title: "Help", action: #selector(NSApplication.showHelp(_:)), keyEquivalent: "?"),
			])
		])
	}
}
