extends Control
class_name Main

func _ready():
	if "-decompile" in OS.get_cmdline_args() or "-compile" in OS.get_cmdline_args():
		var files: PackedStringArray
		for file in OS.get_cmdline_args():
			if "-" in file: continue
			files.append(file)

		if "-decompile" in OS.get_cmdline_args():
			#if global.dzip_decompile(OS.get_cmdline_args()[1]) != OK: global.OS_alert_dontoverlap("Something went wrong while trying to quick extract."); get_tree().quit()
			process_files(files , forcemode.DECOMRPESS)
			await global.decompile_success; get_tree().quit()
		if "-compile" in OS.get_cmdline_args():
			#\if global.dzip_compile(OS.get_cmdline_args()[1]) != OK: global.OS_alert_dontoverlap("Something went wrong while trying to quick compress."); get_tree().quit()
			process_files(files , forcemode.COMPRESS)
			await global.compile_success; get_tree().quit()

	global.main_object = self
	get_window().files_dropped.connect(process_files)


enum forcemode{NONE , COMPRESS , DECOMRPESS}
func process_files(files: PackedStringArray , mode: forcemode = forcemode.NONE):

	var multiple_files = (files.size() > 1)

	var file := files[0]
	print(file)

	if not multiple_files:
		print("Running single file")

		#if CTRL: DISCARDED, USERS WOULD HAVE CTRL PRESSED AND COULD ADD THE DROPPED FILES ONTO AN SPECIFIC DZ.
			#var callback = func(status: bool, selected_paths: PackedStringArray, selected_filter_index: int): 
				#if not status: return
				#if global.dzip_decompile(selected_paths[0] , false) != OK: return
				#await global.decompile_success
				#for sfile in files:
					#DirAccess.copy_absolute(sfile ,  selected_paths[0].get_basename().path_join(sfile.get_file()))
				#global.dzip_compile(selected_paths[0].get_basename())
#
			#DisplayServer.file_dialog_show("Open the DZ" , "" , "" , true , DisplayServer.FILE_DIALOG_MODE_OPEN_FILE , ["*.dz"] , callback)

## Handle error cases
		if not file.get_extension().is_empty() and file.get_extension() != "dz": global.OS_alert_dontoverlap("The file you dropped isn't a dz file nor an folder."); return
		if file.get_extension().is_empty() and mode == forcemode.COMPRESS or mode == forcemode.NONE: global.dzip_compile(file)
		elif mode == forcemode.DECOMRPESS or mode == forcemode.NONE: global.dzip_decompile(file)

	else:
		print("Running multiple files")
		var filename = []
		var callback = func(s: String): filename.append(s)
		get_window().always_on_top = false
		DisplayServer.dialog_input_text("Set dz name" , "Insert dz name" , "" , callback)
		get_window().always_on_top = true
## Temporary folder whose these files will be copied to to be compiled
		var new_folder = DirAccess.make_dir_absolute(files[0].get_base_dir() + "/temp_ezdzip/")
		if new_folder != OK: global.OS_alert_dontoverlap("Error while creating temporary ezdzip folder."); return
 
## Copy those files to the temporary folder
		for dfile in files:
			var r = DirAccess.copy_absolute(dfile , files[0].get_base_dir() + "/temp_ezdzip/" + dfile.get_file())
			if r != OK: 
				global.OS_alert_dontoverlap("Something went wrong while copying files to temporary folder."); return

## Compiles the folder whilst checking if it gone wrong to return, if it doesnt, wait for it to compile and rename the  folder to the name the user input
		if (mode == forcemode.COMPRESS or mode == forcemode.NONE): if global.dzip_compile(files[0].get_base_dir() + "/temp_ezdzip") != OK: global.OS_alert_dontoverlap("Something went wrong while trying to compile to dz."); return
		await global.compile_success
		DirAccess.rename_absolute(files[0].get_base_dir() + "/temp_ezdzip.dz" , files[0].get_base_dir() + "/" + filename[0] + ".dz")

## Get rid of the temporary folder by deleting all the files inside it and the folder itself, then return the window to always on top
		for dirfile in DirAccess.get_files_at(files[0].get_base_dir() + "/temp_ezdzip/"):
			print(dirfile)
			DirAccess.remove_absolute(files[0].get_base_dir() + "/temp_ezdzip/" + dirfile)

		DirAccess.remove_absolute(files[0].get_base_dir() + "/temp_ezdzip")
