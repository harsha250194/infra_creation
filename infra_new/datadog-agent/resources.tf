locals {
 annotations = {
    tmna-bu = "CT"
    tmna-env = var.environment
    tmna-project-name = "onekube"
    tmna-project-type = "k8s-infra"
    tmna-team = "21MM-CTP-Core"
    tmna-terraform-repo = "gitlab/kubernetes-platform"
    tmna-terraform-script = "infra/datadog-agent"
    tmna-terraform-ver = "0.12"
    tmna-terraform-workspace = "kubernetes-platform-${var.environment}-${var.resource_names.region}-12-datadog-agent"
 }
}
resource "kubernetes_secret" "datadog-agent" {
  metadata {
    name = var.service_name
    namespace = var.service_namespace
  }
  data = {
    apikey = var.apikey
    }
}

resource "kubernetes_cluster_role" "datadog-agent" {
    ##depends_on = ["kubernetes_cluster_role_binding.owner_cluster_admin_binding"]
    metadata {
        name = var.service_name
    }

    rule {
        api_groups = [""]
        resources  = ["nodes", "events", "endpoints", "services", "pods" , "componentstatuses"]
        verbs      = ["get", "list", "watch"]
    }
    rule {
      api_groups = ["quota.openshift.io"]
      resources  = ["clusterresourcequotas"]
      verbs      = ["get", "list"]
    }
    rule {
      api_groups = [""]
      resources  = ["configmaps"]
      resource_names = ["datadogtoken", "datadog-leader-election"]
      verbs      = ["get", "update"]
    }
    rule {
      api_groups = [""]
      resources  = ["configmaps"]
      verbs      = ["get"]
    }
    rule {
    verbs             = ["get"]
    non_resource_urls = ["/version", "/healthz", "/metrics"]
    }
    rule {
      api_groups = [""]
      resources  = ["nodes/metrics", "nodes/spec", "nodes/proxy", "nodes/stats"]
      verbs      = ["get"]
    }
}

resource "kubernetes_cluster_role_binding" "datadog_agent" {
  metadata {
    name = var.service_name
    annotations = {
      "tmna-terraform-script" = ""
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    name      = var.service_name
    kind      = "ClusterRole"
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.service_name
    namespace = var.service_namespace
  }
}

resource "kubernetes_config_map" "datadog_agent_installinfo" {
  metadata {
    name      = "datadog-agent-installinfo"
    namespace = var.service_namespace

    annotations = {
      "checksum/install_info" = "9f58f4fe71f1b79dfabae5311eb8f5373bd03072d4636e248cd3f581f8752627"
    }
  }

  data = {
    install_info = "---\ninstall_method:\n  tool: kubernetes sample manifests\n  tool_version: kubernetes sample manifests\n  installer_version: kubernetes sample manifests\n"
  }
}

resource "kubernetes_config_map" "datadog_agent_system_probe_config" {
  metadata {
    name      = "datadog-agent-system-probe-config"
    namespace = var.service_namespace
  }

  data = {
    "system-probe.yaml" = "system_probe_config:\n  enabled: true\n  debug_port:  0\n  sysprobe_socket: /var/run/sysprobe/sysprobe.sock\n  enable_conntrack: true\n  bpf_debug: false\n  enable_tcp_queue_length: false\n  enable_oom_kill: false\n  collect_dns_stats: true\nruntime_security_config:\n  enabled: false\n  debug: false\n  socket: /var/run/sysprobe/runtime-security.sock\n  policies:\n    dir: /etc/datadog-agent/runtime-security.d\n  syscall_monitor:\n    enabled: false\n"
  }
}

resource "kubernetes_config_map" "datadog_agent_security" {
  metadata {
    name      = "datadog-agent-security"
    namespace = var.service_namespace
  }

  data = {
    "system-probe-seccomp.json" = "{\n  \"defaultAction\": \"SCMP_ACT_ERRNO\",\n  \"syscalls\": [\n    {\n      \"names\": [\n        \"accept4\",\n        \"access\",\n        \"arch_prctl\",\n        \"bind\",\n        \"bpf\",\n        \"brk\",\n        \"capget\",\n        \"capset\",\n        \"chdir\",\n        \"clock_gettime\",\n        \"clone\",\n        \"close\",\n        \"connect\",\n        \"copy_file_range\",\n        \"creat\",\n        \"dup\",\n        \"dup2\",\n        \"dup3\",\n        \"epoll_create\",\n        \"epoll_create1\",\n        \"epoll_ctl\",\n        \"epoll_ctl_old\",\n        \"epoll_pwait\",\n        \"epoll_wait\",\n        \"epoll_wait\",\n        \"epoll_wait_old\",\n        \"eventfd\",\n        \"eventfd2\",\n        \"execve\",\n        \"execveat\",\n        \"exit\",\n        \"exit_group\",\n        \"fchmod\",\n        \"fchmodat\",\n        \"fchown\",\n        \"fchown32\",\n        \"fchownat\",\n        \"fcntl\",\n        \"fcntl64\",\n        \"fstat\",\n        \"fstat64\",\n        \"fstatfs\",\n        \"fsync\",\n        \"futex\",\n        \"getcwd\",\n        \"getdents\",\n        \"getdents64\",\n        \"getegid\",\n        \"geteuid\",\n        \"getgid\",\n        \"getpeername\",\n        \"getpid\",\n        \"getppid\",\n        \"getpriority\",\n        \"getrandom\",\n        \"getresgid\",\n        \"getresgid32\",\n        \"getresuid\",\n        \"getresuid32\",\n        \"getrlimit\",\n        \"getrusage\",\n        \"getsid\",\n        \"getsockname\",\n        \"getsockopt\",\n        \"gettid\",\n        \"gettimeofday\",\n        \"getuid\",\n        \"getxattr\",\n        \"ioctl\",\n        \"ipc\",\n        \"listen\",\n        \"lseek\",\n        \"lstat\",\n        \"lstat64\",\n        \"madvise\",\n        \"mkdir\",\n        \"mkdirat\",\n        \"mmap\",\n        \"mmap2\",\n        \"mprotect\",\n        \"mremap\",\n        \"munmap\",\n        \"nanosleep\",\n        \"newfstatat\",\n        \"open\",\n        \"openat\",\n        \"pause\",\n        \"perf_event_open\",\n        \"pipe\",\n        \"pipe2\",\n        \"poll\",\n        \"ppoll\",\n        \"prctl\",\n        \"pread64\",\n        \"prlimit64\",\n        \"pselect6\",\n        \"read\",\n        \"readlink\",\n        \"readlinkat\",\n        \"recvfrom\",\n        \"recvmmsg\",\n        \"recvmsg\",\n        \"rename\",\n        \"restart_syscall\",\n        \"rmdir\",\n        \"rt_sigaction\",\n        \"rt_sigpending\",\n        \"rt_sigprocmask\",\n        \"rt_sigqueueinfo\",\n        \"rt_sigreturn\",\n        \"rt_sigsuspend\",\n        \"rt_sigtimedwait\",\n        \"rt_tgsigqueueinfo\",\n        \"sched_getaffinity\",\n        \"sched_yield\",\n        \"seccomp\",\n        \"select\",\n        \"semtimedop\",\n        \"send\",\n        \"sendmmsg\",\n        \"sendmsg\",\n        \"sendto\",\n        \"set_robust_list\",\n        \"set_tid_address\",\n        \"setgid\",\n        \"setgid32\",\n        \"setgroups\",\n        \"setgroups32\",\n        \"setns\",\n        \"setrlimit\",\n        \"setsid\",\n        \"setsidaccept4\",\n        \"setsockopt\",\n        \"setuid\",\n        \"setuid32\",\n        \"sigaltstack\",\n        \"socket\",\n        \"socketcall\",\n        \"socketpair\",\n        \"stat\",\n        \"stat64\",\n        \"statfs\",\n        \"sysinfo\",\n        \"umask\",\n        \"uname\",\n        \"unlink\",\n        \"unlinkat\",\n        \"wait4\",\n        \"waitid\",\n        \"waitpid\",\n        \"write\"\n      ],\n      \"action\": \"SCMP_ACT_ALLOW\",\n      \"args\": null\n    },\n    {\n      \"names\": [\n        \"setns\"\n      ],\n      \"action\": \"SCMP_ACT_ALLOW\",\n      \"args\": [\n        {\n          \"index\": 1,\n          \"value\": 1073741824,\n          \"valueTwo\": 0,\n          \"op\": \"SCMP_CMP_EQ\"\n        }\n      ],\n      \"comment\": \"\",\n      \"includes\": {},\n      \"excludes\": {}\n    }\n  ]\n}\n"
  }
}

resource "kubernetes_daemonset" "datadog_agent" {
  metadata {
    name      = var.service_name
    namespace = var.service_namespace

    annotations = local.annotations
  }

  spec {
    selector {
      match_labels = {
        app = "datadog-agent"
      }
    }

    template {
      metadata {
        name = "datadog-agent"

        labels = {
          app = "datadog-agent"
        }

        annotations = {
          "container.apparmor.security.beta.kubernetes.io/system-probe" = "unconfined"

          "container.seccomp.security.alpha.kubernetes.io/system-probe" = "localhost/system-probe"
        }
      }

      spec {
        volume {
          name = "installinfo"

          config_map {
            name = "datadog-agent-installinfo"
          }
        }

        volume {
          name = "config"
        }

        volume {
          name = "runtimesocketdir"

          host_path {
            path = "/var/run"
          }
        }

        volume {
          name = "procdir"

          host_path {
            path = "/proc"
          }
        }

        volume {
          name = "cgroups"

          host_path {
            path = "/sys/fs/cgroup"
          }
        }

        volume {
          name = "sysprobe-config"

          config_map {
            name = "datadog-agent-system-probe-config"
          }
        }

        volume {
          name = "datadog-agent-security"

          config_map {
            name = "datadog-agent-security"
          }
        }

        volume {
          name = "seccomp-root"

          host_path {
            path = "/var/lib/kubelet/seccomp"
          }
        }

        volume {
          name = "debugfs"

          host_path {
            path = "/sys/kernel/debug"
          }
        }

        volume {
          name = "sysprobe-socket-dir"
        }

        volume {
          name = "passwd"

          host_path {
            path = "/etc/passwd"
          }
        }

        init_container {
          name    = "init-volume"
          image   = "gcr.io/datadoghq/agent:7.23.1"
          command = ["bash", "-c"]
          args    = ["cp -r /etc/datadog-agent /opt"]

          resources {
            limits {
              cpu    = "256m"
              memory = "256Mi"
            }

            requests {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/opt/datadog-agent"
          }

          image_pull_policy = "IfNotPresent"
        }

        init_container {
          name    = "init-config"
          image   = "gcr.io/datadoghq/agent:7.23.1"
          command = ["bash", "-c"]
          args    = ["for script in $(find /etc/cont-init.d/ -type f -name '*.sh' | sort) ; do bash $script ; done"]

          env {
            name = "DD_API_KEY"

            value_from {
              secret_key_ref {
                name = var.service_name
                key  = "api-key"
              }
            }
          }

          env {
            name = "DD_KUBERNETES_KUBELET_HOST"

            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name  = "KUBERNETES"
            value = "yes"
          }

          env {
            name  = "DOCKER_HOST"
            value = "unix:///host/var/run/docker.sock"
          }

          env {
            name  = "DD_KUBELET_TLS_VERIFY"
            value = "false"
          }

          resources {
            limits {
              cpu    = "256m"
              memory = "256Mi"
            }

            requests {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/datadog-agent"
          }

          volume_mount {
            name              = "procdir"
            read_only         = true
            mount_path        = "/host/proc"
            mount_propagation = "None"
          }

          volume_mount {
            name              = "runtimesocketdir"
            read_only         = true
            mount_path        = "/host/var/run"
            mount_propagation = "None"
          }

          volume_mount {
            name       = "sysprobe-config"
            mount_path = "/etc/datadog-agent/system-probe.yaml"
            sub_path   = "system-probe.yaml"
          }

          image_pull_policy = "IfNotPresent"
        }

        init_container {
          name    = "seccomp-setup"
          image   = "gcr.io/datadoghq/agent:7.23.1"
          command = ["cp", "/etc/config/system-probe-seccomp.json", "/host/var/lib/kubelet/seccomp/system-probe"]

          resources {
            limits {
              cpu    = "256m"
              memory = "256Mi"
            }

            requests {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          volume_mount {
            name       = "datadog-agent-security"
            mount_path = "/etc/config"
          }

          volume_mount {
            name              = "seccomp-root"
            mount_path        = "/host/var/lib/kubelet/seccomp"
            mount_propagation = "None"
          }
        }

        container {
          name    = "agent"
          image   = "gcr.io/datadoghq/agent:7.23.1"
          command = ["agent", "run"]

          port {
            name           = "dogstatsdport"
            container_port = 8125
            protocol       = "UDP"
          }

          port {
            name           = "traceport"
            host_port      = 8126
            container_port = 8126
            protocol       = "TCP"
          }

          env {
            name = "DD_API_KEY"

            value_from {
              secret_key_ref {
                name = var.service_name
                key  = "api-key"
              }
            }
          }

          env {
            name  = "DD_TAGS"
            value = "env:preprod generation:21mm"
          }

          env {
            name  = "DD_SITE"
            value = "datadoghq.com"
          }

          env {
            name  = "DD_DOGSTATSD_NON_LOCAL_TRAFFIC"
            value = "true"
          }

          env {
            name  = "DD_COLLECT_KUBERNETES_EVENTS"
            value = "true"
          }

          env {
            name  = "DD_LEADER_ELECTION"
            value = "true"
          }

          env {
            name  = "KUBERNETES"
            value = "true"
          }

          env {
            name = "DD_KUBERNETES_KUBELET_HOST"

            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name  = "KUBERNETES"
            value = "yes"
          }

          env {
            name  = "DOCKER_HOST"
            value = "unix:///host/var/run/docker.sock"
          }

          env {
            name  = "DD_LOG_LEVEL"
            value = "INFO"
          }

          env {
            name  = "DD_DOGSTATSD_PORT"
            value = "8125"
          }

          env {
            name  = "DD_CLUSTER_NAME"
            value = "tmna-ctp-21mm-dd-testcluster-ga"
          }

          env {
            name  = "DD_APM_ENABLED"
            value = "true"
          }

          env {
            name  = "DD_LOGS_ENABLED"
            value = "true"
          }

          env {
            name  = "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL"
            value = "true"
          }

          env {
            name  = "DD_LOGS_CONFIG_K8S_CONTAINER_USE_FILE"
            value = "true"
          }

          env {
            name  = "DD_HEALTH_PORT"
            value = "5555"
          }

          env {
            name  = "DD_PROCESS_AGENT_ENABLED"
            value = "true"
          }

          env {
            name  = "DD_SYSTEM_PROBE_ENABLED"
            value = "true"
          }

          env {
            name  = "DD_SYSTEM_PROBE_EXTERNAL"
            value = "true"
          }

          env {
            name  = "DD_SYSPROBE_SOCKET"
            value = "/var/run/sysprobe/sysprobe.sock"
          }

          env {
            name  = "DD_KUBELET_TLS_VERIFY"
            value = "false"
          }

          resources {
            limits {
              cpu    = "256m"
              memory = "256Mi"
            }

            requests {
              cpu    = "100m"
              memory = "256Mi"
            }
          }

          volume_mount {
            name       = "installinfo"
            read_only  = true
            mount_path = "/etc/datadog-agent/install_info"
            sub_path   = "install_info"
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/datadog-agent"
          }

          volume_mount {
            name              = "runtimesocketdir"
            read_only         = true
            mount_path        = "/host/var/run"
            mount_propagation = "None"
          }

          volume_mount {
            name       = "sysprobe-socket-dir"
            read_only  = true
            mount_path = "/var/run/sysprobe"
          }

          volume_mount {
            name       = "sysprobe-config"
            mount_path = "/etc/datadog-agent/system-probe.yaml"
            sub_path   = "system-probe.yaml"
          }

          volume_mount {
            name              = "procdir"
            read_only         = true
            mount_path        = "/host/proc"
            mount_propagation = "None"
          }

          volume_mount {
            name              = "cgroups"
            read_only         = true
            mount_path        = "/host/sys/fs/cgroup"
            mount_propagation = "None"
          }

          volume_mount {
            name       = "debugfs"
            mount_path = "/sys/kernel/debug"
          }

          liveness_probe {
            http_get {
              path   = "/live"
              port   = "5555"
              scheme = "HTTP"
            }

            initial_delay_seconds = 15
            timeout_seconds       = 5
            period_seconds        = 15
            success_threshold     = 1
            failure_threshold     = 6
          }

          readiness_probe {
            http_get {
              path   = "/ready"
              port   = "5555"
              scheme = "HTTP"
            }

            initial_delay_seconds = 15
            timeout_seconds       = 5
            period_seconds        = 15
            success_threshold     = 1
            failure_threshold     = 6
          }

          image_pull_policy = "IfNotPresent"
        }

        container {
          name    = "process-agent"
          image   = "gcr.io/datadoghq/agent:7.23.1"
          command = ["process-agent", "-config=/etc/datadog-agent/datadog.yaml"]

          env {
            name = "DD_API_KEY"

            value_from {
              secret_key_ref {
                name = "datadog-agent"
                key  = "api-key"
              }
            }
          }

          env {
            name = "DD_KUBERNETES_KUBELET_HOST"

            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name  = "KUBERNETES"
            value = "yes"
          }

          env {
            name  = "DOCKER_HOST"
            value = "unix:///host/var/run/docker.sock"
          }

          env {
            name  = "DD_LOG_LEVEL"
            value = "INFO"
          }

          env {
            name  = "DD_SYSTEM_PROBE_ENABLED"
            value = "true"
          }

          env {
            name  = "DD_ORCHESTRATOR_EXPLORER_ENABLED"
            value = "false"
          }

          env {
            name  = "DD_KUBELET_TLS_VERIFY"
            value = "false"
          }

          resources {
            limits {
              cpu    = "256m"
              memory = "256Mi"
            }

            requests {
              cpu    = "100m"
              memory = "256Mi"
            }
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/datadog-agent"
          }

          volume_mount {
            name              = "runtimesocketdir"
            read_only         = true
            mount_path        = "/host/var/run"
            mount_propagation = "None"
          }

          volume_mount {
            name              = "cgroups"
            read_only         = true
            mount_path        = "/host/sys/fs/cgroup"
            mount_propagation = "None"
          }

          volume_mount {
            name       = "passwd"
            mount_path = "/etc/passwd"
          }

          volume_mount {
            name              = "procdir"
            read_only         = true
            mount_path        = "/host/proc"
            mount_propagation = "None"
          }

          volume_mount {
            name       = "sysprobe-socket-dir"
            read_only  = true
            mount_path = "/var/run/sysprobe"
          }

          volume_mount {
            name       = "sysprobe-config"
            mount_path = "/etc/datadog-agent/system-probe.yaml"
            sub_path   = "system-probe.yaml"
          }

          image_pull_policy = "IfNotPresent"
        }

        container {
          name    = "system-probe"
          image   = "gcr.io/datadoghq/agent:7.23.1"
          command = ["/opt/datadog-agent/embedded/bin/system-probe", "--config=/etc/datadog-agent/system-probe.yaml"]

          env {
            name = "DD_API_KEY"

            value_from {
              secret_key_ref {
                name = "datadog-agent"
                key  = "api-key"
              }
            }
          }

          env {
            name = "DD_KUBERNETES_KUBELET_HOST"

            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name  = "KUBERNETES"
            value = "yes"
          }

          env {
            name  = "DOCKER_HOST"
            value = "unix:///host/var/run/docker.sock"
          }

          env {
            name  = "DD_LOG_LEVEL"
            value = "INFO"
          }

          env {
            name  = "DD_SYSPROBE_SOCKET"
            value = "/var/run/sysprobe/sysprobe.sock"
          }

          env {
            name  = "DD_KUBELET_TLS_VERIFY"
            value = "false"
          }

          resources {
            limits {
              cpu    = "256m"
              memory = "256Mi"
            }

            requests {
              cpu    = "100m"
              memory = "256Mi"
            }
          }

          volume_mount {
            name              = "debugfs"
            mount_path        = "/sys/kernel/debug"
            mount_propagation = "None"
          }

          volume_mount {
            name       = "sysprobe-config"
            mount_path = "/etc/datadog-agent/system-probe.yaml"
            sub_path   = "system-probe.yaml"
          }

          volume_mount {
            name       = "sysprobe-socket-dir"
            mount_path = "/var/run/sysprobe"
          }

          volume_mount {
            name              = "procdir"
            read_only         = true
            mount_path        = "/host/proc"
            mount_propagation = "None"
          }

          volume_mount {
            name       = "cgroups"
            read_only  = true
            mount_path = "/host/sys/fs/cgroup"
          }

          image_pull_policy = "Always"

          security_context {
            capabilities {
              add = ["SYS_ADMIN", "SYS_RESOURCE", "SYS_PTRACE", "NET_ADMIN", "NET_BROADCAST", "IPC_LOCK"]
            }
          }
        }

        node_selector = {
          "kubernetes.io/os" = "linux"
        }

        service_account_name = var.service_name
      }
    }

    strategy {
      type = "RollingUpdate"

      rolling_update {
        max_unavailable = "10%"
      }
    }

    revision_history_limit = 10
  }
}
