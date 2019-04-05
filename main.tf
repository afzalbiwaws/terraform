provider "aws" {
  access_key = "AKIAVS5XCFYESSO5LV5I"
  secret_key = "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"
  region     = "us-west-2"
}

resource "aws_vpc" "second" {
  cidr_block       = "192.168.0.0/16"

  tags = {
    Name = "second"
  }
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = "${aws_vpc.second.id}"

  tags = {
    Name = "myigw"
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = "${aws_vpc.second.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.myigw.id}"
  }

  tags = {
    Name = "public_route"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = "${aws_vpc.second.id}"
  availability_zone = "us-west-2a"
  cidr_block = "192.168.1.0/24"


  tags = {
    Name = "subnet1"
  }
}

resource "aws_route_table_association" "subnetassociation" {
  subnet_id      = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.public_route.id}"
}


resource "aws_security_group" "allow" {
  name        = "allow"
  description = "Allow TLS inbound traffic"
  vpc_id      = "${aws_vpc.second.id}"

  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"] # add a CIDR block here
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
   # prefix_list_ids = ["pl-12c4e678"]
  }
}

resource "aws_instance" "test" {

  ami                    = "ami-0ea790e761025f9ce"
  instance_type          = "t2.micro"
  subnet_id              ="${aws_subnet.subnet1.id}"
  key_name               = "terraform"
  vpc_security_group_ids = ["${aws_security_group.allow.id}"]
  associate_public_ip_address = true
  
}

output "url" {
  value = "http://${aws_instance.test.public_ip}"
}