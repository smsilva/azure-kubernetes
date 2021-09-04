FROM alpine:3.13.6
ENV KUBECONFIG_DATA=""
ADD entrypoint.sh /opt/kubernetes/entrypoint.sh
ADD kubectl /opt/kubernetes/kubectl
CMD /opt/kubernetes/entrypoint.sh
