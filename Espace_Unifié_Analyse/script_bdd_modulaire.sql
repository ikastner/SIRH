-- ============================================
-- ARCHITECTURE BDD MODULAIRE
-- Tables dédiées par domaine + tables transverses
-- ============================================

-- ============================================
-- PARTIE 1: SUPPRESSION DES TABLES EXISTANTES
-- ============================================

DROP TABLE IF EXISTS validation_etape CASCADE;
DROP TABLE IF EXISTS workflow_etape CASCADE;
DROP TABLE IF EXISTS piece_jointe CASCADE;
DROP TABLE IF EXISTS traceabilite CASCADE;
DROP TABLE IF EXISTS statut CASCADE;
DROP TABLE IF EXISTS heures_sup_realisation CASCADE;
DROP TABLE IF EXISTS heures_sup_prealable CASCADE;
DROP TABLE IF EXISTS badge CASCADE;
DROP TABLE IF EXISTS notification CASCADE;
DROP TABLE IF EXISTS favori CASCADE;
DROP TABLE IF EXISTS agent CASCADE;
DROP TABLE IF EXISTS formulaire CASCADE;
DROP TABLE IF EXISTS organisation CASCADE;
DROP TABLE IF EXISTS service CASCADE;

DROP TYPE IF EXISTS type_badge_enum CASCADE;
DROP TYPE IF EXISTS type_heures_sup_enum CASCADE;
DROP TYPE IF EXISTS statut_enum CASCADE;
DROP TYPE IF EXISTS role_validation_enum CASCADE;

-- ============================================
-- PARTIE 2: TYPES ENUM
-- ============================================

CREATE TYPE type_badge_enum AS ENUM (
    'nouveau_collab',
    'depart_collab',
    'collab_perdu',
    'collab_hs',
    'collab_acces_spec',
    'perso',
    'perso_oubli',
    'perso_desac',
    'presta_new',
    'presta_renew',
    'presta_depart',
    'presta_perdu',
    'presta_hs',
    'presta_acces_spec',
    'autre_specifique'
);

CREATE TYPE type_heures_sup_enum AS ENUM (
    'prealable',
    'realisation'
);

CREATE TYPE statut_enum AS ENUM (
    'brouillon',
    'soumis',
    'en_validation',
    'complement_demande',
    'valide',
    'refuse',
    'clos'
);

CREATE TYPE role_validation_enum AS ENUM (
    'manager',
    'rh',
    'pcs',
    'pointage_rh'
);

-- ============================================
-- PARTIE 3: TABLES FONDAMENTALES
-- ============================================

-- Table: organisation
CREATE TABLE organisation (
    code_organisation VARCHAR(50) PRIMARY KEY,
    libelle VARCHAR(255) NOT NULL,
    actif BOOLEAN DEFAULT TRUE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: service
CREATE TABLE service (
    code_service VARCHAR(50) PRIMARY KEY,
    code_organisation VARCHAR(50) REFERENCES organisation(code_organisation),
    libelle VARCHAR(255) NOT NULL,
    actif BOOLEAN DEFAULT TRUE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table: agent (référence vers ANAIS)
CREATE TABLE agent (
    code_agent VARCHAR(50) PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    code_organisation VARCHAR(50) REFERENCES organisation(code_organisation),
    code_service VARCHAR(50) REFERENCES service(code_service),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actif BOOLEAN DEFAULT TRUE
);

-- Table: formulaire (catalogue simplifié)
CREATE TABLE formulaire (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL,
    titre VARCHAR(255) NOT NULL,
    description TEXT,
    categorie VARCHAR(50),
    version VARCHAR(20) DEFAULT '1.0',
    actif BOOLEAN DEFAULT TRUE,
    ordre_affichage INTEGER DEFAULT 0,
    icone VARCHAR(100),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    code_agent_creation VARCHAR(50),
    code_agent_modification VARCHAR(50)
);

-- ============================================
-- PARTIE 4: TABLE STATUT (Référentiel)
-- ============================================

CREATE TABLE statut (
    id SERIAL PRIMARY KEY,
    code VARCHAR(50) UNIQUE NOT NULL,
    libelle VARCHAR(255) NOT NULL,
    description TEXT,
    ordre_affichage INTEGER DEFAULT 0,
    couleur VARCHAR(50),
    icone VARCHAR(100),
    type_objet VARCHAR(50), -- 'badge', 'heures_sup', 'generique'
    actif BOOLEAN DEFAULT TRUE
);

-- Insertion des statuts
INSERT INTO statut (code, libelle, description, ordre_affichage, couleur, type_objet) VALUES
('brouillon', 'Brouillon', 'Demande en cours de saisie', 1, 'gray', 'generique'),
('soumis', 'Soumis', 'Demande soumise en attente de traitement', 2, 'blue', 'generique'),
('en_validation', 'En validation', 'Demande en cours de validation', 3, 'orange', 'generique'),
('complement_demande', 'Complément demandé', 'Des compléments sont requis', 4, 'yellow', 'generique'),
('valide', 'Validé', 'Demande validée', 5, 'green', 'generique'),
('refuse', 'Refusé', 'Demande refusée', 6, 'red', 'generique'),
('clos', 'Clos', 'Demande clôturée', 7, 'purple', 'generique');

-- ============================================
-- PARTIE 5: TABLE WORKFLOW_ETAPE
-- ============================================

CREATE TABLE workflow_etape (
    id SERIAL PRIMARY KEY,
    formulaire_id INTEGER REFERENCES formulaire(id),
    numero INTEGER NOT NULL,
    libelle VARCHAR(255) NOT NULL,
    role_validation role_validation_enum,
    statut_code VARCHAR(50) REFERENCES statut(code),
    action VARCHAR(100),
    ordre_affichage INTEGER DEFAULT 0,
    description TEXT,
    UNIQUE(formulaire_id, numero)
);

CREATE INDEX idx_workflow_formulaire ON workflow_etape(formulaire_id);
CREATE INDEX idx_workflow_numero ON workflow_etape(numero);

-- ============================================
-- PARTIE 6: TABLE BADGE (Domaine Badges)
-- ============================================

CREATE TABLE badge (
    id SERIAL PRIMARY KEY,
    type_badge type_badge_enum NOT NULL,
    code_agent_demandeur VARCHAR(50) NOT NULL REFERENCES agent(code_agent),
    code_agent_concerne VARCHAR(50) REFERENCES agent(code_agent),
    
    -- Informations collaborateur (si nouveau/départ/perdu)
    nom_collaborateur VARCHAR(255),
    prenom_collaborateur VARCHAR(255),
    service_collaborateur VARCHAR(50),
    fonction VARCHAR(255),
    date_debut DATE,
    date_depart DATE,
    projet TEXT,
    
    -- Informations prestataire
    societe_prestataire VARCHAR(255),
    nom_prestataire VARCHAR(255),
    prenom_prestataire VARCHAR(255),
    mission_prestataire TEXT,
    contact_entreprise VARCHAR(255),
    date_debut_prestataire DATE,
    date_fin_prestataire DATE,
    
    -- Badge
    numero_badge VARCHAR(100),
    type_perte VARCHAR(50), -- 'Perdu', 'Volé', 'Cassé', 'HS'
    date_perte DATE,
    date_oubli DATE,
    declaration TEXT,
    
    -- Accès
    zones_acces TEXT[], -- Array de zones
    horaires VARCHAR(100),
    type_badge_acces VARCHAR(50), -- 'Permanent', 'Temporaire'
    duree_mois INTEGER,
    duree_jours INTEGER,
    
    -- Dép part
    prolongation BOOLEAN DEFAULT FALSE,
    motif_prolongation TEXT,
    date_fin_prolongation DATE,
    rendu_badge BOOLEAN DEFAULT FALSE,
    
    -- Autres
    motif TEXT,
    action_demandee VARCHAR(100),
    duree_temporaire INTEGER, -- en heures
    type_specifique VARCHAR(255),
    justification TEXT,
    
    -- Statut et workflow
    statut_code VARCHAR(50) NOT NULL DEFAULT 'brouillon' REFERENCES statut(code),
    etape_actuelle INTEGER DEFAULT 1,
    
    -- Dates
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_soumission TIMESTAMP,
    date_cloture TIMESTAMP,
    
    -- Traçabilité
    code_agent_creation VARCHAR(50),
    code_agent_modification VARCHAR(50),
    
    -- Soft delete
    est_supprime BOOLEAN DEFAULT FALSE,
    motif_suppression TEXT,
    commentaire_suppression TEXT,
    code_agent_suppression VARCHAR(50),
    date_suppression TIMESTAMP
);

CREATE INDEX idx_badge_type ON badge(type_badge);
CREATE INDEX idx_badge_statut ON badge(statut_code);
CREATE INDEX idx_badge_demandeur ON badge(code_agent_demandeur);
CREATE INDEX idx_badge_concerne ON badge(code_agent_concerne);
CREATE INDEX idx_badge_date_creation ON badge(date_creation);
CREATE INDEX idx_badge_etape ON badge(etape_actuelle);

-- ============================================
-- PARTIE 7: TABLE HEURES_SUP_PREALABLE (Domaine HS)
-- ============================================

CREATE TABLE heures_sup_prealable (
    id SERIAL PRIMARY KEY,
    code_agent_demandeur VARCHAR(50) NOT NULL REFERENCES agent(code_agent),
    code_agent_concerne VARCHAR(50) REFERENCES agent(code_agent),
    
    -- Période
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    jours_semaine TEXT[], -- Array: ['lundi', 'mardi', ...]
    type_periode VARCHAR(50), -- 'Ponctuel', 'Récurrent'
    
    -- Heures
    nb_heures_total NUMERIC(5,2) NOT NULL,
    heures_detaillees JSONB, -- Détail par jour si nécessaire
    
    -- Justification
    motif TEXT NOT NULL,
    dossier_lie VARCHAR(255),
    horaires_previsionnels TEXT,
    
    -- Statut et workflow
    statut_code VARCHAR(50) NOT NULL DEFAULT 'brouillon' REFERENCES statut(code),
    etape_actuelle INTEGER DEFAULT 1,
    
    -- Dates
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_soumission TIMESTAMP,
    date_cloture TIMESTAMP,
    
    -- Traçabilité
    code_agent_creation VARCHAR(50),
    code_agent_modification VARCHAR(50),
    
    -- Soft delete
    est_supprime BOOLEAN DEFAULT FALSE,
    motif_suppression TEXT,
    commentaire_suppression TEXT,
    code_agent_suppression VARCHAR(50),
    date_suppression TIMESTAMP
);

CREATE INDEX idx_hs_prealable_statut ON heures_sup_prealable(statut_code);
CREATE INDEX idx_hs_prealable_demandeur ON heures_sup_prealable(code_agent_demandeur);
CREATE INDEX idx_hs_prealable_concerne ON heures_sup_prealable(code_agent_concerne);
CREATE INDEX idx_hs_prealable_dates ON heures_sup_prealable(date_debut, date_fin);

-- ============================================
-- PARTIE 8: TABLE HEURES_SUP_REALISATION
-- ============================================

CREATE TABLE heures_sup_realisation (
    id SERIAL PRIMARY KEY,
    heures_sup_prealable_id INTEGER REFERENCES heures_sup_prealable(id),
    code_agent_demandeur VARCHAR(50) NOT NULL REFERENCES agent(code_agent),
    code_agent_concerne VARCHAR(50) REFERENCES agent(code_agent),
    
    -- Lien préalable
    avec_prealable BOOLEAN DEFAULT FALSE,
    sans_prealable BOOLEAN DEFAULT FALSE,
    motif_urgence TEXT, -- Si sans préalable
    
    -- Réalisation
    dates_realisees DATE[], -- Array de dates
    heures_realisees JSONB, -- Détail par jour: {"2024-12-20": {"debut": "18:00", "fin": "22:00", "nb_heures": 4}}
    total_heures NUMERIC(5,2) NOT NULL,
    
    -- Pointages GTA
    pointages_gta JSONB, -- {"2024-12-20": {"entree": "09:00", "sortie": "22:15"}}
    
    -- Écarts vs préalable
    ecarts_vs_prealable JSONB, -- Si avec préalable
    justification_ecarts TEXT,
    
    -- Statut et workflow
    statut_code VARCHAR(50) NOT NULL DEFAULT 'brouillon' REFERENCES statut(code),
    etape_actuelle INTEGER DEFAULT 1,
    
    -- Dates
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_soumission TIMESTAMP,
    date_cloture TIMESTAMP,
    
    -- Traçabilité
    code_agent_creation VARCHAR(50),
    code_agent_modification VARCHAR(50),
    
    -- Soft delete
    est_supprime BOOLEAN DEFAULT FALSE,
    motif_suppression TEXT,
    commentaire_suppression TEXT,
    code_agent_suppression VARCHAR(50),
    date_suppression TIMESTAMP
);

CREATE INDEX idx_hs_real_statut ON heures_sup_realisation(statut_code);
CREATE INDEX idx_hs_real_demandeur ON heures_sup_realisation(code_agent_demandeur);
CREATE INDEX idx_hs_real_prealable ON heures_sup_realisation(heures_sup_prealable_id);
CREATE INDEX idx_hs_real_dates ON heures_sup_realisation USING GIN(dates_realisees);

-- ============================================
-- PARTIE 9: TABLE VALIDATION_ETAPE
-- ============================================

CREATE TABLE validation_etape (
    id SERIAL PRIMARY KEY,
    
    -- Liaison (polymorphique avec type)
    type_demande VARCHAR(50) NOT NULL, -- 'badge', 'heures_sup_prealable', 'heures_sup_realisation'
    demande_id INTEGER NOT NULL, -- ID de badge, heures_sup_prealable ou heures_sup_realisation
    
    -- Workflow
    workflow_etape_id INTEGER REFERENCES workflow_etape(id),
    etape_workflow INTEGER NOT NULL,
    
    -- Validateur
    code_agent_valideur VARCHAR(50) NOT NULL REFERENCES agent(code_agent),
    role_validation role_validation_enum NOT NULL,
    ordre_validation INTEGER NOT NULL DEFAULT 1,
    
    -- Statut validation
    statut_validation VARCHAR(50) DEFAULT 'en_attente', -- 'en_attente', 'valide', 'refuse', 'annule'
    commentaire TEXT,
    date_validation TIMESTAMP,
    
    -- Dates
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_notification TIMESTAMP,
    
    UNIQUE(type_demande, demande_id, code_agent_valideur, ordre_validation)
);

CREATE INDEX idx_validation_type_id ON validation_etape(type_demande, demande_id);
CREATE INDEX idx_validation_valideur ON validation_etape(code_agent_valideur);
CREATE INDEX idx_validation_statut ON validation_etape(statut_validation);
CREATE INDEX idx_validation_etape ON validation_etape(etape_workflow);

-- ============================================
-- PARTIE 10: TABLE TRACEABILITE
-- ============================================

CREATE TABLE traceabilite (
    id SERIAL PRIMARY KEY,
    
    -- Liaison (polymorphique)
    type_demande VARCHAR(50) NOT NULL, -- 'badge', 'heures_sup_prealable', 'heures_sup_realisation'
    demande_id INTEGER NOT NULL,
    
    -- Action
    action VARCHAR(100) NOT NULL, -- 'creation', 'soumission', 'validation', 'refus', 'complement', etc.
    code_agent VARCHAR(50) REFERENCES agent(code_agent),
    
    -- États
    etape_avant INTEGER,
    etape_apres INTEGER,
    statut_avant VARCHAR(50),
    statut_apres VARCHAR(50),
    
    -- Détails
    commentaire TEXT,
    donnees_avant JSONB,
    donnees_apres JSONB,
    
    -- Date
    date_action TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_trace_type_id ON traceabilite(type_demande, demande_id);
CREATE INDEX idx_trace_date ON traceabilite(date_action);
CREATE INDEX idx_trace_agent ON traceabilite(code_agent);

-- ============================================
-- PARTIE 11: TABLE PIECE_JOINTE
-- ============================================

CREATE TABLE piece_jointe (
    id SERIAL PRIMARY KEY,
    
    -- Liaison (polymorphique)
    type_demande VARCHAR(50) NOT NULL, -- 'badge', 'heures_sup_prealable', 'heures_sup_realisation'
    demande_id INTEGER NOT NULL,
    
    -- Fichier
    nom_fichier VARCHAR(255) NOT NULL,
    chemin_fichier VARCHAR(500) NOT NULL,
    type_mime VARCHAR(100),
    taille_octets BIGINT,
    
    -- Métadonnées
    type_document VARCHAR(50), -- 'justificatif', 'pointage_gta', 'declaration', etc.
    description TEXT,
    
    -- Traçabilité
    code_agent_upload VARCHAR(50) REFERENCES agent(code_agent),
    date_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Statut
    actif BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_pj_type_id ON piece_jointe(type_demande, demande_id);
CREATE INDEX idx_pj_agent ON piece_jointe(code_agent_upload);

-- ============================================
-- PARTIE 12: TABLE NOTIFICATION
-- ============================================

CREATE TABLE notification (
    id SERIAL PRIMARY KEY,
    code_agent_destinataire VARCHAR(50) NOT NULL REFERENCES agent(code_agent),
    type VARCHAR(50) NOT NULL,
    titre VARCHAR(255) NOT NULL,
    message TEXT,
    payload JSONB,
    statut_lecture VARCHAR(50) DEFAULT 'non_lu',
    lien_action VARCHAR(500),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_lecture TIMESTAMP
);

CREATE INDEX idx_notification_destinataire ON notification(code_agent_destinataire);
CREATE INDEX idx_notification_statut ON notification(statut_lecture);
CREATE INDEX idx_notification_date ON notification(date_creation);

-- ============================================
-- PARTIE 13: TABLE FAVORI
-- ============================================

CREATE TABLE favori (
    id SERIAL PRIMARY KEY,
    code_agent VARCHAR(50) NOT NULL REFERENCES agent(code_agent),
    type_cible VARCHAR(50) NOT NULL,
    id_cible INTEGER,
    slug_cible VARCHAR(100),
    libelle VARCHAR(255),
    icone VARCHAR(100),
    ordre INTEGER DEFAULT 0,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(code_agent, type_cible, COALESCE(id_cible::text, slug_cible))
);

CREATE INDEX idx_favori_agent ON favori(code_agent);

-- ============================================
-- PARTIE 14: TRIGGERS
-- ============================================

-- Fonction: Mise à jour date_modification
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers sur tables avec date_modification
CREATE TRIGGER update_badge_modification BEFORE UPDATE ON badge
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_hs_prealable_modification BEFORE UPDATE ON heures_sup_prealable
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_hs_real_modification BEFORE UPDATE ON heures_sup_realisation
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- Fonction: Création traceabilité automatique
CREATE OR REPLACE FUNCTION create_traceabilite()
RETURNS TRIGGER AS $$
DECLARE
    v_type_demande VARCHAR(50);
    v_table_name VARCHAR(50);
BEGIN
    -- Déterminer le type selon la table
    v_table_name := TG_TABLE_NAME;
    
    IF v_table_name = 'badge' THEN
        v_type_demande := 'badge';
    ELSIF v_table_name = 'heures_sup_prealable' THEN
        v_type_demande := 'heures_sup_prealable';
    ELSIF v_table_name = 'heures_sup_realisation' THEN
        v_type_demande := 'heures_sup_realisation';
    END IF;
    
    IF TG_OP = 'INSERT' THEN
        INSERT INTO traceabilite (
            type_demande, demande_id, code_agent, action, 
            etape_apres, statut_apres, commentaire
        ) VALUES (
            v_type_demande, NEW.id, NEW.code_agent_creation, 
            'creation', NEW.etape_actuelle, NEW.statut_code,
            'Étape ' || NEW.etape_actuelle || ': Demande créée (' || NEW.statut_code || ')'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.statut_code IS DISTINCT FROM NEW.statut_code OR 
           OLD.etape_actuelle IS DISTINCT FROM NEW.etape_actuelle THEN
            INSERT INTO traceabilite (
                type_demande, demande_id, code_agent, action,
                etape_avant, etape_apres, statut_avant, statut_apres,
                commentaire
            ) VALUES (
                v_type_demande, NEW.id, NEW.code_agent_modification,
                CASE 
                    WHEN NEW.statut_code = 'soumis' THEN 'soumission'
                    WHEN NEW.statut_code = 'en_validation' THEN 'en_validation'
                    WHEN NEW.statut_code = 'valide' THEN 'validation_finale'
                    WHEN NEW.statut_code = 'refuse' THEN 'refus'
                    WHEN NEW.statut_code = 'clos' THEN 'cloture'
                    ELSE 'changement_statut'
                END,
                OLD.etape_actuelle, NEW.etape_actuelle,
                OLD.statut_code, NEW.statut_code,
                'Étape ' || NEW.etape_actuelle || ': ' || NEW.statut_code
            );
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers traceabilité
CREATE TRIGGER trigger_traceabilite_badge
    AFTER INSERT OR UPDATE ON badge
    FOR EACH ROW EXECUTE FUNCTION create_traceabilite();

CREATE TRIGGER trigger_traceabilite_hs_prealable
    AFTER INSERT OR UPDATE ON heures_sup_prealable
    FOR EACH ROW EXECUTE FUNCTION create_traceabilite();

CREATE TRIGGER trigger_traceabilite_hs_realisation
    AFTER INSERT OR UPDATE ON heures_sup_realisation
    FOR EACH ROW EXECUTE FUNCTION create_traceabilite();

-- ============================================
-- PARTIE 15: DONNÉES DE TEST
-- ============================================

-- Organisations et Services
INSERT INTO organisation (code_organisation, libelle) VALUES
('ORG001', 'URSSAF Caisse Nationale'),
('ORG002', 'URSSAF Direction Régionale'),
('ORG003', 'URSSAF Gaumont'),
('ORG004', 'URSSAF Valbonne'),
('ORG005', 'URSSAF Lille');

INSERT INTO service (code_service, code_organisation, libelle) VALUES
('RH001', 'ORG001', 'RH Service 1'),
('RH002', 'ORG002', 'RH Service 2'),
('RH003', 'ORG001', 'RH Service 3'),
('PCS001', 'ORG003', 'PCS Gaumont'),
('PCS002', 'ORG003', 'PCS Gaumont 2'),
('MGT001', 'ORG004', 'Management Valbonne'),
('MGT002', 'ORG005', 'Management Lille'),
('RH004', 'ORG001', 'RH Service 4'),
('RH005', 'ORG002', 'RH Service 5'),
('RH006', 'ORG001', 'RH Service 6');

-- Agents
INSERT INTO agent (code_agent, nom, prenom, email, code_organisation, code_service) VALUES
('AG001', 'Morel', 'Eric', 'eric.morel@urssaf.fr', 'ORG001', 'RH001'),
('AG002', 'Martin', 'Sophie', 'sophie.martin@urssaf.fr', 'ORG002', 'RH002'),
('AG003', 'Dupont', 'Agathe', 'agathe.dupont@urssaf.fr', 'ORG001', 'RH003'),
('AG004', 'Benali', 'Karim', 'karim.benali@urssaf.fr', 'ORG003', 'PCS001'),
('AG005', 'Leroy', 'Kevin', 'kevin.leroy@urssaf.fr', 'ORG004', 'MGT001'),
('AG006', 'Traore', 'Moussa', 'moussa.traore@urssaf.fr', 'ORG005', 'MGT002'),
('AG007', 'Dubois', 'Marie', 'marie.dubois@urssaf.fr', 'ORG001', 'RH004'),
('AG008', 'Petit', 'Jean', 'jean.petit@urssaf.fr', 'ORG002', 'RH005'),
('AG009', 'Dupuis', 'Amélie', 'amelie.dupuis@urssaf.fr', 'ORG001', 'RH006'),
('AG010', 'Bernard', 'Pierre', 'pierre.bernard@urssaf.fr', 'ORG003', 'PCS002');

-- Formulaires
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage) VALUES
('badge-nouveau-collab', 'Badge Nouveau Collaborateur', 'Demande badge nouveau collaborateur', 'Badges', 10),
('badge-depart-collab', 'Badge Départ Collaborateur', 'Gestion badge départ', 'Badges', 11),
('badge-collab-perdu', 'Badge Collaborateur Perdu', 'Remplacement badge perdu', 'Badges', 12),
('badge-perso-oubli', 'Badge Personnel Oublié', 'Gestion badge oublié', 'Badges', 16),
('badge-presta-new', 'Badge Prestataire Nouveau', 'Badge nouveau prestataire', 'Badges', 18),
('heures-sup-prealable', 'Heures Sup Préalable', 'Demande préalable HS', 'Rémunération', 1),
('heures-sup-realisation', 'Heures Sup Réalisation', 'Saisie réalisation HS', 'Rémunération', 2);

-- Workflows
-- Workflow Badge Nouveau Collab
INSERT INTO workflow_etape (formulaire_id, numero, libelle, role_validation, statut_code, action) VALUES
((SELECT id FROM formulaire WHERE slug = 'badge-nouveau-collab'), 1, 'Création demande', NULL, 'brouillon', 'creation'),
((SELECT id FROM formulaire WHERE slug = 'badge-nouveau-collab'), 2, 'Soumission', NULL, 'soumis', 'soumission'),
((SELECT id FROM formulaire WHERE slug = 'badge-nouveau-collab'), 3, 'Validation Manager', 'manager', 'en_validation', 'validation_manager'),
((SELECT id FROM formulaire WHERE slug = 'badge-nouveau-collab'), 4, 'Validation PCS', 'pcs', 'en_validation', 'validation_pcs'),
((SELECT id FROM formulaire WHERE slug = 'badge-nouveau-collab'), 5, 'Clôture', NULL, 'clos', 'cloture');

-- Workflow HS Préalable
INSERT INTO workflow_etape (formulaire_id, numero, libelle, role_validation, statut_code, action) VALUES
((SELECT id FROM formulaire WHERE slug = 'heures-sup-prealable'), 1, 'Création préalable', NULL, 'brouillon', 'creation'),
((SELECT id FROM formulaire WHERE slug = 'heures-sup-prealable'), 2, 'Soumission', NULL, 'soumis', 'soumission'),
((SELECT id FROM formulaire WHERE slug = 'heures-sup-prealable'), 3, 'Validation Manager', 'manager', 'en_validation', 'validation_manager'),
((SELECT id FROM formulaire WHERE slug = 'heures-sup-prealable'), 4, 'Validation RH', 'rh', 'en_validation', 'validation_rh'),
((SELECT id FROM formulaire WHERE slug = 'heures-sup-prealable'), 5, 'Approuvé', NULL, 'valide', 'approbation');

-- Workflow HS Réalisation
INSERT INTO workflow_etape (formulaire_id, numero, libelle, role_validation, statut_code, action) VALUES
((SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation'), 1, 'Création réalisation', NULL, 'brouillon', 'creation'),
((SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation'), 2, 'Soumission', NULL, 'soumis', 'soumission'),
((SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation'), 3, 'Validation Manager', 'manager', 'en_validation', 'validation_manager'),
((SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation'), 4, 'Validation RH', 'rh', 'en_validation', 'validation_rh'),
((SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation'), 5, 'Pointage RH', 'pointage_rh', 'en_validation', 'pointage_rh'),
((SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation'), 6, 'Clôture', NULL, 'clos', 'cloture_paiement');

-- ============================================
-- PARTIE 16: DONNÉES DE TEST BADGES
-- ============================================

-- Badge 1: Nouveau Collaborateur
INSERT INTO badge (
    type_badge, code_agent_demandeur, code_agent_concerne,
    nom_collaborateur, prenom_collaborateur, service_collaborateur,
    fonction, date_debut, projet,
    zones_acces, horaires, type_badge_acces,
    motif, statut_code, etape_actuelle,
    code_agent_creation
) VALUES (
    'nouveau_collab', 'AG005', 'AG009',
    'Dupuis', 'Amélie', 'RH006',
    'Chargée RH', '2025-01-15', 'Projet Innovation',
    ARRAY['Bureau', 'Parking'], 'Standard', 'Permanent',
    'Nouveau recrutement', 'brouillon', 1,
    'AG005'
);

-- Badge 2: Départ avec Prolongation
INSERT INTO badge (
    type_badge, code_agent_demandeur, code_agent_concerne,
    code_agent_concerne, date_depart,
    prolongation, motif_prolongation, date_fin_prolongation,
    rendu_badge, statut_code, etape_actuelle,
    date_soumission, code_agent_creation
) VALUES (
    'depart_collab', 'AG005', 'AG007',
    'AG007', '2025-02-15',
    TRUE, 'Finalisation projet en cours', '2025-03-01',
    FALSE, 'en_validation', 4,
    '2025-01-12 14:00:00', 'AG005'
);

-- Badge 3: Perdu
INSERT INTO badge (
    type_badge, code_agent_demandeur, code_agent_concerne,
    code_agent_concerne, type_perte, date_perte,
    numero_badge, declaration,
    statut_code, etape_actuelle, date_soumission, code_agent_creation
) VALUES (
    'collab_perdu', 'AG001', 'AG007',
    'AG007', 'Perdu', '2024-12-20',
    'BADGE-12345', 'Badge perdu le 20/12 dans le parking',
    'en_validation', 3, '2024-12-20 16:00:00', 'AG001'
);

-- Badge 4: Personnel Oublié
INSERT INTO badge (
    type_badge, code_agent_demandeur, code_agent_concerne,
    date_oubli, action_demandee, duree_temporaire,
    statut_code, etape_actuelle, date_soumission, date_cloture, code_agent_creation
) VALUES (
    'perso_oubli', 'AG001', 'AG001',
    '2024-12-18', 'Ouverture temporaire', 4,
    'clos', 4, '2024-12-18 08:00:00', '2024-12-18 09:00:00', 'AG001'
);

-- Badge 5: Prestataire Nouveau
INSERT INTO badge (
    type_badge, code_agent_demandeur,
    societe_prestataire, nom_prestataire, prenom_prestataire,
    mission_prestataire, contact_entreprise,
    date_debut_prestataire, date_fin_prestataire,
    zones_acces, type_badge_acces, duree_jours,
    statut_code, etape_actuelle, code_agent_creation
) VALUES (
    'presta_new', 'AG005',
    'TechCorp', 'Martin', 'Jean',
    'Support IT - Migration serveurs', 'contact@techcorp.fr',
    '2025-01-20', '2025-06-20',
    ARRAY['IT', 'Salle serveurs'], 'Temporaire', 150,
    'brouillon', 1, 'AG005'
);

-- Validations Badges
INSERT INTO validation_etape (type_demande, demande_id, workflow_etape_id, etape_workflow, code_agent_valideur, role_validation, ordre_validation, statut_validation) VALUES
('badge', 1, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'badge-nouveau-collab') AND numero = 3), 3, 'AG005', 'manager', 1, 'en_attente'),
('badge', 1, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'badge-nouveau-collab') AND numero = 4), 4, 'AG004', 'pcs', 2, 'en_attente'),
('badge', 2, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'badge-depart-collab') AND numero = 3), 3, 'AG005', 'manager', 1, 'valide'),
('badge', 2, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'badge-depart-collab') AND numero = 4), 4, 'AG004', 'pcs', 2, 'en_attente'),
('badge', 3, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'badge-collab-perdu') AND numero = 3), 3, 'AG004', 'pcs', 1, 'en_attente'),
('badge', 4, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'badge-perso-oubli') AND numero = 3), 3, 'AG004', 'pcs', 1, 'valide');

-- ============================================
-- PARTIE 17: DONNÉES DE TEST HEURES SUP
-- ============================================

-- HS Préalable 1
INSERT INTO heures_sup_prealable (
    code_agent_demandeur, code_agent_concerne,
    date_debut, date_fin, jours_semaine, type_periode,
    nb_heures_total, heures_detaillees, motif, dossier_lie,
    horaires_previsionnels, statut_code, etape_actuelle,
    date_soumission, code_agent_creation
) VALUES (
    'AG001', 'AG001',
    '2024-12-20', '2024-12-27', ARRAY['lundi', 'mardi', 'mercredi'], 'Ponctuel',
    12.00, '{"2024-12-20": 4, "2024-12-23": 4, "2024-12-24": 4}'::jsonb,
    'Dossier client urgent - Deadline 31/12', 'CLIENT-2024-001',
    '18h-22h chaque jour', 'valide', 5,
    '2024-12-15 10:00:00', 'AG001'
);

-- HS Préalable 2 (Refusé)
INSERT INTO heures_sup_prealable (
    code_agent_demandeur, code_agent_concerne,
    date_debut, date_fin, nb_heures_total, motif,
    statut_code, etape_actuelle,
    date_soumission, date_cloture, code_agent_creation
) VALUES (
    'AG007', 'AG007',
    '2025-01-05', '2025-01-10', 25.00, 'Charge de travail élevée',
    'refuse', 3,
    '2024-12-20 10:00:00', '2024-12-21 14:00:00', 'AG007'
);

-- HS Réalisation 1 (avec préalable)
INSERT INTO heures_sup_realisation (
    heures_sup_prealable_id, code_agent_demandeur, code_agent_concerne,
    avec_prealable, sans_prealable,
    dates_realisees, heures_realisees, total_heures,
    pointages_gta, ecarts_vs_prealable, justification_ecarts,
    statut_code, etape_actuelle,
    date_soumission, code_agent_creation
) VALUES (
    1, 'AG001', 'AG001',
    TRUE, FALSE,
    ARRAY['2024-12-20', '2024-12-23', '2024-12-24'],
    '{"2024-12-20": {"debut": "18:00", "fin": "22:00", "nb_heures": 4}, "2024-12-23": {"debut": "18:00", "fin": "22:15", "nb_heures": 4.25}, "2024-12-24": {"debut": "18:00", "fin": "22:00", "nb_heures": 4}}'::jsonb,
    12.25,
    '{"2024-12-20": {"entree": "09:00", "sortie": "22:15"}, "2024-12-23": {"entree": "09:00", "sortie": "22:15"}, "2024-12-24": {"entree": "09:00", "sortie": "22:05"}}'::jsonb,
    '{"2024-12-20": {"ecart": 0}, "2024-12-23": {"ecart": 0.25, "justification": "Client a appelé après 22h"}, "2024-12-24": {"ecart": 0}}'::jsonb,
    'Écart minime le 23/12 dû à appel client',
    'clos', 6,
    '2024-12-28 09:00:00', 'AG001'
);

-- HS Réalisation 2 (sans préalable)
INSERT INTO heures_sup_realisation (
    code_agent_demandeur, code_agent_concerne,
    avec_prealable, sans_prealable, motif_urgence,
    dates_realisees, heures_realisees, total_heures,
    pointages_gta, statut_code, etape_actuelle,
    date_soumission, code_agent_creation
) VALUES (
    'AG002', 'AG002',
    FALSE, TRUE, 'Incident critique système à résoudre en urgence',
    ARRAY['2024-12-18'],
    '{"2024-12-18": {"debut": "18:00", "fin": "20:30", "nb_heures": 2.5}}'::jsonb,
    2.50,
    '{"2024-12-18": {"entree": "09:00", "sortie": "20:35"}}'::jsonb,
    'en_validation', 3,
    '2024-12-19 08:00:00', 'AG002'
);

-- Validations HS Préalable
INSERT INTO validation_etape (type_demande, demande_id, workflow_etape_id, etape_workflow, code_agent_valideur, role_validation, ordre_validation, statut_validation, commentaire, date_validation) VALUES
('heures_sup_prealable', 1, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'heures-sup-prealable') AND numero = 3), 3, 'AG005', 'manager', 1, 'valide', 'Validation Manager - Dossier justifié', '2024-12-16 09:00:00'),
('heures_sup_prealable', 1, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'heures-sup-prealable') AND numero = 4), 4, 'AG002', 'rh', 2, 'valide', 'Validation RH - Préalable approuvé', '2024-12-17 14:00:00'),
('heures_sup_prealable', 2, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'heures-sup-prealable') AND numero = 3), 3, 'AG005', 'manager', 1, 'refuse', 'Trop d''heures demandées sans justification suffisante', '2024-12-21 14:00:00');

-- Validations HS Réalisation
INSERT INTO validation_etape (type_demande, demande_id, workflow_etape_id, etape_workflow, code_agent_valideur, role_validation, ordre_validation, statut_validation, commentaire, date_validation) VALUES
('heures_sup_realisation', 1, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation') AND numero = 3), 3, 'AG005', 'manager', 1, 'valide', 'Validation Manager - Pointages cohérents', '2024-12-29 10:00:00'),
('heures_sup_realisation', 1, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation') AND numero = 4), 4, 'AG002', 'rh', 2, 'valide', 'Validation RH - OK', '2024-12-30 11:00:00'),
('heures_sup_realisation', 1, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation') AND numero = 5), 5, 'AG002', 'pointage_rh', 3, 'valide', 'Pointage RH effectué - Données GTA validées - Paiement programmé', '2024-12-31 09:00:00'),
('heures_sup_realisation', 2, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation') AND numero = 3), 3, 'AG006', 'manager', 1, 'en_attente', NULL, NULL),
('heures_sup_realisation', 2, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation') AND numero = 4), 4, 'AG002', 'rh', 2, 'en_attente', NULL, NULL),
('heures_sup_realisation', 2, (SELECT id FROM workflow_etape WHERE formulaire_id = (SELECT id FROM formulaire WHERE slug = 'heures-sup-realisation') AND numero = 5), 5, 'AG002', 'pointage_rh', 3, 'en_attente', NULL, NULL);

-- ============================================
-- PARTIE 18: PIÈCES JOINTES
-- ============================================

INSERT INTO piece_jointe (type_demande, demande_id, nom_fichier, chemin_fichier, type_mime, taille_octets, type_document, code_agent_upload) VALUES
('heures_sup_prealable', 1, 'justificatif_hs_prealable.pdf', '/uploads/demandes/hs_prealable/1/justificatif.pdf', 'application/pdf', 245678, 'justificatif', 'AG001'),
('heures_sup_realisation', 1, 'pointages_gta_decembre.xlsx', '/uploads/demandes/hs_realisation/1/pointages.xlsx', 'application/vnd.ms-excel', 189432, 'pointage_gta', 'AG001'),
('heures_sup_realisation', 1, 'screenshot_gta_2024-12-20.png', '/uploads/demandes/hs_realisation/1/screenshot.png', 'image/png', 156789, 'justificatif', 'AG001'),
('badge', 1, 'cv_amelie_dupuis.pdf', '/uploads/demandes/badge/1/cv.pdf', 'application/pdf', 345678, 'justificatif', 'AG005'),
('heures_sup_realisation', 2, 'rapport_incident.pdf', '/uploads/demandes/hs_realisation/2/rapport.pdf', 'application/pdf', 278901, 'justificatif', 'AG002');

-- ============================================
-- PARTIE 19: NOTIFICATIONS
-- ============================================

INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG005', 'validation_requise', 'Badge à valider - Nouveau collaborateur',
 'Une demande de badge pour Amélie Dupuis nécessite votre validation Manager.',
 '{"type": "badge", "demande_id": 1, "etape": 3}'::jsonb, '/demandes/badge/1'),
('AG004', 'validation_requise', 'Badge à valider - Après Manager',
 'La demande de badge pour Amélie Dupuis est prête pour validation PCS.',
 '{"type": "badge", "demande_id": 1, "etape": 4}'::jsonb, '/demandes/badge/1'),
('AG005', 'validation_requise', 'HS Préalable à valider',
 'Eric Morel demande votre validation pour 12h HS préalables (20-27 déc).',
 '{"type": "heures_sup_prealable", "demande_id": 1, "etape": 3, "nb_heures": 12}'::jsonb, '/demandes/hs_prealable/1'),
('AG001', 'validation_reponse', 'Votre demande HS préalable a été approuvée',
 'Votre demande préalable de 12h HS (20-27 déc) a été approuvée. Vous pouvez maintenant réaliser les heures.',
 '{"type": "heures_sup_prealable", "demande_id": 1, "etape": 5}'::jsonb, '/demandes/hs_prealable/1'),
('AG001', 'validation_reponse', 'Votre réalisation HS a été validée',
 'Votre réalisation de 12.25h HS a été validée. Le paiement sera effectué sur la prochaine paie.',
 '{"type": "heures_sup_realisation", "demande_id": 1, "etape": 6}'::jsonb, '/demandes/hs_realisation/1');

COMMIT;

