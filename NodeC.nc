#include <Timer.h>
#include "../../includes/command.h"
#include "../../includes/packet.h"
#include "../../includes/neighbor.h"
#include "../../includes/sendInfo.h"
#include "../../includes/linkstate.h"
#include "../../includes/socket.h"

configuration NodeC{
}

implementation{
	components Node;
	components MainC;
	components new AMReceiverC(6);
	components ActiveMessageC;
	components PacketHandlerC;
	components CommandHandlerC;
	components NeighborDiscoveryC;
	components LinkStateRoutingC;
	components TransportC;
	components DataTransferC;
	
	Node -> MainC.Boot;
	Node.Receive -> AMReceiverC;
	Node.SplitControl -> ActiveMessageC;
	Node.PacketHandler -> PacketHandlerC;
	Node.CommandHandler -> CommandHandlerC;
	Node.NeighborDiscovery -> NeighborDiscoveryC;
	Node.LinkStateRouting -> LinkStateRoutingC;
	Node.Transport -> TransportC;
	CommandHandlerC.PacketHandler -> PacketHandlerC;
	CommandHandlerC.NeighborDiscovery -> NeighborDiscoveryC;
	CommandHandlerC.LinkStateRouting -> LinkStateRoutingC;
	CommandHandlerC.Transport -> TransportC;
	NeighborDiscoveryC.PacketHandler -> PacketHandlerC;
	NeighborDiscoveryC.LinkStateRouting -> LinkStateRoutingC;
	LinkStateRoutingC.PacketHandler -> PacketHandlerC;
	TransportC.PacketHandler -> PacketHandlerC;
	TransportC.DataTransfer -> DataTransferC;
	DataTransferC.PacketHandler -> PacketHandlerC;
	DataTransferC.Transport -> TransportC;

	components new HashmapC(uint16_t, NEIGHBOR_TABLE_SIZE) as neighborMap;
	components new HashmapC(uint16_t, SEQUENCE_TABLE_SIZE) as sequenceTable;
	components new HashmapC(uint32_t, ROUTING_TABLE_SIZE) as routingTable;
	components new HashmapC(socket_store_t*, TOTAL_PORTS) as socketTable;
	components new ListC(uint8_t, SOCKET_BUFFER_SIZE) as effectiveWindow;

	Node.neighborMap -> neighborMap;
	NeighborDiscoveryC.neighborMap -> neighborMap;
	Node.sequenceTable -> sequenceTable;
	Node.routingTable -> routingTable;
	Node.socketTable -> socketTable;
	PacketHandlerC.sequenceTable -> sequenceTable;
	PacketHandlerC.routingTable -> routingTable;
	LinkStateRoutingC.neighborMap -> neighborMap;
	LinkStateRoutingC.routingTable -> routingTable;
	TransportC.socketTable -> socketTable;
	DataTransferC.socketTable -> socketTable;
	DataTransferC.effectiveWindow -> effectiveWindow;
	
	components RandomC as Random;						
	components new TimerMilliC() as ConstantCheck;
	components new TimerMilliC() as Check;
	components new TimerMilliC() as BriefCheck;
	components new TimerMilliC() as RareCheck;

	Node.Random -> Random;
	Node.ConstantCheck -> ConstantCheck;
	Node.Check -> Check;
	Node.BriefCheck -> BriefCheck;
	Node.RareCheck -> RareCheck;
	PacketHandlerC.Random -> Random;
	TransportC.Random -> Random;
	DataTransferC.Random -> Random;
}
