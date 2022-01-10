resource "ibm_cloudant" "cloudantLondon" {
  name     = "cloudantLondon"
  location = "eu-gb"
  plan     = "standard"
  resource_group_id = ibm_resource_group.resource_group.id
}

resource "ibm_resource_key" "cloudantLondon_credentials" {
  name                  = "cloudantLondon-key"
  role                  = "Manager"
  resource_instance_id  = ibm_cloudant.cloudantLondon.id
}

output "cloudantLondon_credentials" {
  value = ibm_resource_key.cloudantLondon_credentials.credentials
  sensitive = true
}

resource "ibm_cloudant" "cloudantDallas" {
  name     = "cloudantDallas"
  location = "us-south"
  plan     = "standard"
  resource_group_id = ibm_resource_group.resource_group.id
}

resource "ibm_resource_key" "cloudantDallas_credentials" {
  name                  = "cloudantDallas-key"
  role                  = "Manager"
  resource_instance_id  = ibm_cloudant.cloudantDallas.id
}

output "cloudantDallas_credentials" {
  value = ibm_resource_key.cloudantDallas_credentials.credentials
  sensitive = true
}
