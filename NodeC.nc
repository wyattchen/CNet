/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */

#include <Timer.h>
#include "includes/CommandMsg.h"
#include "includes/packet.h"

configuration NodeC{
}
implementation {
    components MainC;
	components new TimerMilliC() as myTimerC;
    components new TimerMilliC() as lspTimer;
    components Node;
    components RandomC as Random;
    components new AMReceiverC(AM_PACK) as GeneralReceive;
   // components new HashmapC(uint16_t, 50) as NeighborMap;

    Node -> MainC.Boot;
	Node.periodicTimer -> myTimerC;

    Node.lspTimer -> lspTimer;
    //Node.NeighborMap -> NeighborMap;
    Node.Receive -> GeneralReceive; 
    Node.Random -> Random;
    components ActiveMessageC;
    Node.AMControl -> ActiveMessageC;

    components new SimpleSendC(AM_PACK);
    Node.Sender -> SimpleSendC;

    components CommandHandlerC;
    Node.CommandHandler -> CommandHandlerC;

    //components FloodingC; 
    //Node.FloodSender -> FloodingC.FloodSender;
	
}
