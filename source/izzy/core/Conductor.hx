package izzy.core;

import flixel.FlxBasic;
import flixel.FlxG;

typedef EventStruct<ET> = 
{
	var type:ET;
	var tick:Int;
}

enum TimeEvents
{
	BPMChange(bpm:Int);
	Stop(ticks:Int);
}

class Conductor extends FlxBasic
{
	public static final ticksPerBeat:Int = 48;
	
	// Music information
	public static var bpm:Int = 100;
	public static var bars:Int = 4;

	// Store timing and gameplay events separately
	public static var timeEvents:Array<EventStruct<TimeEvents>> = [];

	// Tracking variables
	public static var time:Float = 0;
	public static var interpTime:Float = 0;
	static var prevTime:Float = 0;

	public static var beat:Int = 0;
	static var prevBeat:Int = -1;

	public static var tick:Int = 0;
	static var prevTick:Int = 0;

	// Offset settings
	public static var globalOffset:Float = 0;
	public static var songOffset:Float = 0;

	// Settings
	public static var metronome:Bool = false;

	// Callback to call when a beat changes
	public var onBeat:Int -> Void;
	public var onTick:Int->Void;

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
			time = (FlxG.sound.music.time / 1000) + globalOffset;

			// Interpolated time used for smooth visuals (like note rendering)
			interpTime += elapsed;
			var delta:Float = interpTime - time;
			if (Math.abs(delta) >= 0.05)
			{
				interpTime = time;
			}
		}
		else
		{
			// Always match with actual time when music stopped
			interpTime = time;
		}

		// Update beat
		beat = Math.floor(getBeat(time));

		if (prevBeat != beat)
		{
			// Play a metronome sound when enabled
			if (metronome)
				FlxG.sound.play(AssetHelper.getAsset("metronome.ogg", SOUND));
			
			if (onBeat != null)
			{				
				// In case of beat skipping, execute callback more than once
				if (prevBeat < beat)
				{
					for (x in 0...(beat - prevBeat))
					{
						onBeat(beat);
					}
				}
				else
				{
					onBeat(beat);
				}
			}

			prevBeat = beat;
		}

		// Update tick
		tick = Math.floor(getTick(time));

		if (prevTick != tick)
		{
			if (onTick != null)
			{
				// In case of tick skipping, execute callback more than once
				if (prevTick < tick)
				{
					for (x in 0...(tick - prevTick))
					{
						onTick(tick);
					}
				}
				else
				{
					onTick(tick);
				}
			}

			prevTick = tick;
		}
	}

	public static function getBeat(time:Float):Float
	{
		return time * bpm / 60.0;
	}

	public static function getTick(time:Float):Float
	{
		return getBeat(time) * ticksPerBeat;
	}

	public static function beatToTime(beat:Float):Float
	{
		return (beat * 60) / bpm;
	}

	public static function tickToTime(tick:Float):Float
	{
		return beatToTime(tick / ticksPerBeat);
	}
}
