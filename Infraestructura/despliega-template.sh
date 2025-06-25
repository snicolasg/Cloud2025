#!/bin/bash
# Espero a que el contenedor de la App este listo y desde el me conecto al RDS luego le paso toda la configuracion de mysql para que funcione correctamente la App
kubectl wait --for=condition=ready pod ELIMINAR --timeout=60s
kubectl exec -it ELIMINAR -- bash -c "mysql -h BORRAR -u db_user -p'db_password' database_name < /var/www/html/dump.sql"