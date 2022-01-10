const creds = require("./creds.json")

//get the parameters
//console.log("vars are ", process.env)
if (!process.env.CE_DATA) {
  console.error("Usage: SOURCE=<source> TARGET=<target> DB_NAME=<db_name> node monitor.js")
  process.exit(1)
}
const env = JSON.parse(process.env.CE_DATA)

const source = env.SOURCE
const target = env.TARGET
const dbname = env.DB_NAME

console.log(source, target, dbname)

//do the params exist in the config

const sourceConfig = creds[`cloudant${source}_credentials`].value
const targetConfig = creds[`cloudant${target}_credentials`].value

if (!sourceConfig || !targetConfig) {
  console.error("Unknown location configs. Please check and retry")
  process.exit(2)
}

const replicatorKey = creds.replicatorKey.value
if (!replicatorKey) {
  console.error("Unknown replicator Key. Please check and retry")
  process.exit(3)

}

//create replication document
const doc =
{
  "_id": `${source}To${target}`,
  "continuous": true,

  "source": {
    "url": `${sourceConfig.url}/${dbname}`,
    "auth": {
      "iam": {
        "api_key": replicatorKey
      }
    }
  },
  "target": {
    "url": `${targetConfig.url}/${dbname}`,
    "auth": {
      "iam": {
        "api_key": replicatorKey
      }
    }
  }
}

//console.log(doc)

//create cloudant object with access credentials
const { CloudantV1 } = require('@ibm-cloud/cloudant')

const { IamAuthenticator } = require('ibm-cloud-sdk-core');
const authenticator = new IamAuthenticator({
  apikey: sourceConfig.apikey
});
const cloudant = new CloudantV1({
  authenticator: authenticator
});
cloudant.setServiceUrl(sourceConfig.url);

const main = async function () {
  const REPLICATOR_DB = "_replicator"
  let response
  try {
    console.log("trying to retrieve document")
    response = await cloudant.getDocument({ db: REPLICATOR_DB, docId: doc._id })
    console.log("document found!")
    const ERROR_STRINGS = ["error","failed"]
    if (ERROR_STRINGS.includes(response.result._replication_state)) {
      //try to update the replication document to re-trigger replication
      console.log("Re-uploading document..")
      doc._rev = response.result._rev  //add a rev to a document so it can be updated
      response = await cloudant.postDocument({ db: REPLICATOR_DB, document: doc })

    } else {
      console.log("Replication running and healthy!")
    }

  }
  catch (e) {
    //document not there, so add it
    console.log("document missing. Going to add it")
    response = await cloudant.postDocument({ db: REPLICATOR_DB, document: doc })
    console.log("Document added!")
  }

}

main()

//make it into a CE job!