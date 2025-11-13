-- =============================================
-- SCRIPT MONO-DB : ESPACE UNIFIÉ (Une seule base)
-- =============================================

-- Connexion à la base
\c espace_unifie_db;

-- =============================================
-- 1. CRÉATION DES TABLES
-- =============================================

DROP TABLE IF EXISTS workflow_event CASCADE;
DROP TABLE IF EXISTS workflow_instance CASCADE;
DROP TABLE IF EXISTS workflow_definition CASCADE;
DROP TABLE IF EXISTS comment CASCADE;
DROP TABLE IF EXISTS attachment CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS form_instance_value CASCADE;
DROP TABLE IF EXISTS form_instance CASCADE;
DROP TABLE IF EXISTS form_field CASCADE;
DROP TABLE IF EXISTS form_type CASCADE;
DROP TABLE IF EXISTS permission CASCADE;

-- Catalogue des formulaires
CREATE TABLE form_type (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(64) UNIQUE NOT NULL,
  label VARCHAR(128) NOT NULL,
  description TEXT,
  version INT NOT NULL DEFAULT 1,
  actif BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Champs par formulaire
CREATE TABLE form_field (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_type_id UUID NOT NULL REFERENCES form_type(id) ON DELETE CASCADE,
  code VARCHAR(64) NOT NULL,
  label VARCHAR(128) NOT NULL,
  kind VARCHAR(32) NOT NULL,
  required BOOLEAN NOT NULL DEFAULT FALSE,
  options JSONB,
  validations JSONB,
  display_order INT NOT NULL DEFAULT 0,
  UNIQUE(form_type_id, code)
);

-- Instances de formulaires
CREATE TABLE form_instance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_type_id UUID NOT NULL REFERENCES form_type(id),
  created_by VARCHAR(64) NOT NULL,
  current_state VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_instance_type ON form_instance(form_type_id);
CREATE INDEX idx_instance_created_by ON form_instance(created_by);
CREATE INDEX idx_instance_state ON form_instance(current_state);
CREATE INDEX idx_instance_created_at ON form_instance(created_at);

-- Valeurs des champs
CREATE TABLE form_instance_value (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES form_instance(id) ON DELETE CASCADE,
  field_code VARCHAR(64) NOT NULL,
  value JSONB NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE(form_instance_id, field_code)
);

CREATE INDEX idx_value_instance ON form_instance_value(form_instance_id);

-- Workflows
CREATE TABLE workflow_definition (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_type_id UUID NOT NULL REFERENCES form_type(id),
  name VARCHAR(128) NOT NULL,
  states JSONB NOT NULL,
  transitions JSONB NOT NULL,
  rules JSONB,
  UNIQUE(form_type_id)
);

CREATE TABLE workflow_instance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES form_instance(id) ON DELETE CASCADE,
  definition_id UUID NOT NULL REFERENCES workflow_definition(id),
  state VARCHAR(64) NOT NULL,
  assignee VARCHAR(64),
  started_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_wf_instance_state ON workflow_instance(state);
CREATE INDEX idx_wf_instance_assignee ON workflow_instance(assignee);

CREATE TABLE workflow_event (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_instance_id UUID NOT NULL REFERENCES workflow_instance(id) ON DELETE CASCADE,
  type VARCHAR(32) NOT NULL,
  by_user VARCHAR(64) NOT NULL,
  payload JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_event_instance ON workflow_event(workflow_instance_id);
CREATE INDEX idx_event_created_at ON workflow_event(created_at);

-- Transverse
CREATE TABLE comment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES form_instance(id) ON DELETE CASCADE,
  author VARCHAR(64) NOT NULL,
  message TEXT NOT NULL,
  visibility VARCHAR(32) NOT NULL DEFAULT 'public',
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_comment_instance ON comment(form_instance_id);

CREATE TABLE attachment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES form_instance(id) ON DELETE CASCADE,
  filename VARCHAR(256) NOT NULL,
  mime_type VARCHAR(64) NOT NULL,
  size BIGINT NOT NULL,
  storage_key VARCHAR(512) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE permission (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role VARCHAR(32) NOT NULL,
  resource VARCHAR(64) NOT NULL,
  resource_id UUID,
  action VARCHAR(32) NOT NULL,
  scope VARCHAR(64),
  UNIQUE(role, resource, action)
);

CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(64) NOT NULL,
  action VARCHAR(64) NOT NULL,
  resource VARCHAR(64) NOT NULL,
  resource_id UUID,
  before JSONB,
  after JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_user ON audit_log(user_id);
CREATE INDEX idx_audit_created_at ON audit_log(created_at);

-- =============================================
-- 2. INSERTION DE DONNÉES DE TEST
-- =============================================

-- Types de formulaires
INSERT INTO form_type (code, label, description) VALUES
  ('HEURE_SUP', 'Demande d''heures supplémentaires', 'Gestion des heures sup'),
  ('BADGE_COLLAB', 'Demande de badge collaborateur', 'Badges d''accès collaborateur'),
  ('BADGE_PRESTA', 'Demande de badge prestataire', 'Badges d''accès prestataire'),
  ('DEMANDE_RH', 'Demande RH diverse', 'Demandes variées (mobilité, temps partiel)')
RETURNING id, code;

-- Récupérer les IDs pour les références
WITH type_ids AS (
  SELECT code, id FROM form_type
)
INSERT INTO form_field (form_type_id, code, label, kind, required, options, validations, display_order)
SELECT ti.id, 'date_heure', 'Date', 'date', TRUE, NULL::jsonb, NULL::jsonb, 1 FROM type_ids ti WHERE ti.code = 'HEURE_SUP'
UNION ALL SELECT ti.id, 'heures_normales', 'Heures normales', 'number', TRUE, NULL::jsonb, '{"min": 0, "max": 24}'::jsonb, 2 FROM type_ids ti WHERE ti.code = 'HEURE_SUP'
UNION ALL SELECT ti.id, 'heures_supplementaires', 'Heures supplémentaires', 'number', FALSE, NULL::jsonb, '{"min": 0, "max": 8}'::jsonb, 3 FROM type_ids ti WHERE ti.code = 'HEURE_SUP'
UNION ALL SELECT ti.id, 'nom_collab', 'Nom', 'text', TRUE, NULL::jsonb, '{"minLength": 2}'::jsonb, 1 FROM type_ids ti WHERE ti.code = 'BADGE_COLLAB'
UNION ALL SELECT ti.id, 'prenom_collab', 'Prénom', 'text', TRUE, NULL::jsonb, NULL::jsonb, 2 FROM type_ids ti WHERE ti.code = 'BADGE_COLLAB'
UNION ALL SELECT ti.id, 'email_collab', 'Email', 'email', TRUE, NULL::jsonb, NULL::jsonb, 3 FROM type_ids ti WHERE ti.code = 'BADGE_COLLAB';

-- Workflow definitions
WITH type_ids AS (
  SELECT code, id FROM form_type
)
INSERT INTO workflow_definition (form_type_id, name, states, transitions, rules)
SELECT ti.id, 'Workflow Heures Sup', 
  '["en_attente_manager", "en_attente_rh", "valide", "refuse", "cloture"]'::jsonb,
  '[
    {"from": "en_attente_manager", "to": "en_attente_rh", "action": "approve", "guard": "role:manager"},
    {"from": "en_attente_manager", "to": "refuse", "action": "refuse", "guard": "role:manager"},
    {"from": "en_attente_rh", "to": "valide", "action": "approve", "guard": "role:rh"},
    {"from": "en_attente_rh", "to": "refuse", "action": "refuse", "guard": "role:rh"}
  ]'::jsonb,
  '{"sla": {"en_attente_manager": 3, "en_attente_rh": 5}, "notifications": {"on_state_change": true}}'::jsonb
FROM type_ids ti WHERE ti.code = 'HEURE_SUP';

-- =============================================
-- 3. GÉNÉRATION DE DONNÉES DE TEST (500 formulaires)
-- =============================================

DO $$
DECLARE
  i INTEGER;
  form_type_hs UUID;
  form_type_badge UUID;
  form_type_demande UUID;
  definition_hs UUID;
  instance_id UUID;
  workflow_id UUID;
  states TEXT[] := ARRAY['en_attente_manager', 'en_attente_rh', 'valide', 'refuse', 'cloture'];
  random_state TEXT;
  users TEXT[] := ARRAY['user001', 'user002', 'user003', 'user004', 'user005', 'user006', 'user007', 'user008', 'user009', 'user010'];
  managers TEXT[] := ARRAY['manager001', 'manager002', 'manager003'];
  rh_users TEXT[] := ARRAY['rh001', 'rh002'];
  created_date TIMESTAMP;
BEGIN
  -- Récupérer les IDs
  SELECT id INTO form_type_hs FROM form_type WHERE code = 'HEURE_SUP';
  SELECT id INTO form_type_badge FROM form_type WHERE code = 'BADGE_COLLAB';
  SELECT id INTO form_type_demande FROM form_type WHERE code = 'DEMANDE_RH';
  SELECT id INTO definition_hs FROM workflow_definition WHERE form_type_id = form_type_hs;

  -- Générer 200 demandes d'heures sup (réparties sur 6 mois)
  FOR i IN 1..200 LOOP
    created_date := NOW() - (random() * 180 || ' days')::INTERVAL;
    random_state := states[1 + floor(random() * array_length(states, 1))];
    
    -- Créer l'instance
    INSERT INTO form_instance (form_type_id, created_by, current_state, created_at, updated_at)
    VALUES (form_type_hs, users[1 + floor(random() * array_length(users, 1))], random_state, created_date, created_date)
    RETURNING id INTO instance_id;

    -- Remplir les valeurs
    INSERT INTO form_instance_value (form_instance_id, field_code, value, created_at) VALUES
      (instance_id, 'date_heure', ('"' || (created_date::date)::text || '"')::jsonb, created_date),
      (instance_id, 'heures_normales', (floor(random() * 7 + 1) + 1)::jsonb, created_date),
      (instance_id, 'heures_supplementaires', (floor(random() * 4))::jsonb, created_date);

    -- Créer le workflow
    INSERT INTO workflow_instance (form_instance_id, definition_id, state, assignee, started_at, updated_at)
    VALUES (instance_id, definition_hs, random_state, 
      CASE 
        WHEN random_state IN ('en_attente_manager', 'refuse') THEN managers[1 + floor(random() * array_length(managers, 1))]
        WHEN random_state IN ('en_attente_rh', 'valide', 'cloture') THEN rh_users[1 + floor(random() * array_length(rh_users, 1))]
        ELSE NULL
      END,
      created_date, created_date)
    RETURNING id INTO workflow_id;

    -- Ajouter quelques événements
    IF random_state != 'en_attente_manager' THEN
      INSERT INTO workflow_event (workflow_instance_id, type, by_user, payload, created_at)
      VALUES (workflow_id, 'submit', users[1 + floor(random() * array_length(users, 1))], 
        '{"initial": true}'::jsonb, created_date);
      
      IF random_state != 'en_attente_manager' THEN
        INSERT INTO workflow_event (workflow_instance_id, type, by_user, payload, created_at)
        VALUES (workflow_id, 'approve', managers[1], '{"comment": "OK validé"}'::jsonb, created_date + INTERVAL '2 days');
      END IF;
    END IF;
  END LOOP;

  -- Générer 150 demandes de badges
  FOR i IN 1..150 LOOP
    created_date := NOW() - (random() * 180 || ' days')::INTERVAL;
    random_state := states[1 + floor(random() * array_length(states, 1))];
    
    INSERT INTO form_instance (form_type_id, created_by, current_state, created_at, updated_at)
    VALUES (form_type_badge, users[1 + floor(random() * array_length(users, 1))], random_state, created_date, created_date)
    RETURNING id INTO instance_id;

    INSERT INTO form_instance_value (form_instance_id, field_code, value, created_at) VALUES
      (instance_id, 'nom_collab', ('"Dupont' || i || '"')::jsonb, created_date),
      (instance_id, 'prenom_collab', ('"Jean' || i || '"')::jsonb, created_date),
      (instance_id, 'email_collab', ('"jean.dupont' || i || '@urssaf.fr"')::jsonb, created_date);
  END LOOP;

  -- Générer 150 demandes RH diverses
  FOR i IN 1..150 LOOP
    created_date := NOW() - (random() * 180 || ' days')::INTERVAL;
    random_state := states[1 + floor(random() * array_length(states, 1))];
    
    INSERT INTO form_instance (form_type_id, created_by, current_state, created_at, updated_at)
    VALUES (form_type_demande, users[1 + floor(random() * array_length(users, 1))], random_state, created_date, created_date)
    RETURNING id INTO instance_id;

    INSERT INTO form_instance_value (form_instance_id, field_code, value, created_at) VALUES
      (instance_id, 'type_demande', ('"Mobilité' || i || '"')::jsonb, created_date),
      (instance_id, 'description', ('"Demande variée n°' || i || '"')::jsonb, created_date);
  END LOOP;

  -- Ajouter des commentaires sur certaines demandes
  FOR i IN 1..50 LOOP
    INSERT INTO comment (form_instance_id, author, message, visibility, created_at)
    SELECT fi.id, managers[1 + floor(random() * array_length(managers, 1))], 
      'Commentaire de suivi n°' || i, 'public', 
      fi.created_at + INTERVAL '2 days'
    FROM form_instance fi
    WHERE fi.id = (SELECT id FROM form_instance ORDER BY random() LIMIT 1);
  END LOOP;

  RAISE NOTICE '✅ Données générées avec succès !';
END $$;

-- =============================================
-- 4. REQUÊTES DE TEST
-- =============================================

-- Dashboard : Vue d'ensemble
SELECT 
  ft.code as formulaire,
  fi.current_state as etat,
  COUNT(*) as nombre
FROM form_instance fi
JOIN form_type ft ON fi.form_type_id = ft.id
GROUP BY ft.code, fi.current_state
ORDER BY ft.code, fi.current_state;

-- Top 10 utilisateurs les plus actifs
SELECT 
  created_by as utilisateur,
  COUNT(*) as nombre_demandes
FROM form_instance
GROUP BY created_by
ORDER BY nombre_demandes DESC
LIMIT 10;

-- Distribution par état
SELECT 
  current_state as etat,
  COUNT(*) as nombre,
  ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM form_instance), 2) as pourcentage
FROM form_instance
GROUP BY current_state
ORDER BY nombre DESC;

-- Performance : requête avec jointures
EXPLAIN ANALYZE
SELECT 
  ft.code,
  fi.id,
  fi.created_by,
  fi.current_state,
  wi.assignee,
  fi.created_at
FROM form_instance fi
JOIN form_type ft ON fi.form_type_id = ft.id
LEFT JOIN workflow_instance wi ON wi.form_instance_id = fi.id
WHERE fi.created_at >= NOW() - INTERVAL '30 days'
ORDER BY fi.created_at DESC
LIMIT 50;

-- Volume par mois (derniers 6 mois)
SELECT 
  DATE_TRUNC('month', created_at) as mois,
  COUNT(*) as nombre_demandes
FROM form_instance
WHERE created_at >= NOW() - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY mois;

RAISE NOTICE '✅ Script MONO-DB terminé avec succès !';