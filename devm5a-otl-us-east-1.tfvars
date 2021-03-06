instance_type = "m5a.xlarge"
security_group = "datastax-devm5a-otl"
key_name = "datastax-dev-otl-east"
iam_instance_profile = "DS-OPS"
root_vol_size = "50"
storage_vol_size = "100"
count = "3"
prd_code = "PRD362"
vpc = "DATASCIENCES-DEV-EAST"
key_path = "/home/ec2-user/.ssh/datastax-dev-otl-east.pem" 
termination_protection = "false"
