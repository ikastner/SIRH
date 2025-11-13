- =============================================
-- SCRIPT MULTI-DB : Séparation par module
-- =============================================

-- =============================================
-- BASE 1 : heures_db
-- =============================================

\c heures_db;

-- Schéma MONO mais préfixé "hs_"
DROP TABLE IF EXISTS hs_workflow_event CASCADE;
DROP TABLE IF EXISTS hs_workflow_instance CASCADE;
DROP TABLE IF EXISTS hs_workflow_definition CASCADE;
DROP TABLE IF EXISTS hs_comment CASCADE;
DROP TABLE IF EXISTS hs_form_instance_value CASCADE;
DROP TABLE IF EXISTS hs_form_instance CASCADE;

CREATE TABLE hs_form_instance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_type_code VARCHAR(64) NOT NULL,
  created_by VARCHAR(64) NOT NULL,
  current_state VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_hs_type ON hs_form_instance(form_type_code);
CREATE INDEX idx_hs_state ON hs_form_instance(current_state);
CREATE INDEX idx_hs_created_at ON hs_form_instance(created_at);

CREATE TABLE hs_form_instance_value (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES hs_form_instance(id) ON DELETE CASCADE,
  field_code VARCHAR(64) NOT NULL,
  value JSONB NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE(form_instance_id, field_code)
);

CREATE TABLE hs_workflow_definition (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_type_code VARCHAR(64) NOT NULL,
  name VARCHAR(128) NOT NULL,
  states JSONB NOT NULL,
  transitions JSONB NOT NULL,
  rules JSONB
);

CREATE TABLE hs_workflow_instance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES hs_form_instance(id) ON DELETE CASCADE,
  definition_id UUID NOT NULL REFERENCES hs_workflow_definition(id),
  state VARCHAR(64) NOT NULL,
  assignee VARCHAR(64),
  started_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE hs_workflow_event (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  workflow_instance_id UUID NOT NULL REFERENCES hs_workflow_instance(id) ON DELETE CASCADE,
  type VARCHAR(32) NOT NULL,
  by_user VARCHAR(64) NOT NULL,
  payload JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE hs_comment (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES hs_form_instance(id) ON DELETE CASCADE,
  author VARCHAR(64) NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE hs_event_outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(64) NOT NULL,
  payload JSONB NOT NULL,
  processed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- =============================================
-- BASE 2 : badges_db
-- =============================================

\c badges_db;

DROP TABLE IF EXISTS bd_workflow_event CASCADE;
DROP TABLE IF EXISTS bd_workflow_instance CASCADE;
DROP TABLE IF EXISTS bd_form_instance_value CASCADE;
DROP TABLE IF EXISTS bd_form_instance CASCADE;

CREATE TABLE bd_form_instance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_type_code VARCHAR(64) NOT NULL,
  created_by VARCHAR(64) NOT NULL,
  current_state VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_bd_type ON bd_form_instance(form_type_code);
CREATE INDEX idx_bd_state ON bd_form_instance(current_state);
CREATE INDEX idx_bd_created_at ON bd_form_instance(created_at);

CREATE TABLE bd_form_instance_value (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES bd_form_instance(id) ON DELETE CASCADE,
  field_code VARCHAR(64) NOT NULL,
  value JSONB NOT NULL,
  UNIQUE(form_instance_id, field_code)
);

CREATE TABLE bd_workflow_definition (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_type_code VARCHAR(64) NOT NULL,
  name VARCHAR(128) NOT NULL,
  states JSONB NOT NULL,
  transitions JSONB NOT NULL
);

CREATE TABLE bd_workflow_instance (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES bd_form_instance(id) ON DELETE CASCADE,
  definition_id UUID NOT NULL REFERENCES bd_workflow_definition(id),
  state VARCHAR(64) NOT NULL,
  assignee VARCHAR(64),
  started_at TIMESTAMP NOT NULL DEFAULT now(),
  updated_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE bd_event_outbox (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type VARCHAR(64) NOT NULL,
  payload JSONB NOT NULL,
  processed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

-- Tables spécifiques badges
CREATE TABLE bd_acces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES bd_form_instance(id) ON DELETE CASCADE,
  zone VARCHAR(64) NOT NULL,
  niveau_acces VARCHAR(32) NOT NULL,
  date_debut DATE NOT NULL,
  date_fin DATE
);

CREATE TABLE bd_historique (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_instance_id UUID NOT NULL REFERENCES bd_form_instance(id) ON DELETE CASCADE,
  user_id VARCHAR(64) NOT NULL,
  badge_num VARCHAR(32) NOT NULL,
  action VARCHAR(32) NOT NULL,
  date_action DATE NOT NULL,
  commentaire TEXT
);

-- =============================================
-- BASE 3 : dashboard_db (agrégation)
-- =============================================

\c dashboard_db;

DROP TABLE IF EXISTS kpi_item CASCADE;
DROP TABLE IF EXISTS backlog_item CASCADE;

CREATE TABLE kpi_item (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind VARCHAR(32) NOT NULL,
  label VARCHAR(128) NOT NULL,
  value DECIMAL(10,2) NOT NULL,
  unit VARCHAR(32),
  role_scope VARCHAR(32),
  source VARCHAR(64) NOT NULL,
  computed_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_kpi_kind ON kpi_item(kind);
CREATE INDEX idx_kpi_source ON kpi_item(source);

CREATE TABLE backlog_item (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(256) NOT NULL,
  source VARCHAR(64) NOT NULL,
  source_instance_id UUID NOT NULL,
  assignee VARCHAR(64),
  state VARCHAR(64) NOT NULL,
  due_at TIMESTAMP,
  link VARCHAR(512),
  role_scope VARCHAR(32),
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_backlog_assignee ON backlog_item(assignee);
CREATE INDEX idx_backlog_state ON backlog_item(state);
CREATE INDEX idx_backlog_source ON backlog_item(source);

-- =============================================
-- 2. INSERTION DE DONNÉES DE TEST
-- =============================================

\c heures_db;

INSERT INTO hs_workflow_definition (form_type_code, name, states, transitions, rules)
VALUES ('HEURE_SUP', 'Workflow Heures Sup',
  '["en_attente_manager", "en_attente_rh", "valide", "refuse", "cloture"]'::jsonb,
  '[{"from": "en_attente_manager", "to": "en_attente_rh", "action": "approve"}]'::jsonb,
  '{"sla": {"en_attente_manager": 3}}'::jsonb);

-- Générer 200 demandes d'heures sup
DO $$
DECLARE
  i INTEGER;
  instance_id UUID;
  workflow_id UUID;
  states TEXT[] := ARRAY['en_attente_manager', 'en_attente_rh', 'valide', 'refuse', 'cloture'];
  random_state TEXT;
  users TEXT[] := ARRAY['user001', 'user002', 'user003', 'user004', 'user005', 'user006', 'user007', 'user008', 'user009', 'user010'];
  managers TEXT[] := ARRAY['manager001', 'manager002', 'manager003'];
  rh_users TEXT[] := ARRAY['rh001', 'rh002'];
  created_date TIMESTAMP;
BEGIN
  FOR i IN 1..200 LOOP
    created_date := NOW() - (random() * 180 || ' days')::INTERVAL;
    random_state := states[1 + floor(random() * array_length(states, 1))];
    
    INSERT INTO hs_form_instance (form_type_code, created_by, current_state, created_at, updated_at)
    VALUES ('HEURE_SUP', users[1 + floor(random() * array_length(users, 1))], random_state, created_date, created_date)
    RETURNING id INTO instance_id;

    INSERT INTO hs_form_instance_value (form_instance_id, field_code, value, created_at) VALUES
      (instance_id, 'date_heure', ('"' || (created_date::date)::text || '"')::jsonb, created_date),
      (instance_id, 'heures_normales', (floor(random() * 7 + 1) + 1)::jsonb, created_date),
      (instance_id, 'heures_supplementaires', (floor(random() * 4))::jsonb, created_date);

    INSERT INTO hs_workflow_instance (form_instance_id, definition_id, state, assignee, started_at, updated_at)
    SELECT instance_id, id, random_state, 
      CASE 
        WHEN random_state IN ('en_attente_manager', 'refuse') THEN managers[1 + floor(random() * array_length(managers, 1))]
        WHEN random_state IN ('en_attente_rh', 'valide', 'cloture') THEN rh_users[1 + floor(random() * array_length(rh_users, 1))]
        ELSE NULL
      END,
      created_date, created_date
    FROM hs_workflow_definition WHERE form_type_code = 'HEURE_SUP'
    RETURNING id INTO workflow_id;

    -- Publier événement dans outbox
    INSERT INTO hs_event_outbox (event_type, payload, created_at)
    VALUES ('heures.workflow.submit', 
      jsonb_build_object(
        'instanceId', instance_id,
        'formType', 'HEURE_SUP',
        'state', random_state,
        'by', users[1 + floor(random() * array_length(users, 1))],
        'at', created_date
      ), created_date);

    IF random_state != 'en_attente_manager' THEN
      INSERT INTO hs_workflow_event (workflow_instance_id, type, by_user, payload, created_at)
      VALUES (workflow_id, 'submit', users[1 + floor(random() * array_length(users, 1))], 
        '{"initial": true}'::jsonb, created_date);
    END IF;
  END LOOP;
END $$;

\c badges_db;

INSERT INTO bd_workflow_definition (form_type_code, name, states, transitions)
VALUES ('BADGE_COLLAB', 'Workflow Badges',
  '["en_attente_manager", "en_attente_rh", "valide", "refuse", "cloture"]'::jsonb,
  '[{"from": "en_attente_manager", "to": "en_attente_rh", "action": "approve"}]'::jsonb);

-- Générer 150 demandes de badges
DO $$
DECLARE
  i INTEGER;
  instance_id UUID;
  states TEXT[] := ARRAY['en_attente_manager', 'en_attente_rh', 'valide', 'refuse', 'cloture'];
  random_state TEXT;
  users TEXT[] := ARRAY['user001', 'user002', 'user003', 'user004', 'user005'];
  created_date TIMESTAMP;
BEGIN
  FOR i IN 1..150 LOOP
    created_date := NOW() - (random() * 180 || ' days')::INTERVAL;
    random_state := states[1 + floor(random() * array_length(states, 1))];
    
    INSERT INTO bd_form_instance (form_type_code, created_by, current_state, created_at, updated_at)
    VALUES ('BADGE_COLLAB', users[1 + floor(random() * array_length(users, 1))], random_state, created_date, created_date)
    RETURNING id INTO instance_id;

    INSERT INTO bd_form_instance_value (form_instance_id, field_code, value, created_at) VALUES
      (instance_id, 'nom_collab', ('"Dupont' || i || '"')::jsonb, created_date),
      (instance_id, 'prenom_collab', ('"Jean' || i || '"')::jsonb, created_date),
      (instance_id, 'email_collab', ('"jean.dupont' || i || '@urssaf.fr"')::jsonb, created_date);

    INSERT INTO bd_workflow_instance (form_instance_id, definition_id, state, assignee, started_at, updated_at)
    SELECT instance_id, id, random_state, NULL, created_date, created_date
    FROM bd_workflow_definition WHERE form_type_code = 'BADGE_COLLAB';

    INSERT INTO bd_event_outbox (event_type, payload, created_at)
    VALUES ('badges.workflow.submit', 
      jsonb_build_object(
        'instanceId', instance_id,
        'formType', 'BADGE_COLLAB',
        'state', random_state,
        'at', created_date
      ), created_date);

    INSERT INTO bd_acces (form_instance_id, zone, niveau_acces, date_debut, date_fin)
    VALUES (instance_id, 'Zone_' || i, 'Niveau_' || (floor(random() * 3 + 1)), created_date::date, (created_date + INTERVAL '365 days')::date);

    INSERT INTO bd_historique (form_instance_id, user_id, badge_num, action, date_action, commentaire)
    VALUES (instance_id, users[1 + floor(random() * array_length(users, 1))], 'BDG-' || i, 'created', created_date::date, 'Badge créé');
  END LOOP;
END $$;

\c dashboard_db;

-- =============================================
-- 3. JOB D'AGRÉGATION (simulation)
-- =============================================

-- Simuler la lecture des outboxs et agrégation
DO $$
DECLARE
  hs_count INTEGER;
  bd_count INTEGER;
BEGIN
  \c heures_db;
  SELECT COUNT(*) INTO hs_count FROM hs_event_outbox WHERE processed = FALSE;
  
  \c badges_db;
  SELECT COUNT(*) INTO bd_count FROM bd_event_outbox WHERE processed = FALSE;
  
  \c dashboard_db;
  
  -- Agrégé depuis heures_db
  INSERT INTO kpi_item (kind, label, value, unit, role_scope, source, computed_at)
  VALUES 
    ('heures_pending_manager', 'Heures en attente Manager', hs_count, 'unit', 'manager', 'heures_db', NOW()),
    ('heures_total', 'Total demandes heures', 200, 'unit', 'all', 'heures_db', NOW());
  
  -- Agrégé depuis badges_db
  INSERT INTO kpi_item (kind, label, value, unit, role_scope, source, computed_at)
  VALUES 
    ('badges_pending', 'Badges en attente', bd_count, 'unit', 'manager', 'badges_db', NOW()),
    ('badges_total', 'Total demandes badges', 150, 'unit', 'all', 'badges_db', NOW());
  
  RAISE NOTICE '✅ Agrégation terminée : % événements heures, % événements badges', hs_count, bd_count;
END $$;

-- =============================================
-- 4. REQUÊTES DE TEST MULTI-DB
-- =============================================

-- Vue agrégée depuis dashboard_db
\c dashboard_db;

SELECT 
  kind,
  label,
  value,
  source,
  computed_at
FROM kpi_item
ORDER BY source, kind;

-- Compter les éléments par source
SELECT 
  source,
  COUNT(*) as nombre_kpi,
  SUM(value) as total
FROM kpi_item
GROUP BY source
ORDER BY source;

-- Comparaison performance
EXPLAIN ANALYZE
SELECT 
  kind,
  value,
  source,
  computed_at
FROM kpi_item
WHERE computed_at >= NOW() - INTERVAL '1 hour'
ORDER BY computed_at DESC;