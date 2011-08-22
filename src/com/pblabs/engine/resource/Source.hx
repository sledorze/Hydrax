/*******************************************************************************
 * Hydrax: haXe port of the PushButton Engine
 * Copyright (C) 2010 Dion Amago
 * For more information see http://github.com/dionjwa/Hydrax
 *
 * This file is licensed under the terms of the MIT license, which is included
 * in the License.html file at the root directory of this SDK.
 ******************************************************************************/
package com.pblabs.engine.resource;

enum Source {
	url (u :String);
	bytes (b :haxe.io.Bytes);
	text (t :String);
	embedded (name :String);
	#if flash
	swf(swfName :String);
	#end
}
