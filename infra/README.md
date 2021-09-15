## Setting up an EC2 instance and configuring the DD Agent + HttpCheck
1. Setup an EC2 instance (t2.xlarge)
2. Setup a role and policy

3. DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=<DD-API-KEY> DD_SITE="datadoghq.com" bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"

5. Go to /etc/datadog-agent/conf.d/http_check.d

6. copy the contents from syntheticmonitoring/http_check/conf.yml to above location

7. sudo systemctl restart datadog-agent

8. sudo datadog-agent status