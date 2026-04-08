/*
resource "aws_s3_bucket" "frontend" {
  bucket_prefix = "jenkins-bucket-andre-class7"
  force_destroy = true
  

  tags = {
    Name = "Jenkins Bucket"
  }
}*/

resource "aws_s3_bucket" "frontend" {
  bucket        = "jenkins-bucket-andre-class7-fixed"
  force_destroy = true

  tags = {
    Name = "Jenkins Bucket"
  }
}