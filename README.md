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


## Configuration

### Google Auth

https://docs.n8n.io/integrations/builtin/credentials/google/#oauth2-and-service-account


## Questions

- Install Python3
- Fix route 53
- Import workflow `docker exec -it -u node n8n n8n import:workflow --separate --input /yourfolder/here exec -it -u node n8n n8n update:workflow --all --active=true`
- Enable SSL


## Links

- [N8N on AWS](https://medium.com/@yakuphanbilgic3/deploying-self-hosted-n8n-on-aws-ec2-using-terraform-with-domain-name-ai-starter-kit-0e0df1c367fa)
- [Workflow new video then summarize](https://n8n.io/workflows/8145-automate-meeting-summaries-with-google-drive-gemini-ai-and-google-docs/)
- [Workflow file drive](https://n8n.io/workflows/8145-automate-meeting-summaries-with-google-drive-gemini-ai-and-google-docs/)


docker run -d --name n8n -p 5678:5678 -e N8N_HOST=0.0.0.0 -e N8N_PORT=5678 -v ~/.n8n:/home/node/.n8n b57abeae1a4e