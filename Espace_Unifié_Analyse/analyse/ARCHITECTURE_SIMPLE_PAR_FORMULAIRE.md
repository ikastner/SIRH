# Architecture simple par formulaire (sans formulaire générique)

## Principe
- Une poignée de tables communes: `users`, `attachments`, `audit_log`, `workflow_event`.
- Chaque formulaire a ses tables dédiées (schéma clair, lisible, sans EAV/JSON dynamiques).
- Exemple ci-dessous pour deux formulaires: Heures Supplémentaires (HS) et Badge Collaborateur.

---

## Tables communes

### users
```sql
CREATE TABLE users (
  id VARCHAR(64) PRIMARY KEY,
  email VARCHAR(256) UNIQUE NOT NULL,
  nom VARCHAR(128) NOT NULL,
  prenom VARCHAR(128) NOT NULL,
  role VARCHAR(32) NOT NULL, -- collaborateur, manager, rh, prestataire
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
```

### attachments (pièces jointes)
```sql
-- Polymorphique via colonnes (form_kind, form_id)
CREATE TABLE attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_kind VARCHAR(64) NOT NULL,    -- 'HS' | 'BADGE' | ...
  form_id UUID NOT NULL,             -- id de la table dédiée
  filename VARCHAR(256) NOT NULL,
  mime_type VARCHAR(64) NOT NULL,
  size BIGINT NOT NULL,
  storage_key VARCHAR(512) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_att_kind_id ON attachments(form_kind, form_id);
```

### audit_log (traçabilité technique)
```sql
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(64) NOT NULL,
  action VARCHAR(64) NOT NULL,      -- create, update, approve, refuse, close...
  resource VARCHAR(64) NOT NULL,    -- 'HS' | 'BADGE' | ...
  resource_id UUID NOT NULL,        -- id de l'entité cible
  before JSONB,
  after JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_resource ON audit_log(resource, resource_id);
```

### workflow_event (traçabilité fonctionnelle des états)
```sql
CREATE TABLE workflow_event (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_kind VARCHAR(64) NOT NULL,  -- 'HS' | 'BADGE' | ...
  form_id UUID NOT NULL,           -- id de la table dédiée
  from_state VARCHAR(64),
  to_state VARCHAR(64) NOT NULL,   -- draft, en_attente_manager, en_attente_rh, valide, refuse, cloture
  action VARCHAR(64) NOT NULL,     -- submit, approve, refuse, comment, close, cancel
  by_user VARCHAR(64) NOT NULL,
  payload JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_wfe_kind_id ON workflow_event(form_kind, form_id);
```

---

## Formulaire 1: Heures Supplémentaires (HS)

### Tables dédiées
```sql
-- Demande d'heures sup (en-tête)
CREATE TABLE hs_request (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  date_heure DATE NOT NULL,
  heures_normales DECIMAL(4,2) NOT NULL CHECK (heures_normales >= 0 AND heures_normales <= 24),
  heures_supp DECIMAL(4,2) NOT NULL DEFAULT 0 CHECK (heures_supp >= 0 AND heures_supp <= 8),
  current_state VARCHAR(64) NOT NULL DEFAULT 'en_attente_manager',
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_hs_user ON hs_request(user_id);
CREATE INDEX idx_hs_state ON hs_request(current_state);
CREATE INDEX idx_hs_date ON hs_request(date_heure);

-- Commentaires (optionnel) - si besoin par formulaire
CREATE TABLE hs_comment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  hs_id UUID NOT NULL REFERENCES hs_request(id) ON DELETE CASCADE,
  author VARCHAR(64) NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_hs_comment ON hs_comment(hs_id);
```

### Flux type (exemples SQL)
```sql
-- Création
INSERT INTO hs_request (user_id, date_heure, heures_normales, heures_supp)
VALUES ('user123', '2024-12-15', 7, 2)
RETURNING id; -- => <hs_id>

-- Traçabilité (changement d'état)
INSERT INTO workflow_event(form_kind, form_id, from_state, to_state, action, by_user, payload)
VALUES ('HS', '<hs_id>', 'en_attente_manager', 'en_attente_rh', 'approve', 'manager001', '{"comment":"OK"}'::jsonb);

UPDATE hs_request
SET current_state = 'en_attente_rh', updated_at = now()
WHERE id = '<hs_id>';

-- Pièce jointe
INSERT INTO attachments(form_kind, form_id, filename, mime_type, size, storage_key)
VALUES ('HS', '<hs_id>', 'justificatif.pdf', 'application/pdf', 120345, 's3://bucket/key.pdf');
```

---

## Formulaire 2: Badge Collaborateur

### Tables dédiées
```sql
-- Demande de badge collaborateur (en-tête)
CREATE TABLE badge_request (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(64) NOT NULL REFERENCES users(id),
  nom_collab VARCHAR(128) NOT NULL,
  prenom_collab VARCHAR(128) NOT NULL,
  email_collab VARCHAR(256) NOT NULL,
  current_state VARCHAR(64) NOT NULL DEFAULT 'en_attente_manager',
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_badge_user ON badge_request(user_id);
CREATE INDEX idx_badge_state ON badge_request(current_state);

-- Accès attribués (spécifique badge)
CREATE TABLE badge_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  badge_id UUID NOT NULL REFERENCES badge_request(id) ON DELETE CASCADE,
  zone VARCHAR(64) NOT NULL,
  niveau_acces VARCHAR(32) NOT NULL,
  date_debut DATE NOT NULL,
  date_fin DATE
);
CREATE INDEX idx_badge_access ON badge_access(badge_id);
```

### Flux type (exemples SQL)
```sql
-- Création
INSERT INTO badge_request (user_id, nom_collab, prenom_collab, email_collab)
VALUES ('user789', 'Dupont', 'Jean', 'jean.dupont@urssaf.fr')
RETURNING id; -- => <badge_id>

-- Traçabilité (manager -> RH)
INSERT INTO workflow_event(form_kind, form_id, from_state, to_state, action, by_user)
VALUES ('BADGE', '<badge_id>', 'en_attente_manager', 'en_attente_rh', 'approve', 'manager002');

UPDATE badge_request
SET current_state = 'en_attente_rh', updated_at = now()
WHERE id = '<badge_id>';

-- Accès associé
INSERT INTO badge_access (badge_id, zone, niveau_acces, date_debut, date_fin)
VALUES ('<badge_id>', 'Zone_A', 'N3', CURRENT_DATE, CURRENT_DATE + INTERVAL '365 days');

-- Pièce jointe
INSERT INTO attachments(form_kind, form_id, filename, mime_type, size, storage_key)
VALUES ('BADGE', '<badge_id>', 'photo_id.png', 'image/png', 54213, 's3://bucket/photo.png');
```

---

## Ajouter un nouveau formulaire (pattern)
1. Créer une table d’en-tête dédiée: `<form>_request` (champs métiers + `current_state`).
2. Créer les tables annexes si nécessaire (ex: `<form>_comment`, `<form>_detail`).
3. Utiliser `workflow_event` pour tracer les changements d’état.
4. Utiliser `attachments` pour les pièces jointes.
5. Utiliser `audit_log` pour l’historique technique des modifications.

Avantages:
- Schéma clair, lisible par tous.
- Pas de méta/EAV; chaque domaine garde ses champs explicites.
- Réutilisation maximale des briques communes (utilisateurs, pièces jointes, traçabilité).

Impact:
- Pour 10 formulaires, on aura ~10 tables d’en-tête + quelques tables annexes, mais un modèle constant et simple.
