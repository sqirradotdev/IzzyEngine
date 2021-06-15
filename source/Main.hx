package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.tweens.FlxTween;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.utils.Assets;
import sys.FileSystem;

class Main extends Sprite
{
	public static var overlay:Overlay;

	var splash:Bitmap;
	var focusMusicTween:FlxTween;

	var splashShown:Bool = false;

	public function new()
	{
		super();

		// Print game information
		Sys.println(Lib.application.meta["name"] + " v" + Lib.application.meta["version"]);

		// Totally normal code
		if (!FileSystem.exists("./assets/do_not_delete.png"))
		{
			trace("Problem?");
			Application.current.window.alert("It says do not delete, can't you read?");
			Sys.exit(0);
		}

		// Add splash screen to OpenFL stage
		splash = new Bitmap(Assets.getBitmapData("assets/default/images/splash.png"));
		addChild(splash);
		splash.x = (stage.stageWidth - splash.width) / 2;
		splash.y = (stage.stageHeight - splash.height) / 2;

		splash.addEventListener(Event.ENTER_FRAME, onSplashEnterFrame);
	}

	function onSplashEnterFrame(_)
	{
		// Shows the splash screen one frame, then load the actual game
		if (!splashShown)
			splashShown = true;
		else
		{
			startGame();
			splash.removeEventListener(Event.ENTER_FRAME, onSplashEnterFrame);
		}
	}

	function startGame()
	{
		var targetState:Class<FlxState>;
		if (SongDatabase.updateWeekList())
			targetState = TitleState;
		// targetState = TestState;
		else
			targetState = MissingWeekState;

		addChild(new FlxGame(1280, 720, targetState, 1, 120, 120, true));
		removeChild(splash);

		// FPS and Memory overlay
		overlay = new Overlay(10, 7);
		addChild(overlay);

		// Some changes to default settings
		FlxG.sound.muteKeys = FlxG.sound.volumeUpKeys = FlxG.sound.volumeDownKeys = null;
		FlxG.autoPause = false;
		FlxG.fixedTimestep = false; // Needed for consistent lerp speed
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;
		FlxG.console.autoPause = false;

		#if debug
		// For debugging purposes
		FlxG.console.registerObject("Conductor", Conductor);
		#end

		// Add event listeners for lowering global volume when unfocused
		Application.current.window.onFocusOut.add(onWindowFocusOut);
		Application.current.window.onFocusIn.add(onWindowFocusIn);
	}

	function onWindowFocusOut()
	{
		trace("Game unfocused");

		if (focusMusicTween != null)
			focusMusicTween.cancel();

		focusMusicTween = FlxTween.tween(FlxG.sound, {volume: 0.3}, 0.5);
	}

	function onWindowFocusIn()
	{
		trace("Game focused");

		if (focusMusicTween != null)
			focusMusicTween.cancel();

		focusMusicTween = FlxTween.tween(FlxG.sound, {volume: 1.0}, 0.5);
	}
}
