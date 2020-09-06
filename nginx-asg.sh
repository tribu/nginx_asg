#!/bin/bash
set -u -o pipefail


# Function to exit gracefully when there is an error
function die() {
    local retCode=$?
    echo "[ERROR]  $@" 1>&2
    if [[ $retCode == 0 ]] ; then
        retCode=1
    fi
    exit $retCode
}

# Function to create nginx asg and alb
function create_nginx_asg() {
     TERRAFORM_DIR="$(pwd)/provisioning/terraform/resources/$REGION/$NAME"
     # Set up terraform files to launch asg and alb
     mkdir -p $TERRAFORM_DIR
     FILE="$TERRAFORM_DIR/main.tf"
     MODULE_PATH="$(pwd)/provisioning/terraform/modules/nginx_asg/"

/bin/cat <<EOM >$FILE
variable "vpc_id" {
  description = "vpc id where the asg is launched"
  default     = "$VPC_ID"
}

variable "region" {
   description = "region where the above VPC is located"
   default     = "$REGION"
}

variable "ami_id" {
   description = "Ubuntu ami ID"
   default     = "$AMI_ID"
}

variable "instance_type" {
    description = "instance type on which nginx will be installed"
    default     = "$INSTANCE_TYPE"
 }
provider "aws" {
  region = var.region
}

module "nginx" {
  source   = "$MODULE_PATH"
  vpc_id   = var.vpc_id
  ami_id   = var.ami_id
}

output "nginx_alb_url" {
  value  =  "http://\${module.nginx.elb_dns_name}"
}
EOM

     cd $TERRAFORM_DIR
     terraform init || die "terraform initializing"
     terraform plan -out plan.out
     if [ "$?" -gt 0 ];then
     	die "Terraform plan failed. Exiting."
     fi
     echo "Do you want to apply the terraform changes?(yes/no)"
     read input
     if [ "$input" == "yes" ];then
     	echo "Running terraform apply"
     	terraform apply plan.out || die "Applying terraform plan"
        echo "[SUCCESS] Createed  Nginx asg $NAME"
     else
     	echo "Not received confirmation to continue. Exiting"
     fi
 }

# Function to destroy nginx asg and alb
function destroy_nginx_asg() {
       TERRAFORM_DIR="$(pwd)/provisioning/terraform/resources/$REGION/$NAME"
       cd $TERRAFORM_DIR || die "folder doesnot exist - $TERRAFORM_DIR"

       terraform init || die "terraform initializing"
       terraform plan -destroy -out plan.out
       if [ "$?" -gt 0 ];then
           die "Terraform destroy plan failed. Exiting."
       fi
       echo "Do you want to apply the terraform changes?(yes/no)"
       read input
       if [ "$input" == "yes" ];then
           echo "Running terraform apply"
           terraform apply plan.out || die "Applying terraform plan"
           cd "../"
           rm -rf $TERRAFORM_DIR || die "cannot delete folder $TERRAFORM_DIR"
           echo "[SUCCESS] Destroyed Nginx asg $NAME"
       else
           echo "Not received confirmation to continue. Exiting"
       fi

}


####### Main Program Starts Here ###############
# Extract options from command line
while getopts "n:r:v:a:i:d:h" opt
do
  case "$opt" in
    n)
      NAME="$OPTARG"
      ;;
    r)
      REGION="$OPTARG"
      ;;
    v)
      VPC_ID="$OPTARG"
      ;;
    a)
      AMI_ID="$OPTARG"
      ;;
    i)
      INSTANCE_TYPE="$OPTARG"
      ;;
    d)
      DESTROY="$OPTARG"
      ;;
    h)
      echo "Usage to create : $0 [-n name] [-r region ] [-v vpc_id] [-a ami_id] [-i instance_type] "
      echo "Usage to destroy : $0 [-d destroy] [-n name] [-r region ] [-v vpc_id] [-a ami_id] [-i instance_type] "
      exit
      ;;
    *)
      echo "Use -h to see options."
      exit 1
      ;;
  esac
done


if [[ $@ != *destroy* ]]; then
  create_nginx_asg
else
  destroy_nginx_asg
fi
