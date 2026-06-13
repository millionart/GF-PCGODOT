# Spatial Noise Registry

`Spatial Noise` uses `FlowSpatialNoiseRegistry` for its Mode list. Flow editor registers the UE PCG modes with short names:

- `Perlin2D`
- `Caustic2D`
- `Voronoi2D`
- `FractionalBrownian2D`
- `EdgeMask2D`

External plugins must register modes with a namespaced id:

```gdscript
var err := FlowSpatialNoiseRegistry.register_algorithm(
	"MapGen/CoastNoise",
	Callable(self, "_sample_coast_noise")
)
if err != "":
	push_error(err)
```

External ids without `/` are rejected, and external plugins cannot override built-in UE mode names. The graph stores the mode id string, not the dropdown index, so adding or reordering plugin algorithms does not change existing graphs. If a graph references a plugin algorithm that is no longer registered, `Spatial Noise` reports a missing algorithm error and does not fall back to another mode.

Sampler contract:

```gdscript
func _sample_coast_noise(context : Dictionary) -> Dictionary:
	var position : Vector3 = context.position
	var bounds : Dictionary = context.bounds
	var parameters : Dictionary = context.algorithm_parameters
	return { "ok": true, "value": 0.5 }
```

Context keys:

| Key | Value |
|---|---|
| `algorithm_id` | Registered mode id, such as `MapGen/CoastNoise`. |
| `settings` | The `NoiseNodeSettings` resource. |
| `position` | Current point `$Position`. |
| `random_offset` | Seeded random offset from the node settings. |
| `bounds` | Input `$Position` X/Z bounds used as Flow source bounds. |
| `iterations` | Clamped iteration count. |
| `brightness` | Node brightness setting. |
| `contrast` | Node contrast setting. |
| `algorithm_parameters` | Plugin-editable parameter dictionary. |

Return keys:

| Key | Required | Value |
|---|---|---|
| `ok` | Optional | `true` for success. If omitted, `value` implies success. |
| `value` | Yes | Raw noise value. Flow applies Brightness and Contrast unless `adjusted` is true. |
| `adjusted` | Optional | Set true if the sampler already applied Brightness/Contrast. |
| `error` | On failure | Message shown on the node. |

Built-in UE modes may also return internal keys such as `cell_id` and `rotation`; plugin samplers should not rely on those unless the plugin owns the corresponding output behavior.
