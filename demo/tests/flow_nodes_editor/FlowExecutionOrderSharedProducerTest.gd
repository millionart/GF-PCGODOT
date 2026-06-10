extends SceneTree

const FlowNodeBaseScript = preload("res://addons/flow_nodes_editor/node.gd")
const FlowNodeIO = preload("res://addons/flow_nodes_editor/flow_nodes_io.gd")
const NodeSettingsScript = preload("res://addons/flow_nodes_editor/node_settings.gd")


func _init() -> void:
	if not _run_test():
		push_error("FlowExecutionOrderSharedProducerTest failed.")
		quit(1)
		return
	quit(0)


func _run_test() -> bool:
	var shared_producer := _make_node("shared_producer", "source")
	var branch_b := _make_node("branch_b", "consumer")
	var branch_c := _make_node("branch_c", "consumer")
	var diamond_output := _make_node("diamond_output", "output")

	_connect(shared_producer, branch_b)
	_connect(shared_producer, branch_c)
	_connect(branch_b, diamond_output)
	_connect(branch_c, diamond_output)

	var nodes := [diamond_output, branch_c, branch_b, shared_producer]
	var order: Array = FlowNodeIO.build_execution_order(nodes, _instances_by_name(nodes))

	var passed := (
		_expect_once(order, "shared_producer")
		and _expect_before(order, "shared_producer", "branch_b")
		and _expect_before(order, "shared_producer", "branch_c")
		and _expect_before(order, "branch_b", "diamond_output")
		and _expect_before(order, "branch_c", "diamond_output")
	)
	_free_nodes(nodes)
	return passed


func _make_node(node_name: String, node_template: String) -> FlowNodeBase:
	var node: FlowNodeBase = FlowNodeBaseScript.new()
	node.name = node_name
	node.node_template = node_template
	node.settings = NodeSettingsScript.new()
	node.deps = []
	node.dependants = []
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
