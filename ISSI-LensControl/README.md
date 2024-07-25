# ISSI Lens Control

MATLAB script to operate ISSI LC-2 Ethernet Lens controller. [Reference doc](https://innssi.com/wp-content/uploads/CanonLensController/Documentation/ISSI_LC-2_API.pdf)

## Troubleshooting

The default device IP is `192.168.2.252`. It works if you set your NIC's IP (in Control Panel's network settings) to `192.168.2.xxx` (e.g. `192.168.2.200`)

Connection will likely fail if you do not follow these steps (in this order) : 

1. First, mount the lens
2. Plug in the adapter (then wait for a few seconds)
3. Connect the ethernet cable to computer

