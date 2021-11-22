//
//  AppDelegate.swift
//  VirtualApple
//
//  Created by Saagar Jha on 11/20/21.
//

import Cocoa
import UniformTypeIdentifiers

extension UTType {
	static let vmApple = Self(exportedAs: "com.saagarjha.vmapple")
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {	
	func applicationWillFinishLaunching(_ notification: Notification) {
		Self.setupMenu()
	}
	
	func application(_ application: NSApplication, open urls: [URL]) {
		for url in urls {
			do {
				let virtualMachine = try VirtualMachine(opening: url)
				WindowController(virtualMachine: virtualMachine).showWindow(self)
				NSDocumentController.shared.noteNewRecentDocumentURL(virtualMachine.url)
			} catch {
				NSAlert(error: error).runModal()
			}
		}
	}
	
	func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
		openDocument(sender)
		return true
	}
	
	@objc
	func newDocument(_ sender: Any?) {
		newVirtualMachineController()?.showWindow(self)
	}
	
	@objc
	func openDocument(_ sender: Any?) {
		let openPanel = NSOpenPanel()
		openPanel.allowsMultipleSelection = true
		unsafeBitCast(openPanel, to: _NSSavePanel.self)._showNewDocumentButton = true
		openPanel.allowedContentTypes = [.vmApple]
		guard openPanel.runModal() == .OK else {
			return
		}
		application(NSApp, open: openPanel.urls)
	}
	
	@objc
	@IBAction func newWindowForTab(_ sender: Any?) {
		guard let controller = newVirtualMachineController() else {
			return
		}
		if let window = sender as? NSWindow {
			window.addTabbedWindow(controller.window!, ordered: .above)
		}
		controller.showWindow(sender)
	}
	
	func newVirtualMachineController() -> WindowController? {
		let savePanel = NSSavePanel()
		savePanel.allowedContentTypes = [.vmApple]
		guard savePanel.runModal() == .OK,
			  let url = savePanel.url else {
			return nil
		}
		do {
			let virtualMachine = try VirtualMachine(creatingAt: url)
			NSDocumentController.shared.noteNewRecentDocumentURL(url)
			return WindowController(virtualMachine: virtualMachine)
		} catch {
			NSAlert(error: error).runModal()
			return nil
		}
	}
}

