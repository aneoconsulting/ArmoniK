import json
import argparse
import hcl2

parser = argparse.ArgumentParser(description="Modify ArmoniK paramters.tfvars.json")
parser.add_argument("inputfile", help="Path to the input paramters.tfvars file", type=str)
parser.add_argument("outputfile", help="Path to the output paramters.tfvars.json file", type=str)
parser.add_argument("--control-tag", dest="controltag", help="Tag for control plane image", type=str, default=None)
parser.add_argument("--control-img", dest="controlimg", help="registry/img for control plane image", type=str, default=None)
parser.add_argument("--compute-tag", dest="computetag", help="Tag for compute plane image", type=str, default=None)
parser.add_argument("--compute-img", dest="computeimg", help="registry/img for compute plane image", type=str, default=None)
parser.add_argument("--agent-tag", dest="agenttag", help="Tag for polling agent image", type=str, default=None)
parser.add_argument("--agent-img", dest="agentimg", help="registry/img for polling agent image", type=str, default=None)
args = parser.parse_args()

with open(args.inputfile, 'r') as fin:
    content = hcl2.load(fin)

if args.controlimg != None:
    content['armonik']['control_plane']['image'] = args.controlimg
if args.controltag != None:
    content['armonik']['control_plane']['tag'] = args.controltag

if args.computeimg != None:
    content['armonik']['compute_plane']['polling_agent']['image']
if args.computetag != None:
    content['armonik']['compute_plane']['polling_agent']['tag']

for c in content['armonik']['compute_plane']['compute']:
    if args.agenttag != None:
        c['tag'] = args.agenttag
    if args.agentimg != None:
        c['image'] = args.agentimg

with open(args.outputfile, 'w') as fout:
    json.dump(content, fout, indent=2, sort_keys=True)