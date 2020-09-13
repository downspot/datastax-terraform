instance_type = "m4.2xlarge"
security_group = "datastax-opscenter-dev"
key_name = "datastax-opscenter-east"
iam_instance_profile = "DS-OPS"
root_vol_size = "2048"
count = "3"
prd_code = "PRD362"
vpc = "DATASCIENCES-DEV-EAST"
key_path = "/home/ec2-user/.ssh/datastax-opscenter-east.pem" 
termination_protection = "true"