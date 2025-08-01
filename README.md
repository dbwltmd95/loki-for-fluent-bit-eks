# loki-for-fluent-bit-eks
Fluent Bit를 사용해서 로그를 수집하고, 수집된 로그를 Loki로 전송한다.

---

### 1. Helm으로 Loki 설치
- grafana/loki-stack 사용 시, 이미지 버전 이슈로 Grafana에서 DataSource 등록이 되지 않는다. 
- grafana/loki-distributed 사용하여 설치를 진행한다.
- Fluent Bit로 로그를 수집하므로 Promtail은 비활성화 한다.

### 2. Helm으로 Fluent Bit 설치
      inputs: |
        [INPUT]
            Name tail
            Path /var/log/containers/*.log
            multiline.parser docker, cri
            Tag kube.*
            Mem_Buf_Limit 5MB
            Skip_Long_Lines On
         
      outputs: |
        [OUTPUT]
            name                   loki
            match                  *
            host                   loki.monitoring.svc.cluster.local
            port                   3100
            labels                 job=fluentbit
            auto_kubernetes_labels on

### 3. Helm으로 Grafana 설치 및 DataSource 등록
    http://loki.monitoring.svc.cluster.local:3100 
