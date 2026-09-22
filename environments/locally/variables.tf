# NOTE: We're serving the Container Instance using HTTPS, meaning that we need to pick a
# certificate to front the Container Instance with - hence these values provided via
# `locally run`. We could also demonstrate this without HTTPS, but that's not a good demo.

variable "locally_tls_certificate_path" {
  description = "The path to the Locally TLS certificate, used to serve the Container Instance over HTTPS."
  type        = string
}

variable "locally_tls_certificate_key_path" {
  description = "The path to the private key for the Locally TLS certificate."
  type        = string
}
