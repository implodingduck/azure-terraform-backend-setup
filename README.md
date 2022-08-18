# azure-terraform-backend-setup
Create SPN with Contributor
```
SUB_ID=$(az account show | jq -r '.id')
az ad sp create-for-rbac -n "implodingduck-ghactions-spn" --role Contributor --scopes subscriptions/$SUB_ID
```

Paste contents into spn.json

```
source sp-login.sh
cd terraform
terraform init
terraform apply
```

