set project_dir [file dirname [file normalize [info script]]]
cd $project_dir
open_project audio_tone.gprj
set_option -top_module top
set_option -include_path [list "$project_dir/src"]
set_option -output_base_name audio_tone
set_option -use_cpu_as_gpio 1
set_option -use_sspi_as_gpio 1
run all
