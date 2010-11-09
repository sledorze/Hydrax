package com.pblabs.components.scene;

import com.pblabs.components.manager.NodeComponent;
import com.pblabs.components.scene.SceneAlignment;
import com.pblabs.components.scene.SceneView;
import com.pblabs.engine.debug.Log;
import com.pblabs.geom.Rectangle;
import com.pblabs.geom.Vector2;
import com.pblabs.util.MathUtil;
import com.pblabs.util.Preconditions;
using com.pblabs.util.IterUtil;

/**
  * Layers are arranged: smaller index is behind.
  */
class BaseScene2DManager<Layer :BaseScene2DLayer<Dynamic, Dynamic>> extends NodeComponent<Dynamic, Layer>,
    implements haxe.rtti.Infos
{
    @inject
    public var sceneView(get_sceneView, set_sceneView) :SceneView;
    
    public var zoom(get_zoom, set_zoom) :Float;
    public var sceneBounds(get_sceneBounds, set_sceneBounds) :Rectangle;
    public var layerCount(get_layerCount, never) :Int;
    public var x (get_x, set_x) :Float;
    public var y (get_y, set_y) :Float;
    

    /**
     * Maximum allowed zoom level.
     *
     * @see zoom
     */
    public var zoomMax :Float;
    /**
     * Minimum allowed zoom level.
     *
     * @see zoom
     */
    public var zoomMin :Float;

    /**
     * How the scene is aligned relative to its position property.
     *
     * @see SceneAlignment
     * @see position
     */
    public var sceneAlignment :SceneAlignment;

    public function new ()
    {
        super();
        zoomMax = 5;
        zoomMin = 0;
        sceneAlignment = SceneAlignment.TOP_LEFT;
        _currentViewRect = new Rectangle();
        _zoom = 1.0;
        _position = new Vector2();
        _transformDirty = false;
    }

    function isLayer (name :String) :Bool
    {
        return getLayer(name) != null;
    }

    public function getLayerAt (idx :Int) :Layer
    {
        return children[idx];
    }
    
    public function getLayerIndex (layer :Layer) :Int
    {
        return children.indexOf(layer);
    }
    
    public function setLayerIndex (layer :Layer, index :Int) :Void
    {
        Preconditions.checkNotNull(layer, "Null layer");
        Preconditions.checkPositionIndex(index, children.length, "Layer index out of bounds");
        children.remove(layer);
        children.insert(index, layer);
    }

    override function childAdded (obj :Layer) :Void
    {
        Log.debug("adding scene layer");
        super.childAdded(obj);
        _transformDirty = true;
    }

    public function getTopLayer () :Layer
    {
        if (children.length > 0) {
            return children[children.length - 1];
        }
        return null;
    }

    public function getLayer (layerName :String) :Layer
    {
        for (layer in children) {
            if (null != layer && layer.name == layerName) {
                return layer;
            }
        }
        return null;
    }

    override function onAdd () :Void
    {
        super.onAdd();      
        sceneView = context.getManager(SceneView);
        #if debug
        com.pblabs.util.Assert.isNotNull(sceneView, "No SceneView"); 
        #end
    }

    override function onRemove () :Void
    {
        super.onRemove();
        _sceneView == null;
    }
    
    inline function get_layerCount () :Int
    {
        return children != null ? children.length : 0;
    }
    
    function get_x () :Float
    {
        return _position.x;
    }
    
    function set_x (newX :Float) :Float
    {
        if (_position.x == newX) {
            return newX;
        }
        _position.x = newX;
        _transformDirty = true;
        return newX;
    }
    
    function get_y () :Float
    {
        return _position.y;
    }

    function set_y (newY :Float) :Float
    {
        if (_position.y == newY) {
            return newY;
        }
        _position.y = newY;
        _transformDirty = true;
        return newY;
    }

    function get_sceneBounds () :Rectangle
    {
        return _sceneBounds;
    }

    function set_sceneBounds (value :Rectangle) :Rectangle
    {
        _sceneBounds = value;
        return value;
    }

    function get_sceneView () :SceneView
    {
        return _sceneView;
    }

    function set_sceneView (value :SceneView) :SceneView
    {
        _sceneView = value;
        return value;
    }

    function get_zoom () :Float
    {
        return _zoom;
    }

    function set_zoom (value :Float) :Float
    {
        // Make sure our zoom level stays within the desired bounds
        value = MathUtil.fclamp(value, zoomMin, zoomMax);

        if (_zoom == value) {
            return _zoom;
        }

        _zoom = value;
        _transformDirty = true;
        return value;
    }
    
    var _position :Vector2;
    var _zoom :Float;
    var _transformDirty :Bool;
    
    var _sceneBounds :Rectangle;
    var _sceneView :SceneView;
    var _currentViewRect :Rectangle;

    
    public static var DEFAULT_LAYER_NAME :String = "defaultLayer";
    static var EMPTY_ARRAY :Array<Dynamic> = [];
}

