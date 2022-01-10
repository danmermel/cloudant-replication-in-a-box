/// This set is for Cloudant Replication

resource "ibm_iam_service_id" "replicationServiceID" {
  name        = "replicationSID"
  description = "The service id that Cloudant will use to replicate between instances"
}

resource "ibm_iam_service_policy" "replicatorPolicy" {
  iam_service_id = ibm_iam_service_id.replicationServiceID.id
  roles          = ["Writer", "Reader"]


  resources {
    service = "cloudantnosqldb"
    resource_group_id = ibm_resource_group.resource_group.id

  }
}

resource "ibm_iam_service_api_key" "replicatorApiKey" {
  name = "replicatorkey"
  iam_service_id = ibm_iam_service_id.replicationServiceID.iam_id
}

output "replicatorKey" {
    value =   ibm_iam_service_api_key.replicatorApiKey.apikey
    sensitive = true
}


//// This set is for Code Engine and Container Registry

resource "ibm_iam_service_id" "deploymentServiceID" {
  name        = "deploymentSID"
  description = "The service id that Code Engine will use to access Container Registry"
}

resource "ibm_iam_service_policy" "deploymentPolicy" {
  iam_service_id = ibm_iam_service_id.deploymentServiceID.id
  roles          = ["Writer"]


  resources {
    region = "eu-gb"
    service = "container-registry"
  }
}

resource "ibm_iam_service_api_key" "deploymentApiKey" {
  name = "deploymentkey"
  iam_service_id = ibm_iam_service_id.deploymentServiceID.iam_id
}

output "containerKey" {
    value =   ibm_iam_service_api_key.deploymentApiKey.apikey
    sensitive = true
}