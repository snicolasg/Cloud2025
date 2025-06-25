#!/bin/bash

# Crea infraestructura
terraform init
terraform apply

# Crear el repositorio en AWS ECR
aws ecr create-repository --repository-name frontend

# Obtener el ID de la cuenta AWS
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"

# Capturo el enpoint del RDS para usarlo en la App 
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
RDS=$(echo $RDS_ENDPOINT | cut -d':' -f1)

# En la App agrego el endpoint del RDS
cd App/e-commerce-obligatorio/
cp config.php.template config.php
sed -i "s/BORRAR/$RDS/" config.php

# Construir la imagen con Podman
cd ..
podman build -t php-ecommerce -f Dockerfile

# Obtener el ID de la imagen llamada php-ecommerce
IMAGE_ID=$(podman images --format "{{.ID}}" php-ecommerce)
echo "Image ID: $IMAGE_ID"

# Autenticarse en AWS ECR
aws ecr get-login-password --region us-east-1 | podman login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Etiquetar la imagen para el repositorio en AWS ECR
podman tag $IMAGE_ID $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/frontend:latest

# Subir la imagen al registro de AWS ECR
podman push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/frontend:latest

# Construir la URI de la imagen
IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/frontend:latest"

# Reemplazar en el YAML que está un directorio más arriba
sed "s|IMAGE_PLACEHOLDER|$IMAGE_URI|" ../deployment-template.yaml > ../deployment.yaml

# Despliega RDS
cd ..
aws eks --region us-east-1 update-kubeconfig --name eks-cluster-Obligatorio2025
kubectl apply -f service.yaml

# Despliega App
aws eks --region us-east-1 update-kubeconfig --name eks-cluster-Obligatorio2025
kubectl apply -f deployment.yaml
kubectl apply -f hpa.yaml

# Modifico un script agregando el endpoint del RDS
CONTENEDOR=$(kubectl get pod -o jsonpath="{.items[0].metadata.name}")
cp despliega-template.sh despliega-temp.sh
sed -i "s/BORRAR/$RDS/; s/ELIMINAR/$CONTENEDOR/" despliega-temp.sh
bash despliega-temp.sh