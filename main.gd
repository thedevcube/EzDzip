extends Control
class_name Main

func _ready():
	global.main_object = self
	get_window().files_dropped.connect(on_files_dropped)

func on_files_dropped(files: PackedStringArray):
	var file := files[0]
	print(file)
	if not file.get_extension().is_empty() and file.get_extension() != "dz": OS.alert("The file you dropped isn't a dz file nor an folder."); return
	if file.get_extension().is_empty(): global.dzip_compile(file)
	else: global.dzip_decompile(file)
