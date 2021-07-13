package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.tweens.FlxTween;
import lime.app.Application;
import openfl.Lib;
import openfl.display.Sprite;
import sys.FileSystem;

class Main extends Sprite
{
	// FPS settings
	final normalFps:Int = 120;
	final lowFps:Int = 20;

	public static var overlay:Overlay;

	var focusMusicTween:FlxTween;

	public function new()
	{
		super();

		// Print game name and information to system console
		Sys.println(Lib.application.meta["name"] + " v" + Lib.application.meta["version"]);

		RichPresence.startRichPresence();

		addChild(new FlxGame(1280, 720, InitState, 1, normalFps, normalFps, true));

		overlay = new Overlay(0, 0);
		addChild(overlay);

		// Changes to HaxeFlixel default settings
		FlxG.sound.muteKeys = null;
		FlxG.sound.volumeUpKeys = null;
		FlxG.sound.volumeDownKeys = null;
		FlxG.autoPause = false;
		FlxG.fixedTimestep = false;
		FlxG.mouse.useSystemCursor = true;
		FlxG.mouse.visible = false;
		FlxG.console.autoPause = false;

		#if debug
		// For debugging purposes
		FlxG.console.registerObject("Conductor", Conductor);
		#end

		// Add event listeners for window focus
		Application.current.window.onFocusOut.add(onWindowFocusOut);
		Application.current.window.onFocusIn.add(onWindowFocusIn);
	}

	function onWindowFocusOut()
	{
		trace("Game unfocused");

		// Lower global volume when unfocused
		if (focusMusicTween != null)
			focusMusicTween.cancel();
		focusMusicTween = FlxTween.tween(FlxG.sound, {volume: 0.3}, 0.5);

		// Conserve power by lowering draw framerate when unfocuced
		FlxG.drawFramerate = lowFps;
	}

	function onWindowFocusIn()
	{
		trace("Game focused");

		// Normal global volume when focused
		if (focusMusicTween != null)
			focusMusicTween.cancel();
		focusMusicTween = FlxTween.tween(FlxG.sound, {volume: 1.0}, 0.5);

		// Bring framerate back when focused
		FlxG.drawFramerate = normalFps;
	}
}
