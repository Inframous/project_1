resource "aws_s3_bucket" "proj1bucket" {
  bucket = var.s3_bucket_name // Change this to your desired bucket name in the variables file
  force_destroy = true
  tags = {
    Name = "SQ S3 Bucket"
  }
}

resource "aws_s3_bucket_acl" "s3_bucket_acl" {
  bucket = aws_s3_bucket.proj1bucket.id
  acl    = "public-read-write"
}