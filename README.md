# Course Project Part 2

## Background

For this project, we will be automating the provisioning, configuration, and setup of the Minecraft Server created in the Course Project Part 1. In order to do this, we will be using Terraform and Ansible to create an EC2 instance on AWS, download the Minecraft Server on the instance, and configure the server to start, restart, and shutdown gracefully. This tutorial will go into more detail on these steps in the following sections.

## Requirements

### What will the user need to configure the pipeline?

The user will need:

- an AWS Learner Lab account
- a Linux command line interface
- Installed Terraform, Ansible, and AWS CLI

### What tools should be installed?

- Terraform
- Ansible
- AWS Command Line Interface

### Are there any credentials or CLI required?

- The user will need AWS credentials, which can be found under the 'AWS Details' section of AWS Academy Learner Lab launch page. This includes an aws_access_key_id, aws_secret_access_key, and an aws_session_token.

- The user will also need an SSH key pair on their machine. This key pair needs to be called minecraft-server-key and be stored in the home directory. If the user wants to use a different key in a different directory, they can replace the path to their public key file in the main.tf script. The image below shows where to do this.

![pipeline_diagram](/images/ssh_key_path.png)

### Should the user set environment variables or configure anything?

The user will need to import their AWS credentials.

Example:
`export AWS_ACCESS_KEY_ID="insert-access-key-id"`
`export AWS_SECRET_ACCESS_KEY="insert-secret-access-key"`
`export AWS_SESSION_TOKEN="insert-session-token"`

Alternatively, you can copy and paste the credentials listed in the AWS Details section into ~/.aws/credentials

## Diagram of major steps in the pipeline

![pipeline_diagram](/images/pipeline_diagram.png)

1. **Install Resources**: Install Resources listed in the Requirements section
2. **Import Credentials (and create ssh key pair)**: Import AWS credentials using the steps listed in the Requirements section
3. **Provisioning to setup AWS Resources (Terraform)**: Use Terraform script (terraform/main.tf) to create an EC2 instance on AWS.
4. **Update Ansible Inventory File**: Give public IP address of new EC2 instance to Ansible so it can implement the configuration step.
5. **Configure EC2 Instance with Ansible**: Use Ansible to configure the EC2 instance. Install Java, set up the Minecraft server, and create a systemd service for Minecraft to ensure that it can start, restart, and shutdown gracefully.
6. **Start Minecraft Server with Ansible**: Use Ansible to start the Minecraft server
7. **Connect to the Minecraft Server**: Connect to the Minecraft Server using nmap (see tutorial below for more detail)

## Commands to run

**Before starting on these steps, make sure that you have ssh keys set up (refer to the Requirements section)**

1. **Navigate to the Terraform directory**
   `cd terraform`

   This folder has the file 'main.tf', which is a script to provision the new EC2 instance. 'main.tf' specifies the region of the EC2 instance ("us-west-2"), imports a public key, creates a security group, and specifies settings for the new instance. The security group specifies networking protocols, such as custom inbound rules. Lastly, it outputs the public ip address of the newly created instance, which is important for Ansible to be able to setup the Minecraft server on the instance.

2. **Initialize Terraform**
   `terraform init`

   Creates configuration files and initializes a Terraform working directory.

3. **View Terraform plan**
   `terraform plan`

   Creates a plan that will show what Terraform will do to create and setup the new EC2 instance. This will also make sure there are no errors in the Terraform file.

4. **Run Terraform script**
   `terraform apply`

   This will apply the commands written in the terraform script, essentially creating a new EC2 instance with the specifications listed in the main.tf file.

5. This script will output the public IP address of the EC2 instance that was just created. Copy this IP address.

6. Navigate to the inventory.ini file. Replace the 'insert.ip.address' with the copied IP address and replace the 'path/to/private/key' with the path to the private key on your machine. This will give Ansible the location of where to download and setup the Minecraft Server.
7. **Run the ansible script**
   `ansible-playbook -i inventory.ini minecraft_server.yaml`

   The minecraft_server.yaml file completes numerous tasks to install and setup the Minecraft Server.

   - Updates all packages to the latest version using yum
   - Installs Java (the same version used in Project Part 1: java-21-amazon-corretto-headless)
   - Creates a directory where the server.jar file can live
   - Downloads the Minecraft server in the newly created directory
   - Accepts the Minecraft EULA by creating a eula txt file and writing eula=true
   - Like in Part 1, this script creates a Minecraft service file.
   - The service file sets up auto-start using the same methods as Part 1. It makes sure that the unit waits for network connectivity before it starts the server.
   - The services file sets up restart on failure using the command: `Restart=on-failure`
   - The services file ensures a graceful shutdown by using the command: `ExecStop=/bin/kill -s SIGINT $MAINPID`. The ExecStop indicates the command needed to stop the service. In this case, the SIGINT signal will be sent to the main process.
   - The script then reloads the systemd daemon, enables the minecraft service, and starts the service.

## How to connect to the Minecraft Server once its running

Use the following command to connect to the Minecraft Server. Replace the public.ip.address with the public ip address of your EC2 instance.
`nmap -sV -Pn -p T:25565 public.ip.address`

## Resources Used

**Terraform**: To create the Terraform script, I referred to the steps I took in the Course Project Part 1 and used the Terraform docs to learn more about the init, plan, and apply commands. I also referred to a tutorial on LinkedIn that showed how to provision AWS EC2 instances with Terraform. I used ChatGPT to help me fix the syntax errors I was having.

- [Terraform Docs](https://developer.hashicorp.com/terraform/cli/commands/plan)
- [LinkedIn Tutorial](https://www.linkedin.com/pulse/how-provision-configure-aws-ec2-instance-using-terraform-%D0%B8%D0%B2%D0%B0%D0%BD%D0%BE%D0%B2/)
- ChatGPT

**.ini File**: To create the ini file, I used ChatGPT to help me understand what an .ini file is, why I needed to use it, and how I could format it for my project. I then used the Ansible Docs to help me understand which commands I should be using.

-[Ansible Docs](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/ini_inventory.html)

- ChatGPT

**Ansible File**: To write this file, I compiled all of the steps that I used to download and configure the minecraft server in Part 1 of the project. I used ChatGPT to help with the yaml syntax and to help fill in parts that I might have missed in the script. To figure out how to gracefully stop the program, I used an article about termination signals in Linux and an article about systemd units by Digital Ocean. I also used ChatGPT to create the ExecStop and TimeoutStopSec commands. To figure out how to restart on failure, I used a tutorial by DigitalOcean.

- [AWS Ansible Tutorial](https://dev.to/mariehposa/how-to-deploy-an-application-to-aws-ec2-instance-using-terraform-and-ansible-3e78)
- [Digital Ocean Article](https://www.digitalocean.com/community/tutorials/understanding-systemd-units-and-unit-files)
- [Digital Ocean Tutorial](https://www.digitalocean.com/community/tutorials/how-to-configure-a-linux-service-to-start-automatically-after-a-crash-or-reboot-part-1-practical-examples)
- ChatGPT
