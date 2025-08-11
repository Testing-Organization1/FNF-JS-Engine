package;

import flixel.util.typeLimit.NextState;
import haxe.io.Path;

class LoadingState extends MusicBeatState {
	// TO DO: Make this easier

	public static function loadAndSwitchState(target:NextState, stopMusic = false) {
		FlxG.switchState(getNextState(target, stopMusic));
	}

	static function getNextState(target:NextState, stopMusic = false):NextState {
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);

		#if NO_PRELOAD_ALL
		var loaded:Bool = false;
		if (PlayState.SONG != null) {
			loaded = isSoundLoaded(Paths.inst(PlayState.SONG.song)) && (!PlayState.SONG.needsVoices || isSoundLoaded(Paths.voices(PlayState.SONG.song))) && isLibraryLoaded("shared") && isLibraryLoaded(directory);
		}

		if (!loaded)
			return new LoadingState(target, stopMusic, directory);
		#end
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		return target;
	}

	#if NO_PRELOAD_ALL
	static function isSoundLoaded(path:String):Bool {
		return Assets.cache.hasSound(path);
	}

	static function isLibraryLoaded(library:String):Bool {
		return Assets.getLibrary(library) != null;
	}
	#end
}
