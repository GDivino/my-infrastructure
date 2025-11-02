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
      args:
        creates: "/home/ubuntu/traefik-data/.htpasswd"

    - name: Create .htpasswd file
      file:
        path: "/home/ubuntu/traefik-data/.htpasswd"
        state: touch
        owner: ubuntu
        group: ubuntu
        access_time: preserve
        modification_time: preserve

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

    - name: Install Docker and Docker Compose
      apt:
        name:
          - docker-ce
          - docker-ce-cli
          - containerd.io
          - docker-compose-plugin
        state: present
        update_cache: yes

    - name: Create wg-easy and traefik directories
      file:
        path: "/home/ubuntu/{{ item }}"
        state: directory
        owner: ubuntu
        group: ubuntu
        mode: "0755"
      loop:
        - wg-easy-data
        - traefik-data

    - name: Copy configuration files
      copy:
        src: "templates/{{ item.src }}"
        dest: "/home/ubuntu/{{ item.dest }}"
      loop:
        - { src: 'wg-easy-docker-compose.yml.j2', dest: 'wg-easy-data/docker-compose.yml' }
        - { src: 'traefik-docker-compose.yml.j2', dest: 'traefik-data/docker-compose.yml' }
        - { src: 'traefik/traefik_dynamic.yml.j2', dest: 'traefik-data/traefik_dynamic.yml' }
        - { src: 'traefik/traefik.yml', dest: 'traefik-data/traefik.yml' }

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

    - name: Start traefik container
      community.docker.docker_compose_v2:
        project_src: /home/ubuntu/traefik-data

    - name: Start wg-easy container
      community.docker.docker_compose_v2:
        project_src: /home/ubuntu/wg-easy-data


- name: Configure n8n Server
  hosts: n8n_server
  become: yes
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

    - name: Create n8n data directory
      file:
        path: /home/ubuntu/n8n-data/.n8n
        state: directory
        owner: 1000
        group: 1000

    - name: Copy n8n docker-compose file
      copy:
        src: templates/n8n-docker-compose.yml.j2
        dest: /home/ubuntu/n8n-data/docker-compose.yml

    - name: Start n8n container
      community.docker.docker_compose_v2:
        project_src: /home/ubuntu/n8n-data
