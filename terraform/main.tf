//specify region (us-west-2 is Oregon)
provider "aws" {
  region = "us-west-2"
}

//import public ssh key (needs to be named minecraft-server-key.pub)
resource "aws_key_pair" "minecraft_keypair" {
  key_name      = "minecraft-server-key"
  public_key    = file("~/minecraft-server-key.pub") //replace with the path to your ssh key if needed
}

resource "aws_security_group" "minecraft_server_sg" {
  name        = "minecraft_server_sec_gr"
  description = "Minecraft Server Security Group"

  // Default Inbound Rules
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Custom TCP Rule for Minecraft (port 25565)
  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Outbound Rules (default)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

//create the aws instance using the same settings as Project Part 1
resource "aws_instance" "automated-minecraft-server" {
  ami           = "ami-0eb9d67c52f5c80e5"  // Amazon Linux AMI ID
  instance_type = "t3.medium"
  vpc_security_group_ids = [aws_security_group.minecraft_server_sg.id]
  associate_public_ip_address = true
  key_name      = aws_key_pair.minecraft_keypair.key_name  
  tags = {
    Name = "automated-minecraft-server"
  }
}

//Output the public ip address to be used in the ini file
output "public_ip" {
  value = aws_instance.automated-minecraft-server.public_ip
}


