# Espace Unifié URSSAF — Architecture, Specs & Plan (v1)

## Objectif

Concevoir une architecture modulaire pour:
- Gérer des workflows RH natifs (Heures Sup, Badges, Demandes, etc.).
- Interconnecter des applications externes (ex: Securrsafe) via des cartes d’accès conditionnées par rôles, et remonter leurs données clés dans un dashboard unifié.
- Ajouter facilement de nouveaux formulaires/applications sans refonte (extensibilité).

## Principes directeurs

- Hub unique, modulaire: chaque domaine est un « module » plug-and-play.
- Un modèle de données générique pour formulaires + moteur de workflow réutilisable.
- Interopérabilité par connecteurs: registry, mapping, sécurité (RBAC/SSO), audit.
- Design System unifié: composants UI standard (forms, tables, badges, popups).
- Observabilité: journalisation, métriques, traçabilité bout-en-bout.

---

## Modèle de données (générique formulaires)

Pensé pour couvrir l’ensemble des formulaires RH (Heures Sup, Badges, autres demandes) et permettre l’ajout sans changer le schéma central.

### Schéma logique (simplifié)

- form_type (catalogue)
  - id, code (ex: HEURE_SUP, BADGE_COLLAB, …), libellé, description, version, actif
- form_field (métier de chaque type)
  - id, form_type_id, code, libellé, type (string, number, date, select, file…), required, options (JSON), validations (JSON)
- form_instance (une demande)
  - id, form_type_id, created_by, created_at, updated_at, current_state
- form_instance_value
  - id, form_instance_id, field_code, value (TEXT/JSON)
- workflow_definition
  - id, form_type_id, name, states (JSON), transitions (JSON), rules (JSON)
- workflow_instance
  - id, form_instance_id, definition_id, state, assignee (nullable), started_at, updated_at
- workflow_event
  - id, workflow_instance_id, type (submit, approve, refuse, comment, close…), by_user, payload (JSON), created_at
- comment
  - id, form_instance_id, author, message, visibility, created_at
- attachment
  - id, form_instance_id, filename, mime, size, url/storage_key, created_at
- permission
  - id, role, resource (form_type|instance|connector), action (read|write|approve|admin), scope
- audit_log
  - id, user, action, resource, before (JSON), after (JSON), created_at

### Exemples SQL (extraits)

```sql
-- Form types
CREATE TABLE form_type (
  id UUID PRIMARY KEY,
  code VARCHAR(64) UNIQUE NOT NULL,
  label VARCHAR(128) NOT NULL,
  description TEXT,
  version INT NOT NULL DEFAULT 1,
  actif BOOLEAN NOT NULL DEFAULT TRUE
);

-- Champs dynamiques par type
CREATE TABLE form_field (
  id UUID PRIMARY KEY,
  form_type_id UUID NOT NULL REFERENCES form_type(id),
  code VARCHAR(64) NOT NULL,
  label VARCHAR(128) NOT NULL,
  kind VARCHAR(32) NOT NULL,         -- text, number, date, select, file, boolean...
  required BOOLEAN NOT NULL DEFAULT FALSE,
  options JSONB,                     -- listes, placeholders, etc.
  validations JSONB,                 -- min, max, regex, custom
  UNIQUE(form_type_id, code)
);

-- Instances de formulaires (demandes)
CREATE TABLE form_instance (
  id UUID PRIMARY KEY,
  form_type_id UUID NOT NULL REFERENCES form_type(id),
  created_by VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now(),
  current_state VARCHAR(64) NOT NULL
);

-- Valeurs des champs de l'instance
CREATE TABLE form_instance_value (
  id UUID PRIMARY KEY,
  form_instance_id UUID NOT NULL REFERENCES form_instance(id) ON DELETE CASCADE,
  field_code VARCHAR(64) NOT NULL,
  value JSONB,
  UNIQUE(form_instance_id, field_code)
);

-- Définition du workflow par type (JSON states/transitions)
CREATE TABLE workflow_definition (
  id UUID PRIMARY KEY,
  form_type_id UUID NOT NULL REFERENCES form_type(id),
  name VARCHAR(128) NOT NULL,
  states JSONB NOT NULL,             -- ["en_attente_manager", "en_attente_rh", ...]
  transitions JSONB NOT NULL,        -- { from->to + guards }
  rules JSONB                        -- SLA, auto-assign, notifications
);

-- Instance du workflow
CREATE TABLE workflow_instance (
  id UUID PRIMARY KEY,
  form_instance_id UUID NOT NULL REFERENCES form_instance(id) ON DELETE CASCADE,
  definition_id UUID NOT NULL REFERENCES workflow_definition(id),
  state VARCHAR(64) NOT NULL,
  assignee VARCHAR(64),
  started_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Événements du workflow
CREATE TABLE workflow_event (
  id UUID PRIMARY KEY,
  workflow_instance_id UUID NOT NULL REFERENCES workflow_instance(id) ON DELETE CASCADE,
  type VARCHAR(32) NOT NULL,         -- submit, approve, refuse, comment, close...
  by_user VARCHAR(64) NOT NULL,
  payload JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
```

> Heures Sup, Badges et autres formulaires deviennent des « form_type » avec leurs form_field.
> Les statuts et transitions sont portés par workflow_definition et historisés via workflow_event.

---

## Moteur de workflow (réutilisable)

- États standard: en_attente_manager, en_attente_rh, valide, refuse, cloture.
- Transitions avec garde: ex. approve requiert rôle manager → passe à en_attente_rh.
- Règles: SLA (rappels), auto-assign, notifications (commentaires/refus → motif obligatoire), restrictions (annulation possible tant que en_attente_manager).
- Journalisation systématique (workflow_event) et synchronisation des current_state.

---

## Interconnexion (applications externes)

### Concepts
- connector_registry: catalogue des applis externes (Securrsafe, Paie, Docs, etc.).
- connector_config: secrets, scopes, mappings, webhooks.
- data_mapping: schémas normalisés pour agrégation dashboard (KPI, compteurs, files d’attente).

### Schéma minimal

- connector (registry)
  - id, code, label, description, kind (rest, graphql, soap, file, webhook), enabled
- connector_account
  - id, connector_id, auth_type (oauth2, key, basic, jwt), secrets (vault), scopes
- connector_mapping
  - id, connector_id, source (endpoint/topic), target (schema logical), transform (ETL)
- ingestion_job
  - id, connector_id, schedule (cron), last_run, status, metrics
- ingested_record
  - id, connector_id, kind, payload (JSON), normalized (JSON), created_at

### Patterns d’intégration
- Pull (cron) + cache pour KPI (réduction charge).
- Webhooks pour événements critiques (ex: changement de statut côté Securrsafe).
- Files/events (ex: Kafka/NATS) pour découpler l’ingestion.
- Normalisation dans un schéma logique Dashboard (ex: kpi_items, backlog_items).

### Sécurité & rôles
- RBAC: l’affichage d’une carte d’accès dépend du rôle et du connector autorisé.
- Traçabilité: audit des accès et des synchronisations.
- SSO/MFA: ouverture des apps externes via SSO si possible (deep links sécurisés).

---

## Dashboard Unifié (aggrégation)

- Carte par rôle: tâches à faire (internes + externes).
- KPI: volumes en attente, délais moyens, anomalies.
- Filtres: période, équipe, statut, source.
- Détails: lien vers la source (formulaire interne ou app externe), respectant les permissions.

Schéma minimal KPI:
- kpi_item(id, kind, label, value, unit, role_scope, source, computed_at)
- backlog_item(id, title, source, assignee, due_at, link, role_scope)

---

## API (exemples)

### Formulaires génériques
- GET /api/forms/types — liste des form_type
- GET /api/forms/types/:code — métadonnées + champs + workflow
- POST /api/forms — créer form_instance + workflow_instance
- GET /api/forms/:id — lire instance (valeurs + état + historique)
- PUT /api/forms/:id — modifier valeurs (si autorisé)
- POST /api/forms/:id/actions/{submit|approve|refuse|comment|close|cancel}
- GET /api/forms/:id/events — historique (workflow_event)

### Connecteurs / Dashboard
- GET /api/connectors — registry
- POST /api/connectors/:code/sync — déclenche une sync (admin)
- GET /api/dashboard/kpi — agrégats (internes + externes)
- GET /api/dashboard/backlog — éléments actionnables

---

## Sécurité, Permissions, Conformité

- RBAC: permissions par ressource (form_type, form_instance, connector).
- Traçabilité/Audit: toutes les actions critiques loggées.
- DLP/RGPD: rétention, anonymisation, minimisation des données.
- SSO/MFA: accès multi-support sans VPN (PWA), tokens courts, refresh sécurisé.

---

## Frontend (modulaire)

- Navigation par modules: heures/, badges/, demandes/, connecteurs/.
- Composants réutilisables (références aux maquettes ui/):
  - Forms: date, inputs, select, files; logique conditionnelle; erreurs explicites.
  - Status/Badges: cohérence visuelle (attente/validé/refusé/clôturé).
  - Popups: commentaire, refus (motif obligatoire), annulation, transmission.
  - Tables: tri, filtres, pagination, export.
  - Collapsibles: infos utilisateur, pointages, détails demande.
- Cartes d’accès aux apps externes: affichage conditionnel aux rôles.
- Dashboard: widgets KPI + backlog, filtrables par rôle/périmètre.

---

## Plan d’implémentation (phases)

### Phase 1 — MVP (4 à 6 semaines)
- Modèle générique formulaires + workflow (Heures Sup en 1er cas d’usage).
- RBAC, audit, notifications de base.
- Dashboard: premiers KPI internes (HS) + structure widgets.
- Connecteur « placeholder » (Securrsafe) — carte d’accès + maquette sync.

### Phase 2 — Intégrations (3 à 4 semaines)
- Connecteurs réels (Securrsafe v1):
  - Auth, endpoints clés, mapping, ingestion jobs.
  - Exposition KPI/backlog côté dashboard.
- Badges (form_type) et autre demande prioritaire.

### Phase 3 — Expansions (3 à 4 semaines)
- Dossier Agent: vue historique consolidée (internes + externes).
- Rappels/SLA, validations en masse (manager), exports.
- Observabilité: métriques, alertes de fiabilité, budgets de perf.

### Phase 4 — Optimisation & Gouvernance
- Rationalisation des outils (registry), hardening sécurité.
- UX: assistant de navigation, favoris, historiques, mode offline (lecture).
- Data: référentiels, qualité, gouvernance (catalogue).

---

## Guide d’extension (ajouter un nouveau formulaire)

1. Créer une entrée form_type (code, label, version).
2. Déclarer les champs dans form_field (types, validations, options).
3. Définir workflow_definition (states, transitions, règles, notifications).
4. Câbler les permissions RBAC (qui peut créer/valider/refuser/voir).
5. Générer l’UI automatiquement à partir des métadonnées (form renderer générique).
6. Tester le cycle: création → validations → statuts → audit.
7. Exposer les KPI nécessaires au dashboard.

## Guide d’extension (ajouter une application externe)

1. Enregistrer le connecteur dans connector (code, auth, scopes).
2. Définir connector_mapping (endpoints → schéma normalisé KPI/backlog).
3. Implémenter l’ingestion (pull/cron ou webhook) + cache.
4. Publier les KPI/backlog au dashboard.
5. Créer la carte d’accès (affichage conditionné par rôle/permission).
6. Ajouter l’audit des accès et synchronisations.

---

## Alignement avec la documentation fournie

- documentation-heure_sup/: contraintes métier HS (GTA, formulaires Excel, propositions PowerApps) → mappées sur form_type + form_field + workflow_definition.
- ux/: insights, personas, workflows → navigation guidée, rôles, statuts standard, notifications, KPI/dossier agent.
- ui/: maquettes composantisées → forms standardisés, tables, badges, popups, collapsibles, navigation.

---

## Annexe — États & transitions type (HeureSup)

États: en_attente_manager → en_attente_rh → valide → cloture (refus possible à chaque niveau → refuse).

Actions:
- submit (collaborateur)
- approve/refuse (manager, rh)
- comment (tous selon visibilité)
- cancel (collaborateur tant que en_attente_manager)
- close (rh)

Règles: motif obligatoire au refus; notifications à chaque changement d’état; SLA (rappels) configurables.

---

Fichier généré pour cadrer l’architecture cible modulable et interconnectée de l’Espace Unifié URSSAF.
