# mcp4728verilog


The module is designed to set the value of the DAC for 4 simultaneously MCP4728 using the common SDA and SCL lines and separate LDAC lines for each IC. The module only reads the address of each chip and sets the DAC values in fast mode.

mcp4728.v - module files
i2ctoptest.v - example of run and debug

