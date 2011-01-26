/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.engine.injection;

import Type.ValueType;

import com.pblabs.util.Preconditions;

import com.pblabs.util.ds.Map;
import com.pblabs.util.ds.Maps;
import com.pblabs.util.ds.MultiMap;
import com.pblabs.util.ds.Tuple;
import com.pblabs.util.ds.multimaps.ArrayMultiMap;
import com.pblabs.util.ReflectUtil;

using Lambda;

using Reflect;

using com.pblabs.util.IterUtil;
using com.pblabs.util.ReflectUtil;

/**
  *Injects component PropertyReference fields and hsl signal listeners
  * Use @inject("<id>") to inject fields and functions (as signal listeners)
  * E.g. @inject Coordinates.x
  * If there is no manually assigned field injections (via setFieldInjection),
  * the injection label must correspond with a property reference.
  
  * More detail:
  * The listener annotation can list more than one comma seperating signals e.g.
  * @inject(["signal1", "signal2"])
  */
class Injector
{
	inline public static var INJECT :String = "inject";
	public var parent (get_parent, set_parent) :Injector;
	public var isParentInjector (get_isParentInjector, never) :Bool;
	
	public function new () 
	{
		_injectionValues = Maps.newHashMap(Dynamic);
	}
	
	public function mapValue (type :Class<Dynamic>, value :Dynamic, ?optionalName :String) :Void
	{
		if (Type.getClassName(type) != null) {
			_injectionValues.set(Type.getClassName(type), value);
		}
		if (optionalName != null) {
			_injectionValues.set(optionalName, value);
		}
	}
	
	public function getMapping (key :Class<Dynamic>, ?name :String) :Dynamic
	{
		Preconditions.checkArgument(key != null || name != null, "Both args are null");
		
		if (_injectionValues.get(name) != null) {
			return _injectionValues.get(name);
		}
		
		if (key != null && _injectionValues.get(Type.getClassName(key)) != null) {
			return _injectionValues.get(Type.getClassName(key));
		}
		
		if (isParentInjector) {
			return parent.getMapping(key, name);
		}
		return null;
	}
	
	public function unmap (cls :Class<Dynamic>, ?name :String) :Void
	{
		_injectionValues.remove(cls.getClassName());
		if (name != null) {
			_injectionValues.remove(name);
		}
		if (cls != null) {
			_injectionValues.remove(cls.getClassName());
		}
	}
	
	public function injectInto (obj :Dynamic) :Void
	{
		Preconditions.checkNotNull(obj, "obj argument is null");
		var cls = com.pblabs.util.ReflectUtil.getClass(obj);
		Preconditions.checkNotNull(cls, "obj class is null");
		injectFields(obj, cls);
	}
	
	function injectFields (obj :Dynamic, cls :Class<Dynamic>) :Void
	{
		// trace("injectFields " +cls.getClassName());
		Preconditions.checkNotNull(cls, "obj class is null");
		updateRuntimeCache(cls);
		for (injectionTuple in instanceFieldInjections.get(cls)) {
			if (injectionTuple == NULL_INJECTION) {
				break;
			}
			
			// trace("injectionTuple=" + injectionTuple);
			var field = injectionTuple.v1;
			
			if (Type.typeof(Reflect.field(obj, field)) == ValueType.TFunction) {
				com.pblabs.util.Log.debug("Not injecting into " + Type.getClassName(Type.getClass(obj)) + "." + field + ", field is a function");
				continue;
			}
			
			//Don't inject into fields with existing values
			//TODO: check if the field is a function
			if (Reflect.field(obj, field) != null) {
				com.pblabs.util.Log.warn("Not injecting into " + Type.getClassName(Type.getClass(obj)) + "." + field + ", field is not null, " + field + "=" + Reflect.field(obj, field));
				continue;
			}
			
			for (injectionKey in injectionTuple.v2) {
				
				var injectedValue :Dynamic = getMapping(null, injectionKey);
				if (injectedValue == null) {
					com.pblabs.util.Log.warn("No value set for injection key=" + injectionTuple.v2 + "  ->  " + cls.getClassName() + "." + field);
					continue;
				}
				
				//Haxe doesn't property handle properties when using reflection
				try {
					if (Lambda.has(Type.getInstanceFields(cls), "set_" + field)) {
						SINGLE_VALUE_ARRAY[0] = injectedValue;
						Reflect.callMethod(obj, Reflect.field(obj, "set_" + field), SINGLE_VALUE_ARRAY);
						SINGLE_VALUE_ARRAY[0] = null;
					} else {
							Reflect.setField(obj, field, injectedValue);
					}
				} catch (e :Dynamic) {
					// com.pblabs.util.Log.error(["Could not inject", "injectedValue", injectedValue, "obj", obj, "field", field]);
					throw "Could not inject:  " + obj + "." + field + "=" + injectedValue + ", type=" + ReflectUtil.getClassName(injectedValue) + "\n" + e;
				}
			}
			
		}
		
		var superCls = Type.getSuperClass(cls);
		//Recursively inject superclass fields/listeners
		if (superCls != null) {
			com.pblabs.util.Log.debug("Injecting on superclass=" + superCls.getClassName());
			injectFields(obj, superCls);
		}
	}
	
	function get_isParentInjector () :Bool
	{
		return _parentInjector != null;
	}
	
	/**
	 * Stores mappings from class field names to the injection value key.
	 */
	function updateRuntimeCache (cls :Class<Dynamic>) :Void
	{
		if (instanceFieldInjections.get(cls) != null) {
			com.pblabs.util.Log.debug(cls.getClassName() + " already registered:" + instanceFieldInjections.get(cls));
			// trace("instanceFieldInjections=" + instanceFieldInjections);
			return;
		}
		// trace("updateRuntimeCache for " + cls.getClassName() );
		var m = haxe.rtti.Meta.getFields(cls);
		if (m != null) {
			var tup :Tuple<String, Array<String>>;
			for (field in Reflect.fields(m)) {
				// trace("field=" + field);
				var injectString :String = null;
				//Only cache @inject tags 
				if (!Reflect.hasField(Reflect.field(m, field), INJECT)) {
					continue;
				}
				//Get the field if it has @inject
				var injectMeta :Dynamic = Reflect.field(Reflect.field(m, field), INJECT);
				//TODO: injectMeta will also be null for @editor annotations.
				//Is there extra inject annotation data?
				if (injectMeta == null) {
					if (untyped cls.__rtti != null) {
						switch (cls.getFieldType(field)) {
							case CClass(name, params):
								tup = new Tuple(field, [name]);
								instanceFieldInjections.set(cls, tup);
								com.pblabs.util.Log.debug("Binding field injection " + cls.getClassName() + "." + field + " <- " + name);
							default:
							com.pblabs.util.Log.error("@inject on " + cls.getClassName() + "." + field + ", not a class type: " + cls.getFieldType(field));
						}
					} else {
						com.pblabs.util.Log.error("@inject on " + cls.getClassName() + "." + field + ", but there is no inject annotation, and the class does not implement haxe.rtti.Infos, so we cannot get the class field types at runtime.");
					}
					
				} else {
					var injectArr :Array<String> = cast(injectMeta);
					com.pblabs.util.Log.debug("Binding field injection " + cls.getClassName() + "." + field + " -> " + injectArr);
					tup = new Tuple(field, injectArr);
					instanceFieldInjections.set(cls, tup);
				}
			}
		} else {
			com.pblabs.util.Log.debug("No injections");
		}
		
		//Mark with a null injection, so we know this class has been checked
		if (instanceFieldInjections.get(cls) == null) {
			instanceFieldInjections.set(cls, NULL_INJECTION);
		}
		
		var superCls = Type.getSuperClass(cls);
		//Recursively inject superclass fields/listeners
		if (superCls != null) {
			com.pblabs.util.Log.debug("Caching injections on superclass=" + superCls.getClassName());
			updateRuntimeCache(superCls);
		}
	}
	
	function get_parent () :Injector
	{
		return _parentInjector;
	}
	
	function set_parent (val :Injector) :Injector
	{
		Preconditions.checkArgument(!isParentInjector, "There's already a parent injector");
		_parentInjector = val;
		return val;
	}
	
	var _injectionValues :Map<String, Dynamic>;
	
	var _parentInjector :Injector;
	
	/** Maps class names to <fieldname, injection member key> */
	public static var instanceFieldInjections :MultiMap<Dynamic, Tuple<String, Array<String>>> = ArrayMultiMap.create(Class);
	public static var NULL_INJECTION :Tuple<String, Array<String>> = new Tuple(null, null);
	static var SINGLE_VALUE_ARRAY :Array<Dynamic> = [null];
}


