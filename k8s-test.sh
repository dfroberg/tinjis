#!/bin/bash
TEST_PATHS=$(cat <<'EOT'
/rest/health
/rest/v1/Customers
/rest/v1/Customers/1
/rest/v1/invoices
/rest/v1/invoices/1
EOT
)
NOTICE=0
echo -e "► Testing Antaeus availability..."
ANTAEUS_POD=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
if [ -z "$ANTAEUS_POD" ]; then
    echo -e "  Antaeus Not yet available"
    exit 1
fi
ANTAEUS_PORT=$(kubectl get pod $ANTAEUS_POD -n payments --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}')
ANTAEUS_IMAGE=$(kubectl get pods -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-")).spec.containers[].image')
ANTAEUS_SVC=$(kubectl -n payments get svc -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
ANTAEUS_SVC_PORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-")).spec.ports[].targetPort')
ANTAEUS_INGRESS=$(kubectl -n payments get ingress -l app=antaeus -o jsonpath='{.items[*].metadata.name}')
PAYMENT_POD=$(kubectl -n payments get pods --field-selector status.phase=Running -l app=payments -o jsonpath='{.items[*].metadata.name}')
if [ -z "$PAYMENT_POD" ]; then
    echo -e "  Payment Not yet available"
    exit 1
fi
PAYMENT_PORT=$(kubectl get pod $PAYMENT_POD -n payments --template='{{(index (index .spec.containers 0).ports 0).containerPort}}{{"\n"}}')
PAYMENT_IMAGE=$(kubectl get pods -n payments -o json | jq -r '.items[] | select(.metadata.name | test("payments-")).spec.containers[].image')
PAYMENT_SVC=$(kubectl -n payments get svc -l app=payments -o jsonpath='{.items[*].metadata.name}')
PAYMENT_SVC_PORT=$(kubectl get svc -n payments -o json | jq -r '.items[] | select(.metadata.name | test("payments-")).spec.ports[].targetPort')

echo -e "  $ANTAEUS_POD using $ANTAEUS_IMAGE image is available on port $ANTAEUS_PORT"
echo -e "  $ANTAEUS_SVC is available on port $ANTAEUS_SVC_PORT"
echo -e "► Testing Payment availability..."
echo -e "  $PAYMENT_POD using $PAYMENT_IMAGE image is available on port $PAYMENT_PORT"
echo -e "  $PAYMENT_SVC is available on port $PAYMENT_SVC_PORT"
echo -e "► Testing accessibility..."
#
# If this auto detect of PF won't do it, simply uncomment the next line and comment the auto detect
# TEST_PORTFORWARD=31811
#
TEST_PORTFORWARD=$(ps -aux | grep -v "grep" | grep "kubectl port-forward -n payments service/antaeus-service" | awk -F ":" '{print $3}' | awk -F " " '{print $7}')
if [ -z "$TEST_PORTFORWARD" ]; then
    if [ -z "$ANTAEUS_INGRESS" ]; then
        TEST_HOST=""
    else
        echo -e "► Ingress: $ANTAEUS_INGRESS defined and is exposed on host $ANTAEUS_INGRESS_HOST"
        ANTAEUS_INGRESS_HOST=$(kubectl -n payments get ingress -l app=antaeus -o json | jq -r '.items[] | select(.metadata.name | test("antaeus-")).spec.rules[].host')
        TEST_HOST="$ANTAEUS_INGRESS_HOST"
    fi
else
    TEST_HOST="localhost:$TEST_PORTFORWARD"
fi
echo -e "  $TEST_HOST"

if [ -z "$TEST_HOST" ]; then
    echo -e "► No ingress - Please run either of the below to continue"
    echo -e "  Open a new terminal and run;"
    echo -e "    kubectl port-forward -n payments service/$ANTAEUS_SVC 31811:$ANTAEUS_SVC_PORT"
    echo -e "  or; "
    echo -e "    kubectl apply -f manifests/antaeus-ingress.yaml"
    echo -e "Please Rerun Test"
else
    echo -e "► Testing API Endpoints:"
    for p in $TEST_PATHS
    do
        TEST_URL="http://$TEST_HOST$p"
        echo -e -n "► Testing $TEST_URL ..."
        HTTP_STATUS=$(curl -s -w "%{http_code}" -o >(cat >content.txt) $TEST_URL )
        CONTENT=$(cat content.txt)
        if [ $HTTP_STATUS -gt 200 ]
        then
            echo -e " X Failed"
            echo -e "  Antaeus service is quite slow to build ~1 minute, try again."
            exit 1
        else
            echo -e " ✔ Passed"
            echo -e "  ---\n  $CONTENT\n  ---\n"
        fi
    done
    echo -e "► Testing Payments: Show distribution of INVOICE_STATUS"
    for p in "/rest/v1/invoices"
    do
        TEST_URL="http://$TEST_HOST$p"
        echo -e -n "► Calling $TEST_URL ..."
        for i in {1..1}
        do
            $(HTTP_STATUS=$(curl -X GET -s -w "%{http_code}" -o >(cat >content.txt) $TEST_URL))
            CONTENT=$(cat content.txt)
            if [ $HTTP_STATUS -gt 200 ]; then
                echo -e "X Failed testing, Got Code $HTTP_STATUS "
                exit 1
            else
                echo -e " ✔ Passed"
                echo -e "---\n$(echo $CONTENT | jq '.[].status' | sort | uniq -c | awk -F " " '{print "{\"status\":" $2 ",\"count\":" $1"}"}'| jq .)\n---\n"
            fi

        done
        echo -e "✔ Done"
    done
    echo -e "► Testing Payments: Making a payment call"
    for p in "/rest/v1/invoices/pay"
    do
        TEST_URL="http://$TEST_HOST$p"
        echo -e -n "► Calling $TEST_URL ..."
        for i in {1..1}
        do
            $(HTTP_STATUS=$(curl -X POST -s -w "%{http_code}" -o >(cat >content.txt) $TEST_URL))
            CONTENT=$(cat content.txt)
            if [ $HTTP_STATUS -gt 200 ]; then
                echo -e "X Failed testing, Got Code $HTTP_STATUS "
                exit 1
            else
                echo -e " ✔ Passed"
                if [ $CONTENT == "true" ]; then
                    echo -e "  Returned $CONTENT, Successfuly paid all invoices"
                    NOTICE=1
                else
                    echo -e "  Returned $CONTENT, Not all invoices paid successfuly"
                fi
            fi
        done
        echo -e " "
        echo -e "✔ Done"
    done
    echo -e -n "► Testing Payments: Show distribution of INVOICE_STATUS"
    for p in "/rest/v1/invoices"
    do
        TEST_URL="http://$TEST_HOST$p"
        echo -e -n "► Calling $TEST_URL ..."
        for i in {1..1}
        do
            $(HTTP_STATUS=$(curl -X GET -s -w "%{http_code}" -o >(cat >content.txt) $TEST_URL))
            CONTENT=$(cat content.txt)
            if [ $HTTP_STATUS -gt 200 ]; then
                echo -e "X Failed testing, Got Code $HTTP_STATUS "
                exit 1
            else
                echo -e " ✔ Passed"
                echo -e "---\n$(echo $CONTENT | jq '.[].status' | sort | uniq -c | awk -F " " '{print "{\"status\":" $2 ",\"count\":" $1"}"}'| jq .)\n---\n"
            fi

        done
        echo -e "✔ Done"
    done
    echo -e "✔ All Tests Done"
    rm content.txt
    if [ $NOTICE -gt 0 ]; then
        echo -e "\n*** NOTICE: ***"
        echo "It seems all invoices now have the status PAID, restart the ANTAEUS_POD if you wish to retry the test."
        echo "kubectl delete pod $ANTAEUS_POD -n payments "
        echo -e "\n\n"
    fi
fi
