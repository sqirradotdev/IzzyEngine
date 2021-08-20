package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxPoint;
import haxe.Json;
import haxe.ds.StringMap;
import haxe.macro.Type.AnonType;
import sys.FileSystem;
import sys.io.File;

typedef CharacterData =
{
	var name:String;
	var atlasPath:Array<String>;
	var flipX:Bool;
	var height:Int;
	var cameraOffset:Array<Float>;
	var idleSequence:Array<String>;
	var animations:AnonType;
}

typedef CharacterAnimation =
{
	var fromPrefix:String;
	var indices:Array<Int>;
	var fps:Int;
	var loop:Bool;
	var offset:Array<Float>;
}

class Character extends FlxSprite
{
	public var idleSuffix:String = "";
	public var singSuffix:String = "";
	
	var data:CharacterData;
	var currentSupress:Int = 0;

	public function new(x:Int, y:Int, character:String)
	{
		super(x, y);

		trace("Spawning " + character);

		var path:String = "data/characters/" + character + ".json";
		if (!FileSystem.exists(path))
		{
			trace("Error: Character doesn't exist, defaulting to dad.");
			character = "dad";
		}

		data = Json.parse(File.getContent(path));

		trace(data.idleSequence);

		frames = AssetHelper.getSparrowAtlas(data.atlasPath[0], data.atlasPath[1]);
		antialiasing = true;

		for (animationName in Reflect.fields(data.animations))
		{
			var anim:CharacterAnimation = Reflect.field(data.animations, animationName);

			if (anim.fromPrefix != null && anim.fromPrefix != "")
			{
				if (anim.indices != null)
					animation.addByIndices(animationName, anim.fromPrefix, anim.indices, "", anim.fps, anim.loop, data.flipX);
				else
					animation.addByPrefix(animationName, anim.fromPrefix, anim.fps, anim.loop, data.flipX);

				if (anim.offset != null)
				{
					for (i in animation.getByName(animationName).frames)
					{
						var frame:FlxFrame = frames.frames[i];
						frame.offset.x += anim.offset[0];
						frame.offset.y += anim.offset[1];
					}
				}
			}
		}

		this.y -= data.height;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	public function getCameraMidpoint():FlxPoint
	{
		var midpoint:FlxPoint = super.getMidpoint();

		if (data.cameraOffset != null)
		{
			midpoint.x += data.cameraOffset[0];
			midpoint.y += data.cameraOffset[1];
		}

		return midpoint;
	}

	inline public function playAnim(anim:String, force:Bool = false, supressDuration:Int = 0)
	{
		if (animation.getByName(anim) != null)
		{
			animation.play(anim, force);
			currentSupress = supressDuration;
		}
	}

	public function playIdle(beat:Int)
	{
		if (currentSupress > 0)
			currentSupress -= 1;
		
		if (currentSupress == 0)
		{
			if (data.idleSequence != null)
			{
				if (data.idleSequence.length > 1)
				{
					var index:Int = Std.int(Math.abs(beat)) % data.idleSequence.length;
					playAnim(data.idleSequence[index] + idleSuffix, true);
				}
				else
				{
					playAnim(data.idleSequence[0] + idleSuffix, true);
				}
			}
			else
				playAnim("idle" + singSuffix, true);
		}
	}

	public function playSingAnim(strumIndex:Int, suffix:String = "", force:Bool = true)
	{
		var animName:String = "";
		switch (strumIndex)
		{
			case 0:
				animName = "singLeft";
			case 1:
				animName = "singDown";
			case 2:
				animName = "singUp";
			case 3:
				animName = "singRight";
		}
		
		playAnim(animName + suffix + singSuffix, force, 2);
	}

	public function playMissAnim(strumIndex:Int)
	{
		playSingAnim(strumIndex, "Miss");
	}
}
