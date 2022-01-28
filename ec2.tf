########## EC2  ##############################################
variable ami {
  type        = string
  default     = "ami-07d8796a2b0f8d29c"
  description = "Ubuntu 18.04 AMI"
}

resource "aws_instance" "db" {
  vpc_security_group_ids = [aws_security_group.instance.id]
  ami           = var.ami
  #bunu yoxla
  depends_on = [
    aws_nat_gateway.main-natgw
  ]
  key_name      = "${aws_key_pair.my-key.key_name}"
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  instance_type = "t3.micro"
  user_data = <<EOF
#!/bin/bash
apt update -y
sudo apt-get install mysql-server-5.7 -y
git clone https://github.com/javadovjavad/spring-petclinic.git
sudo sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

mysql -uroot <<MYSQL_SCRIPT
source spring-petclinic/src/main/resources/db/mysql/user.sql;
use petclinic;
source spring-petclinic/src/main/resources/db/mysql/schema.sql;
source spring-petclinic/src/main/resources/db/mysql/data.sql;
FLUSH PRIVILEGES;
INSERT INTO vets ( first_name, last_name) VALUES ( 'Javad', 'Cavad' );
MYSQL_SCRIPT
EOF

  tags = {
    Name = "Database"
  }
}

resource "aws_instance" "app" {
  vpc_security_group_ids = [aws_security_group.instance.id]
  ami           = var.ami
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  depends_on = [
    aws_instance.db
  ]
  key_name      = "${aws_key_pair.my-key.key_name}"
  user_data = <<EOF
#!/bin/bash
apt update && apt install default-jre -y && apt install maven -y 
cd /home/ubuntu
git clone https://github.com/javadovjavad/spring-petclinic.git 
cd spring-petclinic 
sed -i 's/localhost/${aws_instance.db.public_ip}/g' src/main/resources/application-mysql.properties
./mvnw  -DskipTests  spring-boot:run -Dspring-boot.run.profiles=mysql
EOF

  tags = {
    Name = "Application"
  }
}



resource "aws_key_pair" "my-key" {
	key_name = "terrakey"
	public_key = file("~/.ssh/id_rsa.pub")
}

