/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>
#include "includes/header.p4"
#include "includes/parser.p4"
#include "includes/indexKey.p4"


register<time_t>(16) ctime;

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
    time_t  cctime;
    indexKey() indexKeyInstance;

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
        meta.isStub = false;
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
    action getIndex(time_t time) {
        meta.timestamp = time;
        tmp = hdr.ip.v4.srcAddr ++ time;
        tmp = tmp ^ meta.key[4095:4048];
        hash(meta.index, HashAlgorithm.crc16, (bit<16>)0, {tmp}, (bit<16>)256);
        meta.index = 256 - meta.index;
        // meta.MAC = meta.key[4095:4095-15]; //.................
    }
    action getKey(bit<4096> key) {
        meta.key = key;
    }
    action setDstAsn(asn_t asn) {
        if (asn != (asn_t)0)
        {
            meta.dstAsn = asn;
            meta.existMiddle = true;
        }
    }
    action insertIpv4MAC() {
        hdr.ip.v4.ihl = hdr.ip.v4.ihl + 2;
        hdr.ip.v4.totalLen = hdr.ip.v4.totalLen + 8;
        hdr.ipv4Opt.setValid();
        hdr.ipv4Opt.type = IPV4OPT_TYPE;
        hdr.ipv4Opt.len = IPV4OPT_LEN;
        hdr.ipv4Opt.timestamp = meta.timestamp;
        hdr.ipv4Opt.MAC = meta.MAC;
        hdr.ipv4Opt.nop = NOP;
        hdr.ipv4Opt.eop = EOP;
    }
    action verifyMAC() {
        if (meta.MAC == hdr.ipv4Opt.MAC) {
            meta.verified = true;
            hdr.ip.v4.ihl = hdr.ip.v4.ihl - 2;
            hdr.ip.v4.totalLen = hdr.ip.v4.totalLen - 8;
        }
    }

    action setIngressAsn(bit<32> asn) {
        meta.ingressAsn = asn;
    }

    action setEgressAsn(bit<32> asn) {
        meta.egressAsn = asn;
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

    apply {
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
                // if the input packet's src belongs to this as, or this packet's src is not belongs to the coming stub as, drop.
                if (meta.isThisSrcPrefix == true || (meta.isStub == true && meta.ingressAsn != meta.srcAsn)) {
                    drop();
                    exit;
                }
                if (meta.isThisDstPrefix == true && meta.isSrcDeploy == false) { //packets dst is this AS.
                    ipv4_forward(meta.dstAddr);
                    exit;
                }
                //packets dst is not this AS.
                else if (meta.isSrcDeploy == false || meta.isDstDeploy == true || meta.isLast == false) {
                    ipv4_forward(meta.dstAddr);
                    exit;
                }
                // verify MAC
                meta.asn = meta.srcAsn;
            }
            //Output packet.
            else if(meta.isOutput == true){
                if (meta.isThisSrcPrefix == false) {
                    ipv4_forward(meta.dstAddr);
                    exit;
                }
                if (meta.isDstDeploy == false) {
                    lastAS2Dst.apply();
                    if (meta.existMiddle == false) {
                        ipv4_forward(meta.dstAddr);
                        exit;
                    }
                }
                // insert MAC.
                meta.asn = meta.dstAsn;
            }

            AS2Key_exact.apply();
            ctime.read(cctime, 0);
            if (meta.isInput == true && cctime - hdr.ipv4Opt.timestamp >= 2) {
                drop();
                exit;
            }
            // get timesatamp depends on source address.
            if (meta.isInput == true) {
                getIndex(hdr.ipv4Opt.timestamp);
            }
            else if(meta.isOutput == true){
                getIndex(cctime);
            }
            // indexMAC
            indexKeyInstance.apply(meta);
    
            if (meta.isOutput == true) {
                insertIpv4MAC();
                ipv4_forward(meta.dstAddr);
            }
            else if(meta.isInput == true){
                if (hdr.ipv4Opt.isValid() == true) {
                    verifyMAC();
                    hdr.ipv4Opt.setInvalid();
                }
                else {
                    drop();
                    exit;
                }
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
	        hdr.ip.v4.isValid() && hdr.ipv4Opt.isValid() == false,
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

            update_checksum(
	        hdr.ipv4Opt.isValid(),
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
              hdr.ip.v4.dstAddr,
              hdr.ipv4Opt.type,
              hdr.ipv4Opt.len,
              hdr.ipv4Opt.timestamp,
              hdr.ipv4Opt.MAC,
              hdr.ipv4Opt.nop,
              hdr.ipv4Opt.eop},
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
        packet.emit(hdr.ipv4Opt);
        packet.emit(hdr.ipv6Oth);
        packet.emit(hdr.ipv6Dst);
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
