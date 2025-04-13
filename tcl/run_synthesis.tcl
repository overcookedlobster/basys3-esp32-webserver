# Run synthesis and implementation for Basys3 ESP32 Web Server project

# Open the project
open_project /home/workinglobster/basys3-esp32-webserver/vivado_project/basys3_esp32_webserver

# Run synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Run implementation
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Generate bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Close project
close_project

# Create logs directory if it doesn't exist
set project_dir "/home/workinglobster/basys3-esp32-webserver/vivado_project"
file mkdir "$project_dir/logs"

# Move log files to logs directory if they exist
if {[file exists "vivado.log"]} {
    file rename -force "vivado.log" "$project_dir/logs/vivado.log"
}
if {[file exists "vivado.jou"]} {
    file rename -force "vivado.jou" "$project_dir/logs/vivado.jou"
}

puts "Bitstream generation completed."
