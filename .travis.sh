#!/bin/bash

set -e

source ./.typos.sh

# Add ansible.cfg to pick up roles path.
echo -e '[defaults]\nroles_path = ../' > ansible.cfg

# Galaxy would normally install this with a "cevich." prefix
# which is missing from github repo name
ROLENAME="$(basename $PWD)"
echo "$ROLENAME" | grep -q 'cevich' || ln -sfv "$ROLENAME" "../cevich.$ROLENAME"

echo "Configuring vault"
export ANSIBLE_VAULT_PASSWORD_FILE=$(mktemp -p '' .XXXXXXXX)
export OUTPUT_TEMP_FILE=$(mktemp -p '' .XXXXXXXX)

cleanup(){
    set +e
    [ -r "$ANSIBLE_VAULT_PASSWORD_FILE" ] && rm -rf "$ANSIBLE_VAULT_PASSWORD_FILE"
    [ -r "$OUTPUT_TEMP_FILE" ] && rm -rf "$OUTPUT_TEMP_FILE"
    docker exec -i tester /usr/sbin/subscription-manager unregister || true
}
trap cleanup EXIT

(
    set +abefhkmnptuvxBCEHPT
    echo "$ANSIBLE_VAULT_PASSWORD" > "$ANSIBLE_VAULT_PASSWORD_FILE"
) &>/dev/null
unset -v ANSIBLE_VAULT_PASSWORD

echo "Setting up testing container"
cat << EOF | sudo docker build -t tester:latest -
FROM docker.io/centos:latest
RUN yum update -y && \
    yum install -y epel-release && \
    yum install -y subscription-manager && \
    yum clean all
EOF

docker rm -f tester || true
CID=$(sudo docker run --detach --entrypoint /usr/bin/sleep --name "tester" tester:latest 10m)
echo "Started $CID"

echo "Testing subscribe syntax"
ansible-playbook -i tests/inventory tests/test_subscribe.yml --verbose --syntax-check

echo "Testing subscription functionality"
ansible-playbook -i tests/inventory tests/test_subscribe.yml --verbose

echo "Testing subscription idempotence based on functionality test"
ansible-playbook -i tests/inventory tests/test_subscribe.yml --verbose | tee "$OUTPUT_TEMP_FILE"
grep -q 'changed=0.*failed=0'  "$OUTPUT_TEMP_FILE" \
    && (echo 'Subscription Idempotence test: pass' && exit 0) \
    || (echo 'Subscription Idempotence test: fail' && exit 1)


echo "Testing unsubscribe syntax"
ansible-playbook -i tests/inventory tests/test_unsubscribe.yml --verbose --syntax-check

echo "Testing unsubscription functionality"
ansible-playbook -i tests/inventory tests/test_unsubscribe.yml --verbose

echo "Testing unsubscription idempotence based on functionality test"
ansible-playbook -i tests/inventory tests/test_unsubscribe.yml --verbose | tee "$OUTPUT_TEMP_FILE"
grep -q 'changed=0.*failed=0'  "$OUTPUT_TEMP_FILE" \
    && (echo 'Idempotence test: pass' && exit 0) \
    || (echo 'Idempotence test: fail' && exit 1)
