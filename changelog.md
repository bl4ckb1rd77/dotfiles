* helm: add namespace to various OpenSearch resources in templates (#1338)
* webhook: reject duplicate node pool component names
* Add reconciler error count prometheus metric
* fix: add waiting status check in smartscaler to avoid race condition
* chart: fix operator chart appVersion
* fix cve-2026-24051
* Fix typos in user guide: version fields are strings
* Support custom opensearch HOME path
* fix: compare the node name before reconcile in smart scaler (#1321)
* feat: support hostpath in additionalVolumes (#1312)
* Fix: Properly quote YAML values with special characters
* add storageclass for bootstrap pod
* Check rollout status of existing nodepools before cleaning up removed nodepools (#1190)
* chore: add markStsReady helper function
* ci: use ct for chart lint (#1306)
* fix cve-2025-68121
* Add configuration options for securityconfig-update pod (#1270)
* fix: transfer certificate secret ownership during API migration
* fix: test MaxAnnotationSize check against encoded size
* fix: limit the last-applied annotation length
* fix: one-time sync from old apiVersion to new one
* feat: add CVE check CI job and update task file for olm validation (#1288)
* Add OLM bundle and Red Hat OpenShift certification support
* add rotateDaysBeforeExpiry to the OpenSearchCluster manifest Signed-off-by: Andrii Petruchek <apetruchek@gmail.com>
* Added support for using host network
* Support multi-arch builds for helm docs
* doc: update doc for 3.0 pre-release (#1271)
* fix: remove unnecessary permissions
* chore: always calculate the config hash for all node pools (#1244)
* chroe: set readinessprobe for dashboard
* feat: support grpc APIs (#1266)
* major: change opensearch.opster.io to opensearch.org (#1254)
* allow yellow status until we have cluster phase `UPDATING`
* add CI for upgrade test and disallow yellow status
* feat: add operator version upgrade test
* add missing mockery
* refactor: update module path from Opster to opensearch-project
* update golang to 1.24.11 (#1259)
* feat: add data integrity testing framework and practical test scenarios (#1232)
* Fix webhook service selector labels
* fix: update the condition for node version mismatch during upgrade
* test: ism policy graceful error handling
* feat: enable smartScaler in default (#1240)
* chore: automate crd doc gen
* fix: handle pre-release versions in version constraint checker
* fix: resolve deadlocks when upgrading to 3.0.0 (#1217)
* ci: remove dotnet from container host to avoid space issues (#1231)
* fix: use additionalConfig and env correctly (#1214)
* test: add Ordered to integration test suites (#1221)
* ci: fix operator pod label selector
* upgrade linter to 2.7.2
* chore: set priorityClassname and labels
* chore: correct the Prometheus monitoring plugin ref
* fix: add disk size for bootstrap volume size (#1216)
* Fix #1066: Prevent illegal Pod spec updates on bootstrap Pod (#1083)
* update docs
* feat: add default pod anti-affinity for cluster pods
* feat: add webhook validation to prevent storage class changes
* feat: simplify password management with automatic hash generation (#1193)
* Add appProtocol to cluster service definition (#999)
* Add hostAliases to opensearch and dashboards pods (#1085)
* fix: make security update job fail when retry attempts over
* feat: removes ambiguity in TLS configs (#1207)
* Use higher cpu limit for operator
* Added support for topologySpreadConstraints for Dashboards  Signed-of… (#1195)
* fix: replace manual retry patterns with context-aware polling (#1089)
* feat: add NFS volume support to OpenSearchCluster CRD (#1091)
* Parallelize and cleanup transport certs (#1197)
* support NAMESPACE override
* change SetVMMaxMapCount to *bool
* enable coordinator nodes
* Add TLS certificate hot reloading support (fixes #1021) (#1086)
* feat(helm): add namespace-scoped RBAC support (#1183)
* replace readyReplicas with direct pod counts
* feat: make dashboard replicas and version fields optional (#1087)
* feat: add validation webhook (#1126)
* Add support for adding PVC volumes as Additional Volumes (#852)
* upload error logs for operator test
* Fix RemoveExcludeNodeHost leaving trailing/leading commas in exclude._name
* adjust operator helm chart labels & resource names (#1072)
* chore: update versions in upgrade test
* feat: add OperatorClusterURL and CustomFQDN support (#1147)
* Fix #1079: Set setVMMaxMapCount default to true for production readiness (#1084)
* Improve upgrade status reporting in cluster CR (#1168)
* fix: collect pod logs in dispatch workflows and set disk watermarks (#1170)
* install given plugins in bootstrap node
* ci: increase timeout for helm test
* increase timeout for dashboards
* fix: remove kubeRbacProxy from helm docs
* Correct error message when downgrading OpenSearch version
* feat: add helm-docs target; fix: invalid --set param in functional tests (#1032)
* Allow the opensearch operator to watch multiple namespaces
* Remove kube-rbac-proxy in favor of WithAuthenticationAndAuthorization (#1095)
* use jobName instead of instance.Name
* add opster label to securityconfig-update job and pod
* Feat: Allow disabling SSL in OpenSearchCluster CRD with DisableSSL
* fix admin cert generation
* fix: increase timeout for upgrade test
* feat: quorum-safe rolling restarts across nodepools (#1141)
* feat: make certificates duration configurable
* feat(pvc): Allow custom labels and annotations on PVCs (#1128)
* updated prometheus api version to be closer to upstream and to match … (#1145)
* Fix setting jvm heap size params (#1107)
* format dashboards.go
* add support for annotations on dashboard deployment
* Add Prometheus metrics and certificate rotation (#1112)
* feat(chart): add cluster.general.monitoring.labels field to values.yaml (#1005)
* remove cisco-open pkgs
* feat: add initContainers (#1143)
* Add sidecar container support (#1110)
* Fix MergeConfigs() to work with multiple node pools (#1059)
* Fix: Respect storageClassName="" for static provisioning (#1097)
* feat: use PVC for data volume of bootstrap pod
* fix: correct namespace restriction for reconcile watch
* Decrease security config updater poll interval to 20s (#1069)
* Allow customization of the message key in the JSON log format
* fix: correct typos in cleanupStatefulSets func
* Update maintainers list in k8s repository (#1123)
* Fix: SnapshotPolicy deletion schedule incorrectly uses creation schedule (#1122)
* Use container/pod securityContext user/group as owner for /usr/share/opensearch/data directory (#1109)
* Add support for bootstrap pod annotations (#1099)
* make diskSize value consistent (#1067)
* Fix: Don't force ssl.verificationMode to none (#1061)
* fix(helm): use serviceName for ingress backend if set, fallback to clusterName (#1043)
* feat: make readiness probe and startup probe command configurable (#981)
* Fix: combine image and version field for initHelper of chart in opensearch-cluster (>=3.0.0) (#1040)