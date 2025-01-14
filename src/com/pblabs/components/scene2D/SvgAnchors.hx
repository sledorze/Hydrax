package com.pblabs.components.scene2D;

import Type;

import com.pblabs.geom.Vector2;
import com.pblabs.util.Comparators;
import com.pblabs.util.ds.Map;
import com.pblabs.util.ds.Maps;
import com.pblabs.util.ds.maps.SortedMap;
import com.pblabs.util.svg.SvgData;

import de.polygonal.motor2.geom.math.XY;

import flash.geom.Matrix;

using Lambda;

using StringTools;

using com.pblabs.components.scene2D.SvgRenderTools;
using com.pblabs.geom.VectorTools;
using com.pblabs.util.IterUtil;
using com.pblabs.util.StringUtil;
using com.pblabs.util.XmlTools;
using com.pblabs.util.svg.SvgTools;

/**
  * Parses svg Strings for anchor elements, and caches them.
  * Anchors are rect elements with either:
  * 1) an attribute "inkscape:label" (the value is the anchor name,
  * or 
  * 2) a rect with the element name e.g. "anchor*_rect2345".  The anchor name is the first element after splitting the string with "_"
  * 
  */
class SvgAnchors
{
	public static var ANCHOR_PREFIX = "anchor";
	public static var INKSCAPE_LABEL = "inkscape:label";
	
	static var _anchors :Map<SvgData, Map<String, XY>> = Maps.newHashMap(ValueType.TClass(SvgData)); 
	
	public static function getAnchors (svgData :SvgData) :Map<String, XY>
	{
		// com.pblabs.util.Assert.isNotNull(id, ' id is null');
		// com.pblabs.util.Assert.isNotNull(svg, ' svg is null');
		// var md5 = haxe.Md5.encode(svg);
	    if (_anchors.exists(svgData)) {
	    	return _anchors.get(svgData);
	    } else {
	    	// #if js
			// /** SVG documents added to the dom via innerHTML are *not* allowed to have any preamble. */
			// svg = svg.cleanSvgForInnerHtml();
			// #end
			// var svgXml = Xml.parse(svg).ensureNotDocument();
			var map = parseAnchors(svgData.xml);
			//Display objects are by default centered, but Svgs are not. Adjust for this.
			var bounds = svgData.xml.getSvgBounds();
			for (offset in map) {
				offset.x -= bounds.intervalX / 2;
				offset.y -= bounds.intervalY / 2;
			}
			_anchors.set(svgData, map);
			return map;
	    }
	}
	
	public static function parseAnchors(svg :Xml) :Map<String, XY>
	{
		var anchors :Map<String, XY> = new SortedMap(Maps.newHashMap(ValueType.TClass(String)), Comparators.compareStrings);
		parseSvgAnchorsRecursive(svg, anchors);
		return anchors;
	}
	
	static function parseSvgAnchorsRecursive (element :Xml, anchors :Map<String, XY>) :Void
	{
		if (element.nodeName == "rect".svgId()) {
			var isFromInkscapeLabel =  element.get(INKSCAPE_LABEL) != null && element.get(INKSCAPE_LABEL).toLowerCase().startsWith(ANCHOR_PREFIX);
			//Don't look for the second possibility if we've found the first
			var isFromId = !isFromInkscapeLabel && element.get("id").indexOf(ANCHOR_PREFIX) > -1;
			if (isFromInkscapeLabel || isFromId) { 
				var x = Std.parseFloat(element.get("x"));
				var y = Std.parseFloat(element.get("y"));
				var w = Std.parseFloat(element.get("width"));
				var h = Std.parseFloat(element.get("height"));
				//Don't offset by the width and height, that is taken care of by 
				//the hierarchy manager. You cannot assume offsets here.
				var anchor = new flash.geom.Point((x + w / 2), (y + h / 2));
				var transformMatrix = element.getAbsoluteTransform();
				var svgBounds = element.getSvgBounds();
				//We do this somewhere else?
				//Reverse the y axis, the origin of svg documents is the bottom left.
				var label = isFromInkscapeLabel ? element.get(INKSCAPE_LABEL) : element.get("id").split("_")[0];
				// trace(label + "=>" + anchor.toVector2());
				// anchors.set(label, anchor.toVector2().subtractLocal(new Vector2(svgBounds.intervalX / 2, svgBounds.intervalY / 2)));
				anchors.set(label, anchor.toVector2());
			}
		} else {
			if (element.nodeType == Xml.Element) {
				if (element.nodeName == "g".svgId() || element.nodeName == "svg".svgId()) {
					for (child in element.elements()) {
						parseSvgAnchorsRecursive(child, anchors);
					}
				}
			}
		}
	}
}
