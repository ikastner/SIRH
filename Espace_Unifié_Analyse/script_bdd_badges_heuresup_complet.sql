-- ============================================
-- SCRIPT SQL COMPLET - BADGES & HEURES SUP
-- Espace Unifié URSSAF
-- ============================================
-- Ce script crée toutes les tables nécessaires, insère tous les formulaires
-- Badges et Heures Sup, et génère des données de test avec workflows complets
-- ============================================

-- ============================================
-- PARTIE 1: CRÉATION DES TABLES
-- ============================================

-- Suppression des tables existantes (dans l'ordre des dépendances)
DROP TABLE IF EXISTS lien_demande CASCADE;
DROP TABLE IF EXISTS historique_demande CASCADE;
DROP TABLE IF EXISTS valideur_demande CASCADE;
DROP TABLE IF EXISTS document CASCADE;
DROP TABLE IF EXISTS notification CASCADE;
DROP TABLE IF EXISTS favori CASCADE;
DROP TABLE IF EXISTS demande CASCADE;
DROP TABLE IF EXISTS formulaire CASCADE;
DROP TABLE IF EXISTS application_externe CASCADE;
DROP TABLE IF EXISTS dossier_agent_vue CASCADE;
DROP TABLE IF EXISTS agent CASCADE;

-- Suppression des fonctions
DROP FUNCTION IF EXISTS update_modified_column() CASCADE;
DROP FUNCTION IF EXISTS create_historique_demande() CASCADE;
DROP FUNCTION IF EXISTS create_notification_validation() CASCADE;
DROP FUNCTION IF EXISTS avancer_workflow_validation() CASCADE;

-- ============================================
-- TABLE: agent (référence vers ANAIS)
-- ============================================
CREATE TABLE agent (
    code_agent VARCHAR(50) PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    organisation VARCHAR(100),
    code_service VARCHAR(50),
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actif BOOLEAN DEFAULT TRUE
);

-- ============================================
-- TABLE: formulaire
-- ============================================
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
    regles JSONB,
    schema_formulaire JSONB,
    workflow_etapes JSONB, -- Étapes du workflow avec numéros
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    code_agent_creation VARCHAR(50),
    code_agent_modification VARCHAR(50)
);

-- ============================================
-- TABLE: demande
-- ============================================
CREATE TABLE demande (
    id SERIAL PRIMARY KEY,
    formulaire_id INTEGER NOT NULL REFERENCES formulaire(id),
    code_agent_demandeur VARCHAR(50) NOT NULL REFERENCES agent(code_agent),
    code_agent_concerne VARCHAR(50) REFERENCES agent(code_agent),
    statut VARCHAR(50) NOT NULL DEFAULT 'brouillon',
    -- statuts: brouillon, soumis, en_validation, complement_demande, valide, refuse, clos
    etape_actuelle INTEGER DEFAULT 1, -- Numéro de l'étape actuelle du workflow
    donnees JSONB NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_soumission TIMESTAMP,
    date_cloture TIMESTAMP,
    code_agent_creation VARCHAR(50),
    code_agent_modification VARCHAR(50),
    est_supprime BOOLEAN DEFAULT FALSE,
    motif_suppression TEXT,
    commentaire_suppression TEXT,
    code_agent_suppression VARCHAR(50),
    date_suppression TIMESTAMP
);

CREATE INDEX idx_demande_statut ON demande(statut);
CREATE INDEX idx_demande_agent_demandeur ON demande(code_agent_demandeur);
CREATE INDEX idx_demande_agent_concerne ON demande(code_agent_concerne);
CREATE INDEX idx_demande_formulaire ON demande(formulaire_id);
CREATE INDEX idx_demande_date_creation ON demande(date_creation);
CREATE INDEX idx_demande_etape ON demande(etape_actuelle);

-- ============================================
-- TABLE: lien_demande (pour liens entre demandes)
-- ============================================
CREATE TABLE lien_demande (
    id SERIAL PRIMARY KEY,
    demande_source_id INTEGER NOT NULL REFERENCES demande(id) ON DELETE CASCADE,
    demande_cible_id INTEGER NOT NULL REFERENCES demande(id) ON DELETE CASCADE,
    type_lien VARCHAR(50) NOT NULL, -- 'prealable_realisation', 'proroge', 'suite', etc.
    commentaire TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(demande_source_id, demande_cible_id, type_lien)
);

CREATE INDEX idx_lien_source ON lien_demande(demande_source_id);
CREATE INDEX idx_lien_cible ON lien_demande(demande_cible_id);

-- ============================================
-- TABLE: valideur_demande
-- ============================================
CREATE TABLE valideur_demande (
    id SERIAL PRIMARY KEY,
    demande_id INTEGER NOT NULL REFERENCES demande(id) ON DELETE CASCADE,
    code_agent_valideur VARCHAR(50) NOT NULL REFERENCES agent(code_agent),
    role_validation VARCHAR(50) NOT NULL, -- manager, rh, pcs, pointage_rh
    ordre_validation INTEGER NOT NULL DEFAULT 1,
    etape_workflow INTEGER NOT NULL, -- Étape correspondante dans le workflow
    statut VARCHAR(50) DEFAULT 'en_attente', -- en_attente, valide, refuse, annule
    commentaire TEXT,
    date_validation TIMESTAMP,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_notification TIMESTAMP,
    UNIQUE(demande_id, code_agent_valideur, ordre_validation)
);

CREATE INDEX idx_valideur_agent ON valideur_demande(code_agent_valideur);
CREATE INDEX idx_valideur_statut ON valideur_demande(statut);
CREATE INDEX idx_valideur_demande ON valideur_demande(demande_id);
CREATE INDEX idx_valideur_etape ON valideur_demande(etape_workflow);

-- ============================================
-- TABLE: historique_demande
-- ============================================
CREATE TABLE historique_demande (
    id SERIAL PRIMARY KEY,
    demande_id INTEGER NOT NULL REFERENCES demande(id) ON DELETE CASCADE,
    code_agent VARCHAR(50) REFERENCES agent(code_agent),
    action VARCHAR(100) NOT NULL,
    etape_avant INTEGER,
    etape_apres INTEGER,
    ancien_statut VARCHAR(50),
    nouveau_statut VARCHAR(50),
    commentaire TEXT,
    donnees_avant JSONB,
    donnees_apres JSONB,
    date_action TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_historique_demande ON historique_demande(demande_id);
CREATE INDEX idx_historique_date ON historique_demande(date_action);

-- ============================================
-- TABLE: document
-- ============================================
CREATE TABLE document (
    id SERIAL PRIMARY KEY,
    demande_id INTEGER REFERENCES demande(id) ON DELETE CASCADE,
    code_agent VARCHAR(50) REFERENCES agent(code_agent),
    nom_fichier VARCHAR(255) NOT NULL,
    chemin_fichier VARCHAR(500) NOT NULL,
    type_mime VARCHAR(100),
    taille_octets BIGINT,
    type_document VARCHAR(50),
    date_upload TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    code_agent_upload VARCHAR(50),
    actif BOOLEAN DEFAULT TRUE
);

CREATE INDEX idx_document_demande ON document(demande_id);
CREATE INDEX idx_document_agent ON document(code_agent);

-- ============================================
-- TABLE: notification
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
-- TABLE: favori
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
-- TABLE: dossier_agent_vue
-- ============================================
CREATE TABLE dossier_agent_vue (
    code_agent VARCHAR(50) PRIMARY KEY REFERENCES agent(code_agent),
    nb_demandes_total INTEGER DEFAULT 0,
    nb_demandes_en_cours INTEGER DEFAULT 0,
    nb_demandes_validees INTEGER DEFAULT 0,
    nb_demandes_refusees INTEGER DEFAULT 0,
    derniere_demande_date TIMESTAMP,
    date_mise_a_jour TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TRIGGERS: Mise à jour automatique des dates
-- ============================================
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.date_modification = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_demande_modification BEFORE UPDATE ON demande
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

CREATE TRIGGER update_formulaire_modification BEFORE UPDATE ON formulaire
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- ============================================
-- TRIGGERS: Gestion automatique de l'historique
-- ============================================
CREATE OR REPLACE FUNCTION create_historique_demande()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO historique_demande (
            demande_id, code_agent, action, etape_apres, nouveau_statut, commentaire
        ) VALUES (
            NEW.id, NEW.code_agent_creation, 'creation', NEW.etape_actuelle, NEW.statut, 
            'Étape 1: Demande créée (brouillon)'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.statut IS DISTINCT FROM NEW.statut OR OLD.etape_actuelle IS DISTINCT FROM NEW.etape_actuelle THEN
            INSERT INTO historique_demande (
                demande_id, code_agent, action, etape_avant, etape_apres, 
                ancien_statut, nouveau_statut, commentaire, donnees_avant, donnees_apres
            ) VALUES (
                NEW.id, NEW.code_agent_modification, 
                CASE 
                    WHEN NEW.statut = 'soumis' THEN 'soumission'
                    WHEN NEW.statut = 'en_validation' THEN 'en_validation'
                    WHEN NEW.statut = 'valide' THEN 'validation_finale'
                    WHEN NEW.statut = 'refuse' THEN 'refus'
                    WHEN NEW.statut = 'clos' THEN 'cloture'
                    ELSE 'changement_statut'
                END,
                OLD.etape_actuelle, NEW.etape_actuelle, 
                OLD.statut, NEW.statut,
                'Étape ' || NEW.etape_actuelle || ': ' || NEW.statut,
                row_to_json(OLD), row_to_json(NEW)
            );
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_historique_demande
    AFTER INSERT OR UPDATE ON demande
    FOR EACH ROW EXECUTE FUNCTION create_historique_demande();

-- ============================================
-- PARTIE 2: INSERTION DES AGENTS
-- ============================================

INSERT INTO agent (code_agent, nom, prenom, email, organisation, code_service) VALUES
('AG001', 'Morel', 'Eric', 'eric.morel@urssaf.fr', 'URSSAF Caisse Nationale', 'RH001'),
('AG002', 'Martin', 'Sophie', 'sophie.martin@urssaf.fr', 'URSSAF Direction Régionale', 'RH002'),
('AG003', 'Dupont', 'Agathe', 'agathe.dupont@urssaf.fr', 'URSSAF Caisse Nationale', 'RH003'),
('AG004', 'Benali', 'Karim', 'karim.benali@urssaf.fr', 'URSSAF Gaumont', 'PCS001'),
('AG005', 'Leroy', 'Kevin', 'kevin.leroy@urssaf.fr', 'URSSAF Valbonne', 'MGT001'),
('AG006', 'Traore', 'Moussa', 'moussa.traore@urssaf.fr', 'URSSAF Lille', 'MGT002'),
('AG007', 'Dubois', 'Marie', 'marie.dubois@urssaf.fr', 'URSSAF Caisse Nationale', 'RH004'),
('AG008', 'Petit', 'Jean', 'jean.petit@urssaf.fr', 'URSSAF Direction Régionale', 'RH005'),
('AG009', 'Dupuis', 'Amélie', 'amelie.dupuis@urssaf.fr', 'URSSAF Caisse Nationale', 'RH006'),
('AG010', 'Bernard', 'Pierre', 'pierre.bernard@urssaf.fr', 'URSSAF Gaumont', 'PCS002');

-- ============================================
-- PARTIE 3: INSERTION FORMULAIRES BADGES
-- ============================================

-- BADGE 1: Nouveau Collaborateur
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-nouveau-collab', 'Badge Nouveau Collaborateur', 
 'Demande de badge pour nouveau collaborateur', 'Badges', 10, 'badge',
 '{
   "sections": [
     {
       "libelle": "Informations collaborateur",
       "champs": [
         {"nom": "nom", "type": "text", "requis": true, "label": "Nom"},
         {"nom": "prenom", "type": "text", "requis": true, "label": "Prénom"},
         {"nom": "service", "type": "select", "requis": true, "label": "Service"},
         {"nom": "fonction", "type": "text", "requis": false, "label": "Fonction"},
         {"nom": "date_debut", "type": "date", "requis": true, "label": "Date de début"},
         {"nom": "projet", "type": "text", "requis": false, "label": "Projet/Mission"}
       ]
     },
     {
       "libelle": "Accès demandés",
       "champs": [
         {"nom": "zones_acces", "type": "multiselect", "requis": true, "label": "Zones d''accès", "options": ["Bureau", "Parking", "Salle serveurs", "Archives"]},
         {"nom": "horaires", "type": "select", "requis": true, "label": "Horaires", "options": ["Standard", "Étendu", "24/7"]},
         {"nom": "type_badge", "type": "select", "requis": true, "label": "Type", "options": ["Permanent", "Temporaire"]},
         {"nom": "duree_mois", "type": "number", "requis": false, "label": "Durée (mois)", "visible_si": {"type_badge": "Temporaire"}}
       ]
     },
     {
       "libelle": "Justification",
       "champs": [
         {"nom": "motif", "type": "textarea", "requis": true, "label": "Motif"},
         {"nom": "piece_jointe", "type": "file", "requis": false, "label": "Pièce jointe"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_manager": true,
   "validation_pcs": true,
   "ordre_validation": ["manager", "pcs"],
   "duree_max_mois": 365
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande (brouillon)", "statut": "brouillon", "action": "creation"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis", "action": "soumission"},
     {"numero": 3, "libelle": "Validation Manager", "statut": "en_validation", "role": "manager", "action": "validation_manager"},
     {"numero": 4, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs", "action": "validation_pcs"},
     {"numero": 5, "libelle": "Clôture - Badge délivré", "statut": "clos", "action": "cloture"}
   ]
 }'::jsonb);

-- BADGE 2: Départ Collaborateur
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-depart-collab', 'Badge Départ Collaborateur',
 'Gestion badge à la sortie d''un collaborateur', 'Badges', 11, 'logout',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "collaborateur", "type": "select_agent", "requis": true, "label": "Collaborateur"},
         {"nom": "date_depart", "type": "date", "requis": true, "label": "Date de départ"},
         {"nom": "prolongation", "type": "boolean", "requis": false, "label": "Prolongation demandée"},
         {"nom": "motif_prolongation", "type": "textarea", "requis": false, "label": "Motif prolongation", "visible_si": {"prolongation": true}},
         {"nom": "date_fin_prolongation", "type": "date", "requis": false, "label": "Date fin prolongation", "visible_si": {"prolongation": true}},
         {"nom": "rendu_badge", "type": "boolean", "requis": true, "label": "Badge rendu"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_manager": true,
   "validation_pcs": true,
   "ordre_validation": ["manager", "pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation Manager", "statut": "en_validation", "role": "manager"},
     {"numero": 4, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 5, "libelle": "Clôture", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 3: Collaborateur - Badge Perdu
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-collab-perdu', 'Badge Collaborateur Perdu/Volé',
 'Remplacement badge collaborateur perdu ou volé', 'Badges', 12, 'alert',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "collaborateur", "type": "select_agent", "requis": true, "label": "Collaborateur"},
         {"nom": "type_perte", "type": "select", "requis": true, "label": "Type", "options": ["Perdu", "Volé", "Cassé"]},
         {"nom": "date_perte", "type": "date", "requis": true, "label": "Date perte/vol"},
         {"nom": "numero_badge", "type": "text", "requis": true, "label": "Numéro badge"},
         {"nom": "declaration", "type": "textarea", "requis": true, "label": "Déclaration"}
       ]
     },
     {
       "libelle": "Justification",
       "champs": [
         {"nom": "piece_jointe", "type": "file", "requis": false, "label": "Pièce jointe (si vol)"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_pcs": true,
   "ordre_validation": ["pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 4, "libelle": "Clôture - Badge remplacé", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 4: Collaborateur - Badge HS (Hors Service)
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-collab-hs', 'Badge Collaborateur Hors Service',
 'Remplacement badge collaborateur hors service', 'Badges', 13, 'alert-circle',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "collaborateur", "type": "select_agent", "requis": true, "label": "Collaborateur"},
         {"nom": "numero_badge", "type": "text", "requis": true, "label": "Numéro badge"},
         {"nom": "motif_hs", "type": "textarea", "requis": true, "label": "Motif hors service"},
         {"nom": "date_hs", "type": "date", "requis": true, "label": "Date détection"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_pcs": true,
   "ordre_validation": ["pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 4, "libelle": "Clôture - Badge remplacé", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 5: Collaborateur - Accès Spécifique
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-collab-specifique', 'Badge Collaborateur - Accès Spécifique',
 'Demande d''accès spécifique pour collaborateur', 'Badges', 14, 'key',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "collaborateur", "type": "select_agent", "requis": true, "label": "Collaborateur"},
         {"nom": "zones_demandees", "type": "multiselect", "requis": true, "label": "Zones demandées"},
         {"nom": "motif", "type": "textarea", "requis": true, "label": "Motif accès spécifique"},
         {"nom": "duree_jours", "type": "number", "requis": true, "label": "Durée (jours)"},
         {"nom": "date_debut_acces", "type": "date", "requis": true, "label": "Date début accès"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_manager": true,
   "validation_pcs": true,
   "ordre_validation": ["manager", "pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation Manager", "statut": "en_validation", "role": "manager"},
     {"numero": 4, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 5, "libelle": "Clôture - Accès configuré", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 6: Personnel - Demande Standard
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-perso', 'Badge Personnel - Demande Standard',
 'Demande badge personnel standard', 'Badges', 15, 'user',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "type_demande", "type": "select", "requis": true, "label": "Type", "options": ["Nouveau", "Remplacement", "Modification"]},
         {"nom": "motif", "type": "textarea", "requis": true, "label": "Motif"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_pcs": true,
   "ordre_validation": ["pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 4, "libelle": "Clôture", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 7: Personnel - Badge Oublié
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-perso-oubli', 'Badge Personnel - Oublié',
 'Gestion badge personnel oublié', 'Badges', 16, 'alert',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "date_oubli", "type": "date", "requis": true, "label": "Date oubli"},
         {"nom": "action_demandee", "type": "select", "requis": true, "label": "Action", "options": ["Ouverture temporaire", "Remplacement"]},
         {"nom": "duree_temporaire", "type": "number", "requis": false, "label": "Durée (heures)", "visible_si": {"action_demandee": "Ouverture temporaire"}}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_pcs": true,
   "ordre_validation": ["pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 4, "libelle": "Clôture", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 8: Personnel - Désactivation
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-perso-desac', 'Badge Personnel - Désactivation',
 'Demande de désactivation badge personnel', 'Badges', 17, 'x-circle',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "motif_desactivation", "type": "textarea", "requis": true, "label": "Motif désactivation"},
         {"nom": "date_desactivation", "type": "date", "requis": true, "label": "Date souhaitée"},
         {"nom": "temporaire", "type": "boolean", "requis": false, "label": "Désactivation temporaire"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_pcs": true,
   "ordre_validation": ["pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 4, "libelle": "Clôture - Badge désactivé", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 9: Prestataire - Nouveau
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-presta-new', 'Badge Prestataire - Nouveau',
 'Demande badge pour nouveau prestataire', 'Badges', 18, 'briefcase',
 '{
   "sections": [
     {
       "libelle": "Prestataire",
       "champs": [
         {"nom": "societe", "type": "text", "requis": true, "label": "Société"},
         {"nom": "nom", "type": "text", "requis": true, "label": "Nom"},
         {"nom": "prenom", "type": "text", "requis": true, "label": "Prénom"},
         {"nom": "mission", "type": "textarea", "requis": true, "label": "Mission"},
         {"nom": "contact_entreprise", "type": "text", "requis": false, "label": "Contact entreprise"},
         {"nom": "date_debut", "type": "date", "requis": true, "label": "Date début"},
         {"nom": "date_fin", "type": "date", "requis": false, "label": "Date fin prévue"}
       ]
     },
     {
       "libelle": "Accès",
       "champs": [
         {"nom": "zones_acces", "type": "multiselect", "requis": true, "label": "Zones d''accès"},
         {"nom": "type_badge", "type": "select", "requis": true, "label": "Type", "options": ["Permanent", "Temporaire"]},
         {"nom": "duree_autorisation", "type": "number", "requis": true, "label": "Durée autorisation (jours)"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_manager": true,
   "validation_pcs": true,
   "ordre_validation": ["manager", "pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation Manager", "statut": "en_validation", "role": "manager"},
     {"numero": 4, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 5, "libelle": "Clôture - Badge délivré", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 10: Prestataire - Renouvellement
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-presta-renew', 'Badge Prestataire - Renouvellement',
 'Renouvellement badge prestataire', 'Badges', 19, 'refresh',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "prestataire_existant", "type": "text", "requis": true, "label": "Nom prestataire"},
         {"nom": "numero_badge", "type": "text", "requis": true, "label": "Numéro badge actuel"},
         {"nom": "nouvelle_date_fin", "type": "date", "requis": true, "label": "Nouvelle date fin"},
         {"nom": "motif_renouvellement", "type": "textarea", "requis": true, "label": "Motif renouvellement"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_manager": true,
   "validation_pcs": true,
   "ordre_validation": ["manager", "pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation Manager", "statut": "en_validation", "role": "manager"},
     {"numero": 4, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 5, "libelle": "Clôture - Badge renouvelé", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 11: Prestataire - Départ
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-presta-depart', 'Badge Prestataire - Départ',
 'Gestion badge prestataire à la sortie', 'Badges', 20, 'logout',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "prestataire", "type": "text", "requis": true, "label": "Nom prestataire"},
         {"nom": "numero_badge", "type": "text", "requis": true, "label": "Numéro badge"},
         {"nom": "date_depart", "type": "date", "requis": true, "label": "Date départ"},
         {"nom": "rendu_badge", "type": "boolean", "requis": true, "label": "Badge rendu"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_manager": true,
   "validation_pcs": true,
   "ordre_validation": ["manager", "pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation Manager", "statut": "en_validation", "role": "manager"},
     {"numero": 4, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 5, "libelle": "Clôture", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 12: Prestataire - Perdu
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-presta-perdu', 'Badge Prestataire - Perdu/Volé',
 'Remplacement badge prestataire perdu ou volé', 'Badges', 21, 'alert',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "prestataire", "type": "text", "requis": true, "label": "Nom prestataire"},
         {"nom": "type_perte", "type": "select", "requis": true, "label": "Type", "options": ["Perdu", "Volé"]},
         {"nom": "date_perte", "type": "date", "requis": true, "label": "Date perte/vol"},
         {"nom": "numero_badge", "type": "text", "requis": true, "label": "Numéro badge"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_pcs": true,
   "ordre_validation": ["pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 4, "libelle": "Clôture - Badge remplacé", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 13: Prestataire - HS
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-presta-hs', 'Badge Prestataire - Hors Service',
 'Remplacement badge prestataire hors service', 'Badges', 22, 'alert-circle',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "prestataire", "type": "text", "requis": true, "label": "Nom prestataire"},
         {"nom": "numero_badge", "type": "text", "requis": true, "label": "Numéro badge"},
         {"nom": "motif_hs", "type": "textarea", "requis": true, "label": "Motif hors service"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_pcs": true,
   "ordre_validation": ["pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 4, "libelle": "Clôture - Badge remplacé", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 14: Prestataire - Accès Spécifique
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-presta-acces-spec', 'Badge Prestataire - Accès Spécifique',
 'Demande d''accès spécifique pour prestataire', 'Badges', 23, 'key',
 '{
   "sections": [
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "prestataire", "type": "text", "requis": true, "label": "Nom prestataire"},
         {"nom": "zones_demandees", "type": "multiselect", "requis": true, "label": "Zones demandées"},
         {"nom": "motif", "type": "textarea", "requis": true, "label": "Motif accès spécifique"},
         {"nom": "duree_jours", "type": "number", "requis": true, "label": "Durée (jours)"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_manager": true,
   "validation_pcs": true,
   "ordre_validation": ["manager", "pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation Manager", "statut": "en_validation", "role": "manager"},
     {"numero": 4, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 5, "libelle": "Clôture - Accès configuré", "statut": "clos"}
   ]
 }'::jsonb);

-- BADGE 15: Autre - Spécifique
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('badge-autre-specifique', 'Badge Demande Spécifique',
 'Demande badge cas particulier', 'Badges', 24, 'settings',
 '{
   "sections": [
     {
       "libelle": "Type de demande",
       "champs": [
         {"nom": "type_specifique", "type": "text", "requis": true, "label": "Type spécifique"},
         {"nom": "description", "type": "textarea", "requis": true, "label": "Description"},
         {"nom": "justification", "type": "textarea", "requis": true, "label": "Justification"}
       ]
     },
     {
       "libelle": "Informations",
       "champs": [
         {"nom": "beneficiaire", "type": "text", "requis": true, "label": "Bénéficiaire"},
         {"nom": "dates", "type": "daterange", "requis": false, "label": "Période"},
         {"nom": "motif", "type": "textarea", "requis": true, "label": "Motif"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_manager": true,
   "validation_pcs": true,
   "validation_rh": false,
   "ordre_validation": ["manager", "pcs"]
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande", "statut": "brouillon"},
     {"numero": 2, "libelle": "Soumission", "statut": "soumis"},
     {"numero": 3, "libelle": "Validation Manager", "statut": "en_validation", "role": "manager"},
     {"numero": 4, "libelle": "Validation PCS", "statut": "en_validation", "role": "pcs"},
     {"numero": 5, "libelle": "Clôture", "statut": "clos"}
   ]
 }'::jsonb);

-- ============================================
-- PARTIE 4: INSERTION FORMULAIRES HEURES SUP
-- ============================================

-- HEURES SUP 1: Demande Préalable
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('heures-sup-prealable', 'Heures Supplémentaires - Demande Préalable',
 'Demande préalable d''heures supplémentaires', 'Rémunération', 1, 'clock',
 '{
   "sections": [
     {
       "libelle": "Période",
       "champs": [
         {"nom": "date_debut", "type": "date", "requis": true, "label": "Date début"},
         {"nom": "date_fin", "type": "date", "requis": true, "label": "Date fin"},
         {"nom": "jours_semaine", "type": "multiselect", "requis": false, "label": "Jours concernés", "options": ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]},
         {"nom": "type_periode", "type": "select", "requis": true, "label": "Type", "options": ["Ponctuel", "Récurrent"]}
       ]
     },
     {
       "libelle": "Détails heures",
       "champs": [
         {"nom": "nb_heures_total", "type": "number", "requis": true, "label": "Nombre total d''heures"},
         {"nom": "heures_detaillees", "type": "json", "requis": false, "label": "Détail par jour (JSON)"},
         {"nom": "horaires_previsionnels", "type": "textarea", "requis": false, "label": "Horaires prévisionnels"}
       ]
     },
     {
       "libelle": "Justification",
       "champs": [
         {"nom": "motif", "type": "textarea", "requis": true, "label": "Motif"},
         {"nom": "dossier_lie", "type": "text", "requis": false, "label": "Dossier/Projet lié"},
         {"nom": "piece_jointe", "type": "file", "requis": false, "label": "Pièce jointe"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "prealable": true,
   "validation_manager": true,
   "validation_rh": true,
   "ordre_validation": ["manager", "rh"],
   "max_heures_mois": 50
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création demande préalable (brouillon)", "statut": "brouillon", "action": "creation"},
     {"numero": 2, "libelle": "Soumission préalable", "statut": "soumis", "action": "soumission"},
     {"numero": 3, "libelle": "Validation Manager", "statut": "en_validation", "role": "manager", "action": "validation_manager"},
     {"numero": 4, "libelle": "Validation RH", "statut": "en_validation", "role": "rh", "action": "validation_rh"},
     {"numero": 5, "libelle": "Préalable approuvé - Réalisation possible", "statut": "valide", "action": "approbation"}
   ]
 }'::jsonb);

-- HEURES SUP 2: Réalisation (avec ou sans préalable)
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles, workflow_etapes) VALUES
('heures-sup-realisation', 'Heures Supplémentaires - Réalisation',
 'Saisie réalisation d''heures supplémentaires avec pointages', 'Rémunération', 2, 'check-circle',
 '{
   "sections": [
     {
       "libelle": "Lien préalable",
       "champs": [
         {"nom": "avec_prealable", "type": "boolean", "requis": false, "label": "Demande liée à un préalable"},
         {"nom": "demande_prealable_id", "type": "select_demande", "requis": false, "label": "Référence préalable", "visible_si": {"avec_prealable": true}, "filtre": {"formulaire": "heures-sup-prealable", "statut": "valide"}},
         {"nom": "sans_prealable", "type": "boolean", "requis": false, "label": "Sans préalable (cas exceptionnel)"},
         {"nom": "motif_urgence", "type": "textarea", "requis": false, "label": "Motif urgence", "visible_si": {"sans_prealable": true}}
       ]
     },
     {
       "libelle": "Réalisation",
       "champs": [
         {"nom": "dates_realisees", "type": "multidate", "requis": true, "label": "Dates réalisées"},
         {"nom": "heures_realisees", "type": "json", "requis": true, "label": "Heures réalisées (détail par jour)"},
         {"nom": "pointages_gta", "type": "json", "requis": false, "label": "Pointages GTA (JSON)"},
         {"nom": "ecarts_vs_prealable", "type": "json", "requis": false, "label": "Écarts vs préalable", "visible_si": {"avec_prealable": true}}
       ]
     },
     {
       "libelle": "Justification",
       "champs": [
         {"nom": "justification_ecarts", "type": "textarea", "requis": false, "label": "Justification écarts", "visible_si": {"avec_prealable": true}},
         {"nom": "pieces_justificatives", "type": "multifile", "requis": false, "label": "Pièces justificatives"}
       ]
     }
   ]
 }'::jsonb,
 '{
   "validation_manager": true,
   "validation_rh": true,
   "pointage_rh": true,
   "ordre_validation": ["manager", "rh", "pointage_rh"],
   "accepte_sans_prealable": true
 }'::jsonb,
 '{
   "etapes": [
     {"numero": 1, "libelle": "Création saisie réalisation (brouillon)", "statut": "brouillon", "action": "creation"},
     {"numero": 2, "libelle": "Soumission réalisation", "statut": "soumis", "action": "soumission"},
     {"numero": 3, "libelle": "Validation Manager", "statut": "en_validation", "role": "manager", "action": "validation_manager"},
     {"numero": 4, "libelle": "Validation RH", "statut": "en_validation", "role": "rh", "action": "validation_rh"},
     {"numero": 5, "libelle": "Pointage RH - Réconciliation GTA", "statut": "en_validation", "role": "pointage_rh", "action": "pointage_rh"},
     {"numero": 6, "libelle": "Clôture - Validation finale et paiement", "statut": "clos", "action": "cloture_paiement"}
   ]
 }'::jsonb);

-- ============================================
-- PARTIE 5: DONNÉES DE TEST - BADGES
-- ============================================

-- BADGE TEST 1: Nouveau Collaborateur - Workflow complet
-- Étape 1: Création (brouillon)
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, etape_actuelle, donnees, code_agent_creation) VALUES
(1, 'AG005', 'AG009', 'brouillon', 1,
 '{
   "type": "nouveau_collab",
   "nom": "Dupuis",
   "prenom": "Amélie",
   "service": "RH006",
   "fonction": "Chargée RH",
   "date_debut": "2025-01-15",
   "projet": "Projet Innovation",
   "zones_acces": ["Bureau", "Parking"],
   "horaires": "Standard",
   "type_badge": "Permanent",
   "motif": "Nouveau recrutement"
 }'::jsonb,
 'AG005');

-- Étape 2: Soumission → Étape 3: Validation Manager
UPDATE demande SET statut = 'soumis', etape_actuelle = 2, date_soumission = '2025-01-10 10:00:00', code_agent_modification = 'AG005'
WHERE id = 1;

-- Création valideurs pour étape 3 (Manager)
INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, etape_workflow, statut) VALUES
(1, 'AG005', 'manager', 1, 3, 'en_attente'),
(1, 'AG004', 'pcs', 2, 4, 'en_attente');

-- Notification Manager
INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG005', 'validation_requise', 'Badge à valider - Nouveau collaborateur',
 'Une demande de badge pour Amélie Dupuis nécessite votre validation Manager.',
 '{"demande_id": 1, "type": "badge-nouveau-collab", "etape": 3}'::jsonb,
 '/demandes/1');

-- BADGE TEST 2: Départ Collaborateur avec Prolongation
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, etape_actuelle, donnees, date_soumission, code_agent_creation) VALUES
(2, 'AG005', 'AG007', 'en_validation', 3,
 '{
   "collaborateur": "AG007",
   "date_depart": "2025-02-15",
   "prolongation": true,
   "motif_prolongation": "Finalisation projet en cours",
   "date_fin_prolongation": "2025-03-01",
   "rendu_badge": false
 }'::jsonb,
 '2025-01-12 14:00:00',
 'AG005');

INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, etape_workflow, statut, commentaire, date_validation) VALUES
(2, 'AG005', 'manager', 1, 3, 'valide', 'Prolongation validée', '2025-01-13 09:00:00'),
(2, 'AG004', 'pcs', 2, 4, 'en_attente', NULL, NULL);

-- BADGE TEST 3: Badge Collaborateur Perdu
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, etape_actuelle, donnees, date_soumission, code_agent_creation) VALUES
(3, 'AG001', 'AG007', 'en_validation', 3,
 '{
   "collaborateur": "AG007",
   "type_perte": "Perdu",
   "date_perte": "2024-12-20",
   "numero_badge": "BADGE-12345",
   "declaration": "Badge perdu le 20/12 dans le parking"
 }'::jsonb,
 '2024-12-20 16:00:00',
 'AG001');

INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, etape_workflow, statut) VALUES
(3, 'AG004', 'pcs', 1, 3, 'en_attente');

-- BADGE TEST 4: Personnel - Oublié
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, etape_actuelle, donnees, date_soumission, code_agent_creation) VALUES
(7, 'AG001', 'AG001', 'clos', 4,
 '{
   "date_oubli": "2024-12-18",
   "action_demandee": "Ouverture temporaire",
   "duree_temporaire": 4
 }'::jsonb,
 '2024-12-18 08:00:00',
 'AG001');

INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, etape_workflow, statut, date_validation) VALUES
(4, 'AG004', 'pcs', 1, 3, 'valide', '2024-12-18 08:30:00');

UPDATE demande SET statut = 'clos', etape_actuelle = 4, date_cloture = '2024-12-18 09:00:00' WHERE id = 4;

-- BADGE TEST 5: Prestataire - Nouveau
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, etape_actuelle, donnees, code_agent_creation) VALUES
(9, 'AG005', NULL, 'brouillon', 1,
 '{
   "societe": "TechCorp",
   "nom": "Martin",
   "prenom": "Jean",
   "mission": "Support IT - Migration serveurs",
   "contact_entreprise": "contact@techcorp.fr",
   "date_debut": "2025-01-20",
   "date_fin": "2025-06-20",
   "zones_acces": ["IT", "Salle serveurs"],
   "type_badge": "Temporaire",
   "duree_autorisation": 150
 }'::jsonb,
 'AG005');

-- ============================================
-- PARTIE 6: DONNÉES DE TEST - HEURES SUP
-- ============================================

-- HS TEST 1: Demande Préalable - Workflow complet
-- Étape 1: Création brouillon
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, etape_actuelle, donnees, code_agent_creation) VALUES
(16, 'AG001', 'AG001', 'brouillon', 1,
 '{
   "type": "prealable",
   "date_debut": "2024-12-20",
   "date_fin": "2024-12-27",
   "jours_semaine": ["lundi", "mardi", "mercredi"],
   "type_periode": "Ponctuel",
   "nb_heures_total": 12,
   "heures_detaillees": {
     "2024-12-20": 4,
     "2024-12-23": 4,
     "2024-12-24": 4
   },
   "horaires_previsionnels": "18h-22h chaque jour",
   "motif": "Dossier client urgent - Deadline 31/12",
   "dossier_lie": "CLIENT-2024-001"
 }'::jsonb,
 'AG001');

-- Étape 2: Soumission
UPDATE demande SET statut = 'soumis', etape_actuelle = 2, date_soumission = '2024-12-15 10:00:00', code_agent_modification = 'AG001'
WHERE id = 5;

-- Étape 3: Création valideurs (Manager puis RH)
INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, etape_workflow, statut) VALUES
(5, 'AG005', 'manager', 1, 3, 'en_attente'),
(5, 'AG002', 'rh', 2, 4, 'en_attente');

-- Notification Manager
INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG005', 'validation_requise', 'HS Préalable à valider',
 'Eric Morel demande votre validation pour 12h HS préalables (20-27 déc).',
 '{"demande_id": 5, "type": "heures-sup-prealable", "etape": 3, "nb_heures": 12}'::jsonb,
 '/demandes/5');

-- Simulation Étape 3: Validation Manager
UPDATE valideur_demande SET statut = 'valide', commentaire = 'Validation Manager - Dossier justifié', date_validation = '2024-12-16 09:00:00'
WHERE demande_id = 5 AND role_validation = 'manager';

UPDATE demande SET etape_actuelle = 4, code_agent_modification = 'AG005'
WHERE id = 5;

-- Notification RH (Manager a validé)
INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG002', 'validation_requise', 'HS Préalable à valider - Après Manager',
 'La demande HS préalable d''Eric Morel est prête pour validation RH.',
 '{"demande_id": 5, "type": "heures-sup-prealable", "etape": 4}'::jsonb,
 '/demandes/5');

-- Simulation Étape 4: Validation RH → Étape 5: Approuvé
UPDATE valideur_demande SET statut = 'valide', commentaire = 'Validation RH - Préalable approuvé', date_validation = '2024-12-17 14:00:00'
WHERE demande_id = 5 AND role_validation = 'rh';

UPDATE demande SET statut = 'valide', etape_actuelle = 5, code_agent_modification = 'AG002'
WHERE id = 5;

-- Notification demandeur (approuvé)
INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG001', 'validation_reponse', 'Votre demande HS préalable a été approuvée',
 'Votre demande préalable de 12h HS (20-27 déc) a été approuvée. Vous pouvez maintenant réaliser les heures.',
 '{"demande_id": 5, "type": "heures-sup-prealable", "etape": 5}'::jsonb,
 '/demandes/5');

-- HS TEST 2: Réalisation avec Préalable - Workflow complet
-- Étape 1: Création réalisation
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, etape_actuelle, donnees, code_agent_creation) VALUES
(17, 'AG001', 'AG001', 'brouillon', 1,
 '{
   "type": "realisation",
   "avec_prealable": true,
   "demande_prealable_id": 5,
   "sans_prealable": false,
   "dates_realisees": ["2024-12-20", "2024-12-23", "2024-12-24"],
   "heures_realisees": {
     "2024-12-20": {"debut": "18:00", "fin": "22:00", "nb_heures": 4},
     "2024-12-23": {"debut": "18:00", "fin": "22:15", "nb_heures": 4.25},
     "2024-12-24": {"debut": "18:00", "fin": "22:00", "nb_heures": 4}
   },
   "pointages_gta": {
     "2024-12-20": {"entree": "09:00", "sortie": "22:15"},
     "2024-12-23": {"entree": "09:00", "sortie": "22:15"},
     "2024-12-24": {"entree": "09:00", "sortie": "22:05"}
   },
   "ecarts_vs_prealable": {
     "2024-12-20": {"ecart": 0, "justification": null},
     "2024-12-23": {"ecart": 0.25, "justification": "Client a appelé après 22h"},
     "2024-12-24": {"ecart": 0, "justification": null}
   },
   "total_heures": 12.25,
   "justification_ecarts": "Écart minime le 23/12 dû à appel client"
 }'::jsonb,
 'AG001');

-- Lien avec préalable
INSERT INTO lien_demande (demande_source_id, demande_cible_id, type_lien, commentaire) VALUES
(5, 6, 'prealable_realisation', 'Réalisation liée au préalable 5');

-- Étape 2: Soumission
UPDATE demande SET statut = 'soumis', etape_actuelle = 2, date_soumission = '2024-12-28 09:00:00', code_agent_modification = 'AG001'
WHERE id = 6;

-- Étape 3, 4, 5: Création valideurs (Manager, RH, Pointage RH)
INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, etape_workflow, statut) VALUES
(6, 'AG005', 'manager', 1, 3, 'en_attente'),
(6, 'AG002', 'rh', 2, 4, 'en_attente'),
(6, 'AG002', 'pointage_rh', 3, 5, 'en_attente');

-- Notification Manager
INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG005', 'validation_requise', 'HS Réalisation à valider',
 'Eric Morel a réalisé 12.25h HS (lien préalable #5). Validation Manager requise.',
 '{"demande_id": 6, "type": "heures-sup-realisation", "etape": 3, "prealable_id": 5}'::jsonb,
 '/demandes/6');

-- Simulation Étape 3: Validation Manager
UPDATE valideur_demande SET statut = 'valide', commentaire = 'Validation Manager - Pointages cohérents', date_validation = '2024-12-29 10:00:00'
WHERE demande_id = 6 AND role_validation = 'manager';

UPDATE demande SET etape_actuelle = 4, code_agent_modification = 'AG005'
WHERE id = 6;

-- Notification RH (Manager a validé)
INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG002', 'validation_requise', 'HS Réalisation à valider - Après Manager',
 'La réalisation HS d''Eric Morel (12.25h) est prête pour validation RH.',
 '{"demande_id": 6, "type": "heures-sup-realisation", "etape": 4}'::jsonb,
 '/demandes/6');

-- Simulation Étape 4: Validation RH
UPDATE valideur_demande SET statut = 'valide', commentaire = 'Validation RH - OK', date_validation = '2024-12-30 11:00:00'
WHERE demande_id = 6 AND role_validation = 'rh';

UPDATE demande SET etape_actuelle = 5, code_agent_modification = 'AG002'
WHERE id = 6;

-- Notification Pointage RH
INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG002', 'validation_requise', 'Pointage RH requis - HS Réalisation',
 'Pointage et réconciliation GTA requis pour la réalisation HS d''Eric Morel.',
 '{"demande_id": 6, "type": "heures-sup-realisation", "etape": 5}'::jsonb,
 '/demandes/6');

-- Simulation Étape 5: Pointage RH → Étape 6: Clôture
UPDATE valideur_demande SET statut = 'valide', commentaire = 'Pointage RH effectué - Données GTA validées - Paiement programmé', date_validation = '2024-12-31 09:00:00'
WHERE demande_id = 6 AND role_validation = 'pointage_rh';

UPDATE demande SET statut = 'clos', etape_actuelle = 6, date_cloture = '2024-12-31 09:30:00', code_agent_modification = 'AG002'
WHERE id = 6;

-- Notification demandeur (clôturé)
INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG001', 'validation_reponse', 'Votre réalisation HS a été validée et clôturée',
 'Votre réalisation de 12.25h HS a été validée. Le paiement sera effectué sur la prochaine paie.',
 '{"demande_id": 6, "type": "heures-sup-realisation", "etape": 6}'::jsonb,
 '/demandes/6');

-- HS TEST 3: Réalisation SANS Préalable (cas exceptionnel)
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, etape_actuelle, donnees, date_soumission, code_agent_creation) VALUES
(17, 'AG002', 'AG002', 'en_validation', 3,
 '{
   "type": "realisation_sans_prealable",
   "avec_prealable": false,
   "sans_prealable": true,
   "motif_urgence": "Incident critique système à résoudre en urgence",
   "dates_realisees": ["2024-12-18"],
   "heures_realisees": {
     "2024-12-18": {"debut": "18:00", "fin": "20:30", "nb_heures": 2.5}
   },
   "pointages_gta": {
     "2024-12-18": {"entree": "09:00", "sortie": "20:35"}
   },
   "total_heures": 2.5
 }'::jsonb,
 '2024-12-19 08:00:00',
 'AG002');

INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, etape_workflow, statut) VALUES
(7, 'AG006', 'manager', 1, 3, 'en_attente'),
(7, 'AG002', 'rh', 2, 4, 'en_attente'),
(7, 'AG002', 'pointage_rh', 3, 5, 'en_attente');

-- HS TEST 4: Préalable Refusé par Manager
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, etape_actuelle, donnees, date_soumission, date_cloture, code_agent_creation) VALUES
(16, 'AG007', 'AG007', 'refuse', 3,
 '{
   "type": "prealable",
   "date_debut": "2025-01-05",
   "date_fin": "2025-01-10",
   "nb_heures_total": 25,
   "motif": "Charge de travail élevée"
 }'::jsonb,
 '2024-12-20 10:00:00',
 '2024-12-21 14:00:00',
 'AG007');

INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, etape_workflow, statut, commentaire, date_validation) VALUES
(8, 'AG005', 'manager', 1, 3, 'refuse', 'Trop d''heures demandées sans justification suffisante', '2024-12-21 14:00:00');

-- ============================================
-- PARTIE 7: DOCUMENTS DE TEST
-- ============================================

INSERT INTO document (demande_id, code_agent, nom_fichier, chemin_fichier, type_mime, taille_octets, type_document, code_agent_upload) VALUES
(5, 'AG001', 'justificatif_hs_prealable.pdf', '/uploads/demandes/5/justificatif.pdf', 'application/pdf', 245678, 'piece_jointe', 'AG001'),
(6, 'AG001', 'pointages_gta_decembre.xlsx', '/uploads/demandes/6/pointages.xlsx', 'application/vnd.ms-excel', 189432, 'piece_jointe', 'AG001'),
(6, 'AG001', 'screenshot_gta_2024-12-20.png', '/uploads/demandes/6/screenshot.png', 'image/png', 156789, 'piece_jointe', 'AG001'),
(1, 'AG005', 'cv_amelie_dupuis.pdf', '/uploads/demandes/1/cv.pdf', 'application/pdf', 345678, 'piece_jointe', 'AG005'),
(7, 'AG002', 'rapport_incident.pdf', '/uploads/demandes/7/rapport.pdf', 'application/pdf', 278901, 'piece_jointe', 'AG002');

-- ============================================
-- PARTIE 8: NOTIFICATIONS SUPPLEMENTAIRES
-- ============================================

INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG004', 'validation_requise', 'Badge à valider - Après Manager',
 'La demande de badge pour Amélie Dupuis est prête pour validation PCS.',
 '{"demande_id": 1, "type": "badge-nouveau-collab", "etape": 4}'::jsonb,
 '/demandes/1'),
('AG007', 'validation_reponse', 'Votre demande de badge départ a été validée',
 'Votre demande de prolongation de badge jusqu''au 01/03 a été approuvée.',
 '{"demande_id": 2, "type": "badge-depart-collab"}'::jsonb,
 '/demandes/2'),
('AG007', 'validation_reponse', 'Votre badge perdu sera remplacé',
 'Votre demande de remplacement de badge perdu a été validée par PCS.',
 '{"demande_id": 3, "type": "badge-collab-perdu"}'::jsonb,
 '/demandes/3'),
('AG007', 'validation_reponse', 'Votre demande HS préalable a été refusée',
 'Votre demande préalable de 25h HS a été refusée par votre manager. Motif: justification insuffisante.',
 '{"demande_id": 8, "type": "heures-sup-prealable"}'::jsonb,
 '/demandes/8');

-- ============================================
-- PARTIE 9: REQUÊTES UTILES POUR TESTER
-- ============================================

-- Nombre de demandes par statut
-- SELECT statut, COUNT(*) as nb FROM demande WHERE est_supprime = FALSE GROUP BY statut;

-- Demandes à valider par agent avec workflow
-- SELECT v.code_agent_valideur, d.id, f.titre, d.etape_actuelle, f.workflow_etapes->'etapes'->(d.etape_actuelle-1) as etape_detail
-- FROM valideur_demande v
-- JOIN demande d ON v.demande_id = d.id
-- JOIN formulaire f ON d.formulaire_id = f.id
-- WHERE v.statut = 'en_attente' AND d.est_supprime = FALSE
-- ORDER BY d.date_soumission;

-- Workflow d'une demande spécifique
-- SELECT h.*, a.nom, a.prenom
-- FROM historique_demande h
-- LEFT JOIN agent a ON h.code_agent = a.code_agent
-- WHERE h.demande_id = 6
-- ORDER BY h.date_action;

-- Demandes liées (HS préalable → réalisation)
-- SELECT ld.*, ds.id as demande_source_id, dc.id as demande_cible_id,
--        fs.titre as titre_source, fc.titre as titre_cible
-- FROM lien_demande ld
-- JOIN demande ds ON ld.demande_source_id = ds.id
-- JOIN demande dc ON ld.demande_cible_id = dc.id
-- JOIN formulaire fs ON ds.formulaire_id = fs.id
-- JOIN formulaire fc ON dc.formulaire_id = fc.id;

-- Notifications non lues par agent
-- SELECT code_agent_destinataire, COUNT(*) as nb_non_lu
-- FROM notification
-- WHERE statut_lecture = 'non_lu'
-- GROUP BY code_agent_destinataire;

COMMIT;

