package izzy.state;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.plugin.taskManager.FlxTask;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import izzy.core.AssetHelper;
import izzy.core.Conductor;
import izzy.core.RichPresence;
import izzy.core.Util;
import izzy.state.base.MusicBeatState;
import openfl.Lib;

class MainMenuState extends MusicBeatState
{
	static var optionSelection:Int = 0;

	var optionSelected:Bool = false;
	var backed:Bool = false;

	var options:Array<String> = ["story mode", "freeplay", "donate", "options"];

	var tipTextMargin:Float = 10;
	var tipTextScrolling:Bool = false;

	var bg:FlxSprite;
	var bgMagenta:FlxSprite;
	var camFollow:FlxObject;
	var optionItems:FlxTypedGroup<FlxSprite>;

	var tipBackground:FlxSprite;
	var tipText:FlxText;

	public function new()
	{
		super();
		persistentUpdate = true;
	}

	override public function create()
	{
		super.create();

		RichPresence.setIdling(MAIN_MENU);

		bg = new FlxSprite(-100).loadGraphic(AssetHelper.getAsset("mainMenu/menuBG.png", IMAGE));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.10;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		bgMagenta = new FlxSprite(-80).loadGraphic(AssetHelper.getAsset("mainMenu/menuDesat.png", IMAGE));
		bgMagenta.scrollFactor.x = 0;
		bgMagenta.scrollFactor.y = 0.10;
		bgMagenta.setGraphicSize(Std.int(bgMagenta.width * 1.1));
		bgMagenta.screenCenter();
		bgMagenta.visible = false;
		bgMagenta.antialiasing = true;
		bgMagenta.color = 0xFFfd719b;
		add(bgMagenta);

		optionItems = new FlxTypedGroup<FlxSprite>();
		add(optionItems);

		var mainMenuAssets:FlxAtlasFrames = AssetHelper.getSparrowAtlas("mainMenu/mainMenuAssets");

		for (x in 0...options.length)
		{
			var optionItem:FlxSprite = new FlxSprite(0, 78 + (x * 160));
			optionItem.frames = mainMenuAssets;
			optionItem.animation.addByPrefix('idle', options[x] + " basic", 24);
			optionItem.animation.addByPrefix('selected', options[x] + " white", 24);
			optionItem.animation.play('idle');
			optionItem.ID = x;
			optionItem.updateHitbox();
			optionItem.screenCenter(X);
			optionItem.scrollFactor.set();
			optionItem.antialiasing = true;
			optionItems.add(optionItem);
		}

		var gameVersion:String = Lib.application.meta["version"];
		var versionText:FlxText = new FlxText(0, FlxG.height - 18, 0, "v" + gameVersion, 12);
		versionText.scrollFactor.set();
		versionText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionText.updateHitbox();
		versionText.x = FlxG.width - 5 - versionText.width;
		add(versionText);

		var name:String = Lib.application.meta["name"];
		var nameText:FlxText = new FlxText(5, FlxG.height - 18, 0, name, 12);
		nameText.scrollFactor.set();
		nameText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(nameText);

		tipBackground = new FlxSprite();
		tipBackground.scrollFactor.set();
		tipBackground.alpha = 0.7;
		add(tipBackground);

		tipText = new FlxText(0, 0, 0,
			"Welcome to Friday Night Funkin' Izzy Engine! This is a complete rework of the game that changes a lot of stuff from the main game, but still retains the \"vibe\" of the original game. Please do support the original devs on their Patreon and Kickstarter page. Thank you!");
		tipText.scrollFactor.set();
		tipText.setFormat("VCR OSD Mono", 24, FlxColor.WHITE, LEFT);
		tipText.updateHitbox();
		add(tipText);

		tipBackground.makeGraphic(FlxG.width, Std.int((tipTextMargin * 2) + tipText.height), FlxColor.BLACK);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		FlxG.camera.follow(camFollow);

		if (FlxG.sound.music == null || !FlxG.sound.music.playing)
		{
			Conductor.bpm = 102;
			FlxG.sound.playMusic(AssetHelper.getAsset("freakyMenu.ogg", MUSIC));
		}

		changeOption(optionSelection);
		tipTextStartScrolling();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (tipTextScrolling)
		{
			tipText.x -= elapsed * 130;
			if (tipText.x < -tipText.width)
			{
				tipTextScrolling = false;
				tipTextStartScrolling();
			}
		}

		FlxG.camera.followLerp = elapsed * 6;

		if (!backed && !optionSelected)
		{
			if (FlxG.keys.justPressed.UP)
			{
				changeOption(optionSelection - 1);
				FlxG.sound.play(AssetHelper.getAsset("scrollMenu.ogg", SOUND));
			}
			if (FlxG.keys.justPressed.DOWN)
			{
				changeOption(optionSelection + 1);
				FlxG.sound.play(AssetHelper.getAsset("scrollMenu.ogg", SOUND));
			}
			if (FlxG.keys.justPressed.ENTER)
			{
				if (options[optionSelection] == "donate")
				{
					var url:String = "https://www.kickstarter.com/projects/funkin/friday-night-funkin-the-full-ass-game";
					Util.openUrl(url);
				}
				else
				{
					optionSelected = true;

					FlxG.sound.play(AssetHelper.getAsset("confirmMenu.ogg", SOUND));
					FlxFlicker.flicker(bgMagenta, 1.1, 0.15, false);

					optionItems.forEach(function(option:FlxSprite)
					{
						if (option.ID == optionSelection)
						{
							FlxFlicker.flicker(option, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								goToOption();
							});
						}
						else
						{
							FlxTween.tween(option, {alpha: 0}, 1.3, {ease: FlxEase.quadOut});
						}

						option.updateHitbox();
						option.screenCenter(X);
					});
				}
			}
			if (FlxG.keys.justPressed.ESCAPE)
			{
				backed = true;

				FlxG.sound.play(AssetHelper.getAsset("cancelMenu.ogg", SOUND));
				FlxG.switchState(new TitleState());
			}
		}
	}

	function tipTextStartScrolling()
	{
		tipText.x = tipTextMargin;
		tipText.y = -tipText.height;

		new FlxTimer().start(1.0, function(timer:FlxTimer)
		{
			FlxTween.tween(tipText, {y: tipTextMargin}, 0.3);
			new FlxTimer().start(2.25, function(timer:FlxTimer)
			{
				tipTextScrolling = true;
			});
		});
	}

	function changeOption(selection:Int = 0)
	{
		optionSelection = selection;

		if (optionSelection >= options.length) // Loop back to first option
			optionSelection = 0;
		if (optionSelection < 0) // Loop forward to last option
			optionSelection = options.length - 1;

		optionItems.forEach(function(option:FlxSprite)
		{
			if (option.ID == optionSelection)
			{
				option.animation.play("selected");
				camFollow.setPosition(option.getGraphicMidpoint().x, option.getGraphicMidpoint().y);
			}
			else
				option.animation.play("idle");

			option.updateHitbox();
			option.screenCenter(X);
		});
	}

	function goToOption()
	{
		switch (options[optionSelection])
		{
			case "story mode", "options":
				FlxG.switchState(new TitleState());
			case "freeplay":
				FlxG.switchState(new FreeplayState());
		}
	}
}
