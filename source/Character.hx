package;

import flixel.FlxSprite;
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
	var idleSequence:Array<String>;
	var animations:AnonType;
}

typedef CharacterAnimations =
{
	var fromPrefix:String;
	var indices:Array<Int>;
	var fps:Int;
	var loop:Bool;
}

class Character extends FlxSprite
{
	var data:CharacterData;
	var canIdle:Bool = true;

	public function new(x:Int, y:Int, character:String)
	{
		super(x, y);

		trace("Spawning " + character);

		var path:String = "data/characters/" + character + ".json";
		if (FileSystem.exists(path))
			data = Json.parse(File.getContent(path));
		else
		{
			trace("Error: Character doesn't exist");
			data = null;
			return;
		}

		/* Idle sequence must contain data so this is just a fallback */
		if (data.idleSequence == null || data.idleSequence.length == 0)
			data.idleSequence = ["idle"];

		trace(data.idleSequence);

		frames = AssetHelper.getSparrowAtlas(data.atlasPath[0], data.atlasPath[1]);
		antialiasing = true;

		for (animationName in Reflect.fields(data.animations))
		{
			var anim:CharacterAnimations = Reflect.field(data.animations, animationName);

			if (anim.fromPrefix != null && anim.fromPrefix != "")
			{
				if (anim.indices != null)
					animation.addByIndices(animationName, anim.fromPrefix, anim.indices, "", anim.fps, anim.loop, data.flipX);
				else
					animation.addByPrefix(animationName, anim.fromPrefix, anim.fps, anim.loop, data.flipX);
			}
		}

		this.y -= data.height;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	inline public function playAnim(anim:String, force:Bool = false)
	{
		if (animation.getByName(anim) != null)
			animation.play(anim, force);
	}

	public function playIdle(beat:Int)
	{
		if (data.idleSequence != null)
		{
			if (data.idleSequence.length > 1)
			{
				var index:Int = Std.int(Math.abs(beat)) % data.idleSequence.length;
				playAnim(data.idleSequence[index], true);
			}
			else
			{
				playAnim(data.idleSequence[0], true);
			}
		}
	}
}
