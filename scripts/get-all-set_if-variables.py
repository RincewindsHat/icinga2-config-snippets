#!/usr/bin/python3

import json
import requests
# from typing import List

url = "https://10.0.0.1"
credentials = ('user', 'password')

req = requests.get(url + ":5665/v1/objects/checkcommands", auth=credentials, verify=False)

jo = json.loads(req.text)

set_if_variables = []

for i in jo['results']:
    if "arguments" in i['attrs'] and i['attrs']['arguments']:
        arguments = i['attrs']['arguments']
        for j in arguments:
            if 'set_if' in arguments[j] and type(arguments[j]['set_if']) is str:
                set_if_variables.append(arguments[j]['set_if'].strip(' $'))


output = dict()

for idx, val in enumerate(set_if_variables):
    output[str(idx)] = {
                "varname": val,
                "caption": val,
                "datatype": "Icinga\\Module\\Director\\DataType\\DataTypeBoolean",
                "originalId": str(idx)
                }

output = {"Datafield": output}
print(json.dumps(output))
