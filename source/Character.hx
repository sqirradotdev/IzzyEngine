package;

import flixel.FlxG;
import flixel.FlxSprite;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.ds.StringMap;
import lime.utils.Assets;
#if desktop
import sys.FileSystem;
import sys.io.File;
#end

typedef CharacterData =
{
	var name:String;
	var atlasPath:Array<String>;
	var flipX:Bool;
	var animations:StringMap<CharacterAnimationData>;
}

typedef CharacterAnimationData =
{
	var fromPrefix:String;
	var indices:Array<Int>;
	var fps:Int;
	var loop:Bool;
}

class Character extends FlxSprite
{
	public function new(x:Int, y:Int, character:String)
	{
		super(x, y);

		var path:String = "data/characters/" + character + ".json";
		var characterData:CharacterData;

		#if desktop
		if (FileSystem.exists(path))
			characterData = Json.parse(File.getContent(path));
		else
		{
			trace("Unknown character.");
			characterData = null;
		}
		#else
		characterData = Json.parse(Assets.getText(path));
		#end

		frames = AssetHelper.getSparrowAtlas(characterData.atlasPath[0], characterData.atlasPath[1]);
		antialiasing = true;

		trace(characterData.name + " animations:");

		for (animationName in Reflect.fields(characterData.animations))
		{
			var anim:CharacterAnimationData = Reflect.field(characterData.animations, animationName);

			if (anim.fromPrefix != null && anim.fromPrefix != "")
			{
				if (anim.indices != null)
					animation.addByIndices(animationName, anim.fromPrefix, anim.indices, "", anim.fps, anim.loop, characterData.flipX);
				else
					animation.addByPrefix(animationName, anim.fromPrefix, anim.fps, anim.loop, characterData.flipX);
			}
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
