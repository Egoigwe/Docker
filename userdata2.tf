locals {
  maven-script = <<-EDF
#!/bin/bash
sudo yum update -y
sudo yum upgrade -y
sudo yum install maven git -y
EDF
}