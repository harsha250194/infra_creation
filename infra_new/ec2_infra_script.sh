chmod 400 ~/${var.key_name}.pem
export DD_AGENT_MAJOR_VERSION=7
export DD_API_KEY='${var.ddapikey}'
export DD_SITE='datadoghq.com'
curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh
bash -c install_script.sh