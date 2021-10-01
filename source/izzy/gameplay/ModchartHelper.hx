package izzy.gameplay;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;
import izzy.core.AssetHelper;
import izzy.scripting.ScriptHelper;
import izzy.state.PlayState;

@:access(izzy.state.PlayState)
class ModchartHelper extends FlxTypedGroup<FlxBasic>
{
	var scriptHelper:ScriptHelper;
	var playState:PlayState;

	public function new(path:String, state:PlayState)
	{
		super();
		
		this.playState = state;

		if (scriptHelper == null)
			scriptHelper = new ScriptHelper();
		
		if (!scriptHelper.expose.exists("stage"))
			scriptHelper.expose.set("stage", playState.stage);
		
		if (!scriptHelper.expose.exists("gf") && playState.stage.gf != null)
			scriptHelper.expose.set("gf", playState.stage.gf);
		if (!scriptHelper.expose.exists("enemy") && playState.stage.enemy != null)
			scriptHelper.expose.set("enemy", playState.stage.enemy);
		if (!scriptHelper.expose.exists("player") && playState.stage.player != null)
			scriptHelper.expose.set("player", playState.stage.player);

		scriptHelper.expose.set("stageCamera", playState.stageCamera);
		scriptHelper.expose.set("uiCamera", playState.uiCamera);
		scriptHelper.expose.set("enemyStrumLine", playState.enemyStrumLine);
		scriptHelper.expose.set("playerStrumLine", playState.playerStrumLine);

		scriptHelper.loadScript(path);

		if (scriptHelper.get("onCreate") != null)
			scriptHelper.get("onCreate")();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (scriptHelper.get("onUpdate") != null)
			scriptHelper.get("onUpdate")(elapsed);
	}

	public function onBeat(beat:Int)
	{
		if (scriptHelper.get("onBeat") != null)
			scriptHelper.get("onBeat")(beat);
	}

	public function onTick(tick:Int)
	{
		if (scriptHelper.get("onTick") != null)
			scriptHelper.get("onTick")(tick);
	}
}
