#include <Timer.h>
#include "includes/command.h"
#include "includes/channels.h"
#include "includes/packet.h"
#include "includes/neighbor.h"
#include "includes/sendInfo.h"
#include "includes/linkstate.h"
#include "includes/socket.h"

module Node{
	uses interface Boot;
	uses interface SplitControl;
	uses interface Receive;
	
	uses interface PacketHandler;
	uses interface CommandHandler;
	uses interface NeighborDiscovery;
	uses interface LinkStateRouting;
	uses interface Transport;
	
	uses interface Random;
	uses interface Timer<TMilli> as ConstantCheck;
	uses interface Timer<TMilli> as Check;
	uses interface Timer<TMilli> as BriefCheck;
	uses interface Timer<TMilli> as RareCheck;
	
	uses interface Hashmap<uint16_t> as neighborMap;
	uses interface Hashmap<uint16_t> as sequenceTable;
	uses interface Hashmap<uint32_t> as routingTable;
	uses interface Hashmap<socket_store_t*> as socketTable;
	uses interface List<uint8_t> as effectiveWindow;	
}

implementation{	
	event void Boot.booted(){
		call SplitControl.start();
		
		call CommandHandler.initialize();
		call LinkStateRouting.initialize();
		call PacketHandler.initialize();
		call NeighborDiscovery.initialize();
		call Transport.initialize();
		
		call ConstantCheck.startOneShot((call Random.rand32()%200) + 3999);
		call Check.startOneShot((call Random.rand32()%2000) + 19991);
		call BriefCheck.startOneShot((call Random.rand32()%20000) + 189999);
		call RareCheck.startOneShot((call Random.rand32()%40000) + 889999);
		
		dbg(GENERAL_CHANNEL, "Booted\n");	
	}

	event void SplitControl.startDone(error_t err){
		if(err == SUCCESS){
			dbg(GENERAL_CHANNEL, "Radio On\n");
		}
		else{
			// Retry until successful
			call SplitControl.start();
		}
	} 

	event void SplitControl.stopDone(error_t err){
		if(err == SUCCESS){
			dbg(GENERAL_CHANNEL, "Radio Off\n");
		}
		else{
			// Retry until successful
			call SplitControl.stop();
		}
	}

	event void ConstantCheck.fired(){
		call NeighborDiscovery.findNeighbors();
		call ConstantCheck.startOneShot((call Random.rand32()%200) + 3999);
	}

	event void Check.fired(){
		call NeighborDiscovery.deadCheck();
		call LinkStateRouting.updateLinkState(FALSE);
		call Check.startOneShot((call Random.rand32()%2000) + 19991);
	}

	event void BriefCheck.fired(){
		call LinkStateRouting.findRoute();	
		call BriefCheck.startOneShot((call Random.rand32()%20000) + 189999);
		//call Transport.resendSynAck();
	}

	event void RareCheck.fired(){
		call LinkStateRouting.updateLinkState(TRUE);
		call PacketHandler.updateSequence();
		call RareCheck.startOneShot((call Random.rand32()%40000) + 889999);
	}

	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		pack* Packet = (pack*)payload;

		if(len != sizeof(pack)){
			dbg(GENERAL_CHANNEL, "Unknown packet type %d\n", len);
			return msg;
		}
		
		if (call PacketHandler.dup(Packet)){
			// dbg(GENERAL_CHANNEL, "Duplicate packet found\n");
			return msg;
		}
		
		call CommandHandler.receive(Packet);
		call NeighborDiscovery.receive(Packet);
		call LinkStateRouting.receive(Packet);
		call PacketHandler.receive(Packet);
		call Transport.receive(Packet);
		return msg;
	}
}