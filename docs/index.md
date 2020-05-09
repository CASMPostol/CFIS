# CFIS - CAS Flight Inspection System of the radio navigation aids

![CFIS](_media/RepoCard.png)

The CAS Flight Inspection System of the radio navigation aids (CFIS) is used for the airborne evaluation of the accuracy and performance of ground navigation facilities. The system provides the capability to inspect the following aids:

- ILS (instrument landing system),
- MKS (ILS associated approach markers),
- VOR (VHF omnidirectional range),
- DME (distance measuring equipment),
- NDB (non-directional beacon system),
- VHF (communication) and radar systems

It is modern, computerized system designed for the acquisition, recording, processing, analysis, display, and reporting of flight inspection data. It acquires various conditional signals from the avionics.

## Features

- Facilities database
- System Parameters database
- Automatic calibration
- Mission database
- Mission replay capacities
- Run time analysis

## Functions

- Data acquisition 5 samples/second
- Data filtering
- Data recording
- Trajectory follow navigation
- Flight data management
- Checklist
- Real-time data display
- Real-time analysis
- Hardcopy report
- Post run data replay
- Flying map

Flight Inspection System of Radio Navigation Aids (CFIS) is a computer-based system used for the airborne evaluation of the accuracy and performance of the ground navigation facilities. It includes VHF systems, specialized converters, a multiprocessor computer system, and dedicated software. The CFIS was used to maintain the Polish civil air space. The system is carried by aircraft for airborne evaluation of accuracy and performance of ground navigation facilities with the aim of their calibration according to ICAO and FAA international and de facto standards.

One of the system's basic functions is to locate an inspection airplane in airspace with great accuracy. For that purpose, we use a telemetric system with dedicated software. This way we can determine in real-time exactly the position of an aircraft flying at a speed of 240 km/h at the runway threshold with decimeter accuracy using the theodolite indications. The aircraft position is also determined independently based on the global positioning system. Several transceivers intended for navigation and using radio waves in MHz and GHz frequency bands are installed in the system.

It engages a unique [real-time concurrent programming framework][RTP] improving software robustness. As a result, allowing developers to avoid hard-to-discover errors at the software testing stage. Finally it also greatly reduces development cost, which is of crucial importance because the software has a hundred thousand lines of code. The system was in service for 15 years and no incident was reported. In general., Flight Inspection Systems are offered only by a few companies in the world and they are used for periodical airborne evaluation of accuracy and performance of ground navigation facilities such as NDB, VOR, DME, ILS, and radars. The solution was awarded a gold medal at the International Fair of Aviation and Astronautics AeroInterLot 1996.

The CFIS was designed, developed, and deployed by CAS Lodz Poland. @mpostol is the founder and Executive Director of CAS. Now CAS is just an individual business activity conducted by @mpostol, so that was decided to move this software to Open Source. @mpostol was also Chief Architect and software developer of the CFIS.

## See also

- [Flight Inspection System of the radio navigation aids brochure](_media\cfis_en.pdf)
- [IMPLEMENTATION OF MONITOR CONCEPT IN MODULA-2][RTP]
- [User manual; in Polish](https://github.com/CASMPostol/CFIS/tree/master/docs/UserManual.pl)

[RTP]:_media\realtimeprogramming_en.pdf
