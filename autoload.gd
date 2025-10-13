extends Node

## Used to rebuild dzip from scratch when compiling or decompiling
var main_object: Main
var current_path: String
var is_process_running := false

var decompile_thread: Thread
var compile_thread: Thread

func remove_dzip() -> void:
	var result = DirAccess.remove_absolute(current_path + "/dzip.exe")
	if result != OK: OS.alert("Unable to delete temporary dzip.exe.")

func remove_dcl() -> void:
	var result = DirAccess.remove_absolute(current_path + "/dc.dcl")
	if result != OK: OS.alert("Unable to delete temporary dc.dcl. (dzip config file)")

func dzip_decompile(path_to_file: String) -> void:
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
	if result.is_empty(): OS.alert("Something went wrong while decompiling %s" % path_to_file.get_file()); is_process_running = false; return

## Create a thread to watch the CMD process to check when it's completed
	decompile_thread = Thread.new(); decompile_thread.start(watch_thread.bind(result["pid"] , func():OS.alert("The dz file has been decompiled."); remove_dzip()))

func dzip_compile(path_to_folder: String) -> void:
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
	for file in DirAccess.get_files_at(path_to_folder):
		config += "\nfile %s 0 zlib" % file.get_file()
	configdcl.store_string(config)
	configdcl.close()

## Run dzip on configdcl
	var result = OS.execute_with_pipe("cmd.exe" , ["/C" , 'cd %s&&dzip dc.dcl' % path_to_folder.get_base_dir()] , false)
	is_process_running = true
	print(result)
	if result.is_empty(): OS.alert("Something went wrong"); return

## Watch the cmd (read the decompile one for more details)
	compile_thread = Thread.new(); compile_thread.start(watch_thread.bind(result["pid"] , func():OS.alert("The dz file has been compiled."); remove_dzip(); remove_dcl()))

func watch_thread(pid: int , callback: Callable) -> void:
	while OS.is_process_running(pid):
		OS.delay_msec(100) # Check every 100ms so we dont blow up the computer
## These only run after the "while" loop is false, which is when CMD stops running
## Checks if cmd failed somehow (if it fails, take the L, because i won't know how to fix!)
	if OS.get_process_exit_code(pid) != 0: OS.alert("The process failed."); set_deferred("is_process_running" , false); return
## Function to run outside of the thread cuz it crahses if we dont
	callback.call_deferred(); set_deferred("is_process_running" , false)
