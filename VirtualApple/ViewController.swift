//
//  ViewController.swift
//  VirtualApple
//
//  Created by Saagar Jha on 11/20/21.
//

import Cocoa
import Virtualization

@MainActor
class ViewController: NSViewController, NSToolbarItemValidation, NSMenuItemValidation {
	var virtualMachine: VirtualMachine!
	var virtualMachineView: VZVirtualMachineView!

	convenience init(virtualMachine: VirtualMachine) {
		self.init()
		self.virtualMachine = virtualMachine
	}

	override func loadView() {
		setupVirtualMachineView()
	}

	func setupVirtualMachineView() {
		let virtualMachineView = VZVirtualMachineView()
		virtualMachineView.capturesSystemKeys = true
		virtualMachineView.frame.size = self.virtualMachineView?.frame.size ?? NSSize(width: 640, height: 400)
		self.virtualMachineView = virtualMachineView
		view = virtualMachineView
	}

	@IBAction func openSettings(_ sender: NSToolbarItem) {
		presentAsSheet(ConfigurationViewController(virtualMachine: virtualMachine))
	}

	@IBAction func toggleState(_ sender: NSToolbarItem) {
		if virtualMachine.metadata.installed {
			(!virtualMachine.running ? run : stop)(sender)
		} else {
			presentAsSheet(InstallViewController(virtualMachine: virtualMachine))
		}
	}

	@IBAction func run(_ sender: Any?) {
		Task {
			try virtualMachine.setupVirtualMachine()
			view.window!.contentAspectRatio = NSSize(width: virtualMachine.metadata.configuration!.screenWidth, height: virtualMachine.metadata.configuration!.screenHeight)
			setupVirtualMachineView()
			virtualMachineView.virtualMachine = virtualMachine.virtualMachine
			try await virtualMachine.start()
			view.window!.toolbar!.validateVisibleItems()
		}.presentErrorIfNecessary(window: view.window!)
	}

	@IBAction func stop(_ sender: Any?) {
		Task {
			try await virtualMachine.stop()
			view.window!.toolbar!.validateVisibleItems()
		}.presentErrorIfNecessary(window: view.window!)
	}

	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		switch menuItem.action {
			case #selector(run(_:)):
				return !virtualMachine.running
			case #selector(stop(_:)):
				return virtualMachine.running
			default:
				preconditionFailure()
		}
	}

	func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
		switch ToolbarIdentifiers(item.itemIdentifier)! {
			case .settings:
				return !virtualMachine.running
			case .toggleState:
				item.image = virtualMachine.running ? NSImage(systemSymbolName: "stop", accessibilityDescription: "Stop") : NSImage(systemSymbolName: "play", accessibilityDescription: "Run")
				view.window!.isDocumentEdited = virtualMachine.running
				return true
		}
	}
}

extension Task where Success == Void, Failure == Error {
	func presentErrorIfNecessary(window: NSWindow) {
		Task { @MainActor in
			do {
				try await value
			} catch {
				await NSAlert(error: error).beginSheetModal(for: window)
			}
		}
	}
}
