/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 */

package com.pblabs.components.tasks;

import com.pblabs.engine.core.IEntity;
import com.pblabs.util.Preconditions;
import com.pblabs.util.ReflectUtil;

class SetFieldTask
	implements IEntityTask 
{
	
	public function new (obj :Dynamic, fieldName :String, val :Dynamic)
	{
		Preconditions.checkNotNull(obj);
		Preconditions.checkNotNull(fieldName);
		_obj = obj;
		_fieldName = fieldName;
		_val = val;
	}
	
	public function update (dt :Float, obj :IEntity) :Bool
	{
		ReflectUtil.setField(_obj, _fieldName, _val);
		return true;
	}
	
	public function clone () :IEntityTask
	{
		return new SetFieldTask(_obj, _fieldName, _val);
	}
	
	var _obj :Dynamic;
	var _fieldName :String;
	var _val :Dynamic;
}