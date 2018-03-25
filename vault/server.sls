{% from "vault/map.jinja" import vault with context %}

vault-group:
  group.present:
    - name: {{ vault.group }}

vault-user:
  user.present:
    - name: {{ vault.user }}
    - groups:
      - {{ vault.group }}
    - home: {{ salt['uuser.info'](vault.user)['home']|default('/etc/vault') }}
    - createhome: false
    - system: true
    - require:
      - group: vault-group

/etc/vault:
  file.directory:
    - user: {{ vault.user }}
    - group: {{ vault.group }}
    - mode: 755

/etc/vault/config:
  file.directory:
    - user: {{ vault.user }}
    - group: {{ vault.group }}
    - mode: 755
    - require:
      - file: /etc/vault

/etc/vault/config/server.hcl:
  file.serialize:
    - formatter: json
    - dataset: {{ vault.config }}
    - user: {{ vault.user }}
    - group: {{ vault.group }}
    - mode: 0640
    - require:
      - file: /etc/vault/config
      - user: vault-user

{%- if vault.service.type == 'systemd' %}
/etc/systemd/system/vault.service:
  file.managed:
    - source: salt://vault/files/vault_systemd.service.jinja
    - template: jinja
    - user: {{ vault.user }}
    - group: {{ vault.group }}
    - mode: 644
    - require_in:
      - service: vault

{% elif vault.service.type == 'upstart' %}
/etc/init/vault.conf:
  file.managed:
    - source: salt://vault/files/vault_upstart.conf.jinja
    - template: jinja
    - user: {{ vault.user }}
    - group: {{ vault.group }}
    - require_in:
      - service: vault
{% endif -%}

vault:
  service.running:
    - enable: True
    - require:
      - file: /etc/vault/config/server.hcl
      - cmd: install vault
    - onchanges:
      - cmd: install vault
      - file: /etc/vault/config/server.hcl
