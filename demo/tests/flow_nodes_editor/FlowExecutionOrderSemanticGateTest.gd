extends SceneTree

const FlowNodeBaseScript = preload("res://addons/flow_nodes_editor/node.gd")
const FlowNodeIO = preload("res://addons/flow_nodes_editor/flow_nodes_io.gd")
const NodeSettingsScript = preload("res://addons/flow_nodes_editor/node_settings.gd")


func _init() -> void:
	if not _run_test():
		push_error("FlowExecutionOrderSemanticGateTest failed.")
		quit(1)
		return
	quit(0)


func _run_test() -> bool:
	var graph_bundle := _make_node("graph_bundle", "semantic_bundle")
	var csharp_bundle := _make_node("csharp_bundle", "semantic_bundle")
	var validate := _make_node("validate", "semantic_validate")
	var gate := _make_node("gate", "semantic_gate")
	var split := _make_node("split", "semantic_split")
	var output_1 := _make_node("output_1", "output_1")
	var parity_probe := _make_node("parity_probe", "semantic_probe", true)

	_connect(graph_bundle, validate)
	_connect(validate, gate)
	_connect(csharp_bundle, gate)
	_connect(gate, split)
	_connect(split, output_1)
	_connect(graph_bundle, parity_probe)
	_connect(csharp_bundle, parity_probe)

	var nodes := [
		output_1,
		parity_probe,
		split,
		gate,
		validate,
		csharp_bundle,
		graph_bundle,
	]
	var order: Array = FlowNodeIO.build_execution_order(nodes, _instances_by_name(nodes))

	var passed := (
		_expect_once(order, "graph_bundle")
		and _expect_once(order, "csharp_bundle")
		and _expect_before(order, "graph_bundle", "validate")
		and _expect_before(order, "validate", "gate")
		and _expect_before(order, "csharp_bundle", "gate")
		and _expect_before(order, "gate", "split")
		and _expect_before(order, "split", "output_1")
		and _expect_before(order, "graph_bundle", "parity_probe")
		and _expect_before(order, "csharp_bundle", "parity_probe")
	)
	_free_nodes(nodes)
	return passed


func _make_node(
	node_name: String,
	node_template: String,
	is_final := false
) -> FlowNodeBase:
	var node: FlowNodeBase = FlowNodeBaseScript.new()
	node.name = node_name
	node.node_template = node_template
	node.settings = NodeSettingsScript.new()
	node.deps = []
	node.dependants = []
	node.meta_node = {"is_final": is_final}
	return node


func _connect(src_node: FlowNodeBase, dst_node: FlowNodeBase) -> void:
	var conn := {
		"from_node": src_node.name,
		"from_port": 0,
		"to_node": dst_node.name,
		"to_port": 0,
	}
	src_node.dependants.append(conn)
	dst_node.deps.append(conn)


func _instances_by_name(nodes: Array) -> Dictionary:
	var instances := {}
	for node: FlowNodeBase in nodes:
		instances[node.name] = node
	return instances


func _free_nodes(nodes: Array) -> void:
	for node: FlowNodeBase in nodes:
		node.free()


func _expect_once(order: Array, node_name: String) -> bool:
	var count := 0
	for node: FlowNodeBase in order:
		if node.name == node_name:
			count += 1
	if count == 1:
		return true
	push_error("%s should appear once, found %d in %s." % [node_name, count, _names(order)])
	return false


func _expect_before(order: Array, producer_name: String, consumer_name: String) -> bool:
	var producer_index := _index_of(order, producer_name)
	var consumer_index := _index_of(order, consumer_name)
	if producer_index >= 0 and producer_index < consumer_index:
		return true
	push_error("%s should execute before %s in %s." % [producer_name, consumer_name, _names(order)])
	return false


func _index_of(order: Array, node_name: String) -> int:
	for index in range(order.size()):
		if order[index].name == node_name:
			return index
	return -1


func _names(order: Array) -> Array[String]:
	var names: Array[String] = []
	for node: FlowNodeBase in order:
		names.append(String(node.name))
	return names
