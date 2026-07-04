# Terraform configuration for AWS resources
# Security group, EC2 instance, and Route 53 record for the Roboshop application

resource "aws_security_group" "allow_ports_firewall_roboshop" {
  name        = "allow_ports_firewall_roboshop"
  description = "Allow roboshop firewall inbound traffic and all outbound traffic"
  vpc_id      = "vpc-0fcbf944165ec4597"
  tags = {
    Name = "allow_ports_firewall_roboshop"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ports_firewall_roboshop" {
  security_group_id = aws_security_group.allow_ports_firewall_roboshop.id
  cidr_ipv4         = aws_vpc_security_group_egress_rule.allow_all_traffic_ipv4.cidr_ipv4
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ports_firewall_roboshop.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ports_firewall_roboshop.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


## Create EC2 instances for each component

resource "aws_instance" "instance" {
  for_each = var.components
  ami           = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  iam_instance_profile = var.iam_instance_profile
  vpc_security_group_ids = [aws_security_group.allow_ports_firewall_roboshop.id]
  tags = {
    Name = each.key
  }
}

## Create Route 53 record for each EC2 instance

resource "aws_route53_record" "a-records" {
  for_each = var.components
  zone_id = var.zone_id
  name    = "${each.key}-dev"
  type    = var.type
  ttl     = var.ttl
  records = [aws_instance.instance[each.key].public_ip]
}

# Provisioner to run splunk script on each EC2 instance after the EC2 instance is created and the Route 53 record is created. 
# This is the second step in the pipeline.

resource "null_resource" "splunk_provisioner" {

  depends_on = [aws_instance.instance
                  ,aws_route53_record.a-records
                  ,aws_security_group.allow_ports_firewall_roboshop
                  ,aws_vpc_security_group_ingress_rule.allow_ports_firewall_roboshop
                  ,aws_vpc_security_group_ingress_rule.allow_all_traffic_ipv4
                  ,aws_vpc_security_group_egress_rule.allow_all_traffic_ipv4]

  for_each = var.components

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/ec2-user/.ssh/aws-helpag.pem")
      host        = aws_instance.instance[each.key].public_ip
    }
    inline = [
      "sudo cloud-init status --wait",
      "for i in 1 2 3 4 5; do sudo dnf install -y nginx git && break || sleep 10; done",
      "sudo systemctl enable --now nginx",
      "rm -rf /home/ec2-user/splunk-script",
      "git clone https://github.com/kiranpanchavati9/splunk-script.git /home/ec2-user/splunk-script",
      "cd /home/ec2-user/splunk-script && chmod +x splunk.sh && sudo bash splunk.sh"
    ]
  }
  
}

