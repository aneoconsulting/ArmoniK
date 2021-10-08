apiVersion: batch/v1
kind: Job
metadata:
  name: single-task
spec:
  template:
    spec:
      containers:
      - args: [Client.dll]
        name: generator
        securityContext:
            {}
        image: {{docker_registry}}{{image_name}}:{{image_tag}}
        imagePullPolicy: Always
        resources:
            limits:
              cpu: 100m
              memory: 128Mi
            requests:
              cpu: 100m
              memory: 128Mi
        volumeMounts:
          - name: agent-config-volume
            mountPath: /etc/agent
        env:
          - name: INTRA_VPC
            value: "1"
          - name: HTTP_PROXY
            value: ""
          - name: HTTPS_PROXY
            value: ""
          - name: NO_PROXY
            value: ""
          - name: http_proxy
            value: ""
          - name: https_proxy
            value: ""
          - name: no_proxy
            value: ""
      restartPolicy: Never
      nodeSelector:
        grid/type: Operator
      tolerations:
      - effect: NoSchedule
        key: grid/type
        operator: Equal
        value: Operator
      volumes:
        - name: agent-config-volume
          configMap:
            name: agent-configmap
  backoffLimit: 0
