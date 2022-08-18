export ARM_CLIENT_ID=$(cat spn.json | jq -r '.appId' )
export ARM_CLIENT_SECRET=$(cat spn.json | jq -r '.password' )
export ARM_TENANT_ID=$(cat spn.json | jq -r '.tenant' )
export TF_VAR_subscription_id=$(cat spn.json | jq -r '.subscription' )