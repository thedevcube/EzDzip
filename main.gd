extends Control
class_name Main

func _ready():
	global.main_object = self
	get_window().files_dropped.connect(on_files_dropped)



func on_files_dropped(files: PackedStringArray):

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
		if not file.get_extension().is_empty() and file.get_extension() != "dz": OS.alert("The file you dropped isn't a dz file nor an folder."); return
		if file.get_extension().is_empty(): global.dzip_compile(file)
		else: global.dzip_decompile(file)

	else:
		print("Running multiple files")
		var filename = []
		var callback = func(s: String): filename.append(s)
		get_window().always_on_top = false    # Error messages get behind the main window if i dont do this
		DisplayServer.dialog_input_text("Set dz name" , "Insert dz name" , "" , callback)
## Temporary folder whose these files will be copied to to be compiled
		var new_folder = DirAccess.make_dir_absolute(files[0].get_base_dir() + "/temp_ezdzip/")
		if new_folder != OK: OS.alert("Error while creating temporary ezdzip folder."); return
 
## Copy those files to the temporary folder
		for dfile in files:
			var r = DirAccess.copy_absolute(dfile , files[0].get_base_dir() + "/temp_ezdzip/" + dfile.get_file())
			if r != OK: 
				get_window().always_on_top = true; OS.alert("Something went wrong while copying files to temporary folder."); return

## Compiles the folder whilst checking if it gone wrong to return, if it doesnt, wait for it to compile and rename the  folder to the name the user input
		if global.dzip_compile(files[0].get_base_dir() + "/temp_ezdzip") != OK: OS.alert("Something went wrong while trying to compile to dz."); get_window().always_on_top = true; return
		await global.compile_success
		DirAccess.rename_absolute(files[0].get_base_dir() + "/temp_ezdzip.dz" , files[0].get_base_dir() + "/" + filename[0] + ".dz")

## Get rid of the temporary folder by deleting all the files inside it and the folder itself, then return the window to always on top
		for dirfile in DirAccess.get_files_at(files[0].get_base_dir() + "/temp_ezdzip/"):
			print(dirfile)
			DirAccess.remove_absolute(files[0].get_base_dir() + "/temp_ezdzip/" + dirfile)

		DirAccess.remove_absolute(files[0].get_base_dir() + "/temp_ezdzip")
		get_window().always_on_top = true
