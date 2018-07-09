#!/bin/bash

set -eo pipefail

cd $(dirname $0)

curl -O https://raw.githubusercontent.com/cevich/ADEPT/master/.travis_typo_check.sh
chmod +x ./.travis_typo_check.sh
[[ -z "$CI" ]] || ./.travis_typo_check.sh

export CONTAINER="${CONTAINER:-docker}"

echo "Configuring vault"
export ANSIBLE_VAULT_PASSWORD_FILE=$(mktemp -p '' .XXXXXXXX)
export OUTPUT_TEMP_FILE=$(mktemp -p '' .XXXXXXXX)
cleanup(){
    set +e
    echo "Cleaning up"
    rm -f ansible.cfg
    rm -f "$ANSIBLE_VAULT_PASSWORD_FILE"
    rm -f "$OUTPUT_TEMP_FILE"
    sudo $CONTAINER exec -i tester /usr/sbin/subscription-manager unregister
    sudo $CONTAINER exec -i tester /usr/sbin/subscription-manager clean
    sudo $CONTAINER rm -f tester
}
trap cleanup EXIT

cd tests
mkdir -p roles
cd roles
ln -s ../../ cevich.subscribed
cd ..

export ANSIBLE_CONFIG="$PWD/ansible.cfg"
cat << EOF > ansible.cfg
[defaults]
gather_subset = min
vault_password_file = $ANSIBLE_VAULT_PASSWORD_FILE
display_skipped_hosts = False
any_errors_fatal = True
deprecation_warnings = False
EOF

CID=$(sudo $CONTAINER run --detach --name "tester" docker.io/cevich/test_rhsm sleep 1h)
echo "Started $CID"

(
    set +abefhkmnptuvxBCEHPT
    echo "$ANSIBLE_VAULT_PASSWORD" > "$ANSIBLE_VAULT_PASSWORD_FILE"
) &>/dev/null
unset -v ANSIBLE_VAULT_PASSWORD

echo "Testing syntax"
ansible-playbook -i inventory test_subscribe.yml --verbose --syntax-check
ansible-playbook -i inventory test_unsubscribe.yml --verbose --syntax-check

echo "Testing subscription functionality"
ansible-playbook -i inventory test_subscribe.yml

echo "Testing subscription idempotence based on functionality test"
ansible-playbook -i inventory test_subscribe.yml | tee "$OUTPUT_TEMP_FILE"
grep -q 'changed=0.*failed=0'  "$OUTPUT_TEMP_FILE" \
    && (echo 'Subscription Idempotence test: pass' && exit 0) \
    || (echo 'Subscription Idempotence test: fail' && exit 1)

echo "Testing unsubscription functionality"
ansible-playbook -i inventory test_unsubscribe.yml

echo "Testing unsubscription idempotence based on functionality test"
ansible-playbook -i inventory test_unsubscribe.yml | tee "$OUTPUT_TEMP_FILE"
grep -q 'changed=0.*failed=0'  "$OUTPUT_TEMP_FILE" \
    && (echo 'Idempotence test: pass' && exit 0) \
    || (echo 'Idempotence test: fail' && exit 1)
