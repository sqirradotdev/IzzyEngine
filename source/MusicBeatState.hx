package;

import flixel.FlxG;
import flixel.addons.ui.FlxUIState.FlxUIState;

class MusicBeatState extends FlxUIState
{
	var conductor:Conductor;

	public function new()
	{
		super();
	}

	override public function create()
	{
		super.create();

		conductor = new Conductor();
		conductor.onBeat = this.onBeat;
		add(conductor);

		FlxG.watch.add(Conductor, "time");
		FlxG.watch.add(Conductor, "interpTime");
		FlxG.watch.add(Conductor, "beat");
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public function onBeat():Void {}
}
