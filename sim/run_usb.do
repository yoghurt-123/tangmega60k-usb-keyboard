onerror {quit -code 1 -force}
vlib usb_work
vlog -work usb_work +incdir+src src/top.v src/key_toggle.v src/usb_hid_host.v src/usb_hid_host_rom.v src/usb_a_key.v src/status_led.v src/sine_wave.v src/audio_driver.v src/uart_tx.v src/vofa_uart.v sim/tb_usb_a.v
vsim -c usb_work.tb_usb_a
onbreak {quit -code 1 -force}
run -all
quit -code 0 -force
