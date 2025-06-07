#DO FILE FOR AXB UART MODULE
#WORK LIBRARY
vlib work 
#vmap work dev
#COMPILING ALL RTL DESIGN FILES
vlog ../rtl/s_axi_lite.v
vlog ../rtl/top_module.v

#COMPILING THE TESTBENCH

vlog ../tb/s_axi_tb.sv

#ELABORATION

vsim work.s_axi_tb

add wave -divider "Global Signals"
add wave sim:/s_axi_tb/clk
add wave sim:/s_axi_tb/resetn

add wave -divider "AW Channel"
add wave sim:/s_axi_tb/awvalid
add wave sim:/s_axi_tb/awready
add wave sim:/s_axi_tb/awaddr
add wave -divider "AW Channel EXPECTED"
add wave sim:/s_axi_tb/tb_awready

add wave -divider "W Channel"
add wave sim:/s_axi_tb/wvalid
add wave sim:/s_axi_tb/wready
add wave sim:/s_axi_tb/wdata
add wave sim:/s_axi_tb/wstrb
add wave -divider "W Channel EXPECTED"
add wave sim:/s_axi_tb/tb_wready

add wave -divider "B Channel"
add wave sim:/s_axi_tb/bvalid
add wave sim:/s_axi_tb/bready
add wave sim:/s_axi_tb/bresp
add wave -divider "B Channel EXPECTED"
add wave sim:/s_axi_tb/tb_bvalid
add wave sim:/s_axi_tb/tb_bresp

add wave -divider "AR Channel"
add wave sim:/s_axi_tb/arvalid
add wave sim:/s_axi_tb/arready
add wave sim:/s_axi_tb/araddr
add wave -divider "AR Channel EXPECTED"
add wave sim:/s_axi_tb/tb_arready


add wave -divider "R Channel"
add wave sim:/s_axi_tb/rvalid
add wave sim:/s_axi_tb/rready
add wave sim:/s_axi_tb/rdata
add wave sim:/s_axi_tb/rresp
add wave -divider "R Channel EXPECTED"
add wave sim:/s_axi_tb/tb_rvalid
add wave sim:/s_axi_tb/expected_data
add wave sim:/s_axi_tb/tb_rresp

add wave -divider "SLAVE MEM"
add wave sim:/s_axi_tb/slv_mem
add wave -divider "SLAVE MEM EXPECTED"
add wave sim:/s_axi_tb/mem

# Run simulation
run -all
