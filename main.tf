terraform {
  backend "s3" {
    bucket         = "terraformt2tbucket"
    key            = "terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-db"
    encrypt        = true
  }
}



resource "aws_instance" "myInstance" {
  ami           = "ami-05d72852800cbf29e"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.sam_ssm_profile.name

  key_name = "deployer-one"
  user_data = <<-EOF
	#! /bin/bash
	echo hello
	sudo yum update -y
	sudo yum install -y docker
	sudo service docker start
	sudo docker run -p 8080:8080 somestupiddocker/terraform-aws-ec2-docker:latest

	EOF
	

}	

#policy is attached to a role, role is attached to a profile,profile is attached to ec2 instance...there can be n policies and n roles...

resource "aws_iam_policy" "sam_policy" {
  name = "sam_policy_name"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        }
    ]
})
}




resource "aws_iam_role" "sam_role" {
  name = "sam_ssm_role_name"

assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
managed_policy_arns = [aws_iam_policy.sam_policy.arn]

  tags = {
      tag-key = "tag-value"
  }
}

resource "aws_iam_instance_profile" "sam_ssm_profile" {
  name = "sam_ssm_profile_name"
  role = aws_iam_role.sam_role
}


provider "aws" {
  profile = "default"
  region  = "us-east-2"
}

resource "aws_security_group_rule" "myInstance" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks 		= ["0.0.0.0/0"]
  security_group_id = "sg-8594b8fa"
}


resource "aws_security_group_rule" "myInstance1" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  cidr_blocks 		= ["0.0.0.0/0"]
  security_group_id = "sg-8594b8fa"
}

module "key_pair" {

  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "deployer-one"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAiAistfEpeFZJQy9LvplAwVwPcALRbp7sN6E5Nw1Rf1/PQc8TFsfONo+FNXeqIuGbgZNpAglsNROyHQaldMDHlDF/GtUzsBpCplSYweDPcmhlLt9NToGqyZ+YA9VYzWdC20Sl/bajs9L3nuwJIaO0Gw7rbhbSMKwuGCJrNjJrvazj5yR5hvopJfdsWriCVekhdr/GqsKh651RE/vHRFzmPvlKUwciIHsYrt4sWv3Tl9PWnHT8uwx4xDE8KxEhD1ZaV66C8YPSpHearkSbpMLhXmMrU3GSS1Po108KBw2JYvNn7mIHNQ511Ag9bIkA/1TF9yHFlG8fVhjGWC8x5B/yvw=="

}


output "DNS" {
  value = aws_instance.myInstance.public_dns
}

output "ID" {
  value = aws_instance.myInstance.id
}
