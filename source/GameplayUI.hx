package;

import flixel.FlxSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import haxe.Json;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import sys.FileSystem;
import sys.io.File;

typedef NoteStyleData =
{
	var name:String;
	var atlasPath:String;
	var globalNoteScale:Float;
	var animations:NoteStyleAnimationData;
}

typedef NoteStyleAnimationData =
{
	var arrowAnimPrefix:Array<String>;
	var tailHoldAnimPrefix:Array<String>;
	var tailEndAnimPrefix:Array<String>;
	var strumIdleAnimPrefix:Array<String>;
	var strumPressAnimPrefix:Array<String>;
	var strumHitAnimPrefix:Array<String>;
}

class NoteStyle
{
	// Holds note assets, from arrows, strum lines, and tails.
	public static var noteAsset:FlxAtlasFrames;

	public static var data:NoteStyleData;

	// Needed for FlxTiledSprite
	public static var tailHoldGraphics:Array<FlxGraphic> = [null, null, null, null];

	public static function loadNoteStyle(file:String = "default", reload:Bool = false)
	{
		if (noteAsset == null || reload)
		{
			var path:String = "./data/noteStyles/";
			if (FileSystem.exists(path + file + ".json"))
				path += file + ".json";
			else
				path += "default.json";

			data = Json.parse(File.getContent(path));

			var atlasTexture:FlxGraphic = AssetHelper.getAsset(data.atlasPath + ".png", IMAGE);
			atlasTexture.persist = true;
			atlasTexture.destroyOnNoUse = false;
			noteAsset = FlxAtlasFrames.fromSparrow(atlasTexture, File.getContent(AssetHelper.getPath(data.atlasPath + ".xml", IMAGE)));

			for (frameName in noteAsset.framesHash.keys())
			{
				for (i in 0...4)
				{
					if (StringTools.startsWith(frameName, NoteStyle.data.animations.tailHoldAnimPrefix[i]))
					{
						var frame:FlxFrame = NoteStyle.noteAsset.framesHash.get(frameName);
						var graphic:FlxGraphic = FlxGraphic.fromFrame(frame);
						graphic.persist = true;
						graphic.destroyOnNoUse = false;

						// Scale the BitmapData inside the graphic
						var matrix:Matrix = new Matrix();
						matrix.scale(data.globalNoteScale, data.globalNoteScale);
						var newBD:BitmapData = new BitmapData(Std.int(graphic.bitmap.width * data.globalNoteScale),
							Std.int(graphic.bitmap.height * data.globalNoteScale), true, 0x000000);
						newBD.draw(graphic.bitmap, matrix, null, null, null, true);
						graphic.bitmap = newBD;

						if (tailHoldGraphics[i] != null)
							tailHoldGraphics[i].destroy();

						tailHoldGraphics[i] = graphic;
					}
				}
			}
		}
	}
}

class Note extends FlxTypedSpriteGroup<FlxSprite>
{
	public var time:Float;
	public var holdTime:Float;
	public var noteSpeed:Float = 1.0;

	var prevNoteSpeed:Float = 0.0;

	var arrow:FlxSprite;
	var tailHold:FlxTiledSprite;
	var tailEnd:FlxSprite;
	var noteScale:Float;

	public function new(x:Float, y:Float, strumIndex:Int, time:Float, holdTime:Float = 0.0, noteSpeed:Float = 1.0, scale:Float = 1.0)
	{
		super(x, y);

		this.time = time;
		this.holdTime = holdTime;
		this.noteSpeed = noteSpeed;
		this.noteScale = scale;

		// Just in case it's not loaded yet
		NoteStyle.loadNoteStyle();

		// Tail (note hold) rendering
		if (holdTime > 0)
		{
			tailHold = new FlxTiledSprite(null, NoteStyle.tailHoldGraphics[strumIndex].width, 10);
			tailHold.loadGraphic(NoteStyle.tailHoldGraphics[strumIndex]);
			tailHold.y = 10;
			tailHold.origin.set();
			tailHold.antialiasing = true;
			add(tailHold);

			tailEnd = new FlxSprite();
			tailEnd.frames = NoteStyle.noteAsset;
			tailEnd.antialiasing = true;
			tailEnd.animation.addByPrefix("idle", NoteStyle.data.animations.tailEndAnimPrefix[strumIndex], 0, false);
			tailEnd.animation.play("idle");
			tailEnd.origin.set();
			tailEnd.scale.x = NoteStyle.data.globalNoteScale * noteScale;
			tailEnd.scale.y = tailEnd.scale.x;
			tailEnd.updateHitbox();
			add(tailEnd);
		}

		// Arrow rendering
		arrow = new FlxSprite(0, 0);
		arrow.frames = NoteStyle.noteAsset;
		arrow.antialiasing = true;
		arrow.animation.addByPrefix("idle", NoteStyle.data.animations.arrowAnimPrefix[strumIndex], 0, false);
		arrow.animation.play("idle");
		arrow.origin.set();
		arrow.scale.x = NoteStyle.data.globalNoteScale * noteScale;
		arrow.scale.y = arrow.scale.x;
		arrow.updateHitbox();

		if (tailHold != null)
			tailHold.x = (arrow.width - tailHold.width) / 2;

		updateNoteHold();

		add(arrow);
	}

	public function updateNoteHold()
	{
		if (prevNoteSpeed != noteSpeed)
		{
			if (tailHold != null)
			{
				tailHold.height = (holdTime * (400.0 * noteSpeed));
				tailEnd.setPosition(tailHold.x, tailHold.y + tailHold.height);
			}

			prevNoteSpeed = noteSpeed;
		}
	}
}

class StrumLine extends FlxTypedSpriteGroup<FlxTypedSpriteGroup<FlxSprite>>
{
	public var noteSpeed:Float;
	public var time:Float;

	var strumLineScale:Float;

	var noteObjects:Array<Note> = [];

	public function new(x:Float, y:Float, scale:Float = 1.0, noteSpeed:Float = 1.0)
	{
		super(x, y);

		this.strumLineScale = scale;
		this.noteSpeed = noteSpeed;

		// Just in case it's not loaded yet
		NoteStyle.loadNoteStyle();

		for (i in 0...4)
		{
			var strumPart:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>((i * (108 * strumLineScale)), 0);
			add(strumPart);

			var strum:FlxSprite = new FlxSprite();
			strum.frames = NoteStyle.noteAsset;
			strum.antialiasing = true;

			strum.animation.addByPrefix("idle", NoteStyle.data.animations.strumIdleAnimPrefix[i], 0);
			strum.animation.addByPrefix("pressed", NoteStyle.data.animations.strumPressAnimPrefix[i], 0);
			strum.animation.addByPrefix("hit", NoteStyle.data.animations.strumHitAnimPrefix[i], 0);
			strum.animation.play("idle");

			strum.updateHitbox();
			strum.origin.set();
			strum.scale.x = NoteStyle.data.globalNoteScale * strumLineScale;
			strum.scale.y = strum.scale.x;
			strumPart.add(strum);
		}
	}

	override public function update(elapsed:Float)
	{
		for (note in noteObjects)
		{
			// Calculate note time relative to current song time
			var timeRel:Float = note.time - time;

			// Used for note hold rendering
			note.noteSpeed = noteSpeed;
			note.updateNoteHold();

			// Update note position
			note.y = (timeRel * (400.0 * noteSpeed)) + y;

			// Unhide note when it's on the screen
			if (!note.visible)
			{
				if (note.y < 720)
					note.visible = true;
			}
		}
	}

	public function addNote(strumIndex:Int, time:Float, holdTime:Float = 0.0)
	{
		if (strumIndex < 4)
		{
			var note:Note = new Note(0, 0, strumIndex, time, holdTime, noteSpeed);
			// Hide note to minimize rendering cost
			note.visible = false;
			members[strumIndex].add(note);
			// Store in a separate array for easy access
			noteObjects.push(note);
		}
	}
}
