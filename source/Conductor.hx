package;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.util.FlxTimer;

class Conductor extends FlxBasic
{
	// Music information
	public static var bpm:Int = 100;
	public static var bars:Int = 4;
	public static var ticksPerBeat:Int = 4;

	// Tracking variables
	public static var time:Float = 0;
	public static var interpTime:Float = 0;
	static var prevTime:Float = 0;
	public static var beat:Int = 0;
	static var prevBeat:Int = -1;
	public static var tickPos:Float = 0;

	// Offset settings
	public static var globalOffset:Float = 0;
	public static var songOffset:Float = 0;

	// Callback to call when a beat changes
	public var onBeat:() -> Void;

	// Timer to update interpTime
	var interpTimeUpdateTimer:FlxTimer;

	public function new()
	{
		super();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// Update time
		if (FlxG.sound.music != null && FlxG.sound.music.playing == true)
		{
			time = FlxG.sound.music.time / 1000;

			// Interpolated time used for smooth visuals (like note rendering)
			interpTime += elapsed;
			if (interpTimeUpdateTimer == null)
			{
				interpTime = time;
				// Update interpTime to match actual time every 500 ms
				interpTimeUpdateTimer = new FlxTimer().start(0.5, function(timer:FlxTimer)
				{
					interpTime = time;
					timer.reset(0.5);
				});

				// Also update interpTime when the frame delta is too high (below 10 FPS-ish)
				if (elapsed >= 0.1)
				{
					interpTime = time;
				}
			}
		}
		else
		{
			if (interpTimeUpdateTimer != null)
			{
				interpTimeUpdateTimer.cancel();
				interpTimeUpdateTimer = null;
			}

			// Always match with actual time when music stopped
			interpTime = time;
		}

		// Update beat
		var beatF:Float = time * bpm / 60.0;
		beat = Math.floor(beatF);

		if (prevBeat != beat)
		{
			if (onBeat != null)
				onBeat();

			prevBeat = beat;
		}
	}
}
