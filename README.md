## aws-poc

I had 0 experience with AWS and Terraform before this little project.  
The learning was intense, but obviously it was worth it.  

This repository contains:
- `README.md` - What you're currently reading.
- `lambda.(py|zip)` - A simple script that returns the time, meant to serve as an AWS Lambda Function.
- `main.tf` - A Terraform deployment of 2 EC2 instances, 1 Lambda Function and 1 ALB to balance traffic between them.
- `populate_ansible_hosts.sh` - After running `terraform apply`, this script can pull the IPs of the instances into the `ansible/hosts` file.
- `ansible/*` - A rather simple NGINX deployment for the instances.
- `.gitignore` - To not have the `*terraform*` and `ansible/hosts` files around here.

The logic I chose to implement inside the ALB is this:
- If a request arrives to `/time` specifically, then it is always forwarded to the Lambda target group.
- Otherwise (and ideally to `/` because only `html/index.html` exists in the NGINXs), 50% of the requests are forwarded to the NGINX target group, and 50% are forwarded to the Lambda one.


### Prerequisites

- To connect to the instances (and as configured in `ansible/ansible.cfg`), I used `/opt/aws_poc_key.pem` as a private key file.
- To authenticate to AWS and allow the public key in the instances, I exported these variables from another file:
  ```
  AWS_ACCESS_KEY_ID="<...>"
  AWS_SECRET_ACCESS_KEY="<...>"
  AWS_DEFAULT_REGION="eu-central-1"
  TF_VAR_public_key="ssh-rsa <...>"
  ```


### Steps to deploy

- `terraform plan`
- `terraform apply`
- `./populate_ansible_hosts.sh`
- `cd ansible/`
- `ansible-playbook setup-nginx.yml`
- After the POC, `terraform destroy` if you want.

