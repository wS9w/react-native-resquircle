import UIKit

@objc(ResquircleDrawingView)
public final class ResquircleDrawingView: UIView {
  private let squircleLayer = CAShapeLayer()
  private var shadowLayers: [CAShapeLayer] = []
  private var shadowSpecs: [ShadowSpec] = []

  private var radius: CGFloat = 0
  private var cornerSmoothingInternal: CGFloat = 0
  private var didReceiveBorderRadiusProp: Bool = false

  private struct PathCacheKey: Equatable {
    let width: CGFloat
    let height: CGFloat
    let radius: CGFloat
    let cornerSmoothing: CGFloat
    let lineWidth: CGFloat
  }

  private var lastFillKey: PathCacheKey? = nil
  private var lastFillPath: CGPath? = nil
  private var lastOuterKey: PathCacheKey? = nil
  private var lastOuterPath: CGPath? = nil

  // MARK: - Props (set from Fabric component view)

  @objc public var squircleBackgroundColor: UIColor = .clear {
    didSet { setBackgroundColor(squircleBackgroundColor) }
  }

  @objc public var squircleBorderColor: UIColor = .clear {
    didSet { setBorderColor(squircleBorderColor) }
  }

  @objc public var squircleBorderWidth: CGFloat = 0 {
    didSet { setBorderWidth(squircleBorderWidth) }
  }

  @objc public var squircleBoxShadow: NSString? = nil {
    didSet { setBoxShadow(squircleBoxShadow as String?) }
  }

  @objc public var borderRadius: CGFloat = 0 {
    didSet { setRadius(borderRadius) }
  }

  /// 0..1
  @objc public var cornerSmoothing: CGFloat = 0.6 {
    didSet { setCornerSmoothing(cornerSmoothing) }
  }

  @objc public var overflow: NSString? = "visible" {
    didSet { updateOverflow() }
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupSquircleLayer()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupSquircleLayer()
  }

  private func setupSquircleLayer() {
    layer.masksToBounds = false
    squircleLayer.contentsScale = UIScreen.main.scale
    squircleLayer.lineJoin = .round
    squircleLayer.lineCap = .round
    squircleLayer.allowsEdgeAntialiasing = true
    layer.addSublayer(squircleLayer)

    // Apply defaults
    setBackgroundColor(squircleBackgroundColor)
    setBorderColor(squircleBorderColor)
    setBorderWidth(squircleBorderWidth)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()

    // If, for any reason, the Fabric prop didn't arrive, fall back to the parent
    // container's cornerRadius (JS wrapper still applies borderRadius there).
    if !didReceiveBorderRadiusProp, let superRadius = superview?.layer.cornerRadius {
      if superRadius != radius {
        radius = superRadius
        invalidatePathCache()
      }
    }

    squircleLayer.frame = bounds
    let fillPath = cachedFillPath()
    squircleLayer.path = fillPath
    updateShadowPaths()

    // Keep the clipping mask in sync with bounds/radius changes.
    updateClippingMaskIfNeeded()
  }

  private func cachedFillPath() -> CGPath {
    let key =
      PathCacheKey(
        width: bounds.width,
        height: bounds.height,
        radius: radius,
        cornerSmoothing: cornerSmoothingInternal,
        lineWidth: squircleLayer.lineWidth
      )
    if key == lastFillKey, let path = lastFillPath {
      return path
    }
    let path = createSquirclePath(insetBy: squircleLayer.lineWidth, radius: radius)
    lastFillKey = key
    lastFillPath = path
    return path
  }

  private func cachedOuterPath() -> CGPath {
    let baseRadius = radius + (squircleLayer.lineWidth / 2)
    let key =
      PathCacheKey(
        width: bounds.width,
        height: bounds.height,
        radius: baseRadius,
        cornerSmoothing: cornerSmoothingInternal,
        lineWidth: 0
      )
    if key == lastOuterKey, let path = lastOuterPath {
      return path
    }
    let path = createSquirclePath(insetBy: 0, radius: baseRadius)
    lastOuterKey = key
    lastOuterPath = path
    return path
  }

  private func invalidatePathCache() {
    lastFillKey = nil
    lastFillPath = nil
    lastOuterKey = nil
    lastOuterPath = nil
  }

  private func createSquirclePath(insetBy inset: CGFloat, radius: CGFloat) -> CGPath {
    let width: CGFloat = bounds.width
    let height: CGFloat = bounds.height

    if width <= 0 || height <= 0 {
      return CGPath(rect: .zero, transform: nil)
    }

    let path =
      SquirclePath.create(
        width: width - inset,
        height: height - inset,
        radius: radius,
        cornerSmoothing: cornerSmoothingInternal
      )

    if inset != 0 {
      var translationTransform =
        CGAffineTransform(translationX: inset / 2, y: inset / 2)
      return path.copy(using: &translationTransform) ?? path
    }

    return path
  }

  private func setBackgroundColor(_ backgroundColor: UIColor) {
    squircleLayer.fillColor = backgroundColor.cgColor
    for layer in shadowLayers {
      layer.fillColor = backgroundColor.cgColor
    }
  }

  private func setBorderColor(_ borderColor: UIColor) {
    squircleLayer.strokeColor = borderColor.cgColor
  }

  private func setBorderWidth(_ borderWidth: CGFloat) {
    squircleLayer.lineWidth = borderWidth
    invalidatePathCache()
    setNeedsLayout()
  }

  private func setCornerSmoothing(_ cornerSmoothing: CGFloat) {
    cornerSmoothingInternal = cornerSmoothing
    invalidatePathCache()
    setNeedsLayout()
  }

  private func setRadius(_ radius: CGFloat) {
    self.radius = radius
    didReceiveBorderRadiusProp = true
    invalidatePathCache()
    setNeedsLayout()
  }

  private func updateOverflow() {
    let shouldClip = overflow?.lowercased == "hidden"
    // For this native overlay view, overflow only affects its own drawing.
    // Clipping the view itself is the most intuitive behavior.
    layer.mask = shouldClip ? clippingMaskLayer() : nil
    setNeedsLayout()
  }

  private func clippingMaskLayer() -> CAShapeLayer {
    let mask = CAShapeLayer()
    mask.frame = bounds
    mask.path = cachedOuterPath()
    return mask
  }

  private func updateClippingMaskIfNeeded() {
    guard let mask = layer.mask as? CAShapeLayer else { return }
    mask.frame = bounds
    mask.path = cachedOuterPath()
  }
}

// MARK: - Shadow rendering (iOS)

private struct ShadowSpec {
  let offset: CGSize
  let blur: CGFloat
  let spread: CGFloat
  let color: UIColor
  let opacity: Float
}

private extension ResquircleDrawingView {
  func setBoxShadow(_ boxShadow: String?) {
    shadowSpecs = Self.parseBoxShadow(boxShadow)
    rebuildShadowLayers()
    setNeedsLayout()
  }

  func rebuildShadowLayers() {
    for l in shadowLayers { l.removeFromSuperlayer() }
    shadowLayers.removeAll()

    guard !shadowSpecs.isEmpty else { return }

    for spec in shadowSpecs {
      let l = CAShapeLayer()
      l.contentsScale = UIScreen.main.scale
      l.frame = bounds
      l.fillColor = squircleLayer.fillColor
      l.strokeColor = nil
      l.lineWidth = 0
      l.masksToBounds = false

      l.shadowColor = spec.color.withAlphaComponent(1).cgColor
      l.shadowOpacity = spec.opacity
      l.shadowRadius = max(0, spec.blur)
      l.shadowOffset = spec.offset

      layer.insertSublayer(l, below: squircleLayer)
      shadowLayers.append(l)
    }
  }

  func updateShadowPaths() {
    guard !shadowLayers.isEmpty, shadowLayers.count == shadowSpecs.count else { return }

    let baseRadius = radius + (squircleLayer.lineWidth / 2)
    let basePath = cachedOuterPath()

    for (index, l) in shadowLayers.enumerated() {
      let spec = shadowSpecs[index]
      let spread = spec.spread

      l.frame = bounds
      l.path = basePath

      let spreadPath = createSquirclePath(insetBy: -spread * 2, radius: baseRadius + spread)
      l.shadowPath = spreadPath
    }
  }

  static func parseBoxShadow(_ boxShadow: String?) -> [ShadowSpec] {
    guard let s = boxShadow?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
      return []
    }

    let parts = splitTopLevelCommas(s)
    var specs: [ShadowSpec] = []

    for part in parts {
      let t = part.trimmingCharacters(in: .whitespacesAndNewlines)
      if t.isEmpty { continue }

      let tokens = splitTopLevelWhitespace(t)
      if tokens.count < 4 { continue }

      let x = parseLength(tokens[0]) ?? 0
      let y = parseLength(tokens[1]) ?? 0
      let blur = parseLength(tokens[2]) ?? 0

      let spread: CGFloat
      let colorTokenIndex: Int
      if tokens.count >= 5, let sp = parseLength(tokens[3]) {
        spread = sp
        colorTokenIndex = 4
      } else {
        spread = 0
        colorTokenIndex = 3
      }

      let colorString = tokens[colorTokenIndex]
      guard let (color, opacity) = parseColor(colorString) else { continue }

      specs.append(
        ShadowSpec(
          offset: CGSize(width: x, height: y),
          blur: blur,
          spread: spread,
          color: color,
          opacity: opacity
        )
      )
    }

    return specs
  }

  static func splitTopLevelCommas(_ s: String) -> [String] {
    var result: [String] = []
    var current = ""
    var depth = 0
    for ch in s {
      if ch == "(" { depth += 1 }
      if ch == ")" { depth = max(0, depth - 1) }
      if ch == "," && depth == 0 {
        result.append(current)
        current = ""
      } else {
        current.append(ch)
      }
    }
    if !current.isEmpty { result.append(current) }
    return result
  }

  static func splitTopLevelWhitespace(_ s: String) -> [String] {
    var result: [String] = []
    var current = ""
    var depth = 0

    func flush() {
      let t = current.trimmingCharacters(in: .whitespacesAndNewlines)
      if !t.isEmpty { result.append(t) }
      current = ""
    }

    for ch in s {
      if ch == "(" { depth += 1 }
      if ch == ")" { depth = max(0, depth - 1) }

      if depth == 0, ch.isWhitespace {
        flush()
      } else {
        current.append(ch)
      }
    }
    flush()
    return result
  }

  static func parseLength(_ token: String) -> CGFloat? {
    let t = token.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "px", with: "")
    return Double(t).map { CGFloat($0) }
  }

  /// Returns (UIColorWithoutAlpha, opacity)
  static func parseColor(_ token: String) -> (UIColor, Float)? {
    let t = token.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.hasPrefix("rgba("), t.hasSuffix(")") {
      let inner = String(t.dropFirst(5).dropLast(1))
      let parts = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      if parts.count != 4 { return nil }
      guard
        let r = Double(parts[0]),
        let g = Double(parts[1]),
        let b = Double(parts[2]),
        let a = Double(parts[3])
      else { return nil }
      let opacity = Float(max(0, min(1, a)))
      let color =
        UIColor(
          red: CGFloat(max(0, min(255, r))) / 255,
          green: CGFloat(max(0, min(255, g))) / 255,
          blue: CGFloat(max(0, min(255, b))) / 255,
          alpha: 1
        )
      return (color, opacity)
    }
    if t.hasPrefix("rgb("), t.hasSuffix(")") {
      let inner = String(t.dropFirst(4).dropLast(1))
      let parts = inner.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      if parts.count != 3 { return nil }
      guard
        let r = Double(parts[0]),
        let g = Double(parts[1]),
        let b = Double(parts[2])
      else { return nil }
      let color =
        UIColor(
          red: CGFloat(max(0, min(255, r))) / 255,
          green: CGFloat(max(0, min(255, g))) / 255,
          blue: CGFloat(max(0, min(255, b))) / 255,
          alpha: 1
        )
      return (color, 1)
    }
    if t.hasPrefix("#") {
      let hex = String(t.dropFirst())
      if hex.count == 6 {
        let r = UInt8(hex.prefix(2), radix: 16) ?? 0
        let g = UInt8(hex.dropFirst(2).prefix(2), radix: 16) ?? 0
        let b = UInt8(hex.dropFirst(4).prefix(2), radix: 16) ?? 0
        let color = UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
        return (color, 1)
      }
      if hex.count == 8 {
        // RRGGBBAA
        let r = UInt8(hex.prefix(2), radix: 16) ?? 0
        let g = UInt8(hex.dropFirst(2).prefix(2), radix: 16) ?? 0
        let b = UInt8(hex.dropFirst(4).prefix(2), radix: 16) ?? 0
        let a = UInt8(hex.dropFirst(6).prefix(2), radix: 16) ?? 255
        let color = UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
        return (color, Float(CGFloat(a) / 255))
      }
    }
    return nil
  }
}

