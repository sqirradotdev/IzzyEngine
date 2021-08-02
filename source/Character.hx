package;

import flixel.FlxSprite;
import haxe.Json;
import haxe.ds.StringMap;
import sys.FileSystem;
import sys.io.File;

typedef CharacterData =
{
	var name:String;
	var atlasPath:Array<String>;
	var flipX:Bool;
	var height:Int;
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
	var character:String;
	var disableAnimPlaying:Bool = false;

	public function new(x:Int, y:Int, character:String)
	{
		super(x, y);

		this.character = character;

		var characterData:CharacterData;

		var path:String = "data/characters/" + character + ".json";
		if (FileSystem.exists(path))
			characterData = Json.parse(File.getContent(path));
		else
		{
			trace("Error: Character doesn't exist");
			characterData = null;
			return;
		}

		frames = AssetHelper.getSparrowAtlas(characterData.atlasPath[0], characterData.atlasPath[1]);
		antialiasing = true;

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

		// TODO: make all character heights
		this.y -= characterData.height;

		trace(characterData.name);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	public function playAnim(anim:String, force:Bool = false)
	{
		if (!disableAnimPlaying)
			animation.play(anim);
	}
}
