package com.pblabs.engine.pooling;
import flash.display.MovieClip;
import flash.display.Sprite;

import com.pblabs.util.DisplayUtils;
import com.pblabs.util.Preconditions;

import com.pblabs.engine.core.pooling.ObjectPool;

class SpritePool extends ObjectPool {
    
    public function new()
    {
        super(Sprite);
    }

    public override function addObject (o :Dynamic) :Void
    {
        Preconditions.checkArgument(!(Std.is( o, MovieClip)), "Sprites, not MovieClips");
        var s:Sprite = cast( o, Sprite);

        //Clean up the Sprite.
        DisplayUtils.detach(s);
        DisplayUtils.removeAllChildren(s);
        s.graphics.clear();
        s.x = 0;
        s.y = 0;
        s.scaleX = s.scaleY = 1;
        s.alpha = 1;
        trace("adding a sprite, total", size);
        super.addObject(s);
    }

}

