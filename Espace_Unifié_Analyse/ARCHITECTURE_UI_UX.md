## Espace Unifié – Analyse, Conception et Architecture

### 1) Contexte et objectifs
- **But**: Unifier l’accès aux services et formulaires RH (interne + liens externes), réduire les frictions et centraliser notifications, demandes et suivi.
- **Contraintes clés**: multi-profils (Agent, Manager, Gestionnaire RH, PCS/Sécurité), accès multi-supports (web/PWA), SSO/MFA, interconnexion avec outils existants, performance et accessibilité.

### 2) Synthèse UX utile à la conception
- **Problèmes récurrents**: navigation complexe, outils multiples, ressaisies, manque de traçabilité et d’unification des formulaires, absence de dossier agent consolidé, communication par email non maîtrisée.
- **Attentes**: point d’entrée unique, recherche globale, favoris, tableau de bord, formulaires homogènes, centre de notifications, mobilité sans VPN, suivi par agent et par portefeuille.
- **Opportunités**: PWA + notifications, moteur de navigation guidée, hub RH personnalisé par rôle, standardisation des formulaires, API/connecteurs, chatbot d’orientation, rationalisation des outils.

### 3) Vision fonctionnelle (Domaines et modules)
- **Navigation & Accueil** (`ui/home`, `ui/navigation`): tableau de bord, recherche globale, favoris, derniers utilisés, accès rapide par rôle.
- **Formulaires unifiés** (`ui/formulaires`): catalogue de formulaires (HeureSup, Parking, Mobilités durables, Travail à distance, etc.) avec un modèle UX homogène.
- **Composants UI** (`ui/composants`): librairie de composants transverses (containers, tables, panneaux repliables/collapsibles).
- **Centre de notifications** (`ui/notifications`): flux interne des alertes (remplace l’email pour le suivi opérationnel).
- **Applications externes** (`ui/applications-externe`): liens intégrés avec badges d’état et métadonnées (description, pour qui, prérequis).
- **Global/Design tokens** (`ui/global`): statuts, états, styles partagés (couleurs, badges, pictos d’état).
- **Dossier Agent**: vue consolidée (historique demandes, documents, statuts, actions à faire) – surfacé depuis recherche et depuis les demandes.

### 4) Architecture applicative (Front)
- **Plateforme de développement**: Convertigo Low Code Studio
- **Type**: Application web responsive avec possibilité PWA (offline lecture partielle) via Convertigo.
- **Routage**: router hiérarchique par domaine (accueil, recherche, formulaires/:slug, demandes/:id, agent/:id, notifications, apps-externe) géré par Convertigo.
- **Gestion d'état**: stockage local Convertigo (variables globales, sessions, cache) pour statuts, notifications, favoris, profil, droits, listes récurrentes.
- **Design System**: composants `ui/composants` comme fondation + composants Convertigo réutilisables (screens, sequences, transactions).
- **Accessibilité**: WCAG AA (focus, contrastes, clavier, ARIA), responsive first, performance (lazy loading via sequences Convertigo).
- **Internationalisation**: textes et labels externalisés dans Convertigo; formatage (dates, nombres) unifié.

### 5) Architecture d'intégration (Back/API et Authentification)
- **Authentification/Autorisation**: 
  - **Intégration ANAIS (Authentification du recouvrement)**: L'authentification et la gestion des rôles proviennent du système ANAIS existant.
  - **RBAC via ANAIS**: Les rôles utilisateurs (agent, manager, gestionnaire RH, PCS/Sécurité, admin) sont hérités d'ANAIS avec leurs permissions associées.
  - **Token/Session ANAIS**: Convertigo récupère et maintient la session utilisateur via connecteur ANAIS pour valider les accès aux fonctionnalités.
- **APIs et Connecteurs Convertigo**: 
  - **Catalogue formulaires**: Sequences Convertigo interrogeant la base de données (métadonnées, règles, prérequis)
  - **Demandes**: Transactions Convertigo pour CRUD + workflow statuts, pièces jointes, historique
  - **Notifications**: Sequences pour pull notifications, lecture/lu, préférences utilisateur
  - **Dossier Agent**: Sequences agrégant historique et KPIs selon rôle utilisateur
  - **Applications externes**: Sequences pour liste, filtres, étiquettes, visibilité selon rôle
  - **Recherche globale**: Sequences de recherche unifiée (agents, demandes, formulaires, documents)
- **Intégrations**: 
  - Connecteurs Convertigo vers outils existants (GTA, Canopée, GED, messagerie) via connecteurs backend ou REST/SOAP.
  - Synchronisation asynchrone via files d'événements ou polling selon besoins.

### 6) Modèle de données conceptuel (MCD – vue synthétique)
- **Agent**(id, identité, organisation, rôle[s])
- **Formulaire**(id, slug, titre, catégories, règles, version)
- **Demande**(id, type_formulaire, agent_demandeur, agent_concerne, données, statut, valideurs[], historique[])
- **Notification**(id, type, cible: agent|rôle, payload, statut_lecture, horodatage)
- **ApplicationExterne**(id, nom, url, tags, pour_qui, prérequis)
- **Favori**(id, agent, cible: {formulaire|app|page}, ordre)
- **Document**(id, type, lien, rattachements: {demande|agent})

Relations clés: Agent 1..* Demande; Demande 1..* Historique; Agent 0..* Favori; Demande 0..* Document; Notification → Agent|Rôle (diffusion ciblée).

### 7) Flux principaux (haute-niveau)
1. **Recherche & Accès rapide**: Home → recherche globale (autosuggest) → ouverture d’un formulaire/app → suggestion d’ajout aux favoris.
2. **Création d’une demande**: Sélection formulaire → pré-remplissage (données Agent) → logique conditionnelle → validation → envoi vers valideur(s) → notifications.
3. **Suivi des demandes**: Tableau de bord → filtres (statut, type, équipe) → actions en attente → historique → relances.
4. **Validation**: Notification → vue demande → contrôle pièces/règles → valider/refuser → notification suivante.
5. **Dossier Agent**: Recherche agent → vue consolidée (demandes, docs, statuts) → export PDF/Excel.
6. **Applications externes**: Catalogue → filtres/tagging → ouverture → suivi d’usage (derniers utilisés).

### 8) Conception UI (patterns et écrans)
- **Accueil/Dashboard** (`ui/home`):
  - Widgets: tâches à faire, dernières activités, favoris, raccourcis rôle-based, annonces RH.
  - Barre de recherche globale + onboarding rapide (raccourcis/astuces).
- **Navigation** (`ui/navigation`):
  - Side-nav par domaines, topbar avec recherche, avatar/profil, centre de notifications.
  - Favoris persistants (drag & drop), tags, segments “les plus utilisés”.
- **Formulaires** (`ui/formulaires`):
  - Modèle commun: étapes, validation inline, aide contextuelle, pièces jointes, sauvegarde brouillon, récapitulatif avant soumission.
  - États: brouillon, soumis, en validation (multi-étapes), compléments demandés, validé, refusé, clôturé.
- **Demandes (listes/détails)**:
  - Liste avec filtres rapides (à moi, à valider, mon équipe), vues sauvegardées.
  - Détails: timeline d’historique, panneau latéral “infos liées” (agent, pièces, règles), actions primaires visibles.
- **Centre de notifications** (`ui/notifications`):
  - Regroupement par conversation/processus, marquer comme lu, préférences, liens deep-linking vers actions.
- **Applications externes** (`ui/applications-externe`):
  - Cartes avec labels “pour qui”, “pré-requis”, statut disponibilité; recherche et filtres.
- **Global/Composants** (`ui/composants`, `ui/global`):
  - Tables virtualisées, containers de mise en page (grid, responsive), collapsibles pour infos secondaires, badges d’état cohérents.

### 9) Sécurité, conformité, qualité
- **Sécurité**: 
  - Authentification via ANAIS (recouvrement), RBAC hérité d'ANAIS, journalisation (audit trail dans Convertigo + logs ANAIS).
  - Contrôle d'accès granulaire (champ/page) selon rôle ANAIS et délégations.
  - Validation des permissions via connecteur ANAIS à chaque action sensible.
- **Protection des données**: minimisation, rétention maîtrisée, chiffrement en transit (HTTPS), politiques de partage.
- **Qualité & Observabilité**: métriques UX (temps à l'info, clics), logs Convertigo, traçage des workflows, monitoring d'erreurs.
- **Accessibilité**: contrastes, navigation clavier, lecteurs d'écran, alternatives médias.

### 10) Performance et industrialisation
- **Front (Convertigo)**: 
  - Optimisation des sequences (lazy loading), cache via variables Convertigo, gestion des assets (images, fichiers).
  - Cache intelligent des données fréquemment utilisées.
  - Optimisation des screens et composants pour performance.
- **CI/CD**: 
  - Déploiement Convertigo (export/import projets), tests de sequences critiques, validation des connecteurs.
  - Prévisualisation d'environnement via Convertigo Cloud ou on-premise.
  - Scans sécurité et validation des accès ANAIS.
- **Feature flags**: déploiement progressif via configuration Convertigo (nouveau formulaire, nouveau widget dashboard).

### 11) Roadmap (phases conseillées)
1. **MVP**: 
   - Intégration authentification ANAIS dans Convertigo.
   - Accueil (recherche globale, favoris), 1-2 formulaires unifiés (ex. HeureSup), listes/détails demandes, notifications basiques, catalogue apps externes.
   - Gestion des rôles via ANAIS, contrôle d'accès basique.
2. **MVP+**: Dossier Agent, vues manager (équipe, priorisation), standardisation formulaires supplémentaires, préférences notifications.
3. **PWA & Offline**: installation PWA via Convertigo, push notifications, lecture offline, performance ++.
4. **Chatbot & Rationalisation**: assistant d'orientation, intégrations avancées, retrait d'outils doublons.

### 12) Traçabilité UX → UI
- Les dossiers `ui/` existants mappent naturellement les modules décrits ci-dessus et servent de base à un Design System transversal.
- Les documents `ux/` (personas, insights, parcours, synthèse) ont été intégrés dans la vision produit (navigation guidée, centralisation, formulaires homogènes, notifications, dossier agent).

### 13) Schéma de Base de Données

#### 13.1) Vue d'ensemble
La base de données utilise PostgreSQL et stocke les formulaires, demandes, notifications, favoris et applications externes. L'authentification et les rôles sont gérés par ANAIS, donc nous ne stockons que les références utilisateur (code_agent) dans notre BDD.

#### 13.2) Structure des tables

```sql
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
    regles JSONB, -- Stocke les règles métier (prérequis, validations, etc.)
    schema_formulaire JSONB, -- Structure du formulaire (champs, types, validation)
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
    -- statuts possibles: brouillon, soumis, en_validation, complement_demande, valide, refuse, clos
    donnees JSONB NOT NULL, -- Données saisies du formulaire
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

-- ============================================
-- TABLE: valideur_demande
-- ============================================
CREATE TABLE valideur_demande (
    id SERIAL PRIMARY KEY,
    demande_id INTEGER NOT NULL REFERENCES demande(id) ON DELETE CASCADE,
    code_agent_valideur VARCHAR(50) NOT NULL REFERENCES agent(code_agent),
    role_validation VARCHAR(50) NOT NULL, -- manager, rh, pcs, etc.
    ordre_validation INTEGER NOT NULL DEFAULT 1,
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

-- ============================================
-- TABLE: historique_demande
-- ============================================
CREATE TABLE historique_demande (
    id SERIAL PRIMARY KEY,
    demande_id INTEGER NOT NULL REFERENCES demande(id) ON DELETE CASCADE,
    code_agent VARCHAR(50) REFERENCES agent(code_agent),
    action VARCHAR(100) NOT NULL, -- creation, soumission, validation, refus, complement, etc.
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
    type_document VARCHAR(50), -- piece_jointe, document_agent, etc.
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
    type VARCHAR(50) NOT NULL, -- demande_soumission, validation_requise, validation_reponse, etc.
    titre VARCHAR(255) NOT NULL,
    message TEXT,
    payload JSONB, -- Données supplémentaires (id_demande, liens, etc.)
    statut_lecture VARCHAR(50) DEFAULT 'non_lu', -- non_lu, lu, archive
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
    type_cible VARCHAR(50) NOT NULL, -- formulaire, application_externe, page
    id_cible INTEGER, -- id du formulaire ou application_externe
    slug_cible VARCHAR(100), -- slug pour les pages
    libelle VARCHAR(255),
    icone VARCHAR(100),
    ordre INTEGER DEFAULT 0,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(code_agent, type_cible, COALESCE(id_cible::text, slug_cible))
);

CREATE INDEX idx_favori_agent ON favori(code_agent);

-- ============================================
-- TABLE: application_externe
-- ============================================
CREATE TABLE application_externe (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    url VARCHAR(500) NOT NULL,
    description TEXT,
    icone VARCHAR(100),
    tags TEXT[], -- Array de tags
    pour_qui TEXT[], -- Array de rôles ou profils
    prerequis TEXT,
    ordre_affichage INTEGER DEFAULT 0,
    actif BOOLEAN DEFAULT TRUE,
    ouverture_nouvel_onglet BOOLEAN DEFAULT TRUE,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_app_ext_tags ON application_externe USING GIN(tags);
CREATE INDEX idx_app_ext_pour_qui ON application_externe USING GIN(pour_qui);

-- ============================================
-- TABLE: dossier_agent_vue
-- ============================================
-- Vue matérialisée ou table pour le dossier agent consolidé
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

CREATE TRIGGER update_app_ext_modification BEFORE UPDATE ON application_externe
    FOR EACH ROW EXECUTE FUNCTION update_modified_column();

-- ============================================
-- TRIGGERS: Gestion automatique de l'historique
-- ============================================
CREATE OR REPLACE FUNCTION create_historique_demande()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO historique_demande (
            demande_id, code_agent, action, nouveau_statut, commentaire
        ) VALUES (
            NEW.id, NEW.code_agent_creation, 'creation', NEW.statut, 'Demande créée'
        );
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.statut IS DISTINCT FROM NEW.statut THEN
            INSERT INTO historique_demande (
                demande_id, code_agent, action, ancien_statut, nouveau_statut, 
                commentaire, donnees_avant, donnees_apres
            ) VALUES (
                NEW.id, NEW.code_agent_modification, 
                'changement_statut', OLD.statut, NEW.statut,
                'Changement de statut de ' || OLD.statut || ' vers ' || NEW.statut,
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
```

### 14) Données de Test (Seed Data)

```sql
-- ============================================
-- INSERT: Agents (références vers ANAIS)
-- ============================================
INSERT INTO agent (code_agent, nom, prenom, email, organisation, code_service) VALUES
('AG001', 'Morel', 'Eric', 'eric.morel@urssaf.fr', 'URSSAF Caisse Nationale', 'RH001'),
('AG002', 'Martin', 'Sophie', 'sophie.martin@urssaf.fr', 'URSSAF Direction Régionale', 'RH002'),
('AG003', 'Dupont', 'Agathe', 'agathe.dupont@urssaf.fr', 'URSSAF Caisse Nationale', 'RH003'),
('AG004', 'Benali', 'Karim', 'karim.benali@urssaf.fr', 'URSSAF Gaumont', 'PCS001'),
('AG005', 'Leroy', 'Kevin', 'kevin.leroy@urssaf.fr', 'URSSAF Valbonne', 'MGT001'),
('AG006', 'Traore', 'Moussa', 'moussa.traore@urssaf.fr', 'URSSAF Lille', 'MGT002'),
('AG007', 'Dubois', 'Marie', 'marie.dubois@urssaf.fr', 'URSSAF Caisse Nationale', 'RH004'),
('AG008', 'Petit', 'Jean', 'jean.petit@urssaf.fr', 'URSSAF Direction Régionale', 'RH005');

-- ============================================
-- INSERT: Formulaires
-- ============================================
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles) VALUES
('heures-sup', 'Heures Supplémentaires', 
 'Demande de paiement d''heures supplémentaires', 'Rémunération', 1, 'clock',
 '{"sections": [{"libelle": "Informations générales", "champs": ["date_demande", "periode", "nb_heures"]}, {"libelle": "Justification", "champs": ["motif", "piece_jointe"]}]}'::jsonb,
 '{"prealable": true, "validation_manager": true, "validation_rh": true}'::jsonb),

('parking', 'Demande de Place de Parking',
 'Demande d''attribution ou de renouvellement de place de parking', 'Mobilité', 2, 'parking',
 '{"sections": [{"libelle": "Type de demande", "champs": ["type", "motif"]}, {"libelle": "Informations véhicule", "champs": ["immatriculation", "marque", "modele"]}]}'::jsonb,
 '{"validation_pcs": true}'::jsonb),

('travail-distance', 'Travail à Distance',
 'Demande d''autorisation ou de renouvellement de télétravail', 'Organisation', 3, 'home',
 '{"sections": [{"libelle": "Période", "champs": ["date_debut", "date_fin", "jours_semaine"]}, {"libelle": "Motivation", "champs": ["motif", "conditions"]}]}'::jsonb,
 '{"validation_manager": true, "validation_rh": true}'::jsonb),

('mobilites-durables', 'Mobilités Durables',
 'Demande d''abonnement transports en commun ou vélo', 'Mobilité', 4, 'bike',
 '{"sections": [{"libelle": "Type de transport", "champs": ["type_transport", "ligne", "zone"]}, {"libelle": "Justification", "champs": ["motif"]}]}'::jsonb,
 '{"validation_manager": true}'::jsonb),

('temps-compensatoire', 'Temps Compensatoire',
 'Demande de récupération ou de compensation d''heures', 'Rémunération', 5, 'calendar',
 '{"sections": [{"libelle": "Période", "champs": ["date", "nb_heures", "type_compensation"]}]}'::jsonb,
 '{"validation_manager": true, "validation_rh": true}'::jsonb),

('mobilier', 'Demande de Mobilier',
 'Demande d''équipement ou de mobilier de bureau', 'Matériel', 6, 'chair',
 '{"sections": [{"libelle": "Équipement", "champs": ["type_mobilier", "quantite", "motif"]}]}'::jsonb,
 '{"validation_manager": true}'::jsonb),

('intervention-technique', 'Demande d''Intervention Technique',
 'Demande d''intervention IT ou support technique', 'IT', 7, 'wrench',
 '{"sections": [{"libelle": "Nature", "champs": ["type_intervention", "description", "urgence"]}]}'::jsonb,
 '{}'::jsonb);

-- ============================================
-- INSERT: Applications externes
-- ============================================
INSERT INTO application_externe (nom, url, description, icone, tags, pour_qui, ordre_affichage) VALUES
('O''Buro', 'https://oburo.urssaf.fr', 'Gestion administrative et paie', 'briefcase', 
 ARRAY['paie', 'administration'], ARRAY['agent', 'manager', 'rh'], 1),

('ODAM', 'https://odam.urssaf.fr', 'Outils de développement et maintenance', 'code',
 ARRAY['it', 'dev'], ARRAY['it', 'technique'], 2),

('Reporting 2AP', 'https://reporting.urssaf.fr', 'Tableaux de bord et reporting', 'chart',
 ARRAY['reporting', 'stats'], ARRAY['manager', 'rh', 'direction'], 3),

('SecurSafe', 'https://secur.urssaf.fr', 'Gestion de la sécurité au travail', 'shield',
 ARRAY['sécurité', 'pcs'], ARRAY['pcs', 'rh', 'manager'], 4);

-- ============================================
-- INSERT: Demandes de test
-- ============================================
-- Demande 1: Heures sup (en validation manager)
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees, date_creation, date_soumission, code_agent_creation) VALUES
(1, 'AG001', 'AG001', 'en_validation',
 '{"date_demande": "2024-12-15", "periode": "Semaine du 02/12/2024", "nb_heures": 5, "motif": "Dossier urgent client"}'::jsonb,
 '2024-12-10 10:00:00', '2024-12-10 10:30:00', 'AG001');

-- Valideur pour la demande 1
INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, statut) VALUES
(1, 'AG005', 'manager', 1, 'en_attente');

-- Demande 2: Parking (validée)
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees, date_creation, date_soumission, code_agent_creation) VALUES
(2, 'AG007', 'AG007', 'valide',
 '{"type": "renouvellement", "immatriculation": "AB-123-CD", "marque": "Renault", "modele": "Clio"}'::jsonb,
 '2024-12-01 14:00:00', '2024-12-01 14:15:00', 'AG007');

INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, statut, commentaire, date_validation) VALUES
(2, 'AG004', 'pcs', 1, 'valide', 'Renouvellement approuvé', '2024-12-02 09:00:00');

-- Demande 3: Travail à distance (brouillon)
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees, date_creation, code_agent_creation) VALUES
(3, 'AG006', 'AG006', 'brouillon',
 '{"date_debut": "2025-01-15", "date_fin": "2025-12-31", "jours_semaine": ["lundi", "mercredi", "vendredi"], "motif": "Optimisation des déplacements"}'::jsonb,
 '2024-12-15 16:00:00', 'AG006');

-- Demande 4: Mobilités durables (complement demandé)
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees, date_creation, date_soumission, code_agent_creation) VALUES
(4, 'AG001', 'AG001', 'complement_demande',
 '{"type_transport": "métro", "ligne": "Ligne 1", "zone": "Zone 1-2", "motif": "Pas de véhicule personnel"}'::jsonb,
 '2024-12-05 11:00:00', '2024-12-05 11:20:00', 'AG001');

INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, statut, commentaire) VALUES
(4, 'AG005', 'manager', 1, 'refuse', 'Merci de préciser la distance domicile-travail');

-- Demande 5: Temps compensatoire (refusée)
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees, date_creation, date_soumission, date_cloture, code_agent_creation) VALUES
(5, 'AG002', 'AG002', 'refuse',
 '{"date": "2024-11-20", "nb_heures": 8, "type_compensation": "récupération"}'::jsonb,
 '2024-11-18 09:00:00', '2024-11-18 09:30:00', '2024-11-20 15:00:00', 'AG002');

INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, statut, commentaire, date_validation) VALUES
(5, 'AG003', 'manager', 1, 'valide', 'Validé par le manager', '2024-11-19 10:00:00'),
(5, 'AG002', 'rh', 2, 'refuse', 'Heures déjà compensées par congés', '2024-11-20 15:00:00');

-- ============================================
-- INSERT: Notifications de test
-- ============================================
INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, statut_lecture, lien_action) VALUES
('AG005', 'validation_requise', 'Validation demandée - Heures supplémentaires',
 'Eric Morel demande votre validation pour une demande d''heures supplémentaires.',
 '{"demande_id": 1, "type": "heures-sup"}'::jsonb, 'non_lu', '/demandes/1'),

('AG004', 'validation_requise', 'Validation demandée - Place de parking',
 'Marie Dubois demande le renouvellement de sa place de parking.',
 '{"demande_id": 2, "type": "parking"}'::jsonb, 'lu', '/demandes/2'),

('AG007', 'validation_reponse', 'Votre demande de parking a été validée',
 'Votre demande de renouvellement de place de parking a été approuvée par PCS.',
 '{"demande_id": 2, "type": "parking"}'::jsonb, 'non_lu', '/demandes/2'),

('AG001', 'complement_requis', 'Compléments demandés pour votre demande',
 'Des compléments sont demandés pour votre demande de mobilités durables.',
 '{"demande_id": 4, "type": "mobilites-durables"}'::jsonb, 'non_lu', '/demandes/4'),

('AG002', 'validation_reponse', 'Votre demande a été refusée',
 'Votre demande de temps compensatoire a été refusée par RH.',
 '{"demande_id": 5, "type": "temps-compensatoire"}'::jsonb, 'non_lu', '/demandes/5');

-- ============================================
-- INSERT: Favoris de test
-- ============================================
INSERT INTO favori (code_agent, type_cible, id_cible, libelle, icone, ordre) VALUES
('AG001', 'formulaire', 1, 'Heures Supplémentaires', 'clock', 1),
('AG001', 'formulaire', 3, 'Travail à Distance', 'home', 2),
('AG005', 'formulaire', 1, 'Heures Supplémentaires', 'clock', 1),
('AG005', 'application_externe', 3, 'Reporting 2AP', 'chart', 2),
('AG002', 'formulaire', 5, 'Temps Compensatoire', 'calendar', 1);

-- ============================================
-- INSERT: Documents de test
-- ============================================
INSERT INTO document (demande_id, code_agent, nom_fichier, chemin_fichier, type_mime, taille_octets, type_document, code_agent_upload) VALUES
(1, 'AG001', 'justificatif_hs.pdf', '/uploads/demandes/1/justificatif_hs.pdf', 'application/pdf', 245678, 'piece_jointe', 'AG001'),
(2, 'AG007', 'carte_grise.pdf', '/uploads/demandes/2/carte_grise.pdf', 'application/pdf', 189432, 'piece_jointe', 'AG007'),
(4, 'AG001', 'attestation_transport.pdf', '/uploads/demandes/4/attestation_transport.pdf', 'application/pdf', 156789, 'piece_jointe', 'AG001');

-- ============================================
-- Vérification des données
-- ============================================
-- Requêtes utiles pour tester

-- Nombre de demandes par statut
SELECT statut, COUNT(*) as nb FROM demande WHERE est_supprime = FALSE GROUP BY statut;

-- Demandes à valider par agent
SELECT v.code_agent_valideur, d.id, f.titre, d.date_soumission
FROM valideur_demande v
JOIN demande d ON v.demande_id = d.id
JOIN formulaire f ON d.formulaire_id = f.id
WHERE v.statut = 'en_attente' AND d.est_supprime = FALSE
ORDER BY d.date_soumission;

-- Notifications non lues par agent
SELECT code_agent_destinataire, COUNT(*) as nb_non_lu
FROM notification
WHERE statut_lecture = 'non_lu'
GROUP BY code_agent_destinataire;

-- Historique d'une demande
SELECT h.*, a.nom, a.prenom
FROM historique_demande h
LEFT JOIN agent a ON h.code_agent = a.code_agent
WHERE h.demande_id = 1
ORDER BY h.date_action;
```

---
Document vivant: à compléter avec les schémas d'architecture détaillés (C4), le design system (tokens, composants), et les contrats d'API une fois la stack technique figée.


