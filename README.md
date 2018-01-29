Subscribed
==========

[Ansible Galaxy enabled](https://galaxy.ansible.com/cevich/subscribed)
role to subscribe or un-subscribe a RHEL
subject purely through the native subscription-manager command.
This works around several niggly problems with the stock Ansible
role, under some specific conditions.  Unfortunately, the details
of the conditions is proprietary information.

Requirements
------------

Same as stock Ansible ``2.3+``

Role Variables
--------------

`rhsm`:
>
>   Dictionary of registration and subscription options described below.
>   Required unless ``unsubscribe`` is ``True``

`rhsm.username`:
>
>   Required, user name to pass when registering.  Will not be logged or
>   displayed, even under verbose mode.

`rhsm.password`:
>
>   Required, corresponding password to use when registering.  Will not be logged or
>   displayed, even under verbose mode.

`rhsm.baseurl`:
>
>   Optional, the URL for the subscription content server.

`rhsm.serverurl`:
>
>   Optional, the URL for the registration server.

`rhsm.insecure`:
>
>   Defaults to ``False``, allow registration and content retrieval
>   using unencrypted or unverifiable secure communication channels.

`rhsm.release`:
>
>   Optional, if non-empty, a string describing major.minor release to
>   lock host onto.  Enables retrieval of EUS a.k.a. z-stream updates.

`rhsm.org`:
>
>   Optional, unless this is a username/password represent a sub-account
>   and/or multiple-organizations are configured on the account. The
>   command ``subscription-manager orgs`` with the above username/password
>   options will display the org. id. number.

`rhsm.force`:
>
>   Defaults to ``False``, allows forcing re-registering of a host
>   that matches an already registered host, with a different identity
>   certificate.  With out being forced in this situation, multiple
>   subscriptions would be consumed by entries with the same hostname
>   but different identities.

`unsubscribe`:
>
>   Defaults to ``False``, unsubscribe the host.  Required when used
>   under ``roles:`` directly, instead of ``include_role`` where the
>   ``unsubscribe.yml`` can be specified to ``tasks_from:``.

`rhsm_retries`:
>
>   Defaults to ``3``, the number of times to re-try a failed command.

`rhsm_delay`:
>
>    Defaults to ``10``, the number of seconds to wait between retries.


Dependencies
------------

A RHEL 6+ system able to communicate with ``rhsm.redhat.com``, a SAM, or satellite server.

Example Playbooks
----------------

**Register / Subscribe**

```yaml
    - hosts: all
      vars_files:
        - '/path/to/rhsm_vault.yml'  # defines _vault_rhsm

      pre_tasks:
        - name: System is registered and subscribed
          include_role:
            name: cevich.subscribed
            private: True  # optional, hide vars outside role
          vars:
            rhsm: '{{ _vault_rhsm }}'
          when: rhsm | default({}, True) | length
```

**Unsubscribe / Deregister**

```yaml
    - hosts: all

      post_tasks:
        - name: System is un-subscribed and de-registered
          include_role:
            name: cevich.subscribed
            private: True  # for the truely paranoid
          vars:
            unsubscribe: True
```

License
-------

> Subscribe or un-subscribe a RHEL subject with subscription-manager command.
> Copyright (C) 2017  Christopher C. Evich
>
> This program is free software: you can redistribute it and/or modify
> it under the terms of the GNU General Public License as published by
> the Free Software Foundation, either version 3 of the License, or
> (at your option) any later version.
>
> This program is distributed in the hope that it will be useful,
> but WITHOUT ANY WARRANTY; without even the implied warranty of
> MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
> GNU General Public License for more details.
>
> You should have received a copy of the GNU General Public License
> along with this program.  If not, see <https://www.gnu.org/licenses/>.


Author Information
------------------

Causing trouble and inciting mayhem with Linux since Windows 98

Continuous Integration
----------------------

Travis CI: [![Build Status](https://travis-ci.org/cevich/subscribed.svg?branch=master)](https://travis-ci.org/cevich/subscribed)
