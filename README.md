```
ooooo                                      oooo  oooo              
`888'                                      `888  `888              
 888          .ooooo.   .ooooo.   .oooo.    888   888  oooo    ooo 
 888         d88' `88b d88' `"Y8 `P  )88b   888   888   `88.  .8'
 888         888   888 888        .oP"888   888   888    `88..8'
 888       o 888   888 888   .o8 d8(  888   888   888     `888'
o888ooooood8 `Y8bod8P' `Y8bod8P' `Y888""8o o888o o888o     .8'
                                                       .o..P'
                                                       `Y8P'
```

# Example: Deploy a SAML-powered CRM as a Container Instance within Locally

This example shows how to deploy [a sample SAML-powered CRM - `tombuildsstuff/customer-notes-crm-saml`](https://hub.docker.com/r/tombuildsstuff/customer-notes-crm-saml) as a Container Instance, to [Locally Build](https://locally.build).

It uses both the [Control Plane](https://locally.build/docs/features/control-plane-api) and the [Directory Emulator](https://locally.build/docs/data-plane-emulators/directory-emulator) within Locally to spin the container up as a Container Instance and to authenticate against it.

The application itself is a small CRM, which lists customers and lets you view or edit notes depending on your role. Two roles are available:

* `Customers.Read` - read-only access: browse and view notes.
* `Customers.Write` - full access: browse, add customers, and add or view notes.

Locally ships with some built-in Users and Groups, and this example seeds the following identities with the following roles:

| Sign in as | Role | What happens |
|---|---|---|
| **Default Identity** | `Customers.Write` | Full access: browse, add customers, add or view notes. |
| `ada.lovelace@…` | `Customers.Write` | Full access: browse, add customers, add or view notes. |
| `grace.hopper@…` | `Customers.Read` | Read-only: browse and view notes. |
| Any other user | *none* | Access denied by the identity provider. |

The application authenticates using SAML, so when you navigate to it you're prompted to pick the identity you want to authenticate as - the Default Identity, or one of the users above, will let you in.

## Requirements

* [Locally Build](https://locally.build).
* Either [HashiCorp Terraform](https://terraform.io) or [OpenTofu](https://opentofu.org).
* Either [Docker](https://www.docker.com) or [Podman](https://podman.io) (recommended).
* The Locally Plugin for `Microsoft.ContainerInstance` installed (`locally plugin install --name Microsoft.ContainerInstance`).

## Running the example

First up, we need to ensure our container runtime (Docker or Podman) is running, then launch Locally:

```bash
locally build
```

With Locally running, in another terminal we can initialise Terraform, which both downloads the providers we need and configures the module for use:

```bash
cd environments/locally
terraform init
```

> [!NOTE]
> It's possible to use OpenTofu here by substituting `terraform` for `tofu`.

With Terraform initialised, we can then provision the example by running:

```bash
locally run terraform apply
```

Once you approve the plan and the resources have been deployed, the application is running at the URL in the outputs:

```
https://locally-example-saml-group-berlin.gondola.locally:8080
```

If you [open that URL in a browser](https://locally-example-saml-group-berlin.gondola.locally:8080) you'll be redirected to Locally's Directory sign-in page, where you can pick which identity to sign in as. Since Locally is an emulator we're not concerned with you knowing the username or password for the user (although you can use it if you want) - just pick the identity you want and you're in. Once you're logged in, you can sign out from the header to switch to a different user.

## Tearing it down

```bash
cd environments/locally
locally run terraform destroy
```

The seeded users and groups are untouched; this example only looks up the existing identities.
