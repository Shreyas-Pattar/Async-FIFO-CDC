# Define Write Clock: 100 MHz (Period = 10.0 ns)
create_clock -period 10.000 -name wclk -waveform {0.000 5.000} [get_ports wclk]

# Define Read Clock: 40 MHz (Period = 25.0 ns)
create_clock -period 25.000 -name rclk -waveform {0.000 12.500} [get_ports rclk]

# Tell the STA engine that wclk and rclk are asynchronous to each other (CDC)
set_clock_groups -asynchronous -group [get_clocks wclk] -group [get_clocks rclk]