@tool
extends FlowNodeBase

func _init():
	meta_node = {
		"title" : "Select",
		"settings" : SelectNodeSettings,
		"aliases" : ["Select"],
		"category" : "ControlFlow",
		"ins" : [{ "label": "Input A" }, { "label": "Input B" }],
		"outs" : [{ "label" : "Out" }],
		"tooltip" : "Control flow node that selects all input data on either Input A or Input B only, based on the Use Input B property.",
	}

func execute( ctx : FlowData.EvaluationContext ):
	var in_data_a : FlowData.Data = get_optional_input(0)
	var in_data_b : FlowData.Data = get_optional_input(1)

	var selected_data : FlowData.Data = in_data_b if bool(settings.use_input_b) else in_data_a
	if selected_data == null:
		selected_data = FlowData.Data.new()
	set_output(0, selected_data)
