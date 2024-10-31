#declare variables 
variable access_key{
    type=string
    sensitive=true #meaning its value will be hidden in Terraform's output, logs, and state files

}  #we can say type=string in the curly braces to define variable type 
#the things we put in the curly brackets are optional
variable secret_key{
    sensitive=true
}        # Replace with your AWS secret access key (leave empty if using IAM roles or env vars)
variable region{
    default = "us-east-1"
}
variable instance_type{
    default = "t3.micro"

}
