package funkin.video;

// sigh rework coming again soon
#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
import flixel.FlxG;
import flixel.util.FlxTimer;

// with hxvlcs improvements this is less needed but still has its values

/**
 * Handles video playback as a `FlxSprite`. Has additional features for ease
 * * If used in `PlayState`, will autopause when the game is paused too
 * * General Usage:
 * ```haxe
 * var video = new FunkinVideoSprite(x,y);
 * add(video);
 * video.onFormat(()->{
 * video.fitToScreen();
 * * });
 * if (video.load(Paths.video('pathToVideo')))
 * {
 *		video.delayAndStart();
 * }
 * ```
 */
class FunkinVideoSprite extends FlxVideoSprite
{
	/**
	 * Video loading argument to make the video loop
	 * * Usage:
	 * ```haxe
	 * video.load(Paths.video(''),[FunkinVideoSprite.looping]);
	 * ```
	 */
	public static final looping:String = ':input-repeat=65535';
	
	/**
	 * Video loading argument to make the video muted
	 * Use if your video doesnt require audio
	 * * Usage:
	 * ```haxe
	 * video.load(Paths.video(''),[FunkinVideoSprite.muted]);
	 * ```
	 */
	public static final muted:String = ':no-audio';

	/**
	 * Manually initiates the Libvlc instance
	 */
	public static function init()
	{
		hxvlc.util.Handle.init();
	}
	
	/**
	 * Bool that decides if `this` should be affected by states
	 * * Disable this if you dont want your video to pause when paused in `PlayState`
	 */
	public var isStateAffected:Bool = true;

	/**
	 * The playback speed of the video. 1.0 is normal speed.
	 */
	public var playbackRate(default, set):Float = 1.0;

	function set_playbackRate(value:Float):Float
	{
		if (bitmap != null)
			bitmap.rate = value;
		
		return playbackRate = value;
	}

	/** Returns whether the video is currently playing. */
	public var isPlaying(get, never):Bool;
	inline function get_isPlaying():Bool return bitmap != null && bitmap.isPlaying;
	
	/**
	 * Creates a new FunkinVideoSprite
	 * @param x `x` position
	 * @param y `y` position
	 * @param oneTimeUse if `true` on video complete, the video will self destroy
	 */
	public function new(x:Float = 0, y:Float = 0, oneTimeUse:Bool = true)
	{
		super(x, y);
		
		if (oneTimeUse) bitmap.onEndReached.add(this.destroy, true, -10);
	}
	
	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (bitmap != null && bitmap.isPlaying)
		{
			// hxvlc volume is an Int from 0 to 100. FlxG.sound.volume is a Float from 0.0 to 1.0
			bitmap.volume = FlxG.sound.muted ? 0 : Std.int(FlxG.sound.volume * 100);
		}

		// If a substate (like a pause menu) opens, and we are state affected, pause the video.
		if (isStateAffected && bitmap != null)
		{
			if (FlxG.state.subState != null && bitmap.isPlaying)
				bitmap.pause();
			else if (FlxG.state.subState == null && !bitmap.isPlaying)
				bitmap.resume();
		}
	}

	/**
	 * Starts the video but sets a delay before starting
	 * * Recommended over `this.play`
	 * @param delay The delay before the video starts. default is next update call
	 */
	public function delayAndStart(delay:Float = 0)
	{
		FlxTimer.wait(delay, () -> {
			if (bitmap != null)
				play();
		});
	}

	/** Pauses the video. */
	public function pause()
	{
		if (bitmap != null) bitmap.pause();
	}

	/** Resumes the video. */
	public function resume()
	{
		if (bitmap != null) bitmap.resume();
	}

	/**
	 * Stops the video immediately and triggers the onEndReached event.
	 * Useful for skipping cutscenes.
	 */
	public function skip()
	{
		if (bitmap != null && bitmap.isPlaying)
		{
			bitmap.stop();
			bitmap.onEndReached.add(bitmap.destroy); 
		}
	}

	/**
	 * Quickly scales and centers the video to fit the entire screen.
	 * Best used inside the `onFormat` callback!
	 */
	public function fitToScreen()
	{
		setGraphicSize(FlxG.width, FlxG.height);
		updateHitbox();
		screenCenter();
	}
	
	/**
	 * Adds a event to be dispatched when the video reaches its end
	 * @param func the event to be called
	 * @param once if this event should be dispatched once, or every time the video ends.
	 */
	public function onEnd(func:Void->Void, once:Bool = false, priority:Int = 0)
	{
		bitmap.onEndReached.add(func, once, priority);
	}
	
	/**
	 * Adds a event to be dispatched when the video starts
	 * @param func the event to be called
	 * @param once if this event should be dispatched once, or every time the video ends.
	 */
	public function onStart(func:Void->Void, once:Bool = false, priority:Int = 0)
	{
		bitmap.onOpening.add(func, once, priority);
	}
	
	/**
	 * Adds a event to be dispatched when the video has formatted itself 
	 * * Recommended to setup ur video during this event
	 * example: 
	 * ```haxe
	 * video.onFormat(()->{
	 * video.fitToScreen();
	 * video.camera = camera;
	 * });
	 * ```
	 * @param func the event to be called
	 * @param once if this event should be dispatched once, or every time the video ends.
	 */
	public function onFormat(func:Void->Void, once:Bool = false, priority:Int = 0)
	{
		bitmap.onFormatSetup.add(func, once, priority);
	}
	
	override function destroy()
	{
		if (bitmap != null)
		{
			bitmap.stop();
			bitmap.onEndReached.removeAll(); 			
			bitmap.onFormatSetup.removeAll();			
			bitmap.onOpening.removeAll();
			
			if (FlxG.signals.focusGained.has(bitmap.resume)) FlxG.signals.focusGained.remove(bitmap.resume);
			if (FlxG.signals.focusLost.has(bitmap.pause)) FlxG.signals.focusLost.remove(bitmap.pause);
		}
		
		super.destroy();
	}
}
#end
