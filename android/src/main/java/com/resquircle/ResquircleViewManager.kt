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

  @ReactProp(name = "color")
  override fun setColor(view: ResquircleView?, color: Int?) {
    view?.setBackgroundColor(color ?: Color.TRANSPARENT)
  }

  companion object {
    const val NAME = "ResquircleView"
  }
}
