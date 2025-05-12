terraform {  
  backend "s3" {  
    bucket       = "terraform-bucket-my-state-file"  
    key          = "statefile.tfstate"  
    region       = "us-east-1"  
    use_lockfile = true  #S3 native locking
  }  
}