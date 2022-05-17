from distutils.dir_util import copy_tree
from email import message
import json
import argparse
import hcl2
from jsonpath_ng import jsonpath, parse

class Expr:
    def __init__(self, value) -> None:
        s = value.split("=")
        if len(s) == 1 or len(s) > 2:
            raise Exception(message="attribute should be of the form key=value")
        self.key = s[0]
        self.val = s[1]

    def __repr__(self):
        return f'Expr( {self.key} : {self.val} )'

    def update(self, data):
        if self.val == "None":
            return
        if self.val == "null":
            expr = parse("$." + self.key)
            expr.update(data, None)
        else:
            expr = parse("$." + self.key)
            expr.update(data, self.val)



parser = argparse.ArgumentParser(description="Modify ArmoniK paramters.tfvars.json")
parser.add_argument("inputfile", help="Path to the input paramters.tfvars file", type=str)
parser.add_argument("outputfile", help="Path to the output paramters.tfvars.json file", type=str)
parser.add_argument("-kv", dest="exprs", help="Add key=value where k is the jsonpath key where to put the given value", action='append', type=Expr)
args = parser.parse_args()

with open(args.inputfile, 'r') as fin:
    content = hcl2.load(fin)

if args.exprs != None:
    for expr in args.exprs:
        expr.update(content)

with open(args.outputfile, 'w') as fout:
    json.dump(content, fout, indent=2, sort_keys=True)
