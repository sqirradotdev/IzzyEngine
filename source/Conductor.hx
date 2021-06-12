package;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.system.FlxSound;

class Conductor extends FlxBasic
{
	// Song information
	public static var bpm:Int = 100;
	public static var bars:Int = 4;
	public static var ticksPerBeat:Int = 4;

	// Tracking variables
	public static var time:Float = 0;
	static var prevTime:Float = 0;
	public static var beat:Int = 0;
	static var prevBeat:Int = -1;
	public static var tickPos:Float = 0;

	// Offset settings
	public static var globalOffset:Float = 0;
	public static var songOffset:Float = 0;

	public var onBeat:() -> Void;

	public function new()
	{
		super();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// Update time
		if (FlxG.sound.music != null && FlxG.sound.music.playing == true)
			time = FlxG.sound.music.time / 1000;

		// Update beat
		var beatF:Float = time * bpm / 60.0;
		beat = Std.int(beatF);

		if (prevBeat != beat)
		{
			if (onBeat != null)
				onBeat();

			prevBeat = beat;
		}
	}
}
