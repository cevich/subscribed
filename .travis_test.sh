
set -e

echo "Testing role syntax"
ansible-playbook -i tests/inventory tests/test.yml --verbose --syntax-check

echo "Configuring vault"
export ANSIBLE_VAULT_PASSWORD_FILE=$(mktemp -p '' .XXXXXXXX)
(
    set +abefhkmnptuvxBCEHPT
    echo "$ANSIBLE_VAULT_PASSWORD" > "$ANSIBLE_VAULT_PASSWORD_FILE"
) &>/dev/null

echo "Setting up testing container"
cat << EOF | sudo docker build -t tester:latest -
FROM docker.io/centos:latest
RUN yum update -y && \
    yum install -y epel-release && \
    yum install -y subscription-manager && \
    yum clean all
EOF

sudo docker run --detach --entrypoint /usr/bin/sleep --name "tester" tester:latest 10m
trap 'docker exec -i tester /usr/sbin/subscription-manager unregister || true' EXIT

echo "Testing role functionality"
sudo ansible-playbook -i tests/inventory tests/test.yml

echo "Testing role idempotence"
ansible-playbook -i tests/inventory tests/test.yml \
    | grep -q 'changed=0.*failed=0' \
    && (echo 'Idempotence test: pass' && exit 0)
    || (echo 'Idempotence test: fail' && exit 1)
