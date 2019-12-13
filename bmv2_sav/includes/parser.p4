/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/
#include "header.p4"
#ifndef PARSER_P4
#define PARSER_P4

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    // parse ethernet header, select parse type by etherType
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            (bit<16>)EtherType.IPV4: parse_ipv4;
            (bit<16>)EtherType.IPV6: parse_ipv6;
            default: accept;
        }
    }

    // parse ipv6 header
    state parse_ipv6 {
        packet.extract(hdr.ip.v6);
        transition select(hdr.ip.v6.nextHdr) {
            (bit<8>)Ipv6ExtType.DSTOPT: parse_ext;
            (bit<8>)Ipv6ExtType.HOPOPT: skip;
            default: accept;
        }
    }

    // parse ipv6 extension
    state skip {
        packet.extract(hdr.ipv6Oth);
        // if (hdr.ipv6Oth.nextHdr == Ipv6ExtType.DSTOPT){
        //     packet.advance(hdr.ipv6Oth.extLen);
        //     transition parse_ext;
        // }
        transition select (hdr.ipv6Oth.nextHdr) {
            (bit<8>)Ipv6ExtType.DSTOPT: parse_ext;
            _:                  accept;
        }
    }

    // parse ipv4 header
    state parse_ipv4 {
        packet.extract(hdr.ip.v4);
        transition select (hdr.ip.v4.ihl) {
            5: accept;
            _: parse_opt;
        }
    }

    // parse ipv6 extension header
    state parse_ext {
        packet.extract(hdr.ipv6Dst);
        transition accept;
    }

    state parse_opt {
        packet.extract(hdr.ipv4Opt);
        transition accept;
    }
}

#endif