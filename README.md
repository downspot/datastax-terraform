## ec2-instance 


Edit or create appropriate `*.tfvars` file formatting as follows:

```
instance_type = "i3.4xlarge"
security_group = "datastax-prod3-otl"
key_name = "datastax-prod-otl-east"
iam_instance_profile = "DS-OPS"
root_vol_size = "250"
storage_vol_size = "4096"
count = "3"
prd_code = "PRD362"
vpc = "DATASCIENCES-EAST"
key_path = "/home/ec2-user/.ssh/datastax-prod-otl-east.pem" 
termination_protection = "true"
```


File name formatting corresponds to environment, adjust accordingly:

dev-us-east-1.tfvars 


Deploy with:

`./deploy.sh <app name> <dev|preprod|prod> <us-east-1|us-west-2>`

Destroy with:

`./destory.sh <app name> <dev|preprod|prod> <us-east-1|us-west-2>`

Show with:

`./show.sh <app name> <dev|preprod|prod> <us-east-1|us-west-2>`

Plan with:

`./plan.sh <app name> <dev|preprod|prod> <us-east-1|us-west-2>`


### Notes

local ssh-agent must be running for remote execution on destroy if used
