package;

import discord_rpc.DiscordRpc;
import lime.app.Application;

@:enum abstract IdleType(String) to String
{
	var TITLE = "Title Screen";
	var MAIN_MENU = "Main Menu";
	var STORY_MENU = "Story Menu";
	var FREEPLAY_MENU = "Freeplay Menu";
	var OPTIONS_MENU = "Options Menu";
}

class RichPresence
{
	public static function startRichPresence()
	{
		trace("Starting Rich Presence...");
		DiscordRpc.start({
			clientID: "856390600818163753",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});

		Application.current.window.onClose.add(shutdownRichPresence);
	}

	static function onReady()
	{
		trace("Rich Presence is ready!");
	}

	static function onError(_code:Int, _message:String)
	{
		trace("Oops! Error code " + _code + " : " + _message);
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		trace("Aw snap! Disconnected code " + _code + " : " + _message);
	}

	public static function setIdling(type:IdleType)
	{
		DiscordRpc.presence({
			details: type,
			state: "Idling",
		});
	}

	public static function shutdownRichPresence()
	{
		trace("Shutting down Rich Presence...");
		DiscordRpc.shutdown();
	}
}
