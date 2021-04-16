import os
import requests

response = requests.post("https://cloudbuild.googleapis.com/v1/projects/carbide-ether-306312/triggers/deploy-main-branch-on-webhook:webhook", params={"secret": os.environ["SECRET"], "key": os.environ["API_KEY"]}, json={})


print(response.content.decode("utf-8"))
if response.status_code != 200:
    raise Exception("Bad status code " + str(response.status_code))
