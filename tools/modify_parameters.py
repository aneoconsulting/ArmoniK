import json
import argparse
import hcl2

parser = argparse.ArgumentParser(description="Modify ArmoniK paramters.tfvars.json")
parser.add_argument("inputfile", help="Path to the input paramters.tfvars file", type=str)
parser.add_argument("outputfile", help="Path to the output paramters.tfvars.json file", type=str)
parser.add_argument("--control-tag", dest="controltag", help="Tag for control plane image", type=str, default=None)
parser.add_argument("--control-img", dest="controlimg", help="registry/img for control plane image", type=str, default=None)
parser.add_argument("--worker-tag", dest="workertag", help="Tag for compute plane worker image", type=str, default=None)
parser.add_argument("--worker-img", dest="workerimg", help="registry/img for compute plane worker image", type=str, default=None)
parser.add_argument("--agent-tag", dest="agenttag", help="Tag for polling agent image", type=str, default=None)
parser.add_argument("--agent-img", dest="agentimg", help="registry/img for polling agent image", type=str, default=None)
args = parser.parse_args()

with open(args.inputfile, 'r') as fin:
    content = hcl2.load(fin)

if args.controlimg != None:
    content['armonik']['control_plane']['image'] = args.controlimg
if args.controltag != None:
    content['armonik']['control_plane']['tag'] = args.controltag

if args.agentimg != None:
    content['armonik']['compute_plane']['polling_agent']['image'] = args.agentimg
if args.agenttag != None:
    content['armonik']['compute_plane']['polling_agent']['tag'] = args.agenttag

if args.workertag != None or args.workerimg != None:
    workers = content['armonik']['compute_plane']['compute']
    for w in workers:
        if args.workertag != None:
            w['tag'] = args.workertag
        if args.workerimg != None:
            w['image'] = args.workerimg
    content['armonik']['compute_plane']['compute'] = workers

with open(args.outputfile, 'w') as fout:
    json.dump(content, fout, indent=2, sort_keys=True)