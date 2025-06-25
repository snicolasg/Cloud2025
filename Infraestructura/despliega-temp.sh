#!/bin/bash
# Espero a que el contenedor de la App este listo y desde el me conecto al RDS luego le paso toda la configuracion de mysql para que funcione correctamente la App
kubectl wait --for=condition=ready pod frontend-84dd6655f-wps94 --timeout=60s
kubectl exec -it frontend-84dd6655f-wps94 -- bash -c "mysql -h mi-db-principal.cp8c6iao66bm.us-east-1.rds.amazonaws.com -u db_user -p'db_password' database_name < /var/www/html/dump.sql"