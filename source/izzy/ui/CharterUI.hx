package izzy.ui;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import izzy.core.AssetHelper;
import izzy.core.ChartParser.NoteData;
import izzy.core.Conductor;
import izzy.ui.GameplayUI.NoteObject;
import izzy.ui.GameplayUI.NoteStyle;
import openfl.geom.Rectangle;

class StatusBar extends FlxTypedGroup<FlxBasic>
{
	var bg:FlxSprite;
	var text:FlxText;
	var versionText:FlxText;
	
	public function new()
	{
		super();

		bg = new FlxSprite().makeGraphic(1280, 35, FlxColor.BLACK);
		bg.graphic.bitmap.fillRect(new Rectangle(0, 0, 1280, 4), 0xFFBE560E);
		bg.y = FlxG.height - 35;
		add(bg);

		text = new FlxText(0, 0, 0, "Ready.");
		text.size = 16;
		text.x = 8;
		text.y = bg.y + 7;
		add(text);
		
		versionText = new FlxText(0, 0, 0, "v0.1");
		versionText.size = 16;
		versionText.updateHitbox();
		versionText.x = FlxG.width - 8 - versionText.width;
		versionText.y = bg.y + 7;
		add(versionText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}

class CharterStrumLine extends FlxTypedGroup<FlxSprite>
{
	// Position and scaling
	public var position:FlxPoint = new FlxPoint();
	var prevPosition:FlxPoint = new FlxPoint();

	public var scale:Float;
	var prevScale:Float = 0;

	public var strumObjects:Array<FlxSprite> = [];

	public function new(x:Float, y:Float, scale:Float = 1.0)
	{
		super();

		position.x = x;
		position.y = y;

		this.scale = scale;

		for (i in 0...4)
		{
			var strum:FlxSprite = new FlxSprite();
			strum.frames = AssetHelper.getSparrowAtlas(NoteStyle.data.atlasPath[0], NoteStyle.data.atlasPath[1]);
			strum.antialiasing = NoteStyle.data.antialiasing;

			strum.animation.addByPrefix("idle", NoteStyle.data.animPrefixes.strumIdle[i], 0, false);
			strum.animation.addByPrefix("hit", NoteStyle.data.animPrefixes.strumHit[i], 24, false);
			strum.animation.play("idle");
			
			add(strum);

			strumObjects.push(strum);
		}

		update(0);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// Update position and scaling of strum line
		if (prevPosition.x != position.x || prevPosition.y != position.y || prevScale != scale)
		{
			for (i in 0...strumObjects.length)
			{
				var strum:FlxSprite = strumObjects[i];

				strum.origin.set();

				strum.scale.x = NoteStyle.data.globalNoteScale * scale;
				strum.scale.y = strum.scale.x;

				strum.x = position.x + (i * 108 * scale);
				strum.y = position.y;

				strum.updateHitbox();
			}

			prevPosition.x = position.x;
			prevPosition.y = position.y;

			prevScale = scale;
		}
	}

	/* Helper function to play animation on a specific strum line sprite */
	inline public function playStrumAnim(strumIndex:Int, animName:String)
		strumObjects[strumIndex].animation.play(animName);
}

class CharterNoteObject extends FlxTypedSpriteGroup<FlxSprite>
{
	public var strumIndex:Int;
	public var whoseStrum:Int;
	public var tick:Int;
	public var holdTick:Int;

	public var arrow:FlxSprite;
	public var noteHold:FlxSprite;
	public var infoText:FlxText;
	public var noteScale:Float;

	var quant:Int = 0;

	public function new(x:Float, y:Float, strumIndex:Int, whoseStrum:Int, tick:Int, scale:Float)
	{
		super(x, y);

		this.strumIndex = strumIndex;
		this.whoseStrum = whoseStrum;
		this.tick = tick;
		this.noteScale = scale;

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
		add(arrow);

/* 		infoText = new FlxText();
		infoText.size = 20;
		infoText.color = FlxColor.RED;
		add(infoText);

		if (tick % Math.floor((192 / 4)) == 0)
			quant = 4;
		else if (tick % Math.floor((192 / 8)) == 0)
			quant = 8;
		else if (tick % Math.floor((192 / 12)) == 0)
			quant = 12;
		else if (tick % Math.floor((192 / 16)) == 0)
			quant = 16;
		else if (tick % Math.floor((192 / 20)) == 0)
			quant = 20;
		else
			quant = 0;

		infoText.text = Std.string(quant); */

	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		//infoText.setPosition(arrow.x, arrow.y);
	}
}

class CharterArea extends FlxTypedGroup<FlxBasic>
{
	public var currentTime:Float = 0;
	public var currentBeat:Float = 0;
	public var currentTick:Float = 0;

	public var currentSnap:Int = 0;
	public var currentZoom:Float = 1.0;

	public var cursorPos:FlxPoint = new FlxPoint();
	public var cursorStrumLine:Int = 0;
	public var cursorStrumPart:Int = 0;
	public var cursorTick:Int = 0;
	public var cursorInside:Bool = false;
	
	var bg0:FlxSprite;
	var bg1:FlxSprite;

	var lines:FlxSprite;
	
	var sl0:CharterStrumLine;
	var sl1:CharterStrumLine;

	var noteObjects:FlxTypedGroup<CharterNoteObject>;

	var quant0:FlxSprite;
	var quant1:FlxSprite;

	var cursor:FlxSprite;

	var informationText:FlxText;
	var cursorPosText:FlxText;
	
	public function new()
	{
		super();

		bg0 = new FlxSprite(189).makeGraphic(320, 720, FlxColor.BLACK);
		bg0.alpha = 0.65;
		add(bg0);

		bg1 = new FlxSprite(523).makeGraphic(320, 720, FlxColor.BLACK);
		bg1.alpha = 0.65;
		add(bg1);

		lines = new FlxSprite(bg0.x).makeGraphic(653, 720, FlxColor.TRANSPARENT, true);
		lines.updateHitbox();
		add(lines);

		sl0 = new CharterStrumLine(236, 120, 0.6);
		add(sl0);

		sl1 = new CharterStrumLine(537, 120, 0.6);
		add(sl1);

		noteObjects = new FlxTypedGroup<CharterNoteObject>();
		add(noteObjects);

		quant0 = new FlxSprite(203, 128).loadGraphic(AssetHelper.getAsset("charter/quantIndicator.png", IMAGE));
		quant0.antialiasing = true;
		add(quant0);

		quant1 = new FlxSprite(805, 128).loadGraphic(quant0.graphic);
		quant1.antialiasing = true;
		add(quant1);

		cursor = new FlxSprite().makeGraphic(Std.int(sl0.strumObjects[0].width), Std.int(sl0.strumObjects[0].height),
			FlxColor.WHITE);
		cursor.alpha = 0.5;
		add(cursor);

		informationText = new FlxText(10, 550);
		informationText.size = 16;
		add(informationText);

		cursorPosText = new FlxText(10, 100);
		cursorPosText.size = 16;
		add(cursorPosText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var tickMod:Float = currentTick % Conductor.ticksPerBeat;

		// Line row rendering
		FlxSpriteUtil.fill(lines, FlxColor.TRANSPARENT);
		for (i in -10...30)
		{
			var targetY:Float = sl0.position.y + (i * Conductor.ticksPerBeat * 3 * currentZoom) - (tickMod * 6 * currentZoom) + (sl0.strumObjects[0].height / 2);
			var color:FlxColor = FlxColor.WHITE;
			if (i % 2 != 0)
				color = FlxColor.GRAY;
			FlxSpriteUtil.drawLine(lines, 0, targetY, 319, targetY, {color: color, thickness: 2});
			FlxSpriteUtil.drawLine(lines, 335, targetY, 320 + 336, targetY, {color: color, thickness: 2});
		}

		// Note rendering
		noteObjects.forEach(function(noteObject:CharterNoteObject)
		{
			var sl:CharterStrumLine = noteObject.whoseStrum == 0 ? sl0 : sl1;
			
			noteObject.x = sl.position.x + (noteObject.strumIndex * 108 * sl.scale);
			noteObject.y = sl.position.y + ((noteObject.tick - currentTick) * 6 * currentZoom);
		});

		cursorPos = FlxG.mouse.getPositionInCameraView(camera).copyTo();

		var sl:CharterStrumLine = null;
		if (cursorPos.x >= sl0.position.x && cursorPos.x <= (sl0.strumObjects[3].x + sl0.strumObjects[3].width))
			sl = sl0;
		else if (cursorPos.x >= sl1.position.x && cursorPos.x <= (sl1.strumObjects[3].x + sl1.strumObjects[3].width))
			sl = sl1;

		if (sl != null)
		{
			cursorPos.x -= sl.position.x;
			cursorPos.x = cursorPos.x - (cursorPos.x % sl.strumObjects[0].width);
			cursorStrumPart = Std.int(cursorPos.x / sl.strumObjects[0].width);
			cursorPos.x += sl.position.x;

			cursorPos.y -= sl.position.y;
			cursorPos.y = cursorPos.y - (cursorPos.y % (6 * currentZoom * (192 / currentSnap)));
			cursorTick = Std.int((cursorPos.y / (6 * currentZoom)) + currentTick);
			cursorPos.y += sl.position.y;

			cursor.setPosition(cursorPos.x, cursorPos.y);
			cursor.visible = true;
			cursorInside = true;
		}
		else
		{
			cursor.visible = false;
			cursorInside = false;
		}

		cursorPosText.text = "sp: " + cursorStrumPart + "\ntick: " + cursorTick;

		informationText.text = "Snap: " + currentSnap
			+ "\nZoom: " + currentZoom + "x"
			+ "\n\nTime: " + currentTime
			+ "\nBeat: " + Math.floor(currentBeat)
			+ "\nTick: " + Math.floor(currentTick);
	}

	public function makeArrows(notes:Array<NoteData>)
	{
		for (note in notes)
		{
			var noteObject:CharterNoteObject = new CharterNoteObject(0, 0, note.strumIndex, note.whoseStrum, note.tick, sl0.scale);
			noteObjects.add(noteObject);
		}
	}

	public function setQuantColor(color:FlxColor)
	{
		quant0.color = color;
		quant1.color = color;
	}
}