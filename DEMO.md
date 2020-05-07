# Demonstration

## Pre-steps

Hide bookmarks

Run `./apply_cockroach.sh`

Make sure Admin UI and hello-app is up: `kubectl get pods`

Make sure db client is open in a terminal session
`kubectl exec -it cockroachdb-client-secure -- ./cockroach sql --certs-dir=/cockroach-certs --host=cockroachdb-public`

Forward ports
- kubectl port-forward cockroachdb-0 8080
- kubectl port-forward `kubectl get pods -l app=flask | grep appdeploy | head -1 | awk '{print $1}'` 5000

Make sure you can reach Admin UI and hello-app
- http://localhost:5000
- http://localhost:8080

Put "Goals for today" as tasks in the Todo hello-app

## Demo Slide

"Goals for today":
- Use a custom Certificate Authority
- Create a secure CockroachDB cluster on EKS
- Connect a Flask dockerized app to CockroachDB
- Test Resilience in case of a pod failure

## Show Application

- Let's start with the end state and show the hello-app
- "I have this little dinky todo App and I'm going to create a quick todo."
- Add a Todo in Web App
- For good measure let's see that record in the database - `select * from todos.todos;`
- Let's now remove the statefulsets, pods, services, etc and build it from scratch

`./remove_all.sh`

## Show custom CA and CRDB

  - Why is this important?
      - Security is always important
      - If a security feature is available you should try to enable it
      - Setting up wire encryption which is often referred to as TLS (Transport Layer Security) for inter node and client communication.

  - Show the CA setup in the comments of the StatefulSet
  https://github.com/cockroachdb/cockroach/blob/master/cloud/kubernetes/bring-your-own-certs/cockroachdb-statefulset.yaml
  - Setup custom certs first
    - CA, node and user certs
  - Then deploy your cluster

## Explain StatefulSet

  - Why is this important?
    - Useful stateful apps / engines / distributed systems like CockroachDB.
    - This creates pods with consistent identities for both networking and storage.

  - So what's in the Cockroach Stateful set?
    - Contains how CockroachDB pods should be deployed
      - Have Persistent Volume claims for those pods as well
    - Services for DNS and Load Balancing

## Show CockroachDB deployment

This self driving demo script will deploy the stateful set and then we'll take a look at the database.  Here are the steps it executes:
- 1 Create StatefulSet
- 2 Check out Admin UI
- 3 Deploy our hello-app / Todo Application
- 4 Kill a node
- 5 Show resilience in Admin UI

`./apply_cockroach.sh`
