# N8N Hands On

## Troubleshooting

### AWS Provisioning

In case of an error on provisioning:
````
cat /var/log/cloud-init-output.log
````


### GCP Provisioning

In case of an error on provisioning:
````
cat /var/log/syslog | grep startup-script
````


### Hashing password
````
node -e 'const bcrypt = require("bcryptjs"); console.log(bcrypt.hashSync("nLtM8AvFyL5wJ3In", 10));'
````


### Perform SQL Query

List schema:
````
sudo docker exec -it  docker-postgres-1 psql -U admin -d n8n -c "SELECT schema_name FROM information_schema.schemata;"
````

List tables:
````
sudo docker exec -it docker-postgres-1 psql -U admin -d n8n -c "\dt public.*"
````

List all projects:
````
sudo docker exec -it docker-postgres-1 psql psql -U admin -d n8n -c "SELECT * FROM project;"
````


### Import from JSON

````
n8n import:credentials --separate --input=/initial-data/credentials
n8n import:workflow --separate --input=/initial-data/workflows
````


### Backup DB

````
sudo docker exec postgres pg_dump -U admin n8n > /home/ubuntu/dump.sql
````

Download dump:
````
scp -i ~/.ssh/n8n-aws.key ubuntu@adresse_ip_serveur:/home/ubuntu/dump.sql ~/dump.sql
````


### Generate Initial SSL Certificate

If you don't have an original SSL certificate (fullchain.pem and privkey.pem), you have to generate one first.

- Run `sudo docker compose down`
- Comment the SSL block in your nginx default.conf file
- Run `sudo docker exec -it certbot sh`
- Run inside the container: `certbot certonly --webroot --webroot-path=/var/www/certbot --email votre-email@acme.com --agree-tos --no-eff-email -d acme.com`
- Files are generated in `/etc/letsencrypt/live/`


### Display AWS SES Credentials

````
terraform output ses_access_key_id
terraform output ses_secret_access_key
````


## Configuration

### Google Auth

https://docs.n8n.io/integrations/builtin/credentials/google/#oauth2-and-service-account


## Questions

- Install Python3
- Fix password for owner not correct hash
- Import workflow `docker exec -it -u node n8n n8n import:workflow --separate --input /yourfolder/here exec -it -u node n8n n8n update:workflow --all --active=true`
- Enable SSL


## How To

### Read Google Drive Result in Python

````
# Loop over input items and add a new field called 'my_new_field' to the JSON of each one
for item in _items:
  item["json"]["my_new_field"] = 1

print(_items)
  
return _items
````


## Links

- [N8N on AWS](https://medium.com/@yakuphanbilgic3/deploying-self-hosted-n8n-on-aws-ec2-using-terraform-with-domain-name-ai-starter-kit-0e0df1c367fa)
- [Workflow new video then summarize](https://n8n.io/workflows/8145-automate-meeting-summaries-with-google-drive-gemini-ai-and-google-docs/)
- [Workflow file drive](https://n8n.io/workflows/8145-automate-meeting-summaries-with-google-drive-gemini-ai-and-google-docs/)
