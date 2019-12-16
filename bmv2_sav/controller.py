#! /usr/bin/env python2
import argparse
import grpc
import os
import sys
import json
from time import sleep, time

# Import P4Runtime lib from parent utils dir
# Probably there's a better way of doing this.
sys.path.append(
    os.path.join(os.path.dirname(os.path.abspath(__file__)),
                 '../utils/'))
import p4runtime_lib.bmv2 as bmv2
from p4runtime_lib.error_utils import printGrpcError
from p4runtime_lib.switch import ShutdownAllSwitchConnections
import p4runtime_lib.helper as helper
import p4runtime_lib.convert as convert
import p4runtime_lib.simple_controller as simple_controller
# SWITCH_TO_HOST_PORT = 1
# SWITCH_TO_SWITCH_PORT = 2

sw = ("s1", "s2", "s3", "s4", "s5_1", "s5_2", "s5_3", "s6_1", "s6_2", "s6_3")
p4prgm = {"s1": "stubSav", "s2": "basic", "s3": "basic", "s4": "stubSav",
                 "s5_1": "basic", "s5_2": "basic", "s5_3": "basic", "s6_1": "tranSav",
                  "s6_2": "tranSav", "s6_3": "tranSav"}
# self.p4info_helper = {}


class SwitchControl:
    """
        Attributes:
            sw       : string   // switch name
            sw_conf  : string   // switch configuration file
    """
    def __init__(self, sw, sw_conf):
        try:
            # Create a switch connection object for s1 and s2;
            # this is backed by a P4Runtime gRPC connection.
            # Also, dump all P4Runtime messages sent to switch to given txt files.
            self.sw_conf = sw_conf
            self.p4info_helper = helper.P4InfoHelper("./build/%s.p4.p4info.txt"%p4prgm[sw])
            self.sw_name = sw
            self.sw = bmv2.Bmv2SwitchConnection(
                name=self.sw_name,
                address='127.0.0.1:%d'% self.sw_conf['grpc_port'],
                device_id=sw_conf['device_id'],
                proto_dump_file='logs/%s-p4runtime-requests.txt'% sw)

            # Send master arbitration update message to establish this controller as
            # master (required by P4Runtime before performing any other write operation)
            self.sw.MasterArbitrationUpdate()

            # Install the P4 program on the switches
            """
            s1.SetForwardingPipelineConfig(p4info=self.p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
            print "Installed P4 Program using SetForwardingPipelineConfig on s1"
            s2.SetForwardingPipelineConfig(p4info=self.p4info_helper.p4info,
                                        bmv2_json_file_path=bmv2_file_path)
            print "Installed P4 Program using SetForwardingPipelineConfig on s2"
            """
            self.sw.SetForwardingPipelineConfig(p4info=self.p4info_helper.p4info,
                                            bmv2_json_file_path="./build/%s.json"%p4prgm[sw])
            # Write the rules that tunnel traffic from h1 to h2
            """
            writeTunnelRules(self.p4info_helper, ingress_sw=s1, egress_sw=s2, tunnel_id=100,
                            dst_eth_addr="08:00:00:00:02:22", dst_ip_addr="10.0.2.2")

            # Write the rules that tunnel traffic from h2 to h1
            writeTunnelRules(self.p4info_helper, ingress_sw=s2, egress_sw=s1, tunnel_id=200,
                            dst_eth_addr="08:00:00:00:01:11", dst_ip_addr="10.0.1.1")
            """
            # TODO Uncomment the following two lines to read table entries from s1 and s2
            # readTableRules(self.p4info_helper, s1)
            # readTableRules(self.p4info_helper, s2)

        except KeyboardInterrupt:
            print " Shutting down."
        except grpc.RpcError as e:
            printGrpcError(e)


    def readTableRules(self):
        """
        Reads the table entries from all tables on the switch.

        :param self.p4info_helper: the P4Info helper
        :param sw: the switch connection
        """
        print '\n----- Reading tables rules for %s -----' % self.sw.name
        for response in self.sw.ReadTableEntries():
            for entity in response.entities:
                entry = entity.table_entry
                # TODO For extra credit, you can use the self.p4info_helper to translate
                #      the IDs in the entry to names
                # print entry
                table_name = self.p4info_helper.get_name("tables", entry.table_id)
                print table_name
                print '-----'
                for i in entry.match:
                    print self.p4info_helper.get_match_field_name(table_name, i.field_id)
                    value = self.p4info_helper.get_match_field_value(i)
                    if type(value) != str:
                        value = convert.decodeIPv4(value[0])
                    else:
                        value = convert.decodeNum(value)
                    print value
                    print '*************'
                print '-----'


    def printCounter(self, counter_name, index):
        """
        Reads the specified counter at the specified index from the switch. In our
        program, the index is the tunnel ID. If the index is 0, it will return all
        values from the counter.

        :param self.p4info_helper: the P4Info helper
        :param sw:  the switch connection
        :param counter_name: the name of the counter from the P4 program
        :param index: the counter index (in our case, the tunnel ID)
        """
        for response in self.sw.ReadCounters(self.p4info_helper.get_counters_id(counter_name), index):
            for entity in response.entities:
                counter = entity.counter_entry
                print "%s %s %d: %d packets (%d bytes)" % (
                    self.sw.name, counter_name, index,
                    counter.data.packet_count, counter.data.byte_count
                )

    def syncTime(self, register_name, index, time):
        register_entry = self.p4info_helper.buildRegisterEntry(register_name, index, time)
        self.sw.WriteRegister(register_entry)

    def writeTableRules(self, dst_ip_addr):
        """
        Installs three rules:
        1) An tunnel ingress rule on the ingress switch in the ipv4_lpm table that
        encapsulates traffic into a tunnel with the specified ID
        2) A transit rule on the ingress switch that forwards traffic based on
        the specified ID
        3) An tunnel egress rule on the egress switch that decapsulates traffic
        with the specified ID and sends it to the host

        :param self.p4info_helper: the P4Info helper
        :param ingress_sw: the ingress switch connection
        :param egress_sw: the egress switch connection
        :param tunnel_id: the specified tunnel ID
        :param dst_eth_addr: the destination IP to match in the ingress rule
        :param dst_ip_addr: the destination Ethernet address to write in the
                            egress rule
        """
        # 1) Tunnel Ingress Rule
        table_entry = self.p4info_helper.buildTableEntry(
            table_name="MyIngress.ipv4_lpm",
            match_fields={
                "hdr.ipv4.dstAddr": (dst_ip_addr, 32)
            },
            action_name="MyIngress.drop")
        self.sw.WriteTableEntry(table_entry)
        print "Installed ingress tunnel rule on %s" % self.sw_name



def main(topology_file_path):
    # Instantiate a P4Runtime helper from the p4info file
    # self.p4info_helper = helper.P4InfoHelper(p4info_file_path)
    with open(topology_file_path) as f:
        topo = json.load(f)
    switches = topo['switches']
    swc = {}

    for sw, sw_conf in switches.items(): 
        swc[sw] = SwitchControl(sw, sw_conf)

    print "*******writing table rules******"
    swc['s2'].writeTableRules("127.0.0.0")
    while True:
        sleep(1)
        # print '\n----- Reading tunnel counters -----'
        # printCounter(self.p4info_helper, s1, "MyIngress.ingressTunnelCounter", 100)
        print "\n-------syncing time---------"
        ctime = str(int(time()*1000).__mod__(65536))
        for sw, swc in swc.items():
            if p4prgm[sw] != "basic":
                print "-------syncing %s-------" % sw
                swc.syncTime("MyIngress.ctime", 0, ctime)

    ShutdownAllSwitchConnections()

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='P4Runtime Controller')
    # parser.add_argument('--bmv2-json', help='BMv2 JSON file from p4c',
    #                     type=str, action="store", required=False,
    #                     default='./build/advanced_tunnel.json')
    parser.add_argument('--topology', help='Topology JSON file',
                        type=str, action="store", required=False,
                        default='./topology.json')
    args = parser.parse_args()

    if not os.path.exists(args.topology):
        parser.print_help()
        print "\n p4info file not found: %s\n Have you run 'make'?" % args.topology
        parser.exit(1)
    # if not os.path.exists(args.bmv2_json):
    #     parser.print_help()
    #     print "\nBMv2 JSON file not found: %s\nHave you run 'make'?" % args.bmv2_json
    #     parser.exit(1)
    main(args.topology)
