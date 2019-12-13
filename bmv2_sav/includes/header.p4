/* -*- P4_16 -*- */

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/
#ifndef HEADER_P4
#define HEADER_P4

const bit<16> TYPE_MYTUNNEL = 0x1212;
const bit<16> TYPE_IPV4 = 0x800;
const bit<32> MAX_TUNNEL_ID = 1 << 16;

const bit<1> IPV6EXT_CHG = 0x00;
const bit<2> IPV6EXT_ACTION = 0x00;
const bit<8> IPV4OPT_TYPE = 0x82;
const bit<8> IPV4OPT_LEN = 0x04;
const bit<8> NOP = 0x01;
const bit<8> EOP = 0x00;

enum bit<16> EtherType{
    VLAN = 0x8100,
    QINQ = 0x9100,
    MPLS = 0x8847,
    IPV4 = 0x0800,
    IPV6 = 0x86dd
}

enum bit<8> Ipv6ExtType{
    HOPOPT = 0x00,
    DSTOPT = 0x3c
}

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;
typedef bit<128> ip6Addr_t;
typedef bit<16> MAC_t;
typedef bit<32> asn_t;
typedef bit<16> time_t;

struct metadata {
    /* empty */
    // bool            srcInner;
    // bool            dstInner;
    bool            isInput;
    bool            isOutput;
    bit<32>         srcAsn;
    bit<32>         dstAsn;
    bool            isStub;
    bit<32>         stubAsn;
    bit<32>         asn; // used for index key.
    egressSpec_t    ingressPort;
    egressSpec_t    egressPort;
    bit<32>         ingressAsn;
    bit<32>         egressAsn;
    macAddr_t       dstAddr;
    bool            isSrcDeploy;
    bool            isDstDeploy;
    bit<4096>       key;
    bit<16>         index;
    bool            isLast;
    bool            isThisSrcPrefix;
    bool            isThisDstPrefix;
    bool            isLocalPrefix;
    MAC_t           MAC;
    time_t          timestamp;
    bool            existMiddle;
    bool            verified;
}



header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

header ipv6_t{
    bit<4> version;
    bit<8> trafficClass;
    bit<20> flowLabel;
    bit<16> payLoadLen;
    bit<8> nextHdr;
    bit<8> hopLimit;
    ip6Addr_t srcAddr;
    ip6Addr_t dstAddr;
}

header ipv6DstExt_t{
    bit<8> nextHdr;
    bit<2> act;
    bit<1> chg;
    bit<5> type;
    bit<8> extLen;
    MAC_t MAC;
}

header ipv6OthExt_t{
    bit<8> nextHdr;
    bit<8> option;
    bit<8> extLen;
}

header ipv4Opt_t {
    bit<8> type;
    bit<8> len;
    time_t timestamp;
    MAC_t MAC;
    bit<8> nop;
    bit<8> eop;
}

header_union IP_h{
    ipv4_t v4;
    ipv6_t v6;
}

struct headers {
    ethernet_t   ethernet;
    IP_h         ip;
    ipv6OthExt_t ipv6Oth;
    ipv6DstExt_t ipv6Dst;
    ipv4Opt_t    ipv4Opt;
}
#endif