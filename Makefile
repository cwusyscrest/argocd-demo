production:
	@argocd app create $@ \
    --dest-namespace argocd \
    --dest-server https://kubernetes.default.svc \
    --repo https://github.com/cwusyscrest/argocd-demo.git \
    --path apps \
    --helm-set environment=$@

pre-production:
	@argocd app create $@ \
    --dest-namespace argocd \
    --dest-server https://kubernetes.default.svc \
    --repo https://github.com/cwusyscrest/argocd-demo.git \
    --path apps \
    --helm-set environment=$@

sync-pre-production:
	@argocd app sync pre-production
	@argocd app sync -l argocd.argoproj.io/instance=pre-production

sync-production:
	@argocd app sync production
	@argocd app sync -l argocd.argoproj.io/instance=production

deploy: pre-production production
sync: sync-pre-production sync-production

delete-pre-production:
	@argocd app delete pre-production

delete-production:
	@argocd app delete production

delete: delete-pre-production delete-production

.PHONY: production sync-production \
	delete-pre-production delete-production \
	pre-production sync-pre-production \
	deploy sync delete \
	init deinit \
	init-argocd deinit-argocd \
	watch

init: init-argocd
deinit: delete deinit-argocd

init-argocd:
	@helm repo add argo https://argoproj.github.io/argo-helm
	@kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	@helm install argocd --namespace argocd argo/argo-cd -f argocd-init/values.yaml --wait
	@echo "Default argocd admin password, be sure to change it! '$$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)'"

deinit-argocd:
	@helm3 uninstall argocd --namespace argocd
	@kubectl delete namespace argocd

watch:
	@watch "kubectl get pods -A --sort-by=status.startTime | awk 'NR<2{print \$$0;next}{print \$$0| \"tail -r\"}'"
