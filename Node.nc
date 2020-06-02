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

#define INFINITY 9999
#define MAX 20

module Node{
   uses interface Boot;
   uses interface Timer<TMilli> as periodicTimer;
   uses interface Timer<TMilli> as lspTimer;
   uses interface Random as Random;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface SimpleSend as Sender;
   uses interface CommandHandler;
}

implementation{
   pack sendPackage;
   pack newPackage;
   pack linkPackage;
   uint16_t count, counter;
   uint16_t i, j,k, node[40];
   uint16_t table[10][10];
   uint16_t dest=9;
   uint16_t source=1;
   uint16_t prev=1;
   uint16_t seq=0;
   uint8_t* neighbor = "Neighbor requested.";
   uint8_t* reply = "Neighbor acknowledged!";
   uint8_t* link="link";
   uint16_t cost[MAX][MAX], distance[MAX], pred[MAX], fwdtable[MAX][MAX];
   uint16_t visited[MAX], mindist, nextnode, startnode, location = 0, point = 0;

   uint16_t complete_table[10][10] = {{9999,1,1,9999,9999,9999,9999,9999,9999}, // Node 1
                                      {1,9999,1,9999,1,9999,9999,9999,9999}, // Node 2
                                      {1,1,9999,1,1,1,9999,9999,9999}, // Node 3
                                      {9999,9999,1,9999,1,1,9999,1,9999}, // Node 4
                                      {9999,1,1,1,9999,9999,1,9999,9999}, // Node 5
                                      {9999,9999,1,1,9999,9999,9999,9999,9999}, // Node 6
                                      {9999,9999,9999,9999,1,9999,9999,1,9999}, // Node 7
                                      {9999,9999,9999,1,9999,9999,1,9999,1}, // Node 8
                                      {9999,9999,9999,9999,9999,9999,9999,1,9999} }; // Node 9

 
   // Prototypes
   void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t *payload, uint8_t length);
   void di(uint16_t G[MAX][MAX], uint16_t start);
   event void Boot.booted(){
      call AMControl.start();
      call periodicTimer.startPeriodic(5333+(uint16_t)((call Random.rand16())%200)); 
      call lspTimer.startPeriodic(20000+(uint16_t)((call Random.rand16())%200));  //Start the Timer in different intervals
      dbg(GENERAL_CHANNEL, "Booted\n");
   }
   
   event void periodicTimer.fired(){
      dbg(NEIGHBOR_CHANNEL, "NEIGHBOR DISCOVERY EVENT \n");
      makePack(&newPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 1, 0, 0, neighbor, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(newPackage, AM_BROADCAST_ADDR);

   }
   
   event void lspTimer.fired(){
      dbg(ROUTING_CHANNEL, "LINK STATE ROUTING EVENT \n");
      for(k = 1; k <  10; k++){

               if(table[TOS_NODE_ID][k]==1){
                  count+=1;
               
              }
            }
            
      makePack(&linkPackage, TOS_NODE_ID, AM_BROADCAST_ADDR, 10, 3, 0, link, PACKET_MAX_PAYLOAD_SIZE);
      call Sender.send(linkPackage, AM_BROADCAST_ADDR);

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
     //dbg(GENERAL_CHANNEL, "Packet Received\n"); 
     if(len==sizeof(pack)){
        pack* myMsg = (pack*) payload;
           
     

        if(myMsg->protocol==0){
            dbg(NEIGHBOR_CHANNEL, "Neighbor request from %d to %d\n", myMsg->src, TOS_NODE_ID);
                      
            //source=TOS_NODE_ID;
            myMsg->TTL-=1;
            //seq+=1;
            makePack(&newPackage, TOS_NODE_ID, myMsg->src, 1, 1, 0, reply, PACKET_MAX_PAYLOAD_SIZE);
            call Sender.send(newPackage,  myMsg->src);
            return msg;
        }
        if(myMsg->protocol==1){
            dbg(NEIGHBOR_CHANNEL, "Neighbor acknowledged from %d to %d\n", myMsg->src, TOS_NODE_ID);
            table[TOS_NODE_ID][myMsg->src]=1;
            
            //makePack(&newPackage, TOS_NODE_ID, myMsg->src, 1, 1, seq, neighbor, PACKET_MAX_PAYLOAD_SIZE);
            //call Sender.send(newPackage,  AM_BROADCAST_ADDR);
           
            //source=TOS_NODE_ID;
            myMsg->TTL-=1;
            for(i = 1; i <  10; i++){
               printf( "Table input: ");
              for(j=1; j<10;j++){
            
                 printf( "%d ", table[i][j]);
              }
              dbg(NEIGHBOR_CHANNEL, "\n");
            }
          
            return msg;
            
        }
        
          
        /*
        if(myMsg->protocol == 6){
           if((myMsg->dest == TOS_NODE_ID) && (myMsg->TTL == 0)){
              dbg(NEIGHBOR_CHANNEL, "%d is my Neighbor.\n", myMsg->src);
           }
           else if(myMsg->TTL != 0){
              //dbg(NEIGHBOR_CHANNEL, "Neighbor Discovery Package\n");
              makePack(&sendPackage, TOS_NODE_ID, myMsg->dest, (myMsg->TTL - 1), 6, 0, neighbor, PACKET_MAX_PAYLOAD_SIZE);
              call Sender.send(sendPackage, AM_BROADCAST_ADDR);
           }
           else{
           }
           return msg;
         }*/
         else{ 
            startnode=TOS_NODE_ID-1;
            di(table, startnode);
            
         if(myMsg->protocol==3){
            dbg(ROUTING_CHANNEL, "Package Payload: %s\n", myMsg->payload);
            return msg;
         }      
         if (myMsg->src == TOS_NODE_ID) {
            
            dbg(GENERAL_CHANNEL, "The msg is not meant for me\n");
            return msg;
         }
         if (myMsg->dest == TOS_NODE_ID ) {
            //stop sending
            dbg(GENERAL_CHANNEL, "Package Payload: %s\n", myMsg->payload);
            return msg;
         }
         
         for( i=0; i<40; i+=1){
            if(node[i]==TOS_NODE_ID){
               dbg(GENERAL_CHANNEL, "been here already!\n");
               count++;
               return msg;
            }
            if(node[i]>0){
               count++;
            }
         }
         node[count]=TOS_NODE_ID;
         
         if(myMsg->TTL==0 ){
            dbg(GENERAL_CHANNEL, "Over!\n");
            return msg;
         }

         myMsg->TTL-=1;
         call Sender.send(*myMsg, AM_BROADCAST_ADDR);
         return msg;   
         } 
      }
      dbg(GENERAL_CHANNEL, "Unknown Packet Type %d\n", len);

      return msg;
   }

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload){
      dbg(GENERAL_CHANNEL, "PING EVENT \n");
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

   void di(uint16_t G[MAX][MAX], uint16_t start){
         for(i=0;i<9;i++){
           for(j=0;j<9;j++){
             if(G[i][j]==0){
               cost[i][j] = INFINITY;
             }
             else{
               if(cost[i][j] == 1)
                  cost[i][j] = G[i][j];
               else
                  cost[i][j] = G[i][j]++;
             }
           }
         }
         for(i=0;i<9;i++){
            pred[i] = start;
            visited[i]=0;
            distance[i]=cost[start][i];
         }
         distance[start] = 0;
         visited[start] = 1;
         counter = 1;
         while(counter<8){
           mindist = INFINITY;
           for(i=0;i<9;i++){
             if(distance[i]<mindist&&!visited[i]){
               mindist = distance[i];
               nextnode = i;
             }
           }
           visited[nextnode]=1;
           for(i=0;i<9;i++){
             if(!visited[i]){
               if(mindist+cost[nextnode][i]<distance[i]){
                 distance[i]=mindist+cost[nextnode][i];
                 pred[i]=nextnode;
               }
             }
           }
         counter++;
         }
         for(i=0;i<9;i++){
           if(i != start){
                printf("\nPath %d", i+1);
                fwdtable[start][point++] = i+1;
             j = i;
             while(j!=start){
               j = pred[j];
               if(j == start)
                  break;
               printf( "<- %d", j+1);
             }
             fwdtable[location][point++] = j+1;
           }
         }
         return;
    }
}
