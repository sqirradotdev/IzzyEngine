package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import sys.io.File;

class Note extends FlxSprite
{
	public static var noteAsset:FlxAtlasFrames;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		if (noteAsset == null)
			loadNoteAsset();
	}

	public static function loadNoteAsset()
	{
		var atlasTexture:FlxGraphic = AssetHelper.getAsset("NOTE_assets.png", IMAGE);
		atlasTexture.persist = true;
		atlasTexture.destroyOnNoUse = false;
		noteAsset = FlxAtlasFrames.fromSparrow(atlasTexture, File.getContent(AssetHelper.getPath("NOTE_assets.xml", IMAGE)));
	}
}

class StrumLine extends FlxTypedSpriteGroup<FlxSprite>
{
	var strumLineScale:Float;

	public function new(x:Float, y:Float, scale:Float = 1.0)
	{
		super(x, y);

		this.strumLineScale = scale;

		if (Note.noteAsset == null)
			Note.loadNoteAsset();

		for (i in 0...4)
		{
			trace(i);

			var strumPart:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>((i * (115 * strumLineScale)), 0);
			add(strumPart);

			var strum:FlxSprite = new FlxSprite();
			strum.ID = 0;
			strum.frames = Note.noteAsset;
			strum.antialiasing = true;
			switch (i)
			{
				case 0:
					strum.animation.addByPrefix("strumLeft", "arrowLEFT", 24);
					strum.animation.play("strumLeft");
				case 1:
					strum.animation.addByPrefix("strumDown", "arrowDOWN", 24);
					strum.animation.play("strumDown");
				case 2:
					strum.animation.addByPrefix("strumUp", "arrowUP", 24);
					strum.animation.play("strumUp");
				case 3:
					strum.animation.addByPrefix("strumRight", "arrowRIGHT", 24);
					strum.animation.play("strumRight");
			}
			strum.updateHitbox();
			strum.origin.set();
			strum.scale.set(0.7 * strumLineScale, 0.7 * strumLineScale);
			strumPart.add(strum);
		}
	}
}
