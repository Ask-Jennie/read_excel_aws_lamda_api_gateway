import urllib.request
import json

def custom_response(code, payload=None):
    responseObject = {}
    responseObject['statusCode'] = code
    responseObject['headers'] = {}
    responseObject['headers']['Content-Type'] = 'application/json'
    responseObject['body'] = json.dumps({"payload": payload, "code": code})
    return responseObject


def get_params(event):
    params = {
        "sheet_id": "",
        "sheet_name": ""
    }
    if "queryStringParameters" in event and event["queryStringParameters"] != None:
        if "sheet_id" in event["queryStringParameters"]:
            source_id = event["queryStringParameters"]["sheet_id"]
            if not source_id:
                return False, custom_response(401, "Invalid Source ID")

            params["sheet_id"] = source_id

        if "sheet_name" in event["queryStringParameters"]:
            sheet_name =event["queryStringParameters"]["sheet_name"]
            if not sheet_name:
                return False, custom_response(401, "Invalid Source ID")

            params["sheet_name"] = sheet_name

    return params                

def lambda_handler(event, context):
    params = get_params(event)
    if len(params["sheet_id"]) < 3:
        return custom_response(400, "Missing Sheet ID")

    if len(params["sheet_name"]) < 3:
        return custom_response(400, "Missing Sheet Name")   

    SHEET_ID = params["sheet_id"]
    SHEET_NAME = params["sheet_name"]
    url = 'https://docs.google.com/spreadsheets/d/' + SHEET_ID + '/gviz/tq?tqx=out:csv&sheet=' + SHEET_NAME
    resp = urllib.request.urlopen(url)
    response = str(resp.read().decode('utf-8')).replace('"', "")
    keys = []
    jsonResp = {}
    for line in response.split("\n"):
        if len(keys) == 0:
            for key in (line.split(",")):
                keys.append(key)
        else:
            for key, value in zip(keys, line.split(",")):
                jsonResp[key] = value
    return custom_response(200, jsonResp)