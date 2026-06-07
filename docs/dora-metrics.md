# 📊 Métricas DORA — PetClinic DevOps

> **Equipo**: PetClinic DevOps  
> **Periodo de medición**: Semana de desarrollo del proyecto  
> **Fecha del reporte**: Junio 2026

---

## 1. ¿Qué son las métricas DORA?

Las métricas DORA (DevOps Research and Assessment) son los 4 indicadores clave definidos por el equipo de investigación de Google para medir el rendimiento de entrega de software de un equipo. Fueron establecidas tras años de investigación en el programa **DORA** del libro *Accelerate* (Nicole Forsgren, Jez Humble, Gene Kim).

| Métrica | Qué mide | Categoría |
|---------|----------|-----------|
| **Deployment Frequency (DF)** | Frecuencia con la que se despliega a producción | Throughput |
| **Lead Time for Changes (LT)** | Tiempo desde commit hasta producción | Throughput |
| **Change Failure Rate (CFR)** | % de deploys que causan incidentes | Stability |
| **Mean Time to Recovery (MTTR)** | Tiempo para restaurar servicio tras falla | Stability |

---

## 2. Benchmarks DORA Report 2024

Según el **DORA State of DevOps Report 2024**, los equipos se clasifican en:

| Métrica | Elite | High | Medium | Low |
|---------|-------|------|--------|-----|
| **Deployment Frequency** | On-demand (múltiples/día) | 1 vez/semana a 1 vez/mes | 1 vez/mes a 1 vez cada 6 meses | < 1 vez cada 6 meses |
| **Lead Time for Changes** | < 1 hora | 1 día a 1 semana | 1 semana a 1 mes | > 6 meses |
| **Change Failure Rate** | < 5% | 5-10% | 10-15% | > 15% |
| **Mean Time to Recovery** | < 1 hora | < 1 día | 1 día a 1 semana | > 6 meses |

---

## 3. Métricas medidas de nuestro equipo

### 3.1 Deployment Frequency (DF)

| Aspecto | Valor |
|---------|-------|
| **Deploys a staging** | ~3-5 por semana (cada push a main) |
| **Deploys a producción** | ~2-3 por semana (con aprobación manual) |
| **Mecanismo** | Pipeline CI/CD automatizado en GitHub Actions |
| **Clasificación DORA** | **High** ✅ |

**Cómo se mide**: Cada push a la rama `main`/`master` dispara automáticamente el pipeline CI/CD que despliega a staging. La promoción a producción requiere aprobación manual en el environment `production` de GitHub.

**Evidencia**: Job `deploy-staging` se ejecuta automáticamente → Job `deploy-production` requiere aprobación → Deployment frequency = cada push aprobado.

---

### 3.2 Lead Time for Changes (LT)

| Fase | Tiempo promedio |
|------|-----------------|
| Build + Tests + SAST | ~3-5 min |
| Docker Build + Trivy Scan | ~2-3 min |
| Terraform Apply | ~1-3 min |
| Deploy Staging | ~3-5 min |
| DAST (OWASP ZAP) | ~5-10 min |
| Aprobación manual (producción) | Variable (minutos a horas) |
| **Total (sin aprobación)** | **~15-25 min** |
| **Clasificación DORA** | **Elite** ✅ |

**Cómo se mide**: Tiempo total del pipeline CI/CD desde el commit hasta el deploy exitoso en staging (automático). El lead time sin contar la aprobación manual es de ~15-25 minutos.

**Evidencia**: Tiempos visibles en GitHub Actions → cada run del workflow `CI/CD Pipeline - Spring PetClinic (GCP & GKE)`.

---

### 3.3 Change Failure Rate (CFR)

| Aspecto | Valor |
|---------|-------|
| **Total de deploys exitosos** | ~8-12 durante el proyecto |
| **Deploys que causaron fallas** | 0 rollbacks necesarios |
| **Change Failure Rate** | **0%** |
| **Clasificación DORA** | **Elite** ✅ |

**Cómo se mide**: Contamos los deploys que resultaron en:
- Rollback de la aplicación
- Incidentes reportados
- Necesidad de hotfix inmediato

**Nota**: Los restarts iniciales de Grafana fueron por configuración de recursos, no por un cambio en el código de la aplicación. No cuentan como change failure.

---

### 3.4 Mean Time to Recovery (MTTR)

| Aspecto | Valor |
|---------|-------|
| **Incidentes de producción** | 0 incidentes durante el periodo |
| **MTTR estimado** | N/A (sin incidentes) |
| **Capacidad de recovery** | < 30 min (re-deploy del pipeline) |
| **Clasificación DORA** | **Elite** ✅ |

**Cómo se mide**: En caso de falla, el equipo puede:
1. Revertir el commit → pipeline se ejecuta automáticamente (~15 min)
2. Escalar manualmente con `kubectl rollout undo` (~2 min)
3. Las alertas de Prometheus notifican proactivamente sobre problemas

**Mecanismos que soportan bajo MTTR**:
- Rolling update con `maxUnavailable: 0` → zero-downtime deploys
- Liveness/Readiness probes en cada pod
- Alertas configuradas: `PetClinicSLOAvailabilityBreach`, `PetClinicHighErrorRate`, `PetClinicPodCrashLooping`
- HPA para auto-escalar bajo carga

---

## 4. Resumen comparativo con DORA 2024

| Métrica | Nuestro equipo | Benchmark DORA | Clasificación |
|---------|---------------|----------------|---------------|
| **Deployment Frequency** | 2-5/semana | High: 1/semana - 1/mes | ✅ **High** |
| **Lead Time for Changes** | ~15-25 min | Elite: < 1 hora | ✅ **Elite** |
| **Change Failure Rate** | 0% | Elite: < 5% | ✅ **Elite** |
| **Mean Time to Recovery** | < 30 min (estimado) | Elite: < 1 hora | ✅ **Elite** |

### Clasificación general: **Elite / High** 🏆

---

## 5. Propuestas de mejora

Aunque nuestras métricas son buenas para un proyecto de una semana, hay oportunidades de mejora para un entorno productivo real:

### 5.1 Deployment Frequency → Elite
| Mejora | Impacto |
|--------|---------|
| Implementar **trunk-based development** | Reducir tiempo en branches, más deploys |
| Agregar **feature flags** (LaunchDarkly, Unleash) | Desplegar sin activar features incompletas |
| Automatizar promoción a producción con **canary releases** | Eliminar aprobación manual |

### 5.2 Lead Time for Changes
| Mejora | Impacto |
|--------|---------|
| **Cache de dependencias Maven** más agresivo | Reducir build time un ~30% |
| **Paralelizar stages** del pipeline | Reducir tiempo total |
| Usar **pre-built base images** para Docker | Eliminar descarga de dependencias |

### 5.3 Change Failure Rate
| Mejora | Impacto |
|--------|---------|
| Agregar **tests de integración** pre-deploy | Detectar fallas antes de staging |
| Implementar **smoke tests** post-deploy automáticos | Validar deploy exitoso |
| **Contract testing** con herramientas como Pact | Prevenir breaking changes |

### 5.4 Mean Time to Recovery
| Mejora | Impacto |
|--------|---------|
| **Runbooks automatizados** | Respuesta estandarizada ante incidentes |
| **PagerDuty/Opsgenie** integrado con Alertmanager | Notificación inmediata al equipo |
| **Chaos Engineering** (Litmus, Chaos Mesh) | Validar resiliencia proactivamente |

---

## 6. Cómo el pipeline soporta las métricas DORA

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   Commit     │────▶│  CI Pipeline  │────▶│   Staging    │
│  (Developer) │     │ Build+Test    │     │  (Automatic) │
└─────────────┘     │ SAST+Trivy    │     └──────┬───────┘
                    └──────────────┘            │
                                                ▼
                                        ┌──────────────┐
                                        │  DAST Scan   │
                                        │ (OWASP ZAP)  │
                                        └──────┬───────┘
                                               │
                                               ▼
                                        ┌──────────────┐
                                        │  Production  │
                                        │ (Approval)   │
                                        └──────────────┘
```

| Componente del pipeline | Métrica DORA que soporta |
|------------------------|--------------------------|
| GitHub Actions CI/CD automático | **DF** — Deploy automático en cada push |
| Pipeline end-to-end ~15-25 min | **LT** — Lead time bajo |
| Trivy + SonarCloud + OWASP ZAP | **CFR** — Prevención de defectos |
| Rolling Update + Probes + Alertas | **MTTR** — Recovery rápido |
| Prometheus + Grafana + Alertmanager | **MTTR** — Detección proactiva |

---

## 7. Referencias

- [DORA State of DevOps Report 2024](https://dora.dev/research/)
- [Accelerate: The Science of Lean Software and DevOps](https://itrevolution.com/product/accelerate/)
- [Google SRE Book — Service Level Objectives](https://sre.google/sre-book/service-level-objectives/)
- [Four Keys Project (DORA metrics tool)](https://github.com/dora-team/fourkeys)
