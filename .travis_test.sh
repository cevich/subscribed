
echo "Testing role syntax"
set -e
ansible-playbook -i tests/inventory tests/test.yml --verbose --syntax-check

echo "Testing role functionality"
ansible-playbook -i tests/inventory tests/test.yml

echo "Testing role idempotence"
ansible-playbook -i tests/inventory tests/test.yml \
    | grep -q 'changed=0.*failed=0' \
    && (echo 'Idempotence test: pass' && exit 0)
    || (echo 'Idempotence test: fail' && exit 1)

echo "Testing role affect"
exit 1  # FIXME: stub
