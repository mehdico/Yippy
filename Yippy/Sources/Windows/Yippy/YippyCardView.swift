//
//  YippyCardView.swift
//  Yippy
//
//  Square card rendering of a HistoryItem for the horizontal layout.
//

import Cocoa

class YippyCardView: NSView {

    private let contentView = NSView()
    private let imageView = NSImageView()
    private let textView = NSTextField(labelWithString: "")
    private let captionView = NSTextField(labelWithString: "")
    private let shortcutLabel = NSTextField(labelWithString: "")
    private let sourceIconView = NSImageView()
    private let sourceNameLabel = NSTextField(labelWithString: "")
    private let sourceStack = NSStackView()

    var isSelected: Bool = false { didSet { updateHighlight() } }

    private var imageTopBelowSource: NSLayoutConstraint!
    private var imageTopAtTop: NSLayoutConstraint!
    private var textTopBelowSource: NSLayoutConstraint!
    private var textTopAtTop: NSLayoutConstraint!

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.cornerRadius = 10
        layer?.masksToBounds = true

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.wantsLayer = true
        contentView.layer?.cornerRadius = 8
        addSubview(contentView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        contentView.addSubview(imageView)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = NSFont.systemFont(ofSize: 11)
        textView.textColor = .labelColor
        textView.maximumNumberOfLines = 8
        textView.lineBreakMode = .byTruncatingTail
        textView.alignment = .left
        textView.cell?.wraps = true
        textView.cell?.isScrollable = false
        contentView.addSubview(textView)

        captionView.translatesAutoresizingMaskIntoConstraints = false
        captionView.font = NSFont.systemFont(ofSize: 10)
        captionView.textColor = .secondaryLabelColor
        captionView.maximumNumberOfLines = 1
        captionView.lineBreakMode = .byTruncatingMiddle
        captionView.alignment = .center
        contentView.addSubview(captionView)

        shortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        shortcutLabel.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        shortcutLabel.textColor = NSColor.white.withAlphaComponent(0.85)
        shortcutLabel.alignment = .center
        shortcutLabel.wantsLayer = true
        shortcutLabel.layer?.cornerRadius = 4
        shortcutLabel.layer?.masksToBounds = true
        if #available(OSX 10.14, *) {
            shortcutLabel.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        } else {
            shortcutLabel.layer?.backgroundColor = NSColor.systemBlue.cgColor
        }
        addSubview(shortcutLabel)

        sourceIconView.translatesAutoresizingMaskIntoConstraints = false
        sourceIconView.imageScaling = .scaleProportionallyDown
        sourceNameLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        sourceNameLabel.textColor = NSColor.white.withAlphaComponent(0.95)
        sourceNameLabel.maximumNumberOfLines = 1
        sourceNameLabel.lineBreakMode = .byTruncatingTail
        sourceStack.translatesAutoresizingMaskIntoConstraints = false
        sourceStack.orientation = .horizontal
        sourceStack.spacing = 5
        sourceStack.alignment = .centerY
        sourceStack.edgeInsets = NSEdgeInsets(top: 3, left: 5, bottom: 3, right: 7)
        sourceStack.wantsLayer = true
        sourceStack.layer?.cornerRadius = 8
        sourceStack.layer?.backgroundColor = NSColor(white: 0, alpha: 0.45).cgColor
        sourceStack.addArrangedSubview(sourceIconView)
        sourceStack.addArrangedSubview(sourceNameLabel)
        contentView.addSubview(sourceStack)

        let inset: CGFloat = 4
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: inset),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset),

            // Source app strip flush with the contentView's top-left corner.
            sourceStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sourceStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            sourceStack.trailingAnchor.constraint(lessThanOrEqualTo: shortcutLabel.leadingAnchor, constant: -4),

            sourceIconView.widthAnchor.constraint(equalToConstant: 16),
            sourceIconView.heightAnchor.constraint(equalToConstant: 16),

            // Content sits below the source strip when present, else at top.
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),

            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            textView.bottomAnchor.constraint(lessThanOrEqualTo: captionView.topAnchor, constant: -4),

            captionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 6),
            captionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            captionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            imageView.bottomAnchor.constraint(lessThanOrEqualTo: captionView.topAnchor, constant: -4),

            shortcutLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            shortcutLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            shortcutLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 28),
            shortcutLabel.heightAnchor.constraint(equalToConstant: 16),
        ])

        imageTopBelowSource = imageView.topAnchor.constraint(equalTo: sourceStack.bottomAnchor, constant: 4)
        imageTopAtTop = imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6)
        textTopBelowSource = textView.topAnchor.constraint(equalTo: sourceStack.bottomAnchor, constant: 4)
        textTopAtTop = textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        // Default to "no source" until configure() is called.
        imageTopAtTop.isActive = true
        textTopAtTop.isActive = true

        updateHighlight()
    }

    func configure(with item: HistoryItem, shortcut: Int?, isRichText: Bool) {
        textView.isHidden = true
        imageView.isHidden = true
        captionView.isHidden = true
        imageView.image = nil
        textView.stringValue = ""
        captionView.stringValue = ""

        if let color = item.getColor() {
            imageView.isHidden = true
            captionView.isHidden = false
            captionView.stringValue = item.getPlainTextString() ?? color.hexString
            contentView.layer?.backgroundColor = color.cgColor
        } else if let fileUrl = item.getFileUrl() {
            contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            imageView.isHidden = false
            imageView.image = item.getThumbnailImage() ?? item.getFileIcon()
            captionView.isHidden = false
            captionView.stringValue = fileUrl.lastPathComponent
        } else if let img = item.getImage() {
            contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            imageView.isHidden = false
            imageView.image = img
        } else {
            contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            textView.isHidden = false
            let attr = HistoryItemText.getAttributedString(forItem: item, usingItemRtf: isRichText)
            textView.attributedStringValue = attr
        }

        if let s = shortcut, s < 10 {
            shortcutLabel.isHidden = false
            shortcutLabel.stringValue = "⌘\(s)"
        } else {
            shortcutLabel.isHidden = true
        }

        if let name = item.getSourceAppName() {
            sourceStack.isHidden = false
            sourceNameLabel.stringValue = name
            sourceIconView.image = item.getSourceAppIcon()
            imageTopAtTop.isActive = false
            textTopAtTop.isActive = false
            imageTopBelowSource.isActive = true
            textTopBelowSource.isActive = true
        } else {
            sourceStack.isHidden = true
            sourceNameLabel.stringValue = ""
            sourceIconView.image = nil
            imageTopBelowSource.isActive = false
            textTopBelowSource.isActive = false
            imageTopAtTop.isActive = true
            textTopAtTop.isActive = true
        }

        updateHighlight()
    }

    private func updateHighlight() {
        let color: CGColor
        if isSelected {
            if #available(OSX 10.14, *) {
                color = NSColor.controlAccentColor.withAlphaComponent(0.9).cgColor
            } else {
                color = NSColor.systemBlue.withAlphaComponent(0.7).cgColor
            }
        } else {
            color = NSColor.clear.cgColor
        }
        guard let layer = layer else { return }
        let anim = CABasicAnimation(keyPath: "backgroundColor")
        anim.fromValue = layer.backgroundColor
        anim.toValue = color
        anim.duration = 0.07
        anim.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(anim, forKey: "bgColor")
        layer.backgroundColor = color
    }
}

private extension NSColor {
    var hexString: String {
        guard let rgb = usingColorSpace(.deviceRGB) else { return "" }
        let r = Int(round(rgb.redComponent * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
