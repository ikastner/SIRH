# Architecture simple (10+ formulaires) — Tables communes + exemples HS/Badge

## Objectif
Avoir une base facile à maintenir pour une dizaine (ou plus) de formulaires, avec uniquement des tables communes:
- Utilisateurs (référence)
- Formulaires génériques (types, instances, valeurs)
- Traçabilité (audit / historique d’état)
- Pièces jointes (attachments)
- États simples (workflow minimal)

Le but: ajouter un nouveau formulaire sans créer de nouvelles tables.

---

## Tables communes (schéma logique)

- users(id, email, nom, prenom, role, created_at)
- form_type(id, code, label, description, actif)
- form_field(id, form_type_id, code, label, kind, required, options(jsonb), validations(jsonb))
- form_instance(id, form_type_id, created_by, current_state, created_at, updated_at)
- form_instance_value(id, form_instance_id, field_code, value(jsonb), created_at)
- workflow_event(id, form_instance_id, from_state, to_state, action, by_user, payload(jsonb), created_at)
- attachment(id, form_instance_id, filename, mime_type, size, storage_key, created_at)
- audit_log(id, user_id, action, resource, resource_id, before(jsonb), after(jsonb), created_at)

Notes:
- kind: 'text' | 'number' | 'date' | 'select' | 'file' | 'boolean' | 'email'
- current_state: 'draft' | 'en_attente_manager' | 'en_attente_rh' | 'valide' | 'refuse' | 'cloture'
- value est JSONB → flexible (string/number/date/objet)

---

## Exemples de formulaires

### 1) Heures Supplémentaires (HS)

Déclaration des métadonnées (exemple):
```sql
-- Type de formulaire
INSERT INTO form_type (code, label, description)
VALUES ('HEURE_SUP', 'Demande d\'heures supplémentaires', 'Gestion des heures sup')
ON CONFLICT (code) DO NOTHING;

-- Champs
WITH ft AS (SELECT id FROM form_type WHERE code = 'HEURE_SUP')
INSERT INTO form_field (form_type_id, code, label, kind, required, options, validations) VALUES
((SELECT id FROM ft), 'date_heure', 'Date', 'date', TRUE, NULL, NULL),
((SELECT id FROM ft), 'heures_normales', 'Heures normales', 'number', TRUE, NULL, '{"min":0, "max":24}'::jsonb),
((SELECT id FROM ft), 'heures_supplementaires', 'Heures supplémentaires', 'number', FALSE, NULL, '{"min":0, "max":8}'::jsonb)
ON CONFLICT DO NOTHING;
```

Création d’une demande (instance + valeurs + état):
```sql
-- Instance
INSERT INTO form_instance (form_type_id, created_by, current_state)
SELECT id, 'user123', 'en_attente_manager' FROM form_type WHERE code = 'HEURE_SUP'
RETURNING id;

-- Valeurs
INSERT INTO form_instance_value (form_instance_id, field_code, value)
VALUES
  ('<instance_id>', 'date_heure', '"2024-12-15"'::jsonb),
  ('<instance_id>', 'heures_normales', '7'::jsonb),
  ('<instance_id>', 'heures_supplementaires', '2'::jsonb);

-- Transition (traçabilité)
INSERT INTO workflow_event (form_instance_id, from_state, to_state, action, by_user, payload)
VALUES ('<instance_id>', 'en_attente_manager', 'en_attente_rh', 'approve', 'manager456', '{"comment":"OK"}'::jsonb);

UPDATE form_instance SET current_state = 'en_attente_rh', updated_at = now() WHERE id = '<instance_id>';
```

### 2) Badge Collaborateur

Déclaration des métadonnées (exemple):
```sql
-- Type de formulaire
INSERT INTO form_type (code, label, description)
VALUES ('BADGE_COLLAB', 'Demande de badge collaborateur', 'Accès collaborateur')
ON CONFLICT (code) DO NOTHING;

-- Champs
WITH ft AS (SELECT id FROM form_type WHERE code = 'BADGE_COLLAB')
INSERT INTO form_field (form_type_id, code, label, kind, required, options, validations) VALUES
((SELECT id FROM ft), 'nom_collab', 'Nom', 'text', TRUE, NULL, '{"minLength":2}'::jsonb),
((SELECT id FROM ft), 'prenom_collab', 'Prénom', 'text', TRUE, NULL, NULL),
((SELECT id FROM ft), 'email_collab', 'Email', 'email', TRUE, NULL, NULL)
ON CONFLICT DO NOTHING;
```

Création d’une demande (instance + valeurs + état):
```sql
-- Instance
INSERT INTO form_instance (form_type_id, created_by, current_state)
SELECT id, 'user789', 'en_attente_manager' FROM form_type WHERE code = 'BADGE_COLLAB'
RETURNING id;

-- Valeurs
INSERT INTO form_instance_value (form_instance_id, field_code, value)
VALUES
  ('<instance_id>', 'nom_collab', '"Dupont"'::jsonb),
  ('<instance_id>', 'prenom_collab', '"Jean"'::jsonb),
  ('<instance_id>', 'email_collab', '"jean.dupont@urssaf.fr"'::jsonb);

-- Transition (traçabilité)
INSERT INTO workflow_event (form_instance_id, from_state, to_state, action, by_user, payload)
VALUES ('<instance_id>', 'en_attente_manager', 'en_attente_rh', 'approve', 'manager001', NULL);

UPDATE form_instance SET current_state = 'en_attente_rh', updated_at = now() WHERE id = '<instance_id>';
```

---

## Pièces jointes (commun)

- Une table unique `attachment` liée à `form_instance_id` suffit (tous formulaires confondus).
- Ajout: upload → créer une ligne; suppression logique possible (colonne `deleted_at`).

Exemple:
```sql
INSERT INTO attachment (form_instance_id, filename, mime_type, size, storage_key)
VALUES ('<instance_id>', 'justificatif.pdf', 'application/pdf', 123456, 's3://bucket/key.pdf');
```

---

## Traçabilité (commun)

- `workflow_event` enregistre toute transition d’état et actions clés (commentaires, refus avec motif, clôture).
- `audit_log` consigne les modifications critiques (avant/après).

Exemple (refus avec motif):
```sql
INSERT INTO workflow_event (form_instance_id, from_state, to_state, action, by_user, payload)
VALUES ('<instance_id>', 'en_attente_rh', 'refuse', 'refuse', 'rh001', '{"motif":"non justifié"}'::jsonb);

UPDATE form_instance SET current_state = 'refuse', updated_at = now() WHERE id = '<instance_id>';
```

---

## Ajout d’un nouveau formulaire (pattern)
1. Ajouter une ligne dans `form_type` (code, label, description).
2. Déclarer ses champs dans `form_field` (types, règles, ordre).
3. Le front peut rendre dynamiquement le formulaire à partir de `form_field`.
4. Lors de la soumission: créer `form_instance` + `form_instance_value`.
5. Les changements d’état sont tracés dans `workflow_event`.
6. Les pièces jointes utilisent `attachment` (commune).

Ce modèle couvre 10+ formulaires avec un nombre minimal de tables, en restant extensible et simple.
