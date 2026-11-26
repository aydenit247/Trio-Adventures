# Usage: godot --headless --path godot --script res://tools/glb_decimate.gd -- in.glb out.glb [target_tris=40000]
# (Asar 11/25) Meshy's image-to-3D models come out at ~2M triangles. This loads the GLB, lets Godot's meshoptimizer
# (ImporterMesh.generate_lods) build simpler versions, keeps the one nearest target_tris, drops unused vertices
# and writes a new GLB with the same material. Shrink its textures afterwards with tools/glb_shrink_textures.py.
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var src: String = args[0]
	var dst: String = args[1]
	var target := int(args[2]) if args.size() > 2 else 40000
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(src, state) != OK:
		push_error("can't read " + src); quit(1); return
	var root := Node3D.new()
	root.name = "Root"
	for gm in state.meshes:
		var im: ImporterMesh = gm.mesh
		im.generate_lods(25.0, 60.0, [])
		var am := ArrayMesh.new()
		for s in im.get_surface_count():
			var arrays := im.get_surface_arrays(s)
			var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var best := idx
			for l in im.get_surface_lod_count(s):
				var li := im.get_surface_lod_indices(s, l)
				if absi(li.size() / 3 - target) < absi(best.size() / 3 - target):
					best = li
			print("surface ", s, ": ", idx.size() / 3, " tris -> ", best.size() / 3)
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _compact(arrays, best))
			am.surface_set_material(s, im.get_surface_material(s))
		var mi := MeshInstance3D.new()
		mi.name = "Mesh"
		mi.mesh = am
		root.add_child(mi)
		mi.owner = root
	var out_doc := GLTFDocument.new()
	var out_state := GLTFState.new()
	out_doc.append_from_scene(root, out_state)
	var err := out_doc.write_to_filesystem(out_state, dst)
	print("wrote ", dst, " err=", err)
	quit()

# Keep only the vertices the new index list uses (positions, normals, tangents, UVs, colours), renumbered.
func _compact(arrays: Array, idx: PackedInt32Array) -> Array:
	var remap := {}
	var order := PackedInt32Array()
	var new_idx := PackedInt32Array()
	new_idx.resize(idx.size())
	for i in idx.size():
		var o := idx[i]
		if not remap.has(o):
			remap[o] = order.size()
			order.append(o)
		new_idx[i] = remap[o]
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	for a in Mesh.ARRAY_MAX:
		var src = arrays[a]
		if src == null or a == Mesh.ARRAY_INDEX:
			continue
		var n: int = src.size()
		var verts: int = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var per := n / verts if verts > 0 else 1   # tangents are 4 floats per vertex
		var dst = src.duplicate()
		dst.resize(order.size() * per)
		for k in order.size():
			for c in per:
				dst[k * per + c] = src[order[k] * per + c]
		out[a] = dst
	out[Mesh.ARRAY_INDEX] = new_idx
	return out
