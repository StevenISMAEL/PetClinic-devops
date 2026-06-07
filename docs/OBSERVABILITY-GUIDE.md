# 🔭 Guía de Observabilidad — PetClinic DevOps

> Guía completa para gestionar el stack de observabilidad: Prometheus, Grafana, Alertmanager.

---

## Tabla de contenidos

1. [Arquitectura de observabilidad](#1-arquitectura-de-observabilidad)
2. [Acceder a Grafana](#2-acceder-a-grafana)
3. [Importar el dashboard SLO manualmente](#3-importar-el-dashboard-slo-manualmente)
4. [Verificar alertas en Prometheus](#4-verificar-alertas-en-prometheus)
5. [Verificar alertas en Alertmanager](#5-verificar-alertas-en-alertmanager)
6. [Exponer Grafana de forma estable](#6-exponer-grafana-de-forma-estable)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Arquitectura de observabilidad

```
┌──────────────────────────────────────────────────────────────┐
│                    Namespace: observability                   │
│                                                              │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────┐  │
│  │ Prometheus   │◄───│ ServiceMonitor│    │  Alertmanager  │  │
│  │  (scraping)  │    │ petclinic-   │    │  (alertas)     │  │
│  │              │────▶│  monitor     │    │                │  │
│  └──────┬───────┘    └──────────────┘    └────────────────┘  │
│         │                                       ▲            │
│         │              ┌──────────────┐         │            │
│         └─────────────▶│ PrometheusRule│─────────┘            │
│                        │ petclinic-   │                      │
│         ┌──────────────│  alerts      │                      │
│         │              └──────────────┘                      │
│         ▼                                                    │
│  ┌─────────────┐                                             │
│  │   Grafana    │◄── ConfigMap (petclinic-slo-dashboard)     │
│  │ (dashboards) │                                            │
│  └─────────────┘                                             │
└──────────────────────────────────────────────────────────────┘
         ▲
         │ scrape /actuator/prometheus
         │
┌────────┴─────────────────────────────────────────────────────┐
│  Namespace: staging / devops-lab                             │
│  ┌─────────────────────────────────┐                         │
│  │ PetClinic (Spring Boot)         │                         │
│  │ - Micrometer + Prometheus exp.  │                         │
│  │ - Port 8080                     │                         │
│  └─────────────────────────────────┘                         │
└──────────────────────────────────────────────────────────────┘
```

**Componentes clave:**
- **ServiceMonitor** (`prometheus-service-monitor.yaml`): Indica a Prometheus que haga scrape de `/actuator/prometheus` en los namespaces `staging` y `devops-lab`
- **PrometheusRule** (`alert-rules.yaml`): Define las reglas de recording y alertas
- **ConfigMap** (`grafana-slo-dashboard.yaml`): Dashboard SLO cargado automáticamente vía sidecar de Grafana
- **Grafana**: Visualización de métricas con dashboards

---

## 2. Acceder a Grafana

### Opción A: Port-forward (desarrollo/testing)

```bash
kubectl port-forward svc/prometheus-grafana -n observability 3000:80
```

Luego abre: http://localhost:3000

**Credenciales por defecto:**
- Usuario: `admin`
- Contraseña: `PetClinic2026!`

### Opción B: Servicio LoadBalancer (exponer externamente)

Ver [sección 6](#6-exponer-grafana-de-forma-estable) para instrucciones de exposición pública.

---

## 3. Importar el dashboard SLO manualmente

El dashboard se carga automáticamente vía ConfigMap + sidecar de Grafana. Sin embargo, si necesitas importarlo manualmente (o usar la versión mejorada con `__inputs`):

### Paso 1: Acceder a Grafana
Abre Grafana en tu navegador (ver sección 2).

### Paso 2: Importar dashboard
1. Click en el icono **"+"** (menú lateral izquierdo)
2. Seleccionar **"Import"**
3. Click en **"Upload JSON file"**
4. Seleccionar el archivo: `monitoring/dashboards/petclinic-slo-dashboard.json`
5. En el campo **"Prometheus"**, seleccionar tu datasource de Prometheus
6. Click en **"Import"**

### Paso 3: Verificar
El dashboard "**PetClinic SLO Dashboard**" debe aparecer con:
- ✅ 4 filas organizadas por categoría
- ✅ 11 paneles con métricas en vivo
- ✅ Auto-refresh cada 30 segundos

### ¿No ves datos?
- Verifica que PetClinic esté corriendo: `kubectl get pods -n staging`
- Genera tráfico: `curl http://<PETCLINIC_IP>/`
- Verifica scraping: Prometheus UI → Status → Targets → buscar `petclinic`

---

## 4. Verificar alertas en Prometheus

### Paso 1: Port-forward a Prometheus

```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n observability 9090:9090
```

### Paso 2: Verificar reglas cargadas

Abre http://localhost:9090/rules y busca los grupos:
- `petclinic-slo` → Recording rules + alertas de SLO
- `petclinic-infrastructure` → Alertas de infraestructura

### Paso 3: Verificar alertas activas

Abre http://localhost:9090/alerts y busca:

| Alerta | Estado esperado | Significado |
|--------|----------------|-------------|
| `PetClinicSLOAvailabilityBreach` | ✅ Inactive (verde) | Disponibilidad > 99.9% |
| `PetClinicHighErrorRate` | ✅ Inactive (verde) | Error rate < 5% |
| `PetClinicHighLatencyP99` | ✅ Inactive (verde) | Latencia P99 < 2s |
| `PetClinicPodCrashLooping` | ✅ Inactive (verde) | Sin pod restarts |
| `PetClinicPodNotReady` | ✅ Inactive (verde) | Todos los pods Ready |
| `PetClinicHighMemoryUsage` | ✅ Inactive (verde) | JVM heap < 90% |

> **Nota**: Las alertas en estado "Inactive" (verde) es lo normal y deseable — significa que no hay problemas activos.

### Paso 4: Probar que una alerta se activa (opcional)

Para demostrar que las alertas funcionan, puedes escalar los pods a 0 temporalmente:

```bash
# Esto activará PetClinicPodNotReady después de 10 minutos
kubectl scale deployment petclinic-deployment -n staging --replicas=0

# RESTAURAR INMEDIATAMENTE después de la demo:
kubectl scale deployment petclinic-deployment -n staging --replicas=1
```

---

## 5. Verificar alertas en Alertmanager

### Paso 1: Port-forward a Alertmanager

```bash
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n observability 9093:9093
```

### Paso 2: Ver alertas

Abre http://localhost:9093/#/alerts

Aquí verás:
- Alertas activas (firing) en rojo
- Alertas silenciadas
- Historial de alertas

### Paso 3: Verificar que las reglas de PetClinic están registradas

```bash
# Listar todas las PrometheusRules
kubectl get prometheusrules -n observability

# Verificar nuestra regla específica
kubectl describe prometheusrule petclinic-alerts -n observability
```

Deberías ver la salida con los 6 alertas definidas:
1. `PetClinicSLOAvailabilityBreach`
2. `PetClinicHighLatencyP99`
3. `PetClinicHighErrorRate`
4. `PetClinicPodCrashLooping`
5. `PetClinicPodNotReady`
6. `PetClinicHighMemoryUsage`

---

## 6. Exponer Grafana de forma estable

### Opción recomendada: Servicio LoadBalancer dedicado

Crear un servicio `grafana-public` que exponga Grafana con una IP pública fija:

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: grafana-public
  namespace: observability
spec:
  type: LoadBalancer
  selector:
    app.kubernetes.io/name: grafana
    app.kubernetes.io/instance: prometheus
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
EOF
```

### Verificar la IP asignada

```bash
# Esperar a que GCP asigne la IP (puede tomar 1-2 minutos)
kubectl get svc grafana-public -n observability -w
```

Cuando la columna `EXTERNAL-IP` muestre una IP (no `<pending>`), puedes acceder a Grafana desde: `http://<EXTERNAL-IP>/`

### Verificar que funciona

```bash
curl -s -o /dev/null -w "%{http_code}" http://<EXTERNAL-IP>/login
# Debería retornar 200
```

### ⚠️ Consideraciones de seguridad

En un entorno de producción real, deberías:
- Usar HTTPS con un certificado TLS
- Configurar autenticación OAuth (Google, GitHub)
- Restringir acceso por IP con Network Policies
- Usar un Ingress Controller con TLS termination

Para este proyecto académico, HTTP con autenticación básica de Grafana es suficiente.

---

## 7. Troubleshooting

### Grafana no muestra datos en el dashboard

```bash
# 1. Verificar que Prometheus está scrapeando PetClinic
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n observability 9090:9090
# Ir a http://localhost:9090/targets → buscar "petclinic-monitor"

# 2. Verificar que PetClinic expone métricas
kubectl port-forward svc/petclinic-service -n staging 8080:8080
curl http://localhost:8080/actuator/prometheus | head -20

# 3. Verificar que el ServiceMonitor existe
kubectl get servicemonitors -n observability

# 4. Verificar que Grafana tiene el datasource de Prometheus
# En Grafana → Configuration → Data Sources → debe haber "Prometheus"
```

### Las alertas no aparecen en Prometheus

```bash
# 1. Verificar que el PrometheusRule fue aplicado
kubectl get prometheusrules -n observability
# Debe listar: petclinic-alerts

# 2. Verificar que Prometheus acepta rules de cualquier namespace
# En prometheus-values.yaml debe estar:
#   ruleSelectorNilUsesHelmValues: false

# 3. Re-aplicar si es necesario
kubectl apply -f monitoring/alert-rules.yaml

# 4. Verificar en Prometheus UI
# http://localhost:9090/rules → buscar "petclinic"
```

### Grafana se reinicia constantemente

```bash
# 1. Verificar recursos
kubectl describe pod -l app.kubernetes.io/name=grafana -n observability | grep -A5 "Limits\|Requests"

# 2. Ver logs
kubectl logs -l app.kubernetes.io/name=grafana -n observability --tail=50

# 3. Si es por OOM, aumentar límites en prometheus-values.yaml:
# grafana.resources.limits.memory: "512Mi"
# Luego: helm upgrade --install prometheus ... --values monitoring/prometheus-values.yaml
```

### No puedo acceder a Grafana por LoadBalancer

```bash
# 1. Verificar el servicio
kubectl get svc grafana-public -n observability

# 2. Si EXTERNAL-IP es <pending>, esperar o verificar cuota de IPs
gcloud compute addresses list --project=petclinic-devops

# 3. Verificar que los selectors del servicio son correctos
kubectl get pods -n observability -l app.kubernetes.io/name=grafana
# Debe haber al menos 1 pod

# 4. Verificar firewall rules
gcloud compute firewall-rules list --filter="allowed.ports:80"
```

---

## Resumen de comandos rápidos

```bash
# === ACCESO ===
kubectl port-forward svc/prometheus-grafana -n observability 3000:80          # Grafana
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n observability 9090:9090  # Prometheus
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager -n observability 9093:9093 # Alertmanager

# === VERIFICACIÓN ===
kubectl get prometheusrules -n observability           # Listar reglas
kubectl get servicemonitors -n observability            # Listar monitors
kubectl get svc -n observability                        # Listar servicios

# === APLICAR CAMBIOS ===
kubectl apply -f monitoring/alert-rules.yaml            # Aplicar alertas
kubectl apply -f monitoring/grafana-slo-dashboard.yaml  # Aplicar dashboard ConfigMap
kubectl apply -f monitoring/prometheus-service-monitor.yaml  # Aplicar service monitor

# === OBSERVAR ESTADO ===
kubectl get pods -n observability                       # Estado de pods
kubectl get pods -n staging                             # Estado de app
kubectl top pods -n observability                       # Recursos usados
```
