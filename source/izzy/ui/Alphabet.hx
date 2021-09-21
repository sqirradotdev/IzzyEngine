package izzy.ui;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import izzy.core.AssetHelper;
import lime.utils.Assets;
import sys.io.File;

class Alphabet extends FlxTypedSpriteGroup<FlxSprite>
{
	static var alphabetAsset:FlxAtlasFrames;

	public function new(x:Float, y:Float, text:String = "")
	{
		super(x, y);

		if (alphabetAsset == null)
			loadAlphabetAsset();

		text = text.toUpperCase();

		var sumWidth:Float = 0;

		for (x in 0...text.length)
		{
			var letter:String = text.charAt(x);

			if (letter != " ")
			{
				var letterSprite:FlxSprite = new FlxSprite(sumWidth, 0);
				letterSprite.frames = alphabetAsset;
				letterSprite.antialiasing = true;
				letterSprite.animation.addByPrefix(letter, letter + " bold", 24, true);
				letterSprite.animation.play(letter);
				add(letterSprite);

				sumWidth += letterSprite.frameWidth;
			}
			else
				sumWidth += 54;
		}
	}

	public function loadAlphabetAsset()
	{
		// var atlasTexture:FlxGraphic = FlxGraphic.fromAssetKey("assets/default/images/alphabet.png");
		var atlasTexture:FlxGraphic = AssetHelper.getAsset("alphabet.png", IMAGE);
		atlasTexture.persist = true;
		atlasTexture.destroyOnNoUse = false;
		alphabetAsset = FlxAtlasFrames.fromSparrow(atlasTexture, File.getContent(AssetHelper.getPath("alphabet.xml", IMAGE)));
	}
}
