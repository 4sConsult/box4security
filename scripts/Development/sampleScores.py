from datetime import datetime
import requests
import time
import json

vulnScores = [0.63] * 10 + [0.7] * 3 + [0.86] * 12 + [0.89] * 15 + [0.90] * 35 + [0.86] * 15
idsScores = [1] * 20 + [0.1] * 3 + [0.5] * 20 + [0.7] * 7 + [1] * 15 + [0.8] * 5 + [0.15] * 3 + [0.99] * 17
numVulnScores = len(vulnScores)
numIDSScores = len(idsScores)
assert numVulnScores == numIDSScores

done = False
while not done:
    print("Deleting previous scores..", end=' ', flush=True)
    try:
        r = requests.delete('http://localhost:9200/scores/')
        assert r.status_code < 400
    except requests.exceptions.ConnectionError:
        print("[FAILED] Is Elasticsearch running and healthy?")
        time.sleep(10)
        continue
    except AssertionError:
        if r.status_code == 404:
            pass
        else:
            print("[FAILED] (HTTP {})".format(r.status_code))
    print("[DONE]")

    print("Inserting scores index pattern..", end=' ', flush=True)
    try:
        _path_pattern = '/home/amadmin/box4s/config/dashboards/Patterns/scores.ndjson'
        _files = {'file': open(_path_pattern)}
        r = requests.post('http://localhost:5601/kibana/api/saved_objects/_import?overwrite=true', files=_files, headers={"kbn-xsrf": "true"})
        assert r.status_code < 400
    except requests.exceptions.ConnectionError:
        print("[FAILED] Is Kibana running and healthy?")
        time.sleep(10)
        continue
    except AssertionError:
        print("[FAILED] (HTTP {})".format(r.status_code))
        print(r.text)
    print("[DONE]")

    print("Inserting scores index mapping..", end=' ', flush=True)
    try:
        _path_mapping = '/home/amadmin/box4s/config/dashboards/Patterns/scores_mapping.json'
        _content = open(_path_mapping, 'r').read()
        r = requests.put('http://localhost:9200/scores')
        r = requests.put('http://localhost:9200/scores/_mapping', data=_content, headers={'Content-Type': 'application/json'})
        assert r.status_code < 400
    except requests.exceptions.ConnectionError:
        print("[FAILED] Is Elasticsearch running and healthy?")
        time.sleep(10)
        continue
    except AssertionError:
        print("[FAILED] (HTTP {})".format(r.status_code))
        print(r.text)
    print("[DONE]")

    print("Inserting prepared scores..", end=' ', flush=True)
    for t in range(numVulnScores):
        _vulnScore = {
            "score_type": "vuln_score",
            "value": round(vulnScores[t] * 100, 2),
            "timestamp": (int(datetime.utcnow().timestamp()) - (numVulnScores - t) * 24 * 60 * 60) * 1000,
            "rules": [{'text': 'Im Netzwerk existiert mindestens eine kritische Schwachstelle.'}]
        }
        _idsScore = {
            "score_type": "alert_score",
            "value": round(idsScores[t] * 100, 2),
            "timestamp": (int(datetime.utcnow().timestamp()) - (numIDSScores - t) * 24 * 60 * 60) * 1000,
            "rules": [{'text': 'Mindestens ein Alarm von hoher Schwere ist aufgetreten.'}]
        }
        _scores = [_vulnScore, _idsScore]
        for _score in _scores:
            try:
                r = requests.post('http://localhost:9200/scores/_doc', data=json.dumps(_score), headers={"Content-Type": "application/json"})
                assert r.status_code < 400
            except requests.exceptions.ConnectionError:
                print("[FAILED] Is elasticsearch running and healthy? Will retry in 10s..")
                time.sleep(10)
                break
            except AssertionError:
                print(r.text)
                print("[FAILED] (HTTP {}) . Data point: {}".format(r.status_code, json.dumps(_score)))
    done = True
    print("[DONE]")
