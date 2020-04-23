production:
	argocd app create $@ \
    --dest-namespace argocd \
    --dest-server https://kubernetes.docker.internal:6443 \
    --repo https://github.com/caitlin615/argocd-demo.git \
    --path apps \
    --values values-$@.yaml

pre-production:
	argocd app create $@ \
    --dest-namespace argocd \
    --dest-server https://kubernetes.docker.internal:6443 \
    --repo https://github.com/caitlin615/argocd-demo.git \
    --path apps \
    --values values-$@.yaml

sync-pre-production:
	argocd app sync pre-production
	argocd app sync -l app.kubernetes.io/instance=pre-production

sync-production:
	argocd app sync production
	argocd app sync -l app.kubernetes.io/instance=production

deploy: pre-production production
sync: sync-pre-production sync-production

delete:
	argocd app delete pre-production
	argocd app delete production

.PHONY: portforward init-argocd deinit-argocd  \
	production sync-production \
	pre-production sync-pre-production \
	deploy sync delete \
	nginx deinit-nginx \
	deinit

init-argocd:
	@# TODO: This should be installed via helm
	@kubectl create namespace argocd
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	@kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer", "ports": [{"name": "http-8080", "port": 8080, "targetPort": 8080, "protocol": "TCP"}]}}'
	@echo "Default argocd admin password, be sure to change it! '$$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)'"

deinit-argocd:
	kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
	kubectl delete namespace argocd

nginx:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml

deinit-nginx:
	kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
	kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml

deinit: deinit-argocd deinit-nginx
