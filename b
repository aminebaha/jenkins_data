#!/bin/bash
set -e

# Démarrer Elasticsearch en arrière-plan
/elasticsearch/bin/elasticsearch &

# Attendre qu'Elasticsearch soit disponible
until curl -s http://localhost:9200/_cluster/health | grep -q '"status":"green"\|"status":"yellow"'; do
  echo "Waiting for Elasticsearch to start..."
  sleep 5
done

# Vérifier si le dépôt de snapshots existe, sinon le créer
if ! curl -s --head --fail "http://localhost:9200/_snapshot/my_repository"; then
  echo "Creating snapshot repository..."
  curl -X PUT "http://localhost:9200/_snapshot/my_repository" -H 'Content-Type: application/json' -d '
  {
    "type": "fs",
    "settings": {
      "location": "/path/to/your/snapshot/directory"
    }
  }'
fi

# Vérifier si la politique de snapshot existe, sinon la créer
if ! curl -s --head --fail "http://localhost:9200/_slm/policy/my_daily_snapshot_policy"; then
  echo "Creating snapshot policy..."
  curl -X PUT "http://localhost:9200/_slm/policy/my_daily_snapshot_policy" -H 'Content-Type: application/json' -d '
  {
    "schedule": "0 0 * * *",
    "name": "<daily-snapshot-{now/d{yyyy.MM.dd}}>",
    "repository": "my_repository",
    "config": {
      "indices": ["*"]
    },
    "retention": {
      "expire_after": "7d",
      "min_count": 1,
      "max_count": 100
    }
  }'
else
  echo "Snapshot policy already exists."
fi

# Mettre en avant-plan Elasticsearch pour que le conteneur reste actif
wait
