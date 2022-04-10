[![k3s Matrix Testing](https://github.com/dfroberg/tinjis/actions/workflows/k3s-test.yaml/badge.svg)](https://github.com/dfroberg/tinjis/actions/workflows/k3s-test.yaml)
[![ci](https://github.com/dfroberg/tinjis/actions/workflows/dockerbuild.yaml/badge.svg)](https://github.com/dfroberg/tinjis/actions/workflows/dockerbuild.yaml)
[![Manifest Validation](https://github.com/dfroberg/tinjis/actions/workflows/manifests-validation.yaml/badge.svg)](https://github.com/dfroberg/tinjis/actions/workflows/manifests-validation.yaml)

# Preface

We're really happy that you're considering to join us! Here's a challenge that will help us understand your skills and serve as a starting discussion point for the interview.

We're not expecting that everything will be done perfectly as we value your time. You're encouraged to point out possible improvements during the interview though!

Have fun!

## The challenge

Pleo runs most of its infrastructure in Kubernetes. It's a bunch of microservices talking to each other and performing various tasks like verifying card transactions, moving money around, paying invoices ...

We would like to see that you both:
- Know how to create a small microservice
- Know how to wire it together with other services running in Kubernetes

We're providing you with a small service (Antaeus) written in Kotlin that's used to charge a monthly subscription to our customers. The trick is, this service needs to call an external payment provider to make a charge and this is where you come in.

You're expected to create a small payment microservice that Antaeus can call to pay the invoices. You can use the language of your choice. Your service should randomly succeed/fail to pay the invoice.

On top of that, we would like to see Kubernetes scripts for deploying both Antaeus and your service into the cluster. This is how we will test that the solution works.

## Instructions

Start by forking this repository. :)

1. Build and test Antaeus to make sure you know how the API works. We're providing a `docker-compose.yml` file that should help you run the app locally.
2. Create your own service that Antaeus will use to pay the invoices. Use the `PAYMENT_PROVIDER_ENDPOINT` env variable to point Antaeus to your service.
3. Your service will be called if you invoke `/rest/v1/invoices/pay` call on Antaeus. You can probably figure out which call returns the current status invoices by looking at the code ;)
4. Kubernetes: Provide deployment scripts for both Antaeus and your service. Don't forget about Service resources so we can call Antaeus from outside the cluster and check the results.
    - Bonus points if your scripts use liveness/readiness probes.
5. **Discussion bonus points:** Use the README file to discuss how this setup could be improved for production environments. We're especially interested in:
    1. How would a new deployment look like for these services? What kind of tools would you use?
    2. If a developers needs to push updates to just one of the services, how can we grant that permission without allowing the same developer to deploy any other services running in K8s?
    3. How do we prevent other services running in the cluster to talk to your service. Only Antaeus should be able to do it.

## How to run

If you want to run Antaeus locally, we've prepared a docker compose file that should help you do it. Just run:
```
docker-compose up
```
and the app should build and start running (after a few minutes when gradle does its job)

## How we'll test the solution

1. We will use your scripts to deploy both services to our Kuberenetes cluster.
2. Run the pay endpoint on Antaeus to try and pay the invoices using your service.
3. Fetch all the invoices from Antaeus and confirm that roughly 50% (remember, your app should randomly fail on some of the invoices) of them will have status "PAID".


# Solution
## Some quirks
The `private fun payInvoices()` in `antaeus/pleo-antaeus-rest/src/main/kotlin/io/pleo/antaeus/rest/AntaeusRest.kt` was modified to work as a proper batch job dispatcher.

It felt like that was the intended function, so one call to `/rest/v1/invoices/pay` will attempt to pay all PENDING invoices.

Also it seems that enum classes needs an added .toString() to be properly converted in an mapOf. Sorry for taking so long but I kind of got lost in the usual dependency rabbit hole while trying to figure that one out *sigh*.

I'm not a Kotlin coder so any changes can probably be MUCH prettier and elegant!

## Some Improvements
### Done
* API Token - Super Simplistic and Static but configurable 1:1 per deployment-
* Batch Payments - Wont fail on first error.
* End to End Tests - Simply run ./k8s-test.sh to test all functions.
* NetworkPolicy - Applied an Network Policy to restrict who can talk to the Payment service.
* Github Action
    * Runs end to end test by creating a one node k3s cluster, deploying the manifests and running the tests.
    * Rudimentary docker image build and push action.

### Suggested
* Depending on the number of DIFFERENT installations and environments of the services.
    * High number of deployments: I'd suggest creating a helm chart to make it more customizable.
    * One off deployments: it's probably more maintainable to run it of GitOps with kustomizations.
* To increase security;
    * it is recommenced to implement mTLS, so all internal communications are encrypted.
    * And regular TLS for endpoints.
    * Secrets management to ingest secrets on runtime. Vault, SOPS etc.
* Developer security
    * Handled by repo permissions and splitting repos.
* Monitoring
    * Add prometheus scrape endpoints to services and have them report KPIs.
* Automation
    * CI/CD via one of the many offerings to automate builds, tests and push.

## Deploy to K8s
To use the prebuilt images and deploy to your Kuberenetes cluster.
Everything will be deployed to the `payments` namespace.

#### If needed get access to your cluster of choice, modify as needed
~~~
export KUBECONFIG=~/cluster/kubeconfig
~~~
#### Use the source Luke
~~~
git clone https://github.com/dfroberg/tinjis.git
~~~
#### Check all the manifests
~~~
./k8s-check.sh
~~~
Should return something like;
~~~
namespace/payments created (dry run)
networkpolicy.networking.k8s.io/payments-network-policy created (dry run)
secret/common-payments-secret created (dry run)
configmap/antaeus-config-map created (dry run)
deployment.apps/antaeus created (dry run)
service/antaeus-service created (dry run)
deployment.apps/payments created (dry run)
service/payments-service created (dry run)
~~~
#### Deploy manifests
~~~
./k8s-deploy.sh
~~~
Should return;
~~~
namespace/payments created
networkpolicy.networking.k8s.io/payments-network-policy created
secret/common-payments-secret created
configmap/antaeus-config-map created
deployment.apps/antaeus created
service/antaeus-service created
deployment.apps/payments created
service/payments-service created
~~~
#### Service ingress
You need to modify the ingress manifest to fit your environment.
~~~
nano manifests/antaeus-ingress.yaml
~~~
or simply add an entry to your /etc/hosts that corresponds to the hostname in the antaeus-ingress.yaml, which is *antaeus.local*.

Then apply;
~~~
kubectl apply -f manifests/antaeus-ingress.yaml
~~~
Should return;
~~~
ingress.networking.k8s.io/antaeus-ingress created
~~~
#### Delete all the manifests
~~~
./k8s-destroy.sh
~~~
Should return;
~~~
deployment.apps "antaeus" deleted
deployment.apps "payments" deleted
service "antaeus-service" deleted
service "payments-service" deleted
secret "common-payments-secret" deleted
configmap "antaeus-config-map" deleted
networkpolicy.networking.k8s.io "payments-network-policy" deleted
namespace "payments" deleted
~~~
# Test Kubernetes deployment
As the payment component due to the Network Policy will not allow access directly to it from outside the pod it has to be tested via antaeus service exposure or ingress.

## Run antaeus tests
If a portforward is active to antaeus the tests will use that regardless if a ingress has been created or not. Simply terminate the portforward to use ingress. If neither exists you'll get instructions when running the test.

~~~
./k8s-tests.sh
~~~
Should return something similar to;
~~~
► Testing Antaeus availability...
antaeus-6fd48d47d5-b9fdz using dfroberg/pleo-antaeus:latest image is available on port 8000
antaeus-service is available on port 8000
► Testing Payment availability...
payments-7cff684d48-p756q using dfroberg/pleo-payment:latest image is available on port 9000
antaeus-service is available on port 9000
► Testing accessibility...
► Ingress: antaeus-ingress defined and is exposed on host antaeus.local
► Testing API Endpoints:
► Testing http://antaeus.local/rest/health ...
"ok"
 ✔ Passed
► Testing http://antaeus.local/rest/v1/Customers ...
[{"id":1,"currency":"USD"},{"id":2,"currency":"DKK"}]
 ✔ Passed
► Testing http://antaeus.local/rest/v1/Customers/1 ...
{"id":1,"currency":"USD"}
 ✔ Passed
► Testing http://antaeus.local/rest/v1/invoices ...
[{"id":1,"customerId":1,"amount":{"value":292.97,"currency":"USD"},"status":"PAID"},{"id":2,"customerId":1,"amount":{"value":22.20,"currency":"USD"},"status":"PENDING"},{"id":3,"customerId":1,"amount":{"value":236.08,"currency":"USD"},"status":"PENDING"},{"id":4,"customerId":1,"amount":{"value":98.38,"currency":"USD"},"status":"PENDING"},{"id":5,"customerId":1,"amount":{"value":325.23,"currency":"USD"},"status":"PENDING"},{"id":6,"customerId":2,"amount":{"value":126.93,"currency":"DKK"},"status":"PAID"},{"id":7,"customerId":2,"amount":{"value":22.94,"currency":"DKK"},"status":"PENDING"},{"id":8,"customerId":2,"amount":{"value":118.84,"currency":"DKK"},"status":"PENDING"},{"id":9,"customerId":2,"amount":{"value":203.34,"currency":"DKK"},"status":"PENDING"},{"id":10,"customerId":2,"amount":{"value":400.86,"currency":"DKK"},"status":"PENDING"}]
 ✔ Passed
► Testing http://antaeus.local/rest/v1/invoices/1 ...
{"id":1,"customerId":1,"amount":{"value":292.97,"currency":"USD"},"status":"PAID"}
 ✔ Passed
► Testing Payments: Show distribution of INVOICE_STATUS
► Testing http://antaeus.local/rest/v1/invoices ...
{ "status": "PAID", "count": 2 } { "status": "PENDING", "count": 8 }

✔ Done
► Testing Payments: Making a payment call
► Testing http://antaeus.local/rest/v1/invoices/pay ...
false

✔ Done
► Testing Payments: Show distribution of INVOICE_STATUS
► Testing http://antaeus.local/rest/v1/invoices ...
{ "status": "PAID", "count": 4 } { "status": "PENDING", "count": 6 }

✔ Done
~~~

# Local Deployment
## Images
### Targets
* docker.io/dfroberg/pleo-antaeus:latest
* docker.io/dfroberg/pleo-payment:latest
### Build and Push all Images
Will traverse thourg the components and execute their local build.sh scripts.
~~~
./buildandpushall.sh
~~~
## Test Components
### Test PaymentProvider Localy
Start services locally:
~~~
git clone https://github.com/dfroberg/tinjis.git
docker-compose up
~~~
Send test payload
~~~
curl -X POST http://127.0.0.1:9000/ -H 'X-Token: TestToken' -H 'Content-Type: application/json' -d '{"customer_id":1,"currency":"USD", "value":1.25}'
~~~
Logs of payment service should show;
~~~
2022/04/05 06:57:51 Authenticated user antaeus
{"customer_id":1,"currency":"USD", "value":1.25}
~~~
Return should be either of;
~~~
{"result":"false"}
{"result":"true"}
~~~
Without token return status should be *Forbidden* and logs should show;
~~~
2022/04/05 06:57:24 Unauthenticated user
~~~
### Test Anteaus Localy
#### List a specific invoice
~~~
curl -X GET http://127.0.0.1:8000/rest/v1/invoices/1
~~~
Should return;
~~~
{"id":1,"customerId":1,"amount":{"value":340.51,"currency":"USD"},"status":"PAID"}
~~~
####  List all invoices
~~~
curl -X GET http://127.0.0.1:8000/rest/v1/invoices
~~~
Should return;
~~~
[{"id":1,"customerId":1,"amount":{"value":340.51,"currency":"USD"},"status":"PAID"},{"id":2,"customerId":1,"amount":{"value":401.82,"currency":"USD"},"status":"PENDING"},{"id":3,"customerId":1,"amount":{"value":79.55,"currency":"USD"},"status":"PENDING"},{"id":4,"customerId":1,"amount":{"value":320.71,"currency":"USD"},"status":"PENDING"},{"id":5,"customerId":1,"amount":{"value":433.92,"currency":"USD"},"status":"PENDING"},{"id":6,"customerId":2,"amount":{"value":375.24,"currency":"DKK"},"status":"PAID"},{"id":7,"customerId":2,"amount":{"value":66.34,"currency":"DKK"},"status":"PENDING"},{"id":8,"customerId":2,"amount":{"value":487.03,"currency":"DKK"},"status":"PENDING"},{"id":9,"customerId":2,"amount":{"value":499.51,"currency":"DKK"},"status":"PENDING"},{"id":10,"customerId":2,"amount":{"value":249.74,"currency":"DKK"},"status":"PENDING"}]
~~~
#### Attempt to pay all invoices
~~~
curl -X POST http://127.0.0.1:8000/rest/v1/invoices/pay
~~~
Should return;
~~~
true | false
~~~
#### List customers:
~~~
curl -X GET http://127.0.0.1:8000/rest/v1/Customers
~~~
Should return;
~~~
[{"id":1,"currency":"USD"},{"id":2,"currency":"DKK"}]
~~~
#### List a specific customers:
~~~
curl -X GET http://127.0.0.1:8000/rest/v1/Customers/1
~~~
Should return;
~~~
[{"id":1,"currency":"USD"}]
~~~

