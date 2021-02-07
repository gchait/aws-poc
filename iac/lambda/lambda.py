from dateutil.tz import gettz
from datetime import datetime

def handler(event, context):
    response = {
        "statusCode": 200,
        "statusDescription": "200 OK",
        "isBase64Encoded": False,
        "headers": {
            "Content-Type": "text/html; charset=utf-8"
        }
    }

    response["body"] = ("<html><head><title>The time in Israel is...</title>"
                        "<style>html, body {margin: 0; padding: 0;"
                        "font-family: Verdana; font-size: 50px;"
                        "font-weight: bold; text-align: center;}</style></head>"
                        f"<body><p>{datetime.now().astimezone(gettz('Israel'))}"
                        "</p></body></html>")
    return response

