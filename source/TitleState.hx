package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class TitleState extends MusicBeatState
{
	static var transitionInitialized:Bool = false;
	static var introSkipped:Bool = false;

	var entered:Bool = false;

	var newgroundsLogo:FlxSprite;
	var logoBumpin:FlxSprite;
	var gfDanceTitle:FlxSprite;
	var titleText:FlxSprite;

	var textGroup:FlxTypedGroup<FlxObject>;

	public function new()
	{
		super();
		persistentUpdate = true;
	}

	override public function create()
	{
		RichPresence.setIdling(TITLE);

		if (introSkipped)
			transIn = FlxTransitionableState.defaultTransIn;
		else
			transIn = null;
		transOut = FlxTransitionableState.defaultTransOut;

		super.create();

		textGroup = new FlxTypedGroup<FlxObject>();
		add(textGroup);

		newgroundsLogo = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(AssetHelper.getAsset("title/newgrounds_logo.png", IMAGE));
		newgroundsLogo.active = false;
		newgroundsLogo.visible = false;
		newgroundsLogo.antialiasing = true;
		newgroundsLogo.setGraphicSize(Std.int(newgroundsLogo.width * 0.8));
		newgroundsLogo.screenCenter(X);
		add(newgroundsLogo);

		gfDanceTitle = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDanceTitle.frames = AssetHelper.getSparrowAtlas("title/gfDanceTitle");
		gfDanceTitle.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDanceTitle.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDanceTitle.visible = false;
		gfDanceTitle.antialiasing = true;
		add(gfDanceTitle);

		logoBumpin = new FlxSprite(-150, -100);
		logoBumpin.frames = AssetHelper.getSparrowAtlas("title/logoBumpin");
		logoBumpin.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBumpin.animation.play("bump");
		logoBumpin.visible = false;
		logoBumpin.antialiasing = true;
		add(logoBumpin);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = AssetHelper.getSparrowAtlas("title/titleEnter");
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.animation.play('idle');
		titleText.visible = false;
		titleText.antialiasing = true;
		add(titleText);

		if (introSkipped)
			toTitle();

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
			Conductor.bpm = 102;
			FlxG.sound.playMusic(AssetHelper.getAsset("freakyMenu.ogg", MUSIC));
		}

		FlxG.watch.add(textGroup, "length");
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!entered && introSkipped)
		{
			if (FlxG.keys.justPressed.ENTER)
			{
				entered = true;

				FlxG.sound.play(AssetHelper.getAsset("confirmMenu.ogg", SOUND));
				FlxG.camera.flash(FlxColor.WHITE, 1);
				titleText.animation.play("press");

				new FlxTimer().start(2, function(timer:FlxTimer)
				{
					FlxG.switchState(new MainMenuState());
				});
			}
		}

		if (FlxG.keys.justPressed.ENTER && !introSkipped)
		{
			deleteAllTexts();
			toTitle();
		}
	}

	override public function onBeat():Void
	{
		if ((Conductor.beat % 2) == 0)
			gfDanceTitle.animation.play("danceLeft");
		else
			gfDanceTitle.animation.play("danceRight");

		if (!introSkipped)
		{
			switch (Conductor.beat)
			{
				case 1:
					addTexts(['ninjamuffin', 'phantomArcade', 'kawaisprite', 'evilsker']);
				case 3:
					addText("present");
				case 4:
					deleteAllTexts();
				case 5:
					addTexts(['In Partnership', 'with']);
				case 7:
					addText("newgrounds");
					newgroundsLogo.visible = true;
				case 8:
					deleteAllTexts();
					newgroundsLogo.visible = false;
				case 9:
					addText("not the original game");
				case 11:
					addText("this is a complete remake");
				case 12:
					deleteAllTexts();
				case 13:
					addText("friday");
				case 14:
					addText("night");
				case 15:
					addText("funkin");
				case 16:
					deleteAllTexts();
					toTitle();
			}
		}
	}

	function toTitle()
	{
		if (!introSkipped)
			FlxG.camera.flash(FlxColor.WHITE, 4);

		introSkipped = true;

		remove(newgroundsLogo, true);
		newgroundsLogo.destroy();

		gfDanceTitle.visible = true;
		logoBumpin.visible = true;
		titleText.visible = true;
	}

	function addText(text:String)
	{
		var alphabet:Alphabet = new Alphabet(0, textGroup.length * 60 + 200, text);
		alphabet.screenCenter(X);
		textGroup.add(alphabet);
	}

	function addTexts(texts:Array<String>)
	{
		for (text in texts)
		{
			addText(text);
		}
	}

	function deleteAllTexts()
	{
		while (textGroup.length > 0)
		{
			textGroup.members[0].destroy();
			textGroup.remove(textGroup.members[0], true);
		}
	}
}
