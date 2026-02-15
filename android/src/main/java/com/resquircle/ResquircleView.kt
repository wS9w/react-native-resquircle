package com.resquircle

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.Path
import com.facebook.react.views.view.ReactViewGroup
import kotlin.math.roundToInt

class ResquircleView(context: Context) : ReactViewGroup(context) {
  private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
  private val borderPaint = Paint(paint)
  private val path = Path() // fill/border path
  private val clipPath = Path() // inner clip for children
  private var shadowSpecs: List<ShadowSpec> = emptyList()
  private var shadowPaints: List<Paint> = emptyList()
  private var shadowPaths: List<Path> = emptyList()

  private var cornerSmoothing = 1.0f
  private var borderColor = 0xFF000000.toInt()
  private var borderWidth = 0f // dp
  private var backgroundColorInt = 0x00000000
  private var borderRadius = 0f // px
  private var boxShadowString: String? = null
  private var clipContent: Boolean = false

  init {
    paint.color = backgroundColorInt
    paint.style = Paint.Style.FILL
    paint.isDither = true

    borderPaint.isDither = true
    borderPaint.strokeJoin = Paint.Join.ROUND
    borderPaint.strokeCap = Paint.Cap.ROUND
    setWillNotDraw(false)
  }

  override fun dispatchDraw(canvas: Canvas) {
    if (!clipContent) {
      super.dispatchDraw(canvas)
      return
    }

    val checkpoint = canvas.save()
    canvas.clipPath(clipPath)
    super.dispatchDraw(canvas)
    canvas.restoreToCount(checkpoint)
  }

  override fun onDraw(canvas: Canvas) {
    super.onDraw(canvas)

    for (i in shadowPaints.indices) {
      val shadowPaint = shadowPaints[i]
      val shadowPath = shadowPaths.getOrNull(i) ?: continue
      canvas.drawPath(shadowPath, shadowPaint)
    }

    paint.color = backgroundColorInt
    canvas.drawPath(path, paint)

    if (borderWidth > 0) {
      borderPaint.color = borderColor
      borderPaint.style = Paint.Style.STROKE
      borderPaint.strokeWidth = Utils.convertDpToPixel(borderWidth, context)
      canvas.drawPath(path, borderPaint)
    }
  }

  override fun onSizeChanged(newWidth: Int, newHeight: Int, oldWidth: Int, oldHeight: Int) {
    super.onSizeChanged(newWidth, newHeight, oldWidth, oldHeight)
    resetPaths(newWidth.toFloat(), newHeight.toFloat())
  }

  private fun resetPaths(width: Float, height: Float) {
    if (width == 0f || height == 0f) return

    val pixelBorderWidth = Utils.convertDpToPixel(this.borderWidth, context)
    val baseRadius = borderRadius + (pixelBorderWidth / 2f)

    shadowPaths =
      shadowSpecs.map { spec ->
        val spread = spec.spreadPx
        val spreadPath =
          SquirclePath(
            width + spread * 2,
            height + spread * 2,
            baseRadius + spread,
            cornerSmoothing,
          )
        val shiftMatrix = Matrix().apply { setTranslate(-spread, -spread) }
        Path().apply { spreadPath.transform(shiftMatrix, this) }
      }

    val squirclePath =
      SquirclePath(
        width - pixelBorderWidth,
        height - pixelBorderWidth,
        borderRadius,
        cornerSmoothing,
      )

    val shiftX = pixelBorderWidth / 2f
    val shiftY = pixelBorderWidth / 2f
    val translationMatrix = Matrix().apply { setTranslate(shiftX, shiftY) }
    val translatedPath = Path().apply { squirclePath.transform(translationMatrix, this) }

    path.reset()
    path.addPath(translatedPath)

    // Clip children to the inner edge of the border stroke.
    val innerInset = pixelBorderWidth
    val innerRadius = (borderRadius - pixelBorderWidth).coerceAtLeast(0f)
    val innerW = (width - 2f * innerInset).coerceAtLeast(0f)
    val innerH = (height - 2f * innerInset).coerceAtLeast(0f)
    val innerSquircle = SquirclePath(innerW, innerH, innerRadius, cornerSmoothing)
    val innerMatrix = Matrix().apply { setTranslate(innerInset, innerInset) }
    val translatedInner = Path().apply { innerSquircle.transform(innerMatrix, this) }
    clipPath.reset()
    clipPath.addPath(translatedInner)
  }

  fun setCornerSmoothing(c: Float) {
    cornerSmoothing = c
    resetPaths(width.toFloat(), height.toFloat())
    invalidate()
  }

  fun setSquircleBorderRadius(b: Float) {
    val pixelRadius = Utils.convertDpToPixel(b, context)
    borderRadius = pixelRadius
    resetPaths(width.toFloat(), height.toFloat())
    invalidate()
  }

  fun setViewBackgroundColor(color: Int) {
    backgroundColorInt = color
    paint.color = backgroundColorInt
    rebuildShadowPaints()
    invalidate()
  }

  fun setBorderColor(color: Int) {
    borderColor = color
    invalidate()
  }

  fun setBorderWidth(width: Float) {
    borderWidth = width
    resetPaths(this.width.toFloat(), this.height.toFloat())
    invalidate()
  }

  fun setSquircleBoxShadow(value: String?) {
    boxShadowString = value
    rebuildShadowPaints()
    invalidate()
  }

  fun setClipContent(value: Boolean) {
    clipContent = value
    resetPaths(width.toFloat(), height.toFloat())
    invalidate()
  }

  private fun rebuildShadowPaints() {
    val s = boxShadowString?.trim()
    if (s.isNullOrEmpty()) {
      shadowSpecs = emptyList()
      shadowPaints = emptyList()
      shadowPaths = emptyList()
      setLayerType(LAYER_TYPE_HARDWARE, null)
      return
    }

    setLayerType(LAYER_TYPE_SOFTWARE, null)

    shadowSpecs = parseBoxShadow(s)
    shadowPaints =
      shadowSpecs.map { spec ->
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
          style = Paint.Style.FILL
          color = Color.argb(1, 0, 0, 0)
          setShadowLayer(spec.blurPx, spec.dxPx, spec.dyPx, spec.colorInt)
        }
      }

    resetPaths(width.toFloat(), height.toFloat())
  }

  private data class ShadowSpec(
    val dxPx: Float,
    val dyPx: Float,
    val blurPx: Float,
    val spreadPx: Float,
    val colorInt: Int,
  )

  private fun parseBoxShadow(input: String): List<ShadowSpec> {
    val parts = splitTopLevelCommas(input)
    val out = mutableListOf<ShadowSpec>()

    for (raw in parts) {
      val t = raw.trim()
      if (t.isEmpty()) continue

      val tokens = splitTopLevelWhitespace(t)
      if (tokens.size < 4) continue

      val xDp = parseLengthDp(tokens[0]) ?: 0f
      val yDp = parseLengthDp(tokens[1]) ?: 0f
      val blurDp = parseLengthDp(tokens[2]) ?: 0f

      val spreadDp: Float
      val colorTokenIndex: Int
      val maybeSpread = parseLengthDp(tokens[3])
      if (tokens.size >= 5 && maybeSpread != null) {
        spreadDp = maybeSpread
        colorTokenIndex = 4
      } else {
        spreadDp = 0f
        colorTokenIndex = 3
      }

      val colorToken = tokens.getOrNull(colorTokenIndex) ?: continue
      val colorInt = parseColor(colorToken) ?: continue

      out.add(
        ShadowSpec(
          dxPx = Utils.convertDpToPixel(xDp, context),
          dyPx = Utils.convertDpToPixel(yDp, context),
          blurPx = Utils.convertDpToPixel(blurDp, context),
          spreadPx = Utils.convertDpToPixel(spreadDp, context),
          colorInt = colorInt,
        )
      )
    }
    return out
  }

  private fun splitTopLevelCommas(s: String): List<String> {
    val out = mutableListOf<String>()
    val current = StringBuilder()
    var depth = 0
    for (ch in s) {
      if (ch == '(') depth += 1
      if (ch == ')') depth = maxOf(0, depth - 1)
      if (ch == ',' && depth == 0) {
        out.add(current.toString())
        current.setLength(0)
      } else {
        current.append(ch)
      }
    }
    if (current.isNotEmpty()) out.add(current.toString())
    return out
  }

  private fun splitTopLevelWhitespace(s: String): List<String> {
    val out = mutableListOf<String>()
    val current = StringBuilder()
    var depth = 0

    fun flush() {
      val t = current.toString().trim()
      if (t.isNotEmpty()) out.add(t)
      current.setLength(0)
    }

    for (ch in s) {
      if (ch == '(') depth += 1
      if (ch == ')') depth = maxOf(0, depth - 1)
      if (depth == 0 && ch.isWhitespace()) {
        flush()
      } else {
        current.append(ch)
      }
    }
    flush()
    return out
  }

  private fun parseLengthDp(token: String): Float? {
    val t = token.trim().removeSuffix("px")
    return t.toFloatOrNull()
  }

  private fun parseColor(token: String): Int? {
    val t = token.trim()
    if (t.startsWith("rgba(") && t.endsWith(")")) {
      val inner = t.substring(5, t.length - 1)
      val parts = inner.split(",").map { it.trim() }
      if (parts.size != 4) return null
      val r = parts[0].toFloatOrNull() ?: return null
      val g = parts[1].toFloatOrNull() ?: return null
      val b = parts[2].toFloatOrNull() ?: return null
      val a = parts[3].toFloatOrNull() ?: return null
      val alpha = (a.coerceIn(0f, 1f) * 255f).roundToInt()
      return Color.argb(
        alpha,
        r.roundToInt().coerceIn(0, 255),
        g.roundToInt().coerceIn(0, 255),
        b.roundToInt().coerceIn(0, 255)
      )
    }
    if (t.startsWith("rgb(") && t.endsWith(")")) {
      val inner = t.substring(4, t.length - 1)
      val parts = inner.split(",").map { it.trim() }
      if (parts.size != 3) return null
      val r = parts[0].toFloatOrNull() ?: return null
      val g = parts[1].toFloatOrNull() ?: return null
      val b = parts[2].toFloatOrNull() ?: return null
      return Color.rgb(
        r.roundToInt().coerceIn(0, 255),
        g.roundToInt().coerceIn(0, 255),
        b.roundToInt().coerceIn(0, 255)
      )
    }
    if (t.startsWith("#")) {
      val hex = t.drop(1)
      if (hex.length == 8) {
        val rr = hex.substring(0, 2)
        val gg = hex.substring(2, 4)
        val bb = hex.substring(4, 6)
        val aa = hex.substring(6, 8)
        return try {
          Color.parseColor("#$aa$rr$gg$bb")
        } catch (_: Throwable) {
          null
        }
      }
      return try {
        Color.parseColor(t)
      } catch (_: Throwable) {
        null
      }
    }
    return null
  }
}
