# Antipaparazzi device

This project is intended to be an anti-paparazzi device.
The idea is to detect if a camera system or other optical system is directed towards the device.
The detection is done by scanning the surroundings with a laser beam, and detect any reflections.
All optical systems will have a retro-reflex, directing the reflected beam in the opposing direction of the incoming beam, 
e.g. back to the device.

## Phased-Locked-Loop design

Natural speed of the combination of motor and drive wheel results in a scanning speed of 16 Hz.
Multiplied by 360 (for 1 degree of angular resolution) means that the clock should be around 5.8 kHz.

Choosing oscillator components according to HFE4046B datasheet section 11.1 (VCO without frequency offset)with a 5760 Hz f0 gives;
	R1 = 100 kOhm	or	R1 = 10 kOhm
	C1 = 800 pF		C1 = 7000 pF

With assumed limits of 12 to 20 Hz the clock limits become 4320 resp. 7200 Hz. (fmax/fmin = 1.667)
Choosing components (VFO with frequency offset) leads to values:
	R1 = 80 kOhm
	R2 = 100 kOhm
	C1 = 2000 pF

Components at hand:
	R1 = 10 kOhm
	C1 = 10 nF


