@tool
extends "res://addons/flow_nodes_editor/nodes/size.gd"

func _init():
	meta_node = {
		"title" : "Get Element Count",
		"settings" : SizeNodeSettings,
		"ins" : [{ "label" : "In" }],
		"outs" : [{ "label" : "Count", "data_type" : FlowData.DataType.Int }],
		"aliases" : ["Get Points Count", "Points Count"],
		"category" : "Utility",
		"tooltip" : "Outputs the number of elements in the input data as a single integer stream.",
	}

func execute( ctx : FlowData.EvaluationContext ):
	if require_input(0, ctx, "Input 'In'") == null:
		return
	super.execute(ctx)
