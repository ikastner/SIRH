# Architecture Logique — Version MONO-DB (Unifiée)

## Principe
Une base de données unique pour tous les formulaires et workflows RH. Le modèle est générique et extensible (types de formulaires + moteur de workflow), ce qui évite de créer de nouvelles tables à chaque nouveau formulaire.

## Schéma logique (conceptuel)

- Formulaires (métadonnées et instances)
  - `form_type(id, code, label, version, actif, description)`
  - `form_field(id, form_type_id, code, label, kind, required, options, validations)`
  - `form_instance(id, form_type_id, created_by, current_state, created_at, updated_at)`
  - `form_instance_value(id, form_instance_id, field_code, value)`
- Workflows (définition et exécution)
  - `workflow_definition(id, form_type_id, states, transitions, rules)`
  - `workflow_instance(id, form_instance_id, definition_id, state, assignee, started_at, updated_at)`
  - `workflow_event(id, workflow_instance_id, type, by_user, payload, created_at)`
- Transverse
  - `comment(id, form_instance_id, author, message, visibility, created_at)`
  - `attachment(id, form_instance_id, filename, mime, size, url, created_at)`
  - `permission(id, role, resource, action, scope)`
  - `audit_log(id, user, action, resource, before, after, created_at)`

## Flux (simplifié)
1. Création d’un `form_instance` à partir d’un `form_type`.
2. Initialisation d’un `workflow_instance` relié à une `workflow_definition`.
3. Saisie/validation: `workflow_event` (submit/approve/refuse/comment/close…), mise à jour `state`.
4. Valeurs stockées dans `form_instance_value` (clé=field_code).
5. KPI agrégés depuis cette base pour le dashboard.

## Avantages
- Simplicité opérationnelle: une seule base à maintenir, sauvegarder, monitorer.
- Évolution rapide: ajout d’un nouveau formulaire = nouveaux `form_type` + `form_field` (pas de migration lourde).
- Cohérence: mêmes tables pour l’audit, permissions, events.
- Requêtes transverses: agrégations et KPI globaux simplifiés.

## Inconvénients
- Hotspot: base unique = point de contention/performance si très gros volume.
- Bruit de données: tout est au même endroit (exige une bonne gouvernance des index et partitions).
- Limites spécifiques: si un module a des besoins DB très particuliers (ex: full-text avancé).

## Performance & Scalabilité
- Index par `form_type_id`, `current_state`, `created_at`.
- Partitionnement par période (mois/année) pour `form_instance`, `workflow_event`.
- Cache applicatif pour KPI.
- File d’événements pour traitements asynchrones (notifications, sync externes).

## Sécurité & Conformité
- RBAC par ressource (`form_type`, `form_instance`).
- Journalisation centralisée (audit unique).
- Rétention/archivage par type (politiques par `form_type`).

## Quand choisir MONO-DB ?
- Démarrage/MVP, équipe réduite, time-to-market clé.
- Volumétrie raisonnable, contraintes techniques homogènes.
- Besoin d’agrégations globales fréquentes.

---

## Annexes — Exemple d’indexation (indicatif)
```sql
CREATE INDEX idx_instance_type ON form_instance(form_type_id);
CREATE INDEX idx_instance_state ON form_instance(current_state);
CREATE INDEX idx_instance_created_at ON form_instance(created_at);
CREATE INDEX idx_event_instance ON workflow_event(workflow_instance_id);
```
