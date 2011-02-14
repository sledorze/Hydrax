package com.pblabs.editor;

import com.bit101.components.Accordion;
import com.bit101.components.AccordionExtended;
import com.bit101.components.CheckBox;
import com.bit101.components.ColorChooser;
import com.bit101.components.ComboBox;
import com.bit101.components.Component;
import com.bit101.components.FPSMeter;
import com.bit101.components.HBox;
import com.bit101.components.HUISlider;
import com.bit101.components.InputText;
import com.bit101.components.Label;
import com.bit101.components.Panel;
import com.bit101.components.PushButton;
import com.bit101.components.Text;
import com.bit101.components.TextArea;
import com.bit101.components.UpdatingLabel;
import com.bit101.components.UpdatingList;
import com.bit101.components.VBox;
import com.bit101.components.Window;

import com.pblabs.engine.core.IPBContext;
import com.pblabs.engine.core.PBGameBase;
import com.pblabs.engine.input.InputKey;
import com.pblabs.util.Preconditions;

import flash.display.DisplayObjectContainer;
import flash.display.Sprite;

import flash.events.KeyboardEvent;

import flash.text.TextField;
import flash.text.TextFormat;

import haxe.PosInfos;

import com.pblabs.editor.CreationPanel;
import com.pblabs.editor.EntityPanel;
import com.pblabs.editor.TimePanel;

using IterTools;

using Lambda;

using ListTools;

using Reflect;

using Type;

using com.pblabs.engine.core.SetManager;
using com.pblabs.engine.util.PBUtil;
using com.pblabs.geom.bounds.BoundsUtil;
using com.pblabs.util.DisplayUtils;
using com.pblabs.util.IterUtil;
using com.pblabs.util.ReflectUtil;

using de.polygonal.gl.DisplayListIterator;

/**
 * In-game editor. Shows all IEntity objects and components.
 * Editor metadata:
 * 
 * IEntityComponent fields can be annotated with e.g. 
 * @editor({ui:"HUISlider", label:"Running Juice", maximum: "runningJuiceMax", minimum: 0})
 * This means that a custom field is shown in the editor when the owning entity
 * is selected.  In this case, a slider is shown, with the given label and maximum and minimum fields.
 * @label If absent, the field name is used.
 * @maximum If absent, the editor will assume the maximum component field name is $fieldname + "Max"
 * @minimum A Float field.  If absent, 0 is assumed.
 *
 * Other "ui" parameters: 
 * UpdatingLabel
 * Combox: Only good for fields of subclasses of Enumerable. 
 */
class Editor extends Sprite
{
	public static var ENTITY_WINDOW_NAME :String = "EntityPanel";
	public function new (app :PBGameBase, ?x :Int = 700, ?y :Int = 0)
	{
		super();
		Preconditions.checkNotNull(app, "Game is null");
		_game = app;
		_active = false;
		_layer = new Sprite();
		addChild(_layer);
		_layer.x = x;
		_layer.y = y;
		
		flash.Lib.current.stage.addChild(this);
		flash.Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
		
		//Register with the managers
		app.registerManager(Editor, this);
		
		_ctx = _game.currentContext;
		setup();
	}
	
	public function selectAccordionWindowNamed (windowName :String) :Void
	{
		var window :Window = null;
	    var getEditorWindow = function (d :flash.display.DisplayObject) :Bool {
			if (Std.is(d, Window)) {
				if (cast(d, Window).title == windowName) {
					window = cast d;
					return true;
				}
			}
			return false;
		}
		
		com.threerings.display.DisplayUtil.applyToHierarchy(_mainAccordion, getEditorWindow);
		if (window != null) {
			window.dispatchEvent(new flash.events.Event(flash.events.Event.SELECT));
		} else {
			com.pblabs.util.Log.error("No editor window found named: " + windowName);
		}
	}
	
	public function shutdown () :Void
	{
	}
	                                                                                                
	function keyPressed (e :KeyboardEvent) :Void
	{
		if (e.charCode == InputKey.P.keyCode) {
			#if profiler
			_LogWindow.minimized = false;			
			com.pblabs.engine.debug.Profiler.report();
			#end
		} else if (e.charCode == InputKey.BACKSPACE.keyCode || e.charCode == InputKey.DELETE.keyCode) {
			if (_entityPanel.selectedObject != null) {
				_entityPanel.selectedObject.destroy();
				_entityPanel.selectedObject = null;
			}
		}
	}
	
	function setup () :Void
	{
		Preconditions.checkNotNull(_game, "Game is null");
		var self = this;
		
		//Top panel
		_rootPanel = new Panel(_layer);
		_rootPanel.setSize(600, 640);
		_rootVbox = new VBox(_rootPanel);
		_rootVbox.setSize(_rootPanel.width, _rootPanel.height);
		var root = _rootVbox;
		new Label(root, 0, 0, "HydraxEditor");
		
		var timePanel = new TimePanel(root, _game);
		
		//Create the main accordion that show different panels
		_mainAccordion = new Accordion(root);
		_mainAccordion.setSize(600, 750);
		_mainAccordion.y = timePanel.y + timePanel.height;
		
		//Add the different panels
		
		//Load/Save contexts
		//Creation
		var windowIndex = 0;
		_mainAccordion.getWindowAt(windowIndex).title = "Load/Save";
		_templatePanel = new TemplatePanel(_mainAccordion.getWindowAt(windowIndex).content, _game);
		//Offset a little to aid in navigating the accordion tabs
		_templatePanel.x = 10;
		
		
		//Creation
		windowIndex = 1;
		_mainAccordion.getWindowAt(windowIndex).title = "Create";
		_creationPanel = new CreationPanel(_mainAccordion.getWindowAt(windowIndex).content, _game);
		//Offset a little to aid in navigating the accordion tabs
		_creationPanel.x = 10;
		
		//Editing
		_mainAccordion.addWindow(ENTITY_WINDOW_NAME);
		windowIndex = 2;
		_mainAccordion.getWindowAt(windowIndex).title = ENTITY_WINDOW_NAME;
		_entityPanel = new EntityPanel(_mainAccordion.getWindowAt(windowIndex).content, _game);
		//Offset a little to aid in navigating the accordion tabs
		_entityPanel.x = 10;
		//If an object is created, select it too
		_creationPanel.objectSelected = _entityPanel.objectSelected;
	}
	
	function createTraceContainer (root :DisplayObjectContainer) :TextArea
	{
		var ta = new TextArea(root);
		for (d in ta) {
			if (Std.is(d, TextField)) {
				var tf = cast(d, TextField);
				tf.embedFonts = false;
				var format = new TextFormat();
				format.font = "Monaco";
				format.size = 10;
				tf.setTextFormat(format);
				tf.defaultTextFormat = format;
			}
		}
		ta.setSize(root.width, root.height);
		var lines = new List<String>();
		var tracer = function (v : Dynamic, ?infos : PosInfos) : Void {
			for (s in Std.string(v).split("\n")) {
				lines.add(s);
			}
			while (lines.length > 50) {
				lines.pop();
			}
			ta.text = lines.join("\n");
		}
		haxe.Log.trace = tracer;
		return ta;
	}
	
	var _game :PBGameBase;
	var _ctx :IPBContext;
	var _active :Bool;
	
	//UI
	var _rootPanel :Panel;
	var _rootVbox :VBox;
	var _mainAccordion :Accordion;
	var _templatePanel :TemplatePanel;
	var _entityPanel :EntityPanel;
	var _creationPanel :CreationPanel;
	var _LogWindow :Window;
	var _layer :Sprite;
}
