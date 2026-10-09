## MemoryGenesis.gd — Autonomous memory geometry engine
##
## Every TICK_S seconds queries your LanceDB for the next rotating thought.
## The result manifests as a "thought burst" — BURST_COUNT glowing particles
## erupting from the corresponding domain cluster, expanding and fading over BURST_TTL.
##
## Your knowledge landscape becomes visible as a living, self-driven field.
## Your memories ARE the geometry.
##
## Setup:
##   1. Add as child Node3D in your scene
##   2. Set LEAN_URL to your lean_api address
##   3. Edit DOMAINS to match your corpus structure
##   4. Edit THOUGHT_SEQUENCE to reflect your knowledge domains
##   5. Set enabled = true to activate
##
## Shader: requires res://shaders/star_point.gdshader (or substitute your own billboard shader)

extends Node3D

const LEAN_URL    := "http://127.0.0.1:8018"  # your lean_api
const TICK_S      := 8.0      # seconds between thoughts
const BURST_COUNT := 80       # particles per thought burst
const BURST_TTL   := 5.0      # seconds before burst fully dissolves

var enabled : bool = false    # set true to enable autonomous memory bursts

# ── Domain positions + colours ─────────────────────────────────────────────────
# Edit these to match your corpus domains.
# pos: 3D world position of the cluster centre
# col: glow colour for this domain
#
# Tip: spread domains across the space — roughly 10–15 units apart —
# so each cluster is visually distinct when you navigate.
const DOMAINS := {
	# ── Example domains — replace with your own ──────────────────────────────
	"domain_a":  {"pos": Vector3(-8,  2, -5),  "col": Color(0.4, 0.7, 1.0)},
	"domain_b":  {"pos": Vector3( 6,  3, -7),  "col": Color(0.9, 0.9, 1.0)},
	"domain_c":  {"pos": Vector3( 0,  8,  2),  "col": Color(1.0, 0.85, 0.2)},
	"domain_d":  {"pos": Vector3(-5, -3,  8),  "col": Color(0.3, 0.9, 0.4)},
	"domain_e":  {"pos": Vector3( 9, -2,  4),  "col": Color(0.5, 0.3, 1.0)},
	"domain_f":  {"pos": Vector3(-7,  5,  3),  "col": Color(0.9, 0.4, 0.8)},
	"domain_g":  {"pos": Vector3( 4, -6, -6),  "col": Color(1.0, 0.6, 0.2)},
	"domain_h":  {"pos": Vector3(-3, -7, -4),  "col": Color(0.2, 0.8, 1.0)},
}

# ── Thought sequence ───────────────────────────────────────────────────────────
# Each entry is one autonomous "thought" — a query fired against your LanceDB.
# domain: must match a key in DOMAINS above
# query:  the semantic search query for this thought
#
# Replace these with queries that reflect your actual corpus.
# The system picks randomly from this list each tick.
const THOUGHT_SEQUENCE := [
	# ── Replace with queries drawn from your corpus ───────────────────────────
	{"domain": "domain_a", "query": "replace with a query relevant to domain_a"},
	{"domain": "domain_b", "query": "replace with a query relevant to domain_b"},
	{"domain": "domain_c", "query": "replace with a query relevant to domain_c"},
	{"domain": "domain_d", "query": "replace with a query relevant to domain_d"},
	{"domain": "domain_e", "query": "replace with a query relevant to domain_e"},
	{"domain": "domain_f", "query": "replace with a query relevant to domain_f"},
	{"domain": "domain_g", "query": "replace with a query relevant to domain_g"},
	{"domain": "domain_h", "query": "replace with a query relevant to domain_h"},
	# Add more thoughts — the more you have, the richer the autonomous display
]

var _tick_acc      : float  = TICK_S    # fire immediately on first frame
var _current_domain: String = ""
var _http          : HTTPRequest = null
var _bursts        : Array  = []        # [{mmi:MultiMeshInstance3D, elapsed:float}]
var _shader        : Shader = null
var _rng           := RandomNumberGenerator.new()


func _ready() -> void:
	name = "MemoryGenesis"
	_rng.randomize()
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_result)
	_shader = load("res://shaders/star_point.gdshader")
	if _shader == null:
		# star_point.gdshader not found — bursts will still render using a standard
		# unshaded material. Less glow but visually functional.
		push_warning("[MemoryGenesis] star_point.gdshader not found — using fallback material")
	print("[MemoryGenesis] online — %d thoughts  %.0fs interval  %dpx burst  TTL %.0fs  shader=%s" % [
		THOUGHT_SEQUENCE.size(), TICK_S, BURST_COUNT, BURST_TTL,
		"custom" if _shader else "fallback"])


func _process(delta: float) -> void:
	# ── Thought tick ───────────────────────────────────────────────────────────
	if enabled:
		_tick_acc += delta
		if _tick_acc >= TICK_S:
			_tick_acc = 0.0
			_fire_thought()

	# ── Age, expand, and fade active bursts ────────────────────────────────────
	for i in range(_bursts.size() - 1, -1, -1):
		var b : Dictionary = _bursts[i]
		b.elapsed += delta
		var t : float = clampf(b.elapsed / BURST_TTL, 0.0, 1.0)

		if t >= 1.0:
			if is_instance_valid(b.mmi):
				b.mmi.queue_free()
			_bursts.remove_at(i)
			continue

		if not is_instance_valid(b.mmi):
			_bursts.remove_at(i)
			continue

		var expansion : float = 1.0 + t * 2.5          # 1× → 3.5×
		var alpha     : float = pow(1.0 - t, 1.5)       # 1 → 0 with slight hold

		b.mmi.scale = Vector3(expansion, expansion, expansion)
		_set_burst_alpha(b.mmi.multimesh, alpha)


func _fire_thought() -> void:
	var status := _http.get_http_client_status()
	if status != HTTPClient.STATUS_DISCONNECTED and \
	   status != HTTPClient.STATUS_CONNECTION_ERROR:
		return

	var idx     : int    = _rng.randi_range(0, THOUGHT_SEQUENCE.size() - 1)
	var thought : Dictionary = THOUGHT_SEQUENCE[idx]
	_current_domain = thought.domain

	var body := JSON.stringify({"query": thought.query, "k": 20})
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := _http.request(LEAN_URL + "/search", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("[MemoryGenesis] HTTP request failed: %d" % err)


func _on_result(result: int, code: int, _headers: PackedStringArray,
		body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return

	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null or not json is Dictionary:
		return

	var results : Array = json.get("results", [])
	var snippet : String = ""
	if results.size() > 0:
		var pick : int = _rng.randi_range(0, min(results.size() - 1, 14))
		snippet = str(results[pick].get("content", "")).left(80)

	if not DOMAINS.has(_current_domain):
		return

	var d : Dictionary = DOMAINS[_current_domain]
	_spawn_burst(d.pos, d.col, _current_domain, snippet)


func _spawn_burst(centre: Vector3, col: Color, domain: String, snippet: String) -> void:
	var mm := MultiMesh.new()
	mm.use_colors       = true
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count   = BURST_COUNT

	var rng := RandomNumberGenerator.new()
	var buf := PackedFloat32Array()
	buf.resize(BURST_COUNT * 16)
	buf.fill(0.0)

	for i in BURST_COUNT:
		var theta : float = rng.randf() * TAU
		var phi   : float = rng.randf() * PI
		var r     : float = absf(rng.randfn(0.0, 0.6))
		var lx    : float = r * sin(phi) * cos(theta)
		var ly    : float = r * sin(phi) * sin(theta)
		var lz    : float = r * cos(phi)
		var sz    : float = 0.8 + rng.randf() * 1.8

		var b : int = i * 16
		buf[b + 0]  = sz;  buf[b + 5]  = sz;  buf[b + 10] = sz
		buf[b + 3]  = lx;  buf[b + 7]  = ly;  buf[b + 11] = lz
		buf[b + 12] = col.r;  buf[b + 13] = col.g
		buf[b + 14] = col.b;  buf[b + 15] = 1.0

	mm.buffer = buf

	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	if _shader:
		var mat := ShaderMaterial.new()
		mat.shader = _shader
		mat.set_shader_parameter("base_pixels", 7.0)
		quad.material = mat
	else:
		# Fallback: standard unshaded material — bursts visible but no glow effect
		var mat := StandardMaterial3D.new()
		mat.shading_mode     = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode   = BaseMaterial3D.BILLBOARD_ENABLED
		mat.vertex_color_use_as_albedo = true
		mat.transparency     = BaseMaterial3D.TRANSPARENCY_ALPHA
		quad.material = mat
	mm.mesh = quad

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh   = mm
	mmi.position    = centre
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	add_child(mmi)

	_bursts.append({"mmi": mmi, "elapsed": 0.0})

	print("[MemoryGenesis] THOUGHT [%s] → '%s…' @%.0f,%.0f,%.0f" % [
		domain, snippet, centre.x, centre.y, centre.z])


func _set_burst_alpha(mm: MultiMesh, alpha: float) -> void:
	var buf := mm.buffer
	if buf.is_empty():
		return
	var n : int = buf.size() / 16
	for i in n:
		buf[i * 16 + 15] = alpha
	mm.buffer = buf
