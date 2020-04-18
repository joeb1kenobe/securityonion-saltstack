# Copyright 2014,2015,2016,2017,2018,2019,2020 Security Onion Solutions, LLC
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
{%- set MASTER = grains['master'] %}
{%- set MASTERIP = salt['pillar.get']('static:masterip', '') %}
{% set VERSION = salt['pillar.get']('static:soversion', 'HH1.2.1') %}

# Strelka config
strelkaconfdir:
  file.directory:
    - name: /opt/so/conf/strelka
    - user: 939
    - group: 939
    - makedirs: True

# Sync dynamic config to conf dir
strelkasync:
  file.recurse:
    - name: /opt/so/conf/strelka/
    - source: salt://strelka/files
    - user: 939
    - group: 939
    - template: jinja

strelkadatadir:
   file.directory:
    - name: /nsm/strelka
    - user: 939
    - group: 939
    - makedirs: True

strelkalogdir:
  file.directory:
    - name: /nsm/strelka/log
    - user: 939
    - group: 939
    - makedirs: True

strelkastagedir:
   file.directory:
    - name: /nsm/strelka/processed
    - user: 939
    - group: 939
    - makedirs: True

strelka_coordinator:
  docker_container.running:
    - image: {{ MASTER }}:5000/soshybridhunter/so-redis:{{ VERSION }}
    - name: so-strelka-coordinator
    - entrypoint: redis-server --save "" --appendonly no
    - port_bindings:
      - 0.0.0.0:6380:6379

strelka_gatekeeper:
  docker_container.running:
    - image: {{ MASTER }}:5000/soshybridhunter/so-redis:{{ VERSION }}
    - name: so-strelka-gatekeeper
    - entrypoint: redis-server --save "" --appendonly no --maxmemory-policy allkeys-lru
    - port_bindings:
      - 0.0.0.0:6381:6379

strelka_frontend:
  docker_container.running:
    - image: {{ MASTER }}:5000/soshybridhunter/so-strelka-frontend:HH1.2.1
    - binds:
      - /opt/so/conf/strelka/frontend/:/etc/strelka/:ro
      - /nsm/strelka/log/:/var/log/strelka/:rw
    - privileged: True
    - name: so-strelka-frontend
    - command: strelka-frontend
    - port_bindings:
      - 0.0.0.0:57314:57314

strelka_backend:
  docker_container.running:
    - image: {{ MASTER }}:5000/soshybridhunter/so-strelka-backend:HH1.2.1
    - binds:
      - /opt/so/conf/strelka/backend/:/etc/strelka/:ro
      - /opt/so/conf/strelka/backend/yara:/etc/yara/:ro
    - name: so-strelka-backend
    - command: strelka-backend
    - restart_policy: on-failure

strelka_manager:
  docker_container.running:
    - image: {{ MASTER }}:5000/soshybridhunter/so-strelka-manager:HH1.2.1
    - binds:
      - /opt/so/conf/strelka/manager/:/etc/strelka/:ro
    - name: so-strelka-manager
    - command: strelka-manager

strelka_filestream:
  docker_container.running:
    - image: {{ MASTER }}:5000/soshybridhunter/so-strelka-filestream:HH1.2.1
    - binds:
      - /opt/so/conf/strelka/filestream/:/etc/strelka/:ro
      - /nsm/strelka:/nsm/strelka
    - name: so-strelka-filestream
    - command: strelka-filestream
    
strelka_zeek_extracted_sync:
  cron.present:
    - user: root
    - name: mv /nsm/zeek/extracted/complete/* /nsm/strelka
    - minute: '*'
