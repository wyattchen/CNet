/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */


#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"
//#include "includes/hmap.h"

module Node{
   uses interface Boot;
   uses interface Timer<TMilli> as periodicTimer;
   uses interface SplitControl as AMControl;
   uses interface Receive;

   uses interface SimpleSend as Sender;

   uses interface CommandHandler;
}

implementation{
   pack sendPackage;
   uint16_t count;
   uint16_t node[40];
   uint16_t i;
   uint8_t *neighbor = "Neighbor";
  
   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);

   event void Boot.booted(){
      call AMControl.start();
	  call periodicTimer.startPeriodic((10000*TOS_NODE_ID));
      dbg(GENERAL_CHANNEL, "Booted\n");
   }
   event void periodicTimer.fired(){
      dbg(NEIGHBOR_CHANNEL, "NEIGHBOR DISCOVERY EVENT \n");
       makePack(&sendPackage, TOS_NODE_ID, TOS_NODE_ID, 1, 6, 0, neighbor, PACKET_MAX_PAYLOAD_SIZE);
       call Sender.send(sendPackage, AM_BROADCAST_ADDR);
    }

   event void AMControl.startDone(error_t err){
      if(err == SUCCESS){
         dbg(GENERAL_CHANNEL, "Radio On\n");
      }else{
         //Retry until successful
         call AMControl.start();
      }
   }
   
	
   event void AMControl.stopDone(error_t err){}

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      dbg(GENERAL_CHANNEL, "Packet Received\n");

      if(len==sizeof(pack)){
         pack* myMsg=(pack*) payload;
         dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
		 
		
			if (myMsg->src == TOS_NODE_ID) {
				
				dbg(GENERAL_CHANNEL, "The is the source node\n");
				return msg;
			}
			if (myMsg->dest == TOS_NODE_ID ) {
				dbg(FLOODING_CHANNEL, "Arrived at destination!\n");

				return msg;
			}
			if(myMsg->TTL==0 ){
				dbg(GENERAL_CHANNEL, "Over!\n");
				return msg;
			}
			
			for( i=0; i<40; i+=2){
				if(node[i]==TOS_NODE_ID && myMsg->seq>node[i+1]){
					dbg(GENERAL_CHANNEL, "been here already!\n");
					count+=2;
					return msg;
				}
				if(node[i]>0){
					count+=2;
				}
			}
			

			node[count]=TOS_NODE_ID;
			myMsg->seq+=1;
			myMsg->TTL-=1;
			call Sender.send(*myMsg, AM_BROADCAST_ADDR);
			return msg;
      
	  }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);
      return msg;
   }


   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
	  dbg(FLOODING_CHANNEL, "The message is sent from source.\n");
      makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, 0, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
	 
      call Sender.send(sendPackage, AM_BROADCAST_ADDR);
   }

   event void CommandHandler.printNeighbors(){}

   event void CommandHandler.printRouteTable(){}

   event void CommandHandler.printLinkState(){}

   event void CommandHandler.printDistanceVector(){}

   event void CommandHandler.setTestServer(){}

   event void CommandHandler.setTestClient(){}

   event void CommandHandler.setAppServer(){}

   event void CommandHandler.setAppClient(){}

   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
      Package->src = src;
      Package->dest = dest;
      Package->TTL = TTL;
      Package->seq = seq;
      Package->protocol = protocol;
	  for( i=0; i<40; i+=1){
				node[i]=0;			
	  }
	  count=0;
      memcpy(Package->payload, payload, length);
   }
}
