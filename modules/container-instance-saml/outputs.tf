output "application_url" {
  description = "Where to reach the application in a browser."
  value       = local.app_public_url
}

output "sign_in_as" {
  description = "The identities that can sign in, and the application role each holds. Sign in as one of these at sign_in_url."
  value = merge(
    { for u in var.write_users : u => "Customers.Write" },
    { for u in var.read_users : u => "Customers.Read" },
    { for s in var.write_service_principals : s => "Customers.Write" },
    { for s in var.read_service_principals : s => "Customers.Read" },
  )
}
