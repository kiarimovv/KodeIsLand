//
//  NotchViewController.swift
//  ClaudeIsland
//
//  Hosts the SwiftUI NotchView in AppKit with click-through support
//

import AppKit
import SwiftUI

/// Custom NSHostingView that passes through clicks on transparent/empty areas.
class PassThroughHostingView<Content: View>: NSHostingView<Content> {
    var isOpened: () -> Bool = { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        // When opened, let SwiftUI handle all hit testing naturally
        if isOpened() {
            return super.hitTest(point)
        }
        // When closed, only accept hits in the notch area (top center)
        let result = super.hitTest(point)
        return result
    }
}

class NotchViewController: NSViewController {
    private let viewModel: NotchViewModel
    private var hostingView: PassThroughHostingView<NotchView>!

    init(viewModel: NotchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        hostingView = PassThroughHostingView(rootView: NotchView(viewModel: viewModel))

        hostingView.isOpened = { [weak self] in
            self?.viewModel.status == .opened
        }

        self.view = hostingView
    }
}
