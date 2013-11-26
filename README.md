CREATING AN INTERRUPT PROCEDURE FOR SERVICING A BUTTON PUSH  

1. Introduction
The interrupt procedure is developed that services the push button, such that it would turn ON on the first interrupt and turn OFF on the second interrupt. The program then returned to the main loop and runs again. 

2. Theory or Background
The ICMP could be set to produce an interrupt when GPIO is inserted. This interrupt could be hooked to the int_director branch at interrupt vector table.  The interrupt procedure could be written at the int_director branch. So we can then check the source of the interrupt and turn the led ON if its due to GPIO <73> interrupt and OFF if its due to the GPIO<73> interrupt. 
