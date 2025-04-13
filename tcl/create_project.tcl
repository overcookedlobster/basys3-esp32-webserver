# Create Vivado project for Basys3 ESP32 Web Server

# Set project parameters
set project_name "basys3_esp32_webserver"
set project_dir "/home/workinglobster/basys3-esp32-webserver/vivado_project"

# Create project with force option to overwrite if it exists
create_project $project_name $project_dir -part xc7a35tcpg236-1 -force

# Set Verilog as target language
set_property target_language Verilog [current_project]

# Add source files
add_files -norecurse [list \
  "$project_dir/../src/fpga_top.sv" \
  "$project_dir/../src/input_handler.sv" \
  "$project_dir/../src/button_debounce.sv" \
  "$project_dir/../src/uart_tx.sv" \
  "$project_dir/../src/constraints.xdc" \
]

# Set top module
set_property top fpga_top [current_fileset]

# Add simulation files
add_files -fileset sim_1 -norecurse "$project_dir/../sim/fpga_tb.sv"
set_property top fpga_tb [get_filesets sim_1]

# Set simulation properties
set_property xsim.simulate.runtime "1000us" [get_filesets sim_1]

# Create logs directory if it doesn't exist
file mkdir "$project_dir/logs"

# Move log files to logs directory if they exist
if {[file exists "vivado.log"]} {
    file rename -force "vivado.log" "$project_dir/logs/vivado.log"
}
if {[file exists "vivado.jou"]} {
    file rename -force "vivado.jou" "$project_dir/logs/vivado.jou"
}

puts "Project $project_name created successfully. Log files moved to $project_dir/logs."
