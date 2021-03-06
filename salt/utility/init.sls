# This state is for checking things
{% if grains['role'] == 'so-master' or grains['role'] == 'so-mastersearch' %}
# Make sure Cross Cluster is good. Will need some logic once we have hot/warm
crossclusterson:
  cmd.script:
    - shell: /bin/bash
    - cwd: /opt/so
    - runas: socore
    - source: salt://utility/bin/crossthestreams
    - template: jinja

{% endif %}
{% if grains['role'] == 'so-eval' %}
fixsearch:
  cmd.script:
    - shell: /bin/bash
    - cwd: /opt/so
    - runas: socore
    - source: salt://utility/bin/eval
    - template: jinja
{% endif %}
