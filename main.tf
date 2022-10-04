# 1. create VPC (CIDR 10.0.0.0/16) 

resource "aws_vpc" "appache-vpc" {
    cidr_block = "10.0.0.0/16"
tags = {
    Name = "appache-vpc"
}
}




# 2. I am creating 2 public Subnets with cidr (10.0.1.0/24 and 10.0.02.0/24 in different AZs)

resource "aws_subnet" "sub-1-pub" {
    vpc_id = aws_vpc.appache-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
tags = {
    Name = "subnet-1-pub"
}
}

resource "aws_subnet" "sub-2-pub" {
    vpc_id = aws_vpc.appache-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
tags = {
    Name = "subnet-2-pub"
}
}

# Here i am creating 2 private Subnets for backend with cidr ('10.0.3.0/24' and '10.0.4.0/24'in diff AZs)

resource "aws_subnet" "sub-1-private"{
    vpc_id = aws_vpc.appache-vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = false
tags = {
    Name = "sub-1-private"
}
}

resource "aws_subnet" "sub-2-private" {
    vpc_id = aws_vpc.appache-vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "us-east-1b"
    map_public_ip_on_launch = false
tags = {
    Name = "sub-2-private"
}
}

# 3. Here i am creating an Iternet GateWay to attache to my appache vpc

resource "aws_internet_gateway" "my-igw" {
    vpc_id = aws_vpc.appache-vpc.id
tags = {
    Name = "my-igw"
}
}


# 4. I am creating a pubiic Route Table

resource "aws_route_table" "my-route-table1" {
    vpc_id = aws_vpc.appache-vpc.id
 route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.my-igw.id
}

tags = {
    Name = "my-tb1"
}
}

# 5. Now associating the my-route-table1 with public Subnets

resource "aws_route_table_association" "rt-asso-pub1" {
  subnet_id      = aws_subnet.sub-1-pub.id
  route_table_id = aws_route_table.my-route-table1.id
}

resource "aws_route_table_association" "rt-asso-pub2" {
  subnet_id      = aws_subnet.sub-2-pub.id
  route_table_id = aws_route_table.my-route-table1.id
}

# I am crating a Private route table and then Association it with private subnets

resource "aws_route_table" "my-route-table2" {
  vpc_id = aws_vpc.appache-vpc.id

  tags = {
    Name = "my-rt2"
  }
}

# Now associating the my-route-table2 with private Subnets

resource "aws_route_table_association" "rt-asso-pv1" {
  subnet_id      = aws_subnet.sub-1-private.id
  route_table_id = aws_route_table.my-route-table2.id
}

resource "aws_route_table_association" "rt-asso-pv2" {
  subnet_id      = aws_subnet.sub-2-private.id
  route_table_id = aws_route_table.my-route-table2.id
}

# 6. I am creating Security Group(appache-sg) for appache-VPC

resource "aws_security_group" "appache-sg" {
    name = "public-sg"
    description = "Allow traffic from VPC"
    vpc_id = aws_vpc.appache-vpc.id 
    depends_on = [
        aws_vpc.appache-vpc
        ]
ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
  }
  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "appache-sg"
  }
}

# 7. Creating security group for ALB

resource "aws_security_group" "SG-ALB" {
  name        = "SG-ALB"
  description = "security group for the load balancer"
  vpc_id      = aws_vpc.appache-vpc.id
  depends_on = [ aws_vpc.appache-vpc ]


  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "SG-ALB"
  }
}

# 8. Creating an EC2 instance for sub-1-pub(public subnet 1)

resource "aws_instance" "httpd-web-server-1" {
    ami = "ami-026b57f3c383c2eec"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.appache-sg.id]
    subnet_id = aws_subnet.sub-1-pub.id

    user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start
        systemctl enable
        echo '<h1>My Name is Marie i am a Certified SAA and Cloud Engineer</h1>' > /usr/share/nginx/html/index.html
        EOF
}

# 9. Creating an EC2 instance for sub-2-pub(public subnet 2)

resource "aws_instance" "httpd-web-server-2" {
  ami             = "ami-026b57f3c383c2eec"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.appache-sg.id]
  subnet_id       = aws_subnet.sub-2-pub.id

  user_data = <<-EOF
        #!/bin/bash
        yum update -y
        yum install httpd -y
        systemctl start
        systemctl enable 
        echo '<h1>I Marie Neuyou is a hardworking, determine, love learning person </h1>' > /usr/share/nginx/html/index.html
        EOF
}

# 10. Here i create  a LB 

resource "aws_lb" "ALB" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.appache-sg.id]
  subnets            = [aws_subnet.sub-1-pub.id, aws_subnet.sub-2-pub.id]

  tags = {
    Environment = "lb"
  }
}

resource "aws_lb_target_group" "TG" {
  name     = "my-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.appache-vpc.id
}

 # 11. Creating an ALB listener

resource "aws_lb_listener" "ALB-Listner" {
  load_balancer_arn = aws_lb.ALB.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target.arn
  }
}

# 12. creating a Target group

resource "aws_lb_target_group" "lb_target" {
  name       = "target"
  port       = "80"
  protocol   = "HTTP"
  vpc_id     = aws_vpc.appache-vpc.id
  health_check {
    interval            = 70
    path                = "/var/www/html/index.html"
    port                = 80
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60
    protocol            = "HTTP"
    matcher             = "200,202"
  }
} 
resource "aws_lb_target_group_attachment" "att-targets-1" {
  target_group_arn = aws_lb_target_group.lb_target.arn
  target_id        = aws_instance.httpd-web-server-1.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "att-targets-2" {
  target_group_arn = aws_lb_target_group.lb_target.arn
  target_id        = aws_instance.httpd-web-server-2.id
  port             = 80
}

# I am Creating a Database subnet group

resource "aws_db_subnet_group" "db_subnet" {
  name       = "db_subnet"
  subnet_ids = [aws_subnet.sub-1-private.id, aws_subnet.sub-2-private.id]
}
# Security group for database tier

resource "aws_security_group" "db_sg" {
  name        = "db_sg"
  description = "allow traffic only from web_sg"
  vpc_id      = aws_vpc.appache-vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.appache-sg.id]
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.appache-sg.id]
    cidr_blocks     = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Finally creating a database instance in private subnet 1

resource "aws_db_instance" "db1" {
  allocated_storage           = 5
  storage_type                = "gp2"
  engine                      = "mysql"
  engine_version              = "5.7"
  instance_class              = "db.t2.micro"
  db_subnet_group_name        = "db_subnet"
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  parameter_group_name        = "default.mysql5.7"
  db_name                     = "db_P18"
  username                    = "admin"
  password                    = "password"
  allow_major_version_upgrade = true
  auto_minor_version_upgrade  = true
  backup_retention_period     = 35
  backup_window               = "21:00-22:00"
  maintenance_window          = "Sun:00:00-Sun:03:00"
  multi_az                    = false
  skip_final_snapshot         = true
}
resource "aws_db_subnet_group" "db_subnets" {
  name       = "project"
  subnet_ids = [aws_subnet.sub-1-private.id, aws_subnet.sub-2-private.id]

  tags = {
    Name = "My DB subnet group"
  }
}