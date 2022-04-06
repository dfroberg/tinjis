#!/bin/bash
TEST_PATHS=$(cat <<'EOT'
/rest/health
/rest/v1/Customers
/rest/v1/Customers/1
/rest/v1/invoices
/rest/v1/invoices/1
EOT
)
ANTAEUS_POD=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
if [ -z "$ANTAEUS_POD" ]; then
    echo "Antaeus Not yet available"
    exit 1
fi
ANTAEUS_PORT=$(kubectl get pod $ANTAEUS_POD -n payments --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}')
ANTAEUS_IMAGE=$(kubectl get pods -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-")).spec.containers[].image')
ANTAEUS_SVC=$(kubectl -n payments get svc -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
ANTAEUS_SVC_PORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-")).spec.ports[].targetPort')
ANTAEUS_INGRESS=$(kubectl -n payments get ingress -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
PAYMENT_POD=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=payments -o jsonpath='{.items[*].metadata.name}')
if [ -z "$PAYMENT_POD" ]; then
    echo "Payment Not yet available"
    exit 1
fi
PAYMENT_PORT=$(kubectl get pod $PAYMENT_POD -n payments --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}')
PAYMENT_IMAGE=$(kubectl get pods -n payments -o json | jq -r '.items[] | select(.metadata.name | test("payments-")).spec.containers[].image')
PAYMENT_SVC=$(kubectl -n payments get svc -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
PAYMENT_SVC_PORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("payments-")).spec.ports[].targetPort')

echo "► Testing Antaeus availability..."
echo "$ANTAEUS_POD using $ANTAEUS_IMAGE image is availble on port $ANTAEUS_PORT"
echo "$ANTAEUS_SVC is availble on port $ANTAEUS_SVC_PORT"
echo "► Testing Payment availability..."
echo "$PAYMENT_POD using $PAYMENT_IMAGE image is availble on port $PAYMENT_PORT"
echo "$PAYMENT_SVC is availble on port $PAYMENT_SVC_PORT"
echo "► Testing accessibility..."
#
# If this auto detect of PF won't do it, simply uncomment the next line and comment the auto detect
# TEST_PORTFORWARD=31811
# 
TEST_PORTFORWARD=$(ps -aux | grep -v "grep" | grep "kubectl port-forward -n payments service/antaeus-service" | awk -F ":" '{print $3}' | awk -F " " '{print $7}')
if [ -z "$TEST_PORTFORWARD" ]; then
    if [ -z "$ANTAEUS_INGRESS" ]; then
        TEST_HOST=""
    else
        echo "► Ingress: $ANTAEUS_INGRESS defined and is exposed on host $ANTAEUS_INGRESS_HOST"
        ANTAEUS_INGRESS_HOST=$(kubectl -n payments get ingress -l app=antaeus -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-")).spec.rules[].host')
        TEST_HOST="$ANTAEUS_INGRESS_HOST"
    fi
else
    TEST_HOST="localhost:$TEST_PORTFORWARD"
fi
echo $TEST_HOST

if [ -z "$TEST_HOST" ]; then
    echo "► No ingress - Please run either of the below to continue"
    echo "Open a new terminal and run;"
    echo "kubectl port-forward -n payments service/$ANTAEUS_SVC 31811:$ANTAEUS_SVC_PORT"
    echo " or; "
    echo "kubectl apply -f manifests/antaeus-ingress.yaml"
    echo "Please Rerun Test"
else
    echo "► Testing API Endpoints:"
    exec 3>&1
    for p in $TEST_PATHS
    do
        TEST_URL="http://$TEST_HOST$p"
        echo "► Testing $TEST_URL ..."
        HTTP_STATUS=$(curl -s -w "%{http_code}" -o >(cat >&3) $TEST_URL)
        echo ""
        if [ $HTTP_STATUS -gt 200 ]
        then
            echo " X Failed"
            exit 1
        else
            echo " ✔ Passed"
        fi
    done
    echo "► Testing Payments: Show distribution of INVOICE_STATUS"
    for p in "/rest/v1/invoices"
    do
        TEST_URL="http://$TEST_HOST$p"
        echo "► Testing $TEST_URL ..."
        for i in {1..1}
        do
            INVOICES_PAID=$(curl -X GET -s $TEST_URL)
            echo $(echo $INVOICES_PAID | jq '.[].status' | sort | uniq -c | awk -F " " '{print "{\"status\":" $2 ",\"count\":" $1"}"}'| jq .)
        done
        echo " "
        echo "✔ Done"
    done
    echo "► Testing Payments: Making a payment call"
    for p in "/rest/v1/invoices/pay"
    do
        TEST_URL="http://$TEST_HOST$p"
        echo "► Testing $TEST_URL ..."
        for i in {1..1}
        do
            INVOICES_PAID_STATUS=$(curl -X POST -s $TEST_URL)
            echo "$INVOICES_PAID_STATUS"
        done
        echo " "
        echo "✔ Done"
    done
    echo "► Testing Payments: Show distribution of INVOICE_STATUS"
    for p in "/rest/v1/invoices"
    do
        TEST_URL="http://$TEST_HOST$p"
        echo "► Testing $TEST_URL ..."
        for i in {1..1}
        do
            INVOICES_PAID=$(curl -X GET -s $TEST_URL)
            echo $(echo $INVOICES_PAID | jq '.[].status' | sort | uniq -c | awk -F " " '{print "{\"status\":" $2 ",\"count\":" $1"}"}'| jq .)
        done
        echo " "
        echo "✔ Done"
    done
fi