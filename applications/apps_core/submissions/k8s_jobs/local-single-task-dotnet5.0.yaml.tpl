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
        imagePullPolicy: IfNotPresent
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
          - name: redis-secrets-volume
            mountPath: /redis_certificates
            readOnly: true
        env:
          - name: INTRA_VPC
            value: "1"
      restartPolicy: Never
      volumes:
        - name: agent-config-volume
          configMap:
            name: agent-configmap
        - name: redis-secrets-volume
          secret:
            secretName: {{redis_secrets}}
      imagePullSecrets:
        - name: regcred
  backoffLimit: 0
