---
- name: Configure VPN Server (wg-easy)
  hosts: vpn_server
  become: yes
  vars:
    traefik_username: "${traefik_username}"
    traefik_password: "${traefik_password}"
  tasks:
    - name: Wait for APT lock to be released
      shell: while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done;
      changed_when: false

    - name: Install required system packages
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
          - python3-pip
          - apache2-utils
        state: present
        update_cache: yes

    - name: Create htpasswd hash for traefik password
      command: htpasswd -nbB "{{ traefik_username }}" "{{ traefik_password }}"
      register: htpasswd_output

    - name: Set htpasswd fact
      set_fact:
        traefik_password_hash: "{{ htpasswd_output.stdout }}"

    - name: Install Docker SDK for Python
      pip:
        name: docker

    - name: Add Docker's official GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Set docker_arch fact based on server architecture
      set_fact:
        docker_arch: "{{ 'arm64' if ansible_architecture == 'aarch64' else 'amd64' }}"

    - name: Add Docker repository for the correct architecture
      apt_repository:
        repo: "deb [arch={{ docker_arch }}] https://download.docker.com/linux/ubuntu {{ ansible_lsb.codename }} stable"
        state: present

    - name: Add Docker repository
      apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_lsb.codename }} stable
        state: present

    - name: Install Docker and Docker Compose
      apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-compose-plugin
        state: present
        update_cache: yes

    - name: Create wg-easy directory
      file:
        path: /home/ubuntu/wg-easy-data
        state: directory
        owner: ubuntu
        group: ubuntu
        mode: "0755"

    - name: Create traefik directory
      file:
        path: /home/ubuntu/traefik-data
        state: directory
        owner: ubuntu
        group: ubuntu
        mode: "0755"

    - name: Copy wg-easy docker-compose file
      copy:
        src: templates/wg-easy-docker-compose.yml.j2
        dest: /home/ubuntu/wg-easy-data/docker-compose.yml

    - name: Copy traefik docker-compose file
      copy:
        src: templates/traefik-docker-compose.yml.j2
        dest: /home/ubuntu/traefik-data/docker-compose.yml

    - name: Copy traefik dynamic file
      template:
        src: templates/traefik/traefik_dynamic.yml.j2
        dest: /home/ubuntu/traefik-data/traefik_dynamic.yml

    - name: Copy traefik yaml file
      copy:
        src: templates/traefik/traefik.yml
        dest: /home/ubuntu/traefik-data/traefik.yml

    - name: Copy acme json file
      copy:
        src: templates/traefik/acme.json
        dest: /home/ubuntu/traefik-data/acme.json
        mode: "600"
        force: no

    - name: Create traefik network
      community.docker.docker_network:
        name: traefik
        driver: bridge
        state: present

    - name: Stop traefik container
      community.docker.docker_compose_v2:
        project_src: /home/ubuntu/traefik-data
        state: absent

    - name: Start traefik container
      community.docker.docker_compose_v2:
        project_src: /home/ubuntu/traefik-data

    - name: Stop wg-easy container
      community.docker.docker_compose_v2:
        project_src: /home/ubuntu/wg-easy-data
        state: absent

    - name: Start wg-easy container
      community.docker.docker_compose_v2:
        project_src: /home/ubuntu/wg-easy-data


- name: Configure n8n Server
  hosts: n8n_server
  become: yes
  tasks:
    # - name: Wait for the host to become available via proxy
    #   wait_for_connection:
    #     delay: 15
    #     timeout: 180
    - name: Wait for APT lock to be released
      shell: while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do sleep 5; done;
      changed_when: false

    - name: Install required system packages
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
          - python3-pip
        state: present
        update_cache: yes

    - name: Install Docker SDK for Python
      pip:
        name: docker

    - name: Add Docker's official GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Set docker_arch fact based on server architecture
      set_fact:
        docker_arch: "{{ 'arm64' if ansible_architecture == 'aarch64' else 'amd64' }}"

    - name: Add Docker repository for the correct architecture
      apt_repository:
        repo: "deb [arch={{ docker_arch }}] https://download.docker.com/linux/ubuntu {{ ansible_lsb.codename }} stable"
        state: present

    - name: Add Docker repository
      apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_lsb.codename }} stable
        state: present

    - name: Install Docker and Docker Compose
      ansible.builtin.apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-compose-plugin
        state: present
        update_cache: yes

    - name: Create n8n directory
      file:
        path: /home/ubuntu/n8n-data
        state: directory
        owner: ubuntu
        group: ubuntu
        mode: "0755"

    - name: Copy n8n docker-compose file
      copy:
        src: templates/n8n-docker-compose.yml.j2
        dest: /home/ubuntu/n8n-data/docker-compose.yml

    - name: Stop n8n container
      community.docker.docker_compose_v2:
        project_src: /home/ubuntu/n8n-data
        state: absent

    - name: Start n8n container
      community.docker.docker_compose_v2:
        project_src: /home/ubuntu/n8n-data
