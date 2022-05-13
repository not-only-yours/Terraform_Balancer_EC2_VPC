# Terraform_Balancer_EC2_VPC

For using this config you need to add aws credentials to <mark>main.tf</mark>

```
provider "aws" {
  region = ...  #Paste region
  access_key = ... #paste access key
  secret_key = ... #paste secret key
}
```
for build use command
```
terraform apply
```
