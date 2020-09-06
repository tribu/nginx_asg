# nginx_asg
CLI tool to create nginx asg in aws vpc

**PreRequisite** :

1. Need linux shell like sh, bash, zsh, gitbash etc…
2. Need IAM user/role with privileges to create Ec2 instance, Security Group, Launch Configuration, Auto Scaling Group and Load Balancers
3. Install latest terraform
4. Get the UBUNTU AMI ID from this link depending on the region : [https://cloud-images.ubuntu.com/locator/ec2](https://cloud-images.ubuntu.com/locator/ec2)
_The CLI was tested using 18.04 LTS AMD64 arch_
5. Get the AWS VPC where the nginx asg needs to be launched. _The assumption is there is at least one public subnet associated with this vpc_

**Diagram:**

When the CLI is successfully executed the nginx server is launched as an ASG with LoadBalancer as the point of accessing the index.html as shown in pic

![](RackMultipart20200906-4-rndf11_html_e83391ec936c67c3.png)

**Run** :

1. Download the folder
2. Run the command ./nginx-asg.sh -h to see the options

**Example command to create :**

./nginx-asg.sh -n rippling -r us-east-1 -v vpc-048c1bd88f5e1983e -a ami-06b263d6ceff0b3dd

**Example command to destroy :**

./nginx-asg.sh -d destroy -n rippling -r us-east-1 -v vpc-048c1bd88f5e1983e -a ami-06b263d6ceff0b3dd
