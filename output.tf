output "base_url" {
  description = "Base URL for API Gateway stage."
  value = "${aws_apigatewayv2_stage.lambda.invoke_url}/read?sheet_id=${var.google_sheet_id}&sheet_name=${var.google_sheet_name}"
}