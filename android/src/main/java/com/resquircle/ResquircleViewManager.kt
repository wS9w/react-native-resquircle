package com.resquircle

import android.graphics.Color
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.ResquircleViewManagerInterface
import com.facebook.react.viewmanagers.ResquircleViewManagerDelegate

@ReactModule(name = ResquircleViewManager.NAME)
class ResquircleViewManager : SimpleViewManager<ResquircleView>(),
  ResquircleViewManagerInterface<ResquircleView> {
  private val mDelegate: ViewManagerDelegate<ResquircleView>

  init {
    mDelegate = ResquircleViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<ResquircleView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): ResquircleView {
    return ResquircleView(context)
  }

  // Back-compat: old example prop.
  @ReactProp(name = "color")
  override fun setColor(view: ResquircleView?, color: Int?) {
    view?.setViewBackgroundColor(color ?: Color.TRANSPARENT)
  }

  @ReactProp(name = "squircleBackgroundColor")
  override fun setSquircleBackgroundColor(view: ResquircleView?, color: Int?) {
    view?.setViewBackgroundColor(color ?: Color.TRANSPARENT)
  }

  @ReactProp(name = "squircleBorderColor")
  override fun setSquircleBorderColor(view: ResquircleView?, color: Int?) {
    view?.setBorderColor(color ?: Color.TRANSPARENT)
  }

  @ReactProp(name = "squircleBorderWidth", defaultFloat = 0f)
  override fun setSquircleBorderWidth(view: ResquircleView?, width: Float) {
    view?.setBorderWidth(width)
  }

  @ReactProp(name = "squircleBoxShadow")
  override fun setSquircleBoxShadow(view: ResquircleView?, boxShadow: String?) {
    view?.setSquircleBoxShadow(boxShadow)
  }

  @ReactProp(name = "borderRadius", defaultFloat = 0f)
  override fun setBorderRadius(view: ResquircleView?, radius: Float) {
    view?.setBorderRadius(radius)
  }

  @ReactProp(name = "cornerSmoothing", defaultFloat = 0.6f)
  override fun setCornerSmoothing(view: ResquircleView?, smoothing: Float) {
    view?.setCornerSmoothing(smoothing)
  }

  @ReactProp(name = "overflow")
  override fun setOverflow(view: ResquircleView?, overflow: String?) {
    view?.setOverflow(overflow)
  }

  companion object {
    const val NAME = "ResquircleView"
  }
}
