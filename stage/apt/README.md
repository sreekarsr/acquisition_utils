# APT Wrappers for MATLAB
Here you will find some commonly used wrappers (class defintions) to make it simpler to interface with Thorlabs devices using APT. If you use a device that doesn't fit within these, create your own wrapper and add a mention in this file.

## Setup and Resources
- Download and install the APT software available on the [Thorlabs Motion Control Software](https://www.thorlabs.com/software_pages/viewsoftwarepage.cfm?code=Motion_Control) page (This should be accessible from the product page of your device).
- There's an old but useful document from Thorlabs about using APT with MATLAB [here][thorlabsmatlab]
- Along with the APT installation you will also find a help file located in `C:\Program Files\Thorlabs\APT\APT Server` to help you figure out the devices that work with a given PROGID and the methods that may be useful to your application.

## Writing your own wrapper
If you use a device that doesn't work with these wrappers, then you can go ahead and create another class definition by modifying one of the existing files.
- To help you figure out the PROGID you need to use, use `actxcontrolselect` in MATLAB and browse through the list.
- Look at the methods and properties in the APT help document (mentioned above). The [Thorlabs MATLAB tutorial][thorlabsmatlab] will also be helpful to start out.

## Notes
- The first two digits of the 8-digit serial number (indicated as S/N on your thorlabs device) is specific to your device type, and determines the PROGID. If you find that `HWSerialNum` is not being set (even without an error), it is likely that you are using the wrong PROGID.
For example, the 4-channel KIM101 will have the first two digits in the S/N as `97` and works with the PROGID `APTPZMOTOR.APTPZMotorCtrl.1`, but it does not work with `MGPIEZO.MGPiezoCtrl.1` which is meant for older piezo controllers like the single-channel KPZ101 which have serial numbers that start with `29`.
- APT is just one way to interface Thorlabs components. You may also use the Kinesis API for interfacing. Here's a [tutorial](https://www.youtube.com/watch?v=VbcCDI6Z6go) using Kinesis with python, and here's [a sample](https://www.mathworks.com/matlabcentral/fileexchange/66497-driver-for-thorlabs-motorized-stages) of what a MATLAB wrapper would look like.

[thorlabsmatlab]: https://www.thorlabs.com/tutorials/Thorlabs_APT_MATLAB.docx
