extends Node
## Procedural cyberpunk SFX + looping street-synth BGM.

const SFX_VOICES := 4

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_i: int = 0
var _bgm: AudioStreamPlayer
var _kick: float = 0.0


func _ready() -> void:
	_ensure_buses()
	for i in SFX_VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_pool.append(p)

	_bgm = AudioStreamPlayer.new()
	_bgm.bus = "Music"
	add_child(_bgm)

	GameEvents.piece_locked.connect(_on_locked)
	GameEvents.lines_cleared.connect(_on_cleared)
	GameEvents.hard_dropped.connect(_on_hard_drop)
	GameEvents.level_up.connect(_on_level_up)
	GameEvents.game_over.connect(_on_game_over)
	GameEvents.game_won.connect(_on_game_won)
	GameEvents.game_timed_out.connect(_on_game_timed_out)
	GameEvents.piece_held.connect(func(_id): _beep(520.0, 0.045, 0.16, 0.35))
	GameEvents.game_started.connect(_on_game_started)

	_start_bgm()


func _process(delta: float) -> void:
	if _kick > 0.0:
		_kick = maxf(0.0, _kick - delta * 1.55)
	_bgm.volume_db = linear_to_db(clampf(SettingsService.music_volume * 0.52, 0.0001, 1.0))


func get_post_kick() -> float:
	return _kick


func play_move() -> void:
	_beep(240.0, 0.028, 0.09, 0.55)


func play_rotate() -> void:
	_beep(360.0, 0.038, 0.11, 0.4)
	_beep(540.0, 0.022, 0.06, 0.2)


func _on_game_started() -> void:
	if not _bgm.playing:
		_start_bgm()


func _on_locked(_id: int, _cells: Array) -> void:
	_beep(130.0, 0.07, 0.2, 0.7)


func _on_hard_drop(_distance: int) -> void:
	_beep(85.0, 0.09, 0.24, 0.85)
	_beep(180.0, 0.04, 0.1, 0.5)


func _on_cleared(_rows: Array, count: int) -> void:
	if count >= 4:
		_kick = 1.0
		_beep(110.0, 0.16, 0.28, 0.9)
		_beep(440.0, 0.12, 0.22, 0.25)
		_beep(880.0, 0.2, 0.32, 0.15)
		_beep(1320.0, 0.1, 0.14, 0.35)
	elif count >= 2:
		_kick = 0.45
		_beep(400.0 + count * 70.0, 0.11, 0.26, 0.3)
		_beep(200.0, 0.08, 0.14, 0.55)
	else:
		_beep(480.0, 0.09, 0.22, 0.35)


func _on_level_up(_level: int) -> void:
	_kick = maxf(_kick, 0.35)
	_beep(660.0, 0.1, 0.22, 0.2)
	_beep(990.0, 0.14, 0.28, 0.15)


func _on_game_over(_score: int) -> void:
	_beep(98.0, 0.28, 0.35, 0.8)
	_beep(73.0, 0.4, 0.3, 0.9)


func _on_game_won(_score: int, _elapsed: float) -> void:
	_kick = 1.0
	_beep(440.0, 0.12, 0.22, 0.35)
	_beep(660.0, 0.14, 0.26, 0.25)
	_beep(990.0, 0.22, 0.32, 0.18)


func _on_game_timed_out(_score: int, _elapsed: float) -> void:
	# Closing the signal window — rising alarm then hard cut.
	_kick = 0.85
	_beep(220.0, 0.08, 0.18, 0.55)
	_beep(330.0, 0.1, 0.22, 0.4)
	_beep(495.0, 0.14, 0.28, 0.3)
	_beep(740.0, 0.2, 0.2, 0.55)


func celebrate_street_record() -> void:
	# Cyan transmission ping for a new Street Log PB.
	_kick = 1.0
	_beep(660.0, 0.1, 0.2, 0.25)
	_beep(990.0, 0.16, 0.28, 0.18)
	_beep(1320.0, 0.12, 0.18, 0.3)


func _ensure_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx2 := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx2, "SFX")
		AudioServer.set_bus_send(idx2, "Master")


func _start_bgm() -> void:
	var stream := _build_cyber_loop()
	_bgm.stream = stream
	_bgm.volume_db = linear_to_db(clampf(SettingsService.music_volume * 0.52, 0.0001, 1.0))
	_bgm.play()


func _build_cyber_loop() -> AudioStreamWAV:
	## 16-beat street synth @ 96 BPM — bass, kick, hats, arp, lead.
	var sample_rate := 22050
	var bpm := 96.0
	var beats := 16.0
	var duration := (60.0 / bpm) * beats
	var n := int(sample_rate * duration)
	var data := PackedFloat32Array()
	data.resize(n)

	# Am – F – C – G feel in minor street neon (Hz roots per beat)
	var roots := [
		55.0, 55.0, 55.0, 55.0,
		58.27, 58.27, 58.27, 58.27,
		65.41, 65.41, 65.41, 65.41,
		49.0, 49.0, 73.42, 49.0,
	]
	var arp := [0, 3, 7, 10, 12, 10, 7, 3]
	# Lead motif (semitone offsets from root), 8th notes over the loop
	var lead := [0, -1, 0, 3, 7, 3, 5, 7, 10, 7, 5, 3, 0, 3, -2, 0]

	for i in n:
		var t := float(i) / sample_rate
		var beat_f: float = t * (bpm / 60.0)
		var beat_i: int = int(beat_f) % roots.size()
		var beat_pos: float = beat_f - floor(beat_f)
		var root: float = float(roots[beat_i])

		# Punchy kick
		var kick_env := exp(-beat_pos * 18.0)
		var kick_hz := 95.0 * exp(-beat_pos * 12.0) + 40.0
		var kick := sin(TAU * kick_hz * t) * kick_env * 0.38
		if int(beat_i) % 2 == 1:
			kick *= 0.55

		# Closed hat on 8ths
		var hat_pos := fmod(beat_f * 2.0, 1.0)
		var hat_n := _hash01(i * 3 + 17)
		var hat := (hat_n * 2.0 - 1.0) * exp(-hat_pos * 28.0) * 0.07
		if int(beat_f * 2.0) % 2 == 0:
			hat *= 0.55

		# Sub + square-ish bass
		var bass_env := 0.75 + 0.25 * (1.0 - beat_pos)
		var bass := sin(TAU * root * t) * 0.26
		bass += sin(TAU * root * 0.5 * t) * 0.14
		var sq := 1.0 if fmod(root * 2.0 * t, 1.0) < 0.5 else -1.0
		bass += sq * 0.05 * bass_env
		bass *= bass_env

		# Soft pad
		var pad := sin(TAU * root * 1.5 * t) * 0.055
		pad += sin(TAU * root * 2.0 * t + 0.35) * 0.035
		pad += sin(TAU * root * 3.0 * t + 1.1) * 0.02

		# Arp blips
		var step := int(beat_f * 4.0) % arp.size()
		var arp_hz := root * pow(2.0, float(arp[step]) / 12.0) * 2.0
		var arp_env := exp(-fmod(beat_f * 4.0, 1.0) * 7.0)
		var arpeggio := sin(TAU * arp_hz * t) * 0.085 * arp_env
		arpeggio += sin(TAU * arp_hz * 2.0 * t) * 0.025 * arp_env

		# Lead (every other 8th for space)
		var lead_i := int(beat_f * 2.0) % lead.size()
		var lead_hz := root * pow(2.0, float(lead[lead_i]) / 12.0) * 4.0
		var lead_pos := fmod(beat_f * 2.0, 1.0)
		var lead_env := exp(-lead_pos * 5.5) * (0.55 if lead_i % 2 == 0 else 0.28)
		var melody := sin(TAU * lead_hz * t) * 0.07 * lead_env
		melody += sin(TAU * lead_hz * 1.5 * t) * 0.025 * lead_env

		# Sidechain duck under kick
		var duck := 1.0 - exp(-beat_pos * 10.0) * 0.42

		# Deterministic hiss so the loop seams cleanly
		var noise := (_hash01(i) * 2.0 - 1.0) * 0.012

		var sample := (kick + hat + (bass + pad + arpeggio + melody) * duck + noise)
		sample = tanh(sample * 1.35)
		data[i] = sample

	var stream := AudioStreamWAV.new()
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n

	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var s := int(clampf(data[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, s)
	stream.data = bytes
	return stream


func _hash01(i: int) -> float:
	var n := sin(float(i) * 12.9898) * 43758.5453
	return n - floor(n)


func _beep(freq: float, duration: float, volume: float, noise_mix: float = 0.25) -> void:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedFloat32Array()
	data.resize(sample_count)
	var vol := volume * SettingsService.sfx_volume
	for i in sample_count:
		var t := float(i) / sample_rate
		var env := exp(-float(i) / sample_count * 3.2) * (1.0 - float(i) / sample_count * 0.35)
		var click := exp(-t * 80.0) * 0.35
		var wave := sin(TAU * freq * t)
		wave += 0.35 * sin(TAU * freq * 2.0 * t)
		wave += 0.12 * sin(TAU * freq * 3.0 * t)
		# Soft square edge for cyber bite
		wave += 0.18 * (1.0 if fmod(freq * t, 1.0) < 0.5 else -1.0)
		var nse := (_hash01(i + int(freq)) * 2.0 - 1.0) * noise_mix * exp(-t * 40.0)
		data[i] = (wave * (0.85 + click) + nse) * env * vol

	var stream := AudioStreamWAV.new()
	stream.mix_rate = sample_rate
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false

	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var s := int(clampf(data[i], -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, s)
	stream.data = bytes

	var player := _sfx_pool[_sfx_i]
	_sfx_i = (_sfx_i + 1) % _sfx_pool.size()
	player.stream = stream
	player.play()
