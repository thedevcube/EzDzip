extends Node

signal decompile_success
signal compile_success

## Used to rebuild dzip from scratch when compiling or decompiling
var main_object: Main
var current_path: String
var is_process_running := false

var decompile_thread: Thread
var compile_thread: Thread

## Redirected version of OS.alert so the main window dont get on front of the alert ones
func OS_alert_dontoverlap(text: String , title: String = "Alert!"):
	get_window().always_on_top = false
	OS.alert(text , title)
	get_window().always_on_top = true

func remove_dzip() -> void:
	var result = DirAccess.remove_absolute(current_path + "/dzip.exe")
	if result != OK: OS_alert_dontoverlap("Unable to delete temporary dzip.exe.")

func remove_dcl() -> void:
	var result = DirAccess.remove_absolute(current_path + "/dc.dcl")
	if result != OK: OS_alert_dontoverlap("Unable to delete temporary dc.dcl. (dzip config file)")

func dzip_decompile(path_to_file: String , warn := true) -> Error:
	current_path = path_to_file.get_base_dir()
	var path_to_dzip = path_to_file.get_base_dir() + "/dzip.exe"
## Create a new dzip.exe on the file's folder
	var dzip = FileAccess.open(path_to_dzip , FileAccess.WRITE)
## Copy original bytes to the new dzip
	dzip.store_buffer(FileAccess.get_file_as_bytes("dzip.exe"))
	dzip.close()

## Run CMD, then cd to the file path folder, then run dzip to decompile the folder
	var result = OS.execute_with_pipe("cmd.exe" , ["/C" , "cd %s&&dzip -d %s" % [path_to_file.get_base_dir() , path_to_file.get_file()]] , false)

	is_process_running = true
	if result.is_empty(): OS_alert_dontoverlap("Something went wrong while decompiling %s" % path_to_file.get_file()); is_process_running = false; return FAILED

## Create a thread to watch the CMD process to check when it's completed
	decompile_thread = Thread.new()
	var threadcheck = decompile_thread.start(watch_thread.bind(result["pid"] , func(): decompile_success.emit(); remove_dzip(); if warn: OS_alert_dontoverlap("The dz file has been decompiled.") , func(): remove_dzip(); OS_alert_dontoverlap("An error occured while decompiling")))
	if threadcheck != OK: return FAILED
	return OK

func dzip_compile(path_to_folder: String , warn := true) -> Error:
	current_path = path_to_folder.get_base_dir()
	var path_to_dzip = path_to_folder.get_base_dir() + "/dzip.exe"
## Create a new dzip.exe on the file's folder
	var dzip = FileAccess.open(path_to_dzip , FileAccess.WRITE)
## Copy original bytes to the new dzip
	dzip.store_buffer(FileAccess.get_file_as_bytes("dzip.exe"))
	dzip.close()

## Setup config  for dzip
	var configdcl = FileAccess.open(path_to_folder.get_base_dir() + "/dc.dcl" , FileAccess.WRITE)
	var config: String = 'archive "%s"\nbasedir "%s"' % [path_to_folder.get_basename() + ".dz" , path_to_folder]

## Setup all the files on config dcl and close it
	for file in get_all_files_in_a_folder(path_to_folder):
		print(file)
		config += '\nfile "%s" 0 zlib' % file
	#print("\nConfig file content: '%s'\n" % config)

	configdcl.store_string(config)
	configdcl.close()

## Run dzip on configdcl
	var thread = Thread.new()
	var result = OS.execute_with_pipe("cmd.exe" , ["/C" , 'cd %s&&dzip dc.dcl' % path_to_folder.get_base_dir()] , false)

	is_process_running = true
	print(result)
	if result.is_empty(): OS_alert_dontoverlap("Something went wrong while running CMD"); return FAILED

## Watch the cmd (read the decompile one for more details)
	compile_thread = Thread.new()
	var threadcheck = compile_thread.start(watch_thread.bind(result["pid"] , func(): compile_success.emit(); remove_dzip(); remove_dcl(); if warn: OS_alert_dontoverlap("The dz file has been compiled.") , func(): OS_alert_dontoverlap("An error occured while compiling"); remove_dzip(); remove_dcl()))
	if threadcheck != OK: return FAILED

	return OK

func watch_thread(pid: int , callback: Callable , error_fallback: Callable) -> void:
	while OS.is_process_running(pid):
		OS.delay_msec(100) # Check every 100ms so we dont blow up the computer
## These only run after the "while" loop is false, which is when CMD stops running
## Checks if cmd failed somehow (if it fails, take the L, because i won't know how to fix!)
	if OS.get_process_exit_code(pid) != 0: error_fallback.call_deferred(); set_deferred("is_process_running" , false); return
## Function to run outside of the thread cuz it crahses if we dont
	callback.call_deferred(); set_deferred("is_process_running" , false)

## Iterates through every file of a folder, if this folder has folders get the relative path to their files by iterating through them too
func get_all_files_in_a_folder(folder: String , relative_path = "") -> Array[String]:
	var array: Array[String]
	for file in DirAccess.get_files_at(folder):
		array.append(relative_path.path_join(file))
	for _folder in DirAccess.get_directories_at(folder):
		array.append_array(get_all_files_in_a_folder(folder.path_join(_folder) , relative_path.path_join(_folder.get_file())))

	return array
