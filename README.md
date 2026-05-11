# N8N Hands On

## Troubleshooting

### AWS Provisioning

In case of an error on provisioning:
````
cat /var/log/cloud-init-output.log
````


### Hashing password
````
node -e 'const bcrypt = require("bcryptjs"); console.log(bcrypt.hashSync("nLtM8AvFyL5wJ3In", 10));'
````

## Links

- [N8N on AWS](https://medium.com/@yakuphanbilgic3/deploying-self-hosted-n8n-on-aws-ec2-using-terraform-with-domain-name-ai-starter-kit-0e0df1c367fa)