/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.components.scene2D;

import com.pblabs.components.manager.NodeComponent;
import com.pblabs.engine.core.ObjectType;
import com.pblabs.engine.time.IAnimatedObject;
import com.pblabs.util.Preconditions;

import flash.geom.Matrix;

/**
  * A 2D layer holding 2DSceneComponents.
  */
class BaseSceneLayer<Scene :BaseSceneManager<Dynamic>, Component :BaseSceneComponent<Dynamic>> extends NodeComponent<Scene, Component>,
	implements IAnimatedObject, implements haxe.rtti.Infos
{
	public var priority :Int;
	
	/** For ignoring all objects in a layer */
	public var objectMask :ObjectType;
	@editor({ui:"UpdatingLabel"})
	public var scene (get_scene, never) :BaseSceneManager<Dynamic>;
	@editor({ui:"NumericStepper", min:0})
	public var index (get_index, set_index) :Int;
	@editor({ui:"HUISlider", min:0.0, max:3.0})
	public var parallaxFactor (get_parallaxFactor, set_parallaxFactor) :Float;
	public var zOrderDirty :Bool;
	
	/** Optionally sort the display children when children are added */
	public var sorter :Array<BaseSceneComponent<Dynamic>>->Void;
	
	#if editor
	@editor({ui:"UpdatingLabel"})
	public var childCount (get_childCount, never) :Int;
	function get_childCount () :Int
	{
		return children.length;
	}
	#end
	
	/** If true, scene objects in this layer ignore mouse/input events */
	// public var ignoreInput :Bool;
	
	var _transformMatrix :Matrix;
	
	public function new ()
	{
		super();
		setDefaultVars();
	}
	
	public function onFrame (dt :Float) :Void
	{
		com.pblabs.engine.debug.Profiler.enter("onFrame");
		if (!zOrderDirty) {
			com.pblabs.engine.debug.Profiler.exit("onFrame");
			return;
		}
		if (sorter != null) {
			sorter(cast children);
		}
		checkZOrder();
		zOrderDirty = false;
		com.pblabs.engine.debug.Profiler.exit("onFrame");
	}
	
	override function childAdded (c :Component) :Void
	{
		super.childAdded(c);
		zOrderDirty = true;
	}
	
	/** Sets the sceneComponent zOrder with the actual z order.  Extended by platform specific subclasses */
	function checkZOrder () :Void
	{
		throw "Subclasses override";
	}
	
	function setDefaultVars () :Void
	{
		priority = 0;
		//By default, searches all children
		objectMask = ObjectType.ALL;
		// ignoreInput = false;
		zOrderDirty = true;
		_parallaxFactor = 1.0;
		_transformMatrix = new Matrix();
	}
	
	function get_scene () :BaseSceneManager<Dynamic>
	{
		return cast parent;
	}
	
	function get_index () :Int
	{
		Preconditions.checkNotNull(parent, "You must property add the Layer component before changing the index");
		return parent.getLayerIndex(this);
	}
	
	function set_index (val :Int) :Int
	{
		Preconditions.checkNotNull(parent, "You must property add the Layer component before changing the index");
		parent.setLayerIndex(this, val);
		return parent.getLayerIndex(this);
	}
	
	function get_parallaxFactor () :Float
	{
	    return _parallaxFactor;
	}
	
	function set_parallaxFactor (val :Float) :Float
	{
	    _parallaxFactor = val;
	    return val;
	}
	
	
	// var _needsSort :Bool;
	var _parallaxFactor :Float;
}
