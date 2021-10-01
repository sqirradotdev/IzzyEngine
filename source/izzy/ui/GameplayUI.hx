package izzy.ui;

import flixel.FlxSprite;
import flixel.animation.FlxAnimation;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import haxe.Json;
import izzy.core.AssetHelper;
import openfl.display.BitmapData;
import openfl.geom.ColorTransform;
import sys.FileSystem;
import sys.io.File;

typedef NoteStyleData =
{
	var name:String;
	var atlasPath:Array<String>;
	var globalNoteScale:Float;
	var antialiasing:Bool;
	var animPrefixes:NoteStyleAnimations;
}

typedef NoteStyleAnimations =
{
	var arrow:Array<String>;
	var tailHold:Array<String>;
	var tailEnd:Array<String>;
	var strumIdle:Array<String>;
	var strumPress:Array<String>;
	var strumHit:Array<String>;
}

class NoteStyle
{
	// Holds note assets, from arrows, strum lines, and tails.
	public static var noteAsset:FlxAtlasFrames;
	public static var data:NoteStyleData;

	// Needed for FlxTiledSprite
	public static var tailHoldGraphics:Array<FlxGraphic> = [null, null, null, null];

	public static function loadNoteStyle(file:String = "default")
	{
		var path:String = AssetHelper.getDataPath(file + ".json", NOTE_STYLES);
		if (!FileSystem.exists(path))
			path = AssetHelper.getDataPath("default.json", NOTE_STYLES);

		data = Json.parse(File.getContent(path));

		noteAsset = AssetHelper.getSparrowAtlas(data.atlasPath[0], data.atlasPath[1]);

		/* Convert hold tail frames to FlxGraphic due to how FlxTiledSprite works */
		for (frameName in noteAsset.framesHash.keys())
		{
			for (i in 0...4)
			{
				if (StringTools.startsWith(frameName, NoteStyle.data.animPrefixes.tailHold[i]))
				{
					var frame:FlxFrame = noteAsset.framesHash.get(frameName);
					var graphic:FlxGraphic = FlxGraphic.fromFrame(frame);

					tailHoldGraphics[i] = graphic;
				}
			}
		}
	}
}

class NoteObject extends FlxTypedSpriteGroup<FlxSprite>
{
	public var strumIndex:Int;
	public var time:Float;
	public var holdTime:Float;
	public var holdProgress:Float = 0.0;
	public var noteSpeed:Float = 1.0;

	public var arrow:FlxSprite;
	public var tailHold:TiledSprite;
	public var tailEnd:FlxSprite;
	public var noteScale:Float;

	var prevNoteSpeed:Float = 0.0;

	public function new(x:Float, y:Float, strumIndex:Int, time:Float, holdTime:Float = 0.0, noteSpeed:Float = 1.0, scale:Float = 1.0)
	{
		super(x, y);

		this.strumIndex = strumIndex;
		this.time = time;
		this.holdTime = holdTime;
		this.noteSpeed = noteSpeed;
		this.noteScale = scale;

		// Tail (note hold) rendering
		if (holdTime > 0)
		{
			tailHold = new TiledSprite(null, 0, 1);
			tailHold.loadGraphic(NoteStyle.tailHoldGraphics[strumIndex]);
			tailHold.origin.set();
			tailHold.width = NoteStyle.tailHoldGraphics[strumIndex].width * NoteStyle.data.globalNoteScale * noteScale;
			tailHold.scale.x = NoteStyle.data.globalNoteScale * noteScale;
			tailHold.scale.y = tailHold.scale.x;
			tailHold.antialiasing = NoteStyle.data.antialiasing;
			add(tailHold);

			tailEnd = new FlxSprite();
			tailEnd.frames = AssetHelper.getSparrowAtlas(NoteStyle.data.atlasPath[0], NoteStyle.data.atlasPath[1]);
			tailEnd.antialiasing = NoteStyle.data.antialiasing;
			tailEnd.animation.addByPrefix("idle", NoteStyle.data.animPrefixes.tailEnd[strumIndex], 0, false);
			tailEnd.animation.play("idle");
			tailEnd.origin.set();
			tailEnd.scale.x = NoteStyle.data.globalNoteScale * noteScale;
			tailEnd.scale.y = tailEnd.scale.x;
			tailEnd.updateHitbox();
			add(tailEnd);
		}

		// Arrow rendering
		arrow = new FlxSprite(0, 0);
		arrow.frames = AssetHelper.getSparrowAtlas(NoteStyle.data.atlasPath[0], NoteStyle.data.atlasPath[1]);
		arrow.antialiasing = NoteStyle.data.antialiasing;
		arrow.animation.addByPrefix("idle", NoteStyle.data.animPrefixes.arrow[strumIndex], 0, false);
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
		if (prevNoteSpeed != noteSpeed || holdProgress > 0)
		{
			if (tailHold != null)
			{
				if (holdProgress > holdTime)
					holdProgress = holdTime;

				/* This is where I ran out of variable names */
				var th:Float = (holdTime * (400.0 * noteSpeed));
				var tp:Float = (holdProgress * (400.0 * noteSpeed));

				tailHold.height = th - tp;
				tailHold.y = 10 + arrow.y + tp;
				tailHold.scrollY = -tp;
				tailEnd.setPosition(tailHold.x, 10 + arrow.y + th);

				// trace("hp " + holdProgress + " tp " + tp + " normal " + holdTime + " y " + arrow.y);
			}

			prevNoteSpeed = noteSpeed;
		}
	}
}

class StrumLine extends FlxTypedGroup<FlxSprite>
{
	// Position and scaling
	public var position:FlxPoint = new FlxPoint();
	var prevPosition:FlxPoint = new FlxPoint();

	public var strumSpacing:Float = 108;
	var prevStrumSpacing:Float = 0;
	
	public var noteSpeed:Float;
	public var time:Float;

	var strumObjects:Array<FlxSprite> = [];
	var noteObjects:Array<NoteObject> = [];

	public function new(x:Float, y:Float, scale:Float = 1.0, noteSpeed:Float = 1.0)
	{
		super();

		this.noteSpeed = noteSpeed;

		position.x = x;
		position.y = y;

		for (i in 0...4)
		{
			var strum:FlxSprite = new FlxSprite();
			strum.frames = AssetHelper.getSparrowAtlas(NoteStyle.data.atlasPath[0], NoteStyle.data.atlasPath[1]);
			strum.antialiasing = NoteStyle.data.antialiasing;

			strum.animation.addByPrefix("idle", NoteStyle.data.animPrefixes.strumIdle[i], 0, false);
			strum.animation.addByPrefix("pressed", NoteStyle.data.animPrefixes.strumPress[i], 24, false);
			strum.animation.addByPrefix("hit", NoteStyle.data.animPrefixes.strumHit[i], 24, false);
			strum.animation.play("idle");

			strum.scale.x = NoteStyle.data.globalNoteScale;
			strum.scale.y = NoteStyle.data.globalNoteScale;

			strum.updateHitbox();
			add(strum);

			strumObjects.push(strum);
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// Update position and scaling of strum line
		if (prevStrumSpacing != strumSpacing || prevPosition.x != position.x || prevPosition.y != position.y)
		{
			for (i in 0...strumObjects.length)
			{
				var strum:FlxSprite = strumObjects[i];

				strum.x = position.x + (i * (strumSpacing));
				strum.y = position.y;
			}
			var totalWidth:Float = (strumObjects[strumObjects.length - 1].x - position.x) + (strumSpacing / 2);
			for (strum in strumObjects)
				strum.x -= totalWidth / 2;

			prevStrumSpacing = strumSpacing;
			prevPosition.x = position.x;
			prevPosition.y = position.y;
		}

		// Update note position
		for (note in noteObjects)
		{
			// Calculate note time relative to current song time
			var timeRel:Float = note.time - time;

			if (timeRel < 3.0)
			{
				// Used for note hold rendering
				note.noteSpeed = noteSpeed;
				note.updateNoteHold();

				// Update note position
				note.x = strumObjects[note.strumIndex].x;
				note.y = strumObjects[note.strumIndex].y + (timeRel * (400.0 * noteSpeed));

				if (!note.visible)
					note.visible = true;
			}
			else
			{
				break;
			}
		}
	}

	/* Helper function to play animation on a specific strum line sprite */
	inline public function playStrumAnim(strumIndex:Int, animName:String, force:Bool = false)
		strumObjects[strumIndex].animation.play(animName, force);

	inline public function getCurrentStrumAnim(strumIndex:Int):FlxAnimation
		return strumObjects[strumIndex].animation.curAnim;

	public function addNote(strumIndex:Int, time:Float, holdTime:Float = 0.0)
	{
		if (strumIndex < 4)
		{
			var note:NoteObject = new NoteObject(0, 0, strumIndex, time, holdTime, noteSpeed);
			// Hide note to minimize rendering cost
			note.visible = false;
			add(note);
			// Store in a separate array for easy access
			noteObjects.push(note);
		}
	}

	public function getNote(strumIndex:Int, time:Float):NoteObject
	{
		for (note in noteObjects)
		{
			if (note.strumIndex == strumIndex && note.time == time)
			{
				return note;
			}
		}

		return null;
	}

	public function invalidateNote(strumIndex:Int, time:Float)
	{
		var note:NoteObject = getNote(strumIndex, time);

		if (note != null)
		{
			note.alpha = 0.2;
			if (note.tailHold != null)
			{
				var clonedBD:BitmapData = note.tailHold.graphic.bitmap.clone();
				var clonedFG:FlxGraphic = FlxGraphic.fromBitmapData(clonedBD);

				clonedBD.colorTransform(clonedBD.rect, new ColorTransform(1, 1, 1, 0.2));
				note.tailHold.graphic = clonedFG;
			}
		}
	}

	public function removeNote(strumIndex:Int, time:Float)
	{
		var note:NoteObject = getNote(strumIndex, time);
		if (note != null)
		{
			remove(note, true);
			noteObjects.remove(note);
			note.destroy();
		}
	}
}
