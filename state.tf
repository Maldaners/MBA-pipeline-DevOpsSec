terraform{
    backend "s3"{
        bucket = "bucket-teste-impacta"
        encrypt = true
        key = "terraform.tfstate"
        region = "sa-east-1"
    }
}