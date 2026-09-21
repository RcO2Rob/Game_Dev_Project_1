extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var audio_manager := root.get_node("AudioManager")
	var music_player: AudioStreamPlayer = audio_manager._music_player
	assert(music_player.stream != null)
	assert(music_player.playing)
	assert(music_player.process_mode == Node.PROCESS_MODE_ALWAYS)
	assert(music_player.volume_db == audio_manager.MUSIC_VOLUME_DB)
	assert(music_player.finished.is_connected(audio_manager._on_music_finished))

	paused = true
	await process_frame
	assert(music_player.playing, "Background music must continue while the tutorial panel pauses gameplay")
	paused = false
	print("Audio manager test passed")
	quit()
