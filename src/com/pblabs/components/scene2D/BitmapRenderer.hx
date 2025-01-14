/*******************************************************************************
 * Hydrax :haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http ://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.components.scene2D;

import com.pblabs.geom.RectangleTools;

import de.polygonal.motor2.geom.math.XY;

import flash.geom.Matrix;
import flash.geom.Point;

using com.pblabs.components.scene2D.SceneUtil;

/**
  * Cross platform bitmap renderer.  The parent class for other more complex renderers.
  * Flash: there is an issue with ObjectPooling and bitmap caching.  Don't pool this class yet.
  */
class BitmapRenderer 
	#if js
	extends com.pblabs.components.scene2D.js.SceneComponent,
	#elseif (flash || cpp)
	extends com.pblabs.components.scene2D.flash.SceneComponent,  
	#end
	implements com.pblabs.components.scene2D.flash.ICopyPixelsRenderer
{
	public var bitmap (get_bitmap, never) :BitmapType;
	var _bitmap :BitmapType;
	inline function get_bitmap () :BitmapType { return _bitmap; }
	
	public var bitmapData (get_bitmapData, set_bitmapData) :ImageData;
	inline function get_bitmapData () :ImageData
	{
		com.pblabs.util.Assert.isNotNull(_bitmap);
		#if (flash || cpp)
		return _bitmap.bitmapData;
		#elseif js
		return _bitmap;
		#end
	}
	
	function set_bitmapData (val :ImageData) :ImageData
	{
		if (val == null) {
			_unscaledBounds.x = 1;
			_unscaledBounds.y = 1;
			
			_bounds.xmin = _x;
			_bounds.xmax = _x + _unscaledBounds.x * _scaleX;
			_bounds.ymin = _y;
			_bounds.ymax = _y + _unscaledBounds.y * _scaleY;
			
			_registrationPoint.x = 0;
			_registrationPoint.y = 0;
			#if flash
			_bitmap.bitmapData = null;
			#elseif js
			_bitmap = null;
			#end
		} else {
			#if flash
			com.pblabs.util.Assert.isNotNull(_bitmap);
			_bitmap.bitmapData = val;
			//This is set to false when a new bitmapData is assigned
			//http://gskinner.com/blog/archives/2007/08/minor_bug_with_.html
			_bitmap.smoothing = _smoothing;
			#elseif js
			_bitmap = val;
			#end
			_registrationPoint.x = _bitmap.width / 2;
			_registrationPoint.y = _bitmap.height / 2;
			recomputeBounds();
		}

		#if js	
		if (!isOnCanvas) {
			redrawBackBuffer();
		}
		_isContentsDirty = true;
		#end
		return val;
	}
	
	#if js
	/** Can also render a js.Image */
	override function get_cacheAsBitmap () :Bool
	{
		return false;
	}
	override function set_cacheAsBitmap (val :Bool) :Bool
	{
		return false;
	}
	
	override private function redrawBackBuffer ()
	{
		com.pblabs.util.Assert.isNotNull(_backBuffer, ' _backBuffer is null');
		
		if (_bitmap != null) {
			com.pblabs.util.Assert.isNotNull(_bitmap, ' _bitmap is null');
			if (_backBuffer.width != _bitmap.width || _backBuffer.height != _bitmap.height) {
				_backBuffer.width = _bitmap.width;
				_backBuffer.height = _bitmap.height;
			} else {
				_backBuffer.getContext("2d").clearRect(0, 0, _backBuffer.width, _backBuffer.height);
			}
			#if haxedev
			_backBuffer.getContext("2d").drawImage(_bitmap , 0, 0);
			#else
			_backBuffer.getContext("2d").drawImage(cast _bitmap , 0, 0);
			#end
		} else {
			_backBuffer.width = _backBuffer.height = 1;
		}
		_isContentsDirty = false;
	}
	
	override function renderCachedBuffer (ctx :CanvasRenderingContext2D) :Void
	{
		if (_bitmap != null) {
			#if haxedev
			ctx.drawImage(_bitmap, 0, 0);
			#else
			ctx.drawImage(cast _bitmap, 0, 0);
			#end
		}
	}
	#end
	
	#if flash
	public var smoothing (get_smoothing, set_smoothing) :Bool;
	var _smoothing :Bool;
	function get_smoothing () :Bool
	{
		return _smoothing;
	}
	
	function set_smoothing (val :Bool) :Bool
	{
		_smoothing = val;
		_bitmap.smoothing = val;
		return val;
	}
	#end
	
	public function new (?width :Int = 1, ?height :Int = 1) :Void
	{
		#if (flash || cpp)
		var sprite = com.pblabs.util.SpriteUtil.create();
		_bitmap = new flash.display.Bitmap(new flash.display.BitmapData(width, height, true, 0xff0000), flash.display.PixelSnapping.NEVER);
		sprite.addChild(_bitmap);
		_displayObject = sprite;
		super();
		#elseif js
		_backBuffer = cast js.Lib.document.createElement("canvas");
		_backBuffer.width = 1;
		_backBuffer.height = 1;
		_backBuffer.style.position = "absolute";
		// _backBuffer.style.visibility = "hidden";
		_backBuffer.style.display = "block";
		//Add to the div display object, so it can be rendered to either CSS or Canvas layers.
		super();
		com.pblabs.util.Assert.isNotNull(div);
		div.appendChild(_backBuffer);
		isTransformDirty = true;
		// cacheAsBitmap = false;
		#end
	}
	
	public function setImage (image :ImageType) :Void
	{
		#if flash
		bitmapData = image.bitmapData;
		#elseif js
		bitmapData = com.pblabs.util.BitmapUtil.toCanvas(image);
		#end
	}
	
	#if flash
	public function drawPixels (objectToScreen :Matrix, renderTarget :flash.display.BitmapData) :Void
	{
		// Draw to the target.
		if (bitmap.bitmapData != null) {
			renderTarget.copyPixels(bitmap.bitmapData, bitmap.bitmapData.rect, objectToScreen.transformPoint(zeroPoint), null, null, true);
		}
	}
	#elseif js
	override public function drawPixels (ctx :CanvasRenderingContext2D)
	{
		renderCachedBuffer(ctx);
	}
	
	public function drawImage (image :Image) :Void
	{
		set_bitmapData(com.pblabs.util.BitmapUtil.toCanvas(image));
	}
	#end
	
	public function isPixelPathActive(objectToScreen :Matrix) :Bool
	{
		// No rotation/scaling/translucency/blend modes
		return (objectToScreen.a == 1 && objectToScreen.b == 0 && objectToScreen.c == 0 && objectToScreen.d == 1 && alpha == 1
		#if flash
		&& (displayObject.filters.length == 0)
		#end
		);
	}
	
	override function onRemove () :Void
	{
		//Where is bitmapData.dispose to be called? Subclasses will be caching the BitmapData. 
		bitmapData = null;
		var keepDisp = _displayObject;
		super.onRemove();//Superclass nulls _displayObject
		_displayObject = keepDisp;
	}
	
	#if (flash || cpp) override #end 
	function recomputeBounds () :Void
	{
		if (_bitmap != null) {
			if (_bitmap.width != _unscaledBounds.x || _bitmap.height != _unscaledBounds.y) {
				_unscaledBounds.x = _bitmap.width;
				_unscaledBounds.y = _bitmap.height;
				
				_bounds.xmin = _x - _registrationPoint.x * _scaleX;
				_bounds.xmax = _bounds.xmin + _bitmap.width * _scaleX;
				_bounds.ymin = _y - _registrationPoint.y * _scaleY;
				_bounds.ymax = _bounds.ymin + _bitmap.height * _scaleY;
			}
			// _registrationPoint.x = _bitmap.width / 2;
			// _registrationPoint.y = _bitmap.height / 2;
		
		} else {
			_unscaledBounds.x = 1;
			_unscaledBounds.y = 1;
			_registrationPoint.x = 0;
			_registrationPoint.y = 0;
			_bounds.xmin = _x;
			_bounds.xmax = _x + 1;
			_bounds.ymin = _y;
			_bounds.ymax = _y + 1;
		}
		// _scaleX = _scaleY = 1.0;
		isTransformDirty = true;
	}
	
	#if flash
	override function setDefaults () :Void
	{
		super.setDefaults();
		_smoothing = true;
	}
	
	static var zeroPoint = new Point();
	#end
	
	#if debug
	override public function toString () :String
	{
		return com.pblabs.util.StringUtil.objectToString(this, ["x", "y", "width", "height"]);
	}
	#end
}
