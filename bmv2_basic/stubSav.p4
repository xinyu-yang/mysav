/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>
#include "includes/header.p4"
#include "includes/parser.p4"
#include "includes/indexKey.p4"

/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    //counter(MAX_TUNNEL_ID, CounterType.packets_and_bytes) ingressTunnelCounter;
    //counter(MAX_TUNNEL_ID, CounterType.packets_and_bytes) egressTunnelCounter;
    // initiate state variable
    bit<48> tmp;
    // time_t  meta.timestamp;
    // indexKey() indexKeyInstance;
    // register<time_t>(1) ctime;

    action initiate() {
        meta.isSrcDeploy = false;
        meta.isDstDeploy = false;
        meta.isLast = false;
        meta.isLocalPrefix = false;
        meta.isThisSrcPrefix = false;
        meta.isThisDstPrefix = false;
        meta.existMiddle = false;
        meta.verified = false;
        meta.isInput = false;
        meta.isOutput = false;
    }

    action drop() {
        mark_to_drop(standard_metadata);
    }
    
    action ipv4_forward(macAddr_t dstAddr) {
        standard_metadata.egress_spec = meta.egressPort;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ip.v4.ttl = hdr.ip.v4.ttl - 1;
    }

    action ipv6_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ip.v6.hopLimit = hdr.ip.v6.hopLimit - 1;
    }

    // action myTunnel_ingress(bit<16> dst_id) {
    //     hdr.myTunnel.setValid();
    //     hdr.myTunnel.dst_id = dst_id;
    //     hdr.myTunnel.proto_id = hdr.ethernet.etherType;
    //     hdr.ethernet.etherType = TYPE_MYTUNNEL;
    //     ingressTunnelCounter.count((bit<32>) hdr.myTunnel.dst_id);
    // }

    // action myTunnel_forward(egressSpec_t port) {
    //     standard_metadata.egress_spec = port;
    // }

    // action myTunnel_egress(macAddr_t dstAddr, egressSpec_t port) {
    //     standard_metadata.egress_spec = port;
    //     hdr.ethernet.dstAddr = dstAddr;
    //     hdr.ethernet.etherType = hdr.myTunnel.proto_id;
    //     hdr.myTunnel.setInvalid();
    //     egressTunnelCounter.count((bit<32>) hdr.myTunnel.dst_id);
    // }

    action setThisSrcPrefix(){
        meta.isThisSrcPrefix = true;
    }
    action setThisDstPrefix(){
        meta.isThisDstPrefix = true;
    }
    action setLocalPrefix() {
        meta.isLocalPrefix = true;
    }
    //flags | | | | | |deployed|last|stub|
    action getSrcAsn(asn_t asn, bit<8> flags) {
        meta.srcAsn = asn;
        if ((flags & 0x04) != 0) {
            meta.isSrcDeploy = true;
        }
        if ((flags & 0x01) != 0) {
            meta.isStub = true;
        }
    }
    action getDstAsn(asn_t asn, egressSpec_t port, macAddr_t dstAddr, bit<8> flags) {
        meta.dstAsn = asn;
        meta.egressPort = port;
        meta.dstAddr = dstAddr;
        if ((flags & 0x04) != 0) {
            meta.isDstDeploy = true;
        }
        if ((flags & 0x02) != 0) {
            meta.isLast = true;
        }
    }

    action getTime(time_t time) {
        meta.timestamp = time;
    }

    action getKey(bit<16> key) {
        meta.MAC = key;
    }
    action setDstAsn(asn_t asn) {
        meta.dstAsn = asn;
        if (asn != (asn_t)0)
        {
            meta.existMiddle = true;
        }
    }
    action insertIpv4MAC() {
        hdr.ip.v4.identification = meta.MAC;
    }
    
    action verifyMAC() {
        if (meta.MAC == hdr.ip.v4.identification) {
            meta.verified = true;
        }
    }


    action setIngressAsn(bit<32> asn) {
        meta.ingressAsn = asn;
    }

    action setEgressAsn(bit<32> asn) {
        meta.egressAsn = asn;
    }

    table getTime_lpm {
        key = {
            hdr.ip.v4.version: lpm;
        }
        actions = {
            getTime;
            drop;
        }
        size = 2;
        default_action = drop;
    }

    table ipv4Src2AS_lpm {
        key = {
            hdr.ip.v4.srcAddr: lpm;
        }
        actions = {
            getSrcAsn;
            drop;
        }
        size = 65535;
        default_action = drop();
    }
    table ipv4Dst2AS_lpm {
        key = {
            hdr.ip.v4.dstAddr: lpm;
        }
        actions = {
            getDstAsn;
            drop;
        }
        size = 65535;
        default_action = drop();
    }

    // if the src frefix owned by this AS
    table thisSrcPrefix_lpm {
        key = {
            hdr.ip.v4.srcAddr: lpm;
        }
        actions = {
            setThisSrcPrefix;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    // if the dst frefix owned by this AS
    table thisDstPrefix_lpm {
        key = {
            hdr.ip.v4.dstAddr: lpm;
        }
        actions = {
            setThisDstPrefix;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }


    table localPrefix_ternary {
        key = {
            hdr.ip.v4.srcAddr: ternary;
        }
        actions = {
            setLocalPrefix;
            NoAction;
        }
        default_action = NoAction();

        const entries = {
            0x0a000000 &&& 0xff000000 : setLocalPrefix(); //10.0.0.0/8
            0xac100000 &&& 0xfff00000 : setLocalPrefix(); //172.16.0.0/12
            0xc0a80000 &&& 0xffff0000 : setLocalPrefix(); //192.168.0.0/16
            // martian address.
            0x00000000 &&& 0xff000000 : setLocalPrefix(); //0.0.0.0/8
            0xc0000000 &&& 0xffffff00 : setLocalPrefix(); //192.0.0.0/24
            0xe0000000 &&& 0xf0000000 : setLocalPrefix(); //224.0.0.0/4
            0xf0000000 &&& 0xf0000000 : setLocalPrefix(); //240.0.0.0/4
        }
    }

    table AS2Key_exact {
        key = {
            meta.asn: exact;
        }
        actions = {
            getKey;
            NoAction;
        }
        size = 65535;
        default_action = NoAction();
    }

    table lastAS2Dst {
        key = {
            meta.dstAsn: exact;
        }
        actions = {
            setDstAsn;
            NoAction;
        }
        size = 65535;
        default_action = NoAction();
    }

    // Judge packets come from inner or Outer. 
    table switchIngressAsn_exact {
        key = {
            standard_metadata.ingress_port: exact;
        }
        actions = {
            setIngressAsn;
            NoAction;
        }
        size = 512;
        default_action = NoAction();
    }

    // Judge packets come from inner or Outer. 
    table switchEgressAsn_exact {
        key = {
            meta.egressPort: exact;
        }
        actions = {
            setEgressAsn;
            NoAction;
        }
        size = 512;
        default_action = NoAction();
    }

    apply {
        // if (hdr.ip.v4.isValid() && !hdr.myTunnel.isValid()) {
        //     // Process only non-tunneled ip.v4 packets.
        //     ip.v4_lpm.apply();
        // }

        // if (hdr.myTunnel.isValid()) {
        //     // Process all tunneled packets.
        //     myTunnel_exact.apply();
        // }
        initiate();
        if (hdr.ip.v4.isValid()) {
            ipv4Dst2AS_lpm.apply();
            switchIngressAsn_exact.apply();
            switchEgressAsn_exact.apply();
            if (meta.ingressAsn == (bit<32>)0x00 && meta.egressAsn != (bit<32>)0x00) {
                meta.isOutput = true;
            }
            if (meta.ingressAsn != (bit<32>)0x00 && meta.egressAsn == (bit<32>)0x00) {
                meta.isInput = true;
            }

            localPrefix_ternary.apply();
            if (meta.isLocalPrefix == true) {
                drop();
                exit;
            }
            thisSrcPrefix_lpm.apply();
            if (meta.isInput == true){ // input packet.
                thisDstPrefix_lpm.apply();
                ipv4Src2AS_lpm.apply();
                if (meta.isThisSrcPrefix == true) {
                    drop();
                    exit;
                }
                if (meta.isSrcDeploy == false) {
                    ipv4_forward(meta.dstAddr);
                    exit;
                }
                // //packets dst is not this AS.
                // else if (meta.isSrcDeploy == false || meta.isDstDeploy == true || meta.isLast == false) {
                //     ipv4_forward(meta.dstAddr);
                //     exit;
                // }
                // verify MAC
                meta.asn = meta.srcAsn;
            }
            else if(meta.isOutput == true){
                if (meta.isThisSrcPrefix == false) {
                    drop();
                    exit;
                }
                if (meta.isDstDeploy == false) {
                    ipv4_forward(meta.dstAddr);
                    exit;
                }
                // insert MAC.
                meta.asn = meta.dstAsn;
            }

            AS2Key_exact.apply();
    
            if (meta.isOutput == true) {
                insertIpv4MAC();
                ipv4_forward(meta.dstAddr);
            }
            else if(meta.isInput == true){
                verifyMAC();
                if (meta.verified == false) {
                    drop();
                    exit;
                }
                else {
                    ipv4_forward(meta.dstAddr);
                }
            }
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers  hdr, inout metadata meta) {
     apply {
             update_checksum(
	        hdr.ip.v4.isValid(),
            { hdr.ip.v4.version,
	          hdr.ip.v4.ihl,
              hdr.ip.v4.diffserv,
              hdr.ip.v4.totalLen,
              hdr.ip.v4.identification,
              hdr.ip.v4.flags,
              hdr.ip.v4.fragOffset,
              hdr.ip.v4.ttl,
              hdr.ip.v4.protocol,
              hdr.ip.v4.srcAddr,
              hdr.ip.v4.dstAddr },
            hdr.ip.v4.hdrChecksum,
            HashAlgorithm.csum16);

    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ip.v4);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
