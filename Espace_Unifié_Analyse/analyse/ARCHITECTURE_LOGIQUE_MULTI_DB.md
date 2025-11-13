# Architecture Logique — Version MULTI-DB (par module/formulaire)

## Principe
Une base par module (ou par famille de formulaires). Exemples: DB Heures, DB Badges, DB Demandes diverses. Chaque module possède son schéma optimisé, tout en exposant une couche commune (API, événements) pour l’agrégation globale et le dashboard.

## Schéma logique (conceptuel)

### Commun (métadonnées & orchestrateur)
- registry des modules (codes, endpoints, versions, états)
- permissions (RBAC central) + audit_log (fédéré)
- events_bus (Kafka/NATS/Service Bus) — synchro et agrégation KPI

### Exemple DB Heures
- hs_form_instance, hs_values, hs_workflow_definition, hs_workflow_instance, hs_workflow_event
- Tables spécifiques: hs_pointage, hs_delta

### Exemple DB Badges
- bd_form_instance, bd_values, bd_workflow_*
- Tables spécifiques: bd_acces, bd_historiques

### Agrégation (Base Dashboard)
- kpi_item(id, kind, label, value, unit, role_scope, source, computed_at)
- backlog_item(id, title, source, assignee, due_at, link, role_scope)

## Flux (simplifié)
1. Un module gère ses formulaires et workflows dans sa DB.
2. Il publie des événements (submit/approve/refuse/close) sur events_bus.
3. Un job d’agrégation met à jour la base Dashboard (KPI/backlog).
4. L’UI interroge chaque module ou le Dashboard selon le besoin.

## Avantages
- Isolation: scalabilité indépendante, pannes circonscrites.
- Optimisation par domaine: schémas et index adaptés au métier.
- Évolutivité: ajout d’un nouveau module = nouvelle DB + enregistrement au registry.

## Inconvénients
- Complexité: ops, monitoring, sauvegardes multiples.
- Cohérence: agrégation et transactions cross-modules plus complexes.
- Latence: KPI via flux/eventual consistency.

## Performance & Scalabilité
- Chaque DB peut sharder/partitionner selon ses besoins.
- Files d’événements pour absorber les pics.
- Cache par module et au niveau Dashboard.

## Sécurité & Conformité
- RBAC central + ACL propres au module.
- Journalisation locale + fédération dans un audit global.
- Politiques de rétention par module (conformité facilitée).

## Quand choisir MULTI-DB ?
- Domaines très hétérogènes (contraintes techniques différentes).
- Volumétrie élevée ou SLA très stricts par domaine.
- Équipe/organisation orientée « microservices ».

---

## Gouvernance & Contrats
- Contrats d’événements (submit/approve/refuse/comment/close): schémas versionnés.
- Contrats API: versionnement, breaking changes maîtrisées.
- Registry: découverte, statut des modules, health-checks.

## Stratégie de migration
- Démarrer en MONO-DB pour l’amorçage.
- Extraire progressivement les domaines lourds (Heures, Badges) vers des DB dédiées.
- Mettre en place l’events_bus et le Dashboard d’agrégation.

## Exemple de mapping d’événements (indicatif)
```json
{
  "event": "form.workflow.approve",
  "version": 1,
  "module": "heures",
  "instanceId": "uuid",
  "formType": "HEURE_SUP",
  "state": "en_attente_rh",
  "by": "user123",
  "at": "2025-10-28T10:22:33Z",
  "payload": { "comment": "OK" }
}
```
