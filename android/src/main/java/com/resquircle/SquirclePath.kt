package com.resquircle

import android.graphics.Path
import android.graphics.RectF
import kotlin.math.cos
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt
import kotlin.math.tan

data class CurveProperties(
  var a: Float,
  var b: Float,
  var c: Float,
  var d: Float,
  var p: Float,
  var arcSectionLength: Float,
  var cornerRadius: Float,
)

class SquirclePath(
  private var width: Float,
  private var height: Float,
  private var borderRadius: Float,
  private var cornerSmoothing: Float,
) : Path() {

  init {
    val checkedRadius = minOf(this.borderRadius, this.width / 2f, this.height / 2f)
    val checkedCornerSmoothing = maxOf(minOf(this.cornerSmoothing, 1f), 0f)

    if (checkedRadius <= 0f || width <= 0f || height <= 0f) {
      addRect(0f, 0f, width, height, Direction.CW)
    } else {
      val curvedProperties =
        calculateCurveProperties(
          checkedRadius,
          checkedCornerSmoothing,
          min(this.width, this.height) / 2,
        )

      buildPath(this.width, this.height, curvedProperties)
    }
  }

  private fun buildPath(width: Float, height: Float, cp: CurveProperties) {
    val a = cp.a
    val b = cp.b
    val c = cp.c
    val d = cp.d
    val p = cp.p
    val arc = cp.arcSectionLength
    val r = cp.cornerRadius

    val topRightCx = width - r
    val topRightCy = r
    val bottomRightCx = width - r
    val bottomRightCy = height - r
    val bottomLeftCx = r
    val bottomLeftCy = height - r
    val topLeftCx = r
    val topLeftCy = r

    var x = width - p
    var y = 0f
    moveTo(x, y)

    fun relCubic(c1x: Float, c1y: Float, c2x: Float, c2y: Float, dx: Float, dy: Float) {
      rCubicTo(c1x, c1y, c2x, c2y, dx, dy)
      x += dx
      y += dy
    }

    fun arcToRelative(deltaX: Float, deltaY: Float, centerX: Float, centerY: Float, radius: Float) {
      val endX = x + deltaX
      val endY = y + deltaY

      val startAngle =
        Math.toDegrees(kotlin.math.atan2((y - centerY), (x - centerX)).toDouble()).toFloat()
      val endAngle =
        Math.toDegrees(kotlin.math.atan2((endY - centerY), (endX - centerX)).toDouble()).toFloat()

      var sweep = endAngle - startAngle
      if (sweep < 0f) sweep += 360f

      val oval = RectF(centerX - radius, centerY - radius, centerX + radius, centerY + radius)
      arcTo(oval, startAngle, sweep, false)

      x = endX
      y = endY
    }

    relCubic(a, 0f, a + b, 0f, a + b + c, d)
    arcToRelative(arc, arc, topRightCx, topRightCy, r)
    relCubic(d, c, d, c + d, d, a + b + c)

    x = width
    y = height - p
    lineTo(x, y)

    relCubic(0f, a, 0f, a + b, -d, a + b + c)
    arcToRelative(-arc, arc, bottomRightCx, bottomRightCy, r)
    relCubic(-c, d, -(b + c), d, -(a + b + c), d)

    x = p
    y = height
    lineTo(x, y)

    relCubic(-a, 0f, -(a + b), 0f, -(a + b + c), -d)
    arcToRelative(-arc, -arc, bottomLeftCx, bottomLeftCy, r)
    relCubic(-d, -c, -d, -(b + c), -d, -(a + b + c))

    x = 0f
    y = p
    lineTo(x, y)

    relCubic(0f, -a, 0f, -(a + b), d, -(a + b + c))
    arcToRelative(arc, -arc, topLeftCx, topLeftCy, r)
    relCubic(c, -d, b + c, -d, a + b + c, -d)

    close()
  }

  private fun calculateCurveProperties(
    cornerRadius: Float,
    cornerSmoothing: Float,
    roundingAndSmoothingBudget: Float,
  ): CurveProperties {
    var p = (1 + cornerSmoothing) * cornerRadius

    val arcMeasure = 90 * (1 - cornerSmoothing)
    val arcSectionLength = sin(toRadians(arcMeasure / 2)) * cornerRadius * sqrt(2f)
    val angleAlpha = (90 - arcMeasure) / 2
    val p3ToP4Distance = cornerRadius * tan(toRadians(angleAlpha / 2))
    val angleBeta = 45 * cornerSmoothing
    val c = p3ToP4Distance * cos(toRadians(angleBeta))
    val d = c * tan(toRadians(angleBeta))
    var b = (p - arcSectionLength - c - d) / 3
    var a = 2 * b

    if (p > roundingAndSmoothingBudget) {
      val p1ToP3MaxDistance = roundingAndSmoothingBudget - d - arcSectionLength - c
      val minA = p1ToP3MaxDistance / 6
      val maxB = p1ToP3MaxDistance - minA
      b = minOf(b, maxB)
      a = p1ToP3MaxDistance - b
      p = minOf(p, roundingAndSmoothingBudget)
    }

    return CurveProperties(a, b, c, d, p, arcSectionLength, cornerRadius)
  }

  private fun toRadians(degrees: Float): Float {
    return degrees * (Math.PI.toFloat() / 180f)
  }
}

