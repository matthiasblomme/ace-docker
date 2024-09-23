# OpenShift Command Cheat Sheet

## Pod Management

### Get Pod Information
- **List all pods in a namespace:**
  ```bash
  oc get pods -n <namespace>
  ```
- **Describe a specific pod (detailed information):**
  ```bash
  oc describe pod <pod-name> -n <namespace>
  ```
- **Retrieve the YAML definition for a pod:**
  ```bash
  oc get pod <pod-name> -n <namespace> -o yaml
  ```

### Interact with Pod Containers
- **Get logs from a specific pod:**
  ```bash
  oc logs <pod-name> -n <namespace>
  ```
- **Get logs from a specific container within a pod:**
  ```bash
  oc logs <pod-name> -c <container-name> -n <namespace>
  ```
- **Get logs from the previous instance of a container (after a restart):**
  ```bash
  oc logs <pod-name> -n <namespace> --previous
  ```
- **Open a terminal (interactive shell) inside a pod:**
  ```bash
  oc exec -it <pod-name> -n <namespace> -- /bin/bash
  ```
- **Open a shell using `sh` (if bash is not available):**
  ```bash
  oc exec -it <pod-name> -n <namespace> -- /bin/sh
  ```

## Pod Lifecycle Management

### Stop/Scale Down Pods
- **Scale a Deployment/DeploymentConfig to 0 replicas (stops all pods):**
  ```bash
  oc scale deployment/<deployment-name> --replicas=0 -n <namespace>
  ```
  or
  ```bash
  oc scale dc/<deploymentconfig-name> --replicas=0 -n <namespace>
  ```
- **Delete a specific pod:**
  ```bash
  oc delete pod <pod-name> -n <namespace>
  ```
- **Delete a specific deployment (and its associated pods):**
  ```bash
  oc delete deployment <deployment-name> -n <namespace>
  ```

## Resource Management

### Create and Manage Resources
- **Apply a resource configuration from a YAML file:**
  ```bash
  oc apply -f <file.yaml> -n <namespace>
  ```
- **Delete a resource using a YAML file:**
  ```bash
  oc delete -f <file.yaml> -n <namespace>
  ```

### View and Retrieve Resources
- **List all resources of a specific type:**
  ```bash
  oc get <resource-type> -n <namespace>
  ```
  Example for deployments:
  ```bash
  oc get deployment -n <namespace>
  ```
- **Retrieve the YAML definition for any resource:**
  ```bash
  oc get <resource-type> <resource-name> -n <namespace> -o yaml
  ```

## Event Management

### View Events
- **Get recent events in a namespace:**
  ```bash
  oc get events -n <namespace>
  ```
- **Get events related to a specific pod:**
  ```bash
  oc get events -n <namespace> --field-selector involvedObject.name=<pod-name>
  ```

## Namespace Management

### Switch Between Projects/Namespaces
- **View the current project (namespace):**
  ```bash
  oc project
  ```
- **Switch to a different project (namespace):**
  ```bash
  oc project <namespace>
  ```

## Service and Route Management

### View Services and Routes
- **List all services in a namespace:**
  ```bash
  oc get svc -n <namespace>
  ```
- **Describe a specific service:**
  ```bash
  oc describe svc <service-name> -n <namespace>
  ```
- **List all routes in a namespace:**
  ```bash
  oc get routes -n <namespace>
  ```
- **Describe a specific route:**
  ```bash
  oc describe route <route-name> -n <namespace>
  ```
