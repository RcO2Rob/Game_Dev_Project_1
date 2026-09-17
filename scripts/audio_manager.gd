extends Node

const BACKGROUND_MUSIC := preload("res://assets/audio/underwater_ambient.wav")
const ENEMY_HIT_SOUND := preload("res://assets/audio/enemy_hit.wav")
const STOMP_SOUND := preload("res://assets/audio/enemy_stomp.wav")
const PLAYER_HURT_SOUND := preload("res://assets/audio/player_hurt.wav")
const COIN_PICKUP_SOUND := preload("res://assets/audio/coin_pickup.wav")
const DIAMOND_PICKUP_SOUND := preload("res://assets/audio/diamond_pickup.wav")
const WEAPON_PICKUP_SOUND := preload("res://assets/audio/weapon_pickup.wav")
const SWORD_SWING_SOUND := preload("res://assets/audio/sword_swing.wav")
const BARREL_BREAK_SOUND := preload("res://assets/audio/barrel_break.wav")

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player := 0


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "BackgroundMusic"
	_music_player.volume_db = -6.0
	add_child(_music_player)

	var music_stream := BACKGROUND_MUSIC.duplicate()
	if music_stream is AudioStreamWAV:
		music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_player.stream = music_stream

	for index in range(8):
		var player := AudioStreamPlayer.new()
		player.name = "SoundEffect%d" % (index + 1)
		player.volume_db = -5.0
		add_child(player)
		_sfx_players.append(player)

	_music_player.play()


func play_enemy_hit() -> void:
	_play_sound(ENEMY_HIT_SOUND, randf_range(0.94, 1.06))


func play_enemy_stomp() -> void:
	_play_sound(STOMP_SOUND, randf_range(0.96, 1.04))


func play_player_hurt() -> void:
	_play_sound(PLAYER_HURT_SOUND, randf_range(0.97, 1.03))


func play_coin_pickup() -> void:
	_play_sound(COIN_PICKUP_SOUND, randf_range(0.98, 1.05))


func play_diamond_pickup() -> void:
	_play_sound(DIAMOND_PICKUP_SOUND, randf_range(0.98, 1.02))


func play_weapon_pickup() -> void:
	_play_sound(WEAPON_PICKUP_SOUND, 1.0)


func play_sword_swing() -> void:
	_play_sound(SWORD_SWING_SOUND, randf_range(0.96, 1.04))


func play_barrel_break() -> void:
	_play_sound(BARREL_BREAK_SOUND, randf_range(0.94, 1.02))


func _play_sound(stream: AudioStream, pitch: float = 1.0) -> void:
	if _sfx_players.is_empty():
		return
	var player := _sfx_players[_next_sfx_player]
	_next_sfx_player = (_next_sfx_player + 1) % _sfx_players.size()
	player.stop()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()
