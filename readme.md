# Read Excel via AWS Lamda and API gateway using Terraform

The automation helps user to automate AWS Lamda and AWS API gateway deployment using terraform to read a public listed excel file.

## Download Command.

```jennie terraform automations download read_excel_aws_lamda_api_gateway```

**make sure to run the command inside project**

## How to use

To use the automation you need create an [IAM](https://us-east-1.console.aws.amazon.com/iamv2) user on your AWS Account.
Make sure the IAM Use has permission for 

- AWSLambda_FullAccess
- AmazonAPIGatewayInvokeFullAccess

Also make sure you have installed [Terraform](https://developer.hashicorp.com/terraform/downloads) properly

Once done download credentials.

### Download automation

```jennie terraform automations download read_excel_aws_lamda_api_gateway```

### Initialize terraform 

```terraform init```

### Create Credentials file 

create a file with name `credentials` and dump your aws key and secret.
**make sure you keep the file safe locally, do not upload it anywhere**

```
[testing]
aws_access_key_id = <YOUR_AWS_ACCESS_KEY>
aws_secret_access_key = <YOUR_AWS_ACESS_SECRET>
```

### Update Google Sheet ID and Name.

Update the name and id of google sheet which you want to read as json.
make sure the first row in google sheet is filled with column name.

Open `terraform.tfvars` and replace `<SHEET_NAME>` and `<SHEET_ID>` with desired sheet name and id.
One could also update rest of the variables.

## Finally Deply

deploy the terraform configration to aws using 

`terraform apply -var-file=terraform.tfvars -auto-approve`