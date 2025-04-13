# Open the project
open_project /home/workinglobster/basys3-esp32-webserver/vivado_project/basys3_esp32_webserver

# Set simulation runtime to 15ms to ensure all test cases are captured
set_property xsim.simulate.runtime {15ms} [get_filesets sim_1]

# Enable logging all signals for detailed output
set_property xsim.simulate.log_all_signals true [get_filesets sim_1]

# Define simulation macros
set_property -name {xsim.compile.verilog.define} -value {SIMULATION=1} -objects [get_filesets sim_1]
set_property -name {xsim.elaborate.verilog.define} -value {SIMULATION=1} -objects [get_filesets sim_1]

# Clear any existing waveform configuration
set_property xsim.view {} [get_filesets sim_1]

# Optionally add waveform config if it exists
set waveform_file [file normalize "$::env(HOME)/waveform_config.wcfg"]
if {[file exists $waveform_file]} {
  add_files -fileset sim_1 -norecurse $waveform_file
}

# Launch simulation
puts "\n=== LAUNCHING SIMULATION WITH UART DEBUGGING ==="
launch_simulation -simset sim_1 -mode behavioral

# Log results after simulation completes
set fp [open "uart_simulation_results.log" w]
puts $fp "=== UART SIMULATION RESULTS ==="
puts $fp "Simulation completed at time [current_time]"
puts $fp "Final UART TX state: [get_value /fpga_tb/dut/uart_tx_inst/current_state]"
puts $fp "Final FPGA state: [get_value /fpga_tb/dut/tx_state]"
puts $fp "Transmitted button data: [get_value /fpga_tb/btn]"
puts $fp "Transmitted switch data: [get_value /fpga_tb/sw]"
close $fp

puts "\n=== SIMULATION COMPLETE ==="
puts "Check 'uart_simulation_results.log' for targeted results"

# Move log files to logs directory
set project_dir "/home/workinglobster/basys3-esp32-webserver/vivado_project"
file mkdir "$project_dir/logs"
if {[file exists "vivado.log"]} {
    file rename -force "vivado.log" "$project_dir/logs/vivado.log"
}
if {[file exists "vivado.jou"]} {
    file rename -force "vivado.jou" "$project_dir/logs/vivado.jou"
}

puts "\nSimulation completed. Log files moved to $project_dir/logs."
