/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file was derived from the equivalent actionscript PushButton Engine 
 * source file:
 * http://code.google.com/p/pushbuttonengine/
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.engine.core;

import com.pblabs.engine.core.IEntity;
import com.pblabs.engine.core.IEntityComponent;
import com.pblabs.engine.core.IPBContext;
import com.pblabs.engine.util.PBUtil;
import com.pblabs.util.ReflectUtil;

/**
* An implementation of the IEntityComponent interface, providing all the basic
* functionality required of all components. Custom components should always
* derive from this class rather than implementing IEntityComponent directly.
* 
* @see IEntity
*/
class EntityComponent 
	implements IEntityComponent, implements haxe.rtti.Infos
{
	/** Key for hashing. Don't modify. */
	public var key :Int;
	
	@editorData({ignore :"true"})
	public var context (get_context, set_context) :IPBContext;
 
	@editorData({ignore :"true"})
	public var owner (get_owner, set_owner) :IEntity;
   
   @editorData({ignore :"true"})
   public var isRegistered (get_isRegistered, never) :Bool;
   
   @editorData({ignore :"true"})
   public var name (get_name, set_name) :String;

   public function new() 
   {
   	   key = com.pblabs.engine.util.PBUtil.KEY_COUNT++;
	   _context =null;
	   _sanityCheck = false;
	   _isRegistered = false;
	   _owner = null;
	   _name = null;
   }
   
   function get_context():IPBContext
   {
	   return _context;
   }
   
   function set_context(value:IPBContext):IPBContext
   {
   	   com.pblabs.util.Assert.isTrue(_context == null || _context == value, ReflectUtil.getClassName(this) + " already registered in another context.");
	   _context = value;
	   return value;
   }

   function get_owner():IEntity
   {
	  return _owner;
   }
  
   function set_owner(value:IEntity):IEntity
   {
	  com.pblabs.util.Assert.isNotNull(value, "Cannot set an Entity owner to null.  This can only happen on unRegister");
	  com.pblabs.util.Assert.isTrue(_owner == null, "Cannot change the owner");
	  _owner = value;
	  return value;
   }
  
  function get_name():String
  {
	 return _name;
  }
  
  function set_name (name :String) :String
  {
	  com.pblabs.util.Assert.isTrue(_name == null, ReflectUtil.getClassName(this) + " already has a name");
	  _name = name;
	  return name;
  }
  
  function get_isRegistered():Bool
  {
	 return _isRegistered;
  }
  
  public function register(owner :IEntity, ?name:String):Void
  {
	  com.pblabs.util.Assert.isTrue(!isRegistered, "Trying to register an already-registered component!");
	 _context = owner.context;
	 _name = name;
	 _owner = owner;
	 _sanityCheck = false;
	 _isRegistered = true;
	 onAdd();
	 com.pblabs.util.Assert.isTrue(_sanityCheck, "Forgot to call super.onAdd(); in " + com.pblabs.util.ReflectUtil.getClassName(this) + "!");
  }
  
  public function unregister():Void
  {
	  com.pblabs.util.Assert.isTrue(isRegistered, "Trying to unregister an unregistered component!");
	 _isRegistered = false;
	 _sanityCheck = false;
	 onRemove();
	 com.pblabs.util.Assert.isTrue(_sanityCheck, "Forgot to call super.onRemove(); in " + com.pblabs.util.ReflectUtil.getClassName(this) + "!");
	 _owner = null;
	 _name = null;
	 _context = null;
  }
  
  public function reset():Void
  {
  	  _sanityCheck = false;
  	  onReset();
  	  com.pblabs.util.Assert.isTrue(_sanityCheck, "Forgot to call super.onReset(); in " + com.pblabs.util.ReflectUtil.getClassName(this) + "!");
  }
  
  /**
   * This is called when the component is added to an entity. Any initialization,
   * event registration, or object lookups should happen here. Component lookups
   * on the owner entity should NOT happen here. Use onReset instead.
   * 
   * @see #onReset()
   */
  function onAdd():Void
  {
	  _sanityCheck = true;
  }
  
  /**
   * This is called when the component is removed from an entity. It should reverse
   * anything that happened in onAdd or onReset (like removing event listeners or
   * nulling object references).
   */
  function onRemove():Void
  {
	#if debug
	debugOwnerName = owner.name + "." + name;
	#end
	  _sanityCheck = true;
  }
  
  /**
   * This is called anytime a component is added or removed from the owner entity.
   * Lookups of other components on the owner entity should happen here.
   * 
   * <p>This can potentially be called multiple times, so make sure previous lookups
   * are properly cleaned up each time.</p>
   */
  function onReset():Void
  {
	  _sanityCheck = true;
  }
  
  #if debug
  public function postDestructionCheck () :Void
  {
  	  //Subclasses override
  }
  var debugOwnerName :String;
  
  public function toString () :String
  {
  	  return "EntityComponent(" + _name + ")";
  }
  #end
  
  @editorData({ignore :"true"})
  var _isRegistered :Bool;
  
  @editorData({ignore :"true"})
  var _owner :IEntity;
  
  @editorData({ignore :"true"})
  var _name :String;
  
  @editorData({ignore :"true"})
  var _context :IPBContext;
  
  @editorData({ignore :"true"})
   var _sanityCheck:Bool;
}
