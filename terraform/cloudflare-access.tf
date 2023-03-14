resource "cloudflare_access_organization" "knowhere" {
  name            = "knowhere.cloudflareaccess.com"
  auth_domain     = "knowhere.cloudflareaccess.com"
  is_ui_read_only = false

}

resource "cloudflare_access_group" "admin" {
  account_id = cloudflare_access_organization.knowhere.account_id
  name       = "Admin"
  include {
    email = ["kmanh999@gmail.com"]
  }
}
