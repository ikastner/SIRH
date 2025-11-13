# Analyse de Compatibilité : Badges et Heures Sup avec la Structure Unifiée

## Objectif
Démontrer que les formulaires **Badges** et **Heures Supplémentaires** peuvent être intégrés dans la structure de base de données et le modèle d'architecture proposé pour l'Espace Unifié.

---

## 1) Analyse du Formulaire BADGES

### 1.1) Types de Demandes Identifiés

D'après l'arborescence des maquettes, on identifie **4 catégories principales** :

#### **1.1.1) Badges Collaborateurs (collab/)**
- `dmd-badge-nouveau-collab.png` → Nouveau collaborateur
- `dmd-badge-depart-collab.png` → Départ collaborateur
- `dmd-badge-depart-prolong-*.png` → Prolongation à la sortie
- `dmd-badge-collab-perdu.png` → Badge perdu/volé
- `dmd-badge-collab-HS.png` → Badge hors service
- `dmd-badge-collab-specifique.png` → Accès spécifique

**Champs probables identifiés** :
- Type de demande (nouveau, départ, perdu, HS, spécifique, prolongation)
- Informations collaborateur (nom, prénom, service, date début/fin)
- Motif/projet
- Accès spécifiques demandés (zones, horaires)
- Renseignements badge (numéro si remplacement, motif perte/vol)

**Workflow** :
1. Création demande → 2. Validation Manager (si nouveau collab) → 3. Validation PCS → 4. Clôture (délivrance badge)

#### **1.1.2) Badges Personnel (perso/)**
- `dmd-badge-perso.png` → Demande standard
- `dmd-badge-perso-oubli.png` → Badge oublié
- `dmd-badge-perso-desac.png` → Désactivation badge

**Champs probables** :
- Motif (oubli, perte, remplacement, désactivation)
- Date oubli/perte
- Action demandée (désactivation, remplacement, réactivation)

**Workflow** :
1. Création demande → 2. Validation PCS → 3. Clôture (action badge)

#### **1.1.3) Badges Prestataires (presta/)**
- `dmd-badge-presta-new.png` → Nouveau prestataire
- `dmd-badge-presta-renew.png` → Renouvellement
- `dmd-badge-presta-depart.png` → Départ prestataire
- `dmd-badge-presta-perdu.png` → Badge perdu
- `dmd-badge-presta-HS.png` → Badge hors service
- `dmd-badge-presta-acces-spec.png` → Accès spécifique

**Champs probables** :
- Informations prestataire (société, nom, prénom, mission)
- Dates (début, fin prévue)
- Accès demandés
- Type de badge (permanent, temporaire)

**Workflow** :
1. Création demande → 2. Validation Manager → 3. Validation PCS → 4. Clôture

#### **1.1.4) Badges Autre (autre/)**
- `dmd-badge-autre-specifique-*.png` → Demandes spécifiques

**Champs probables** :
- Type de demande spécifique
- Justification
- Validation selon contexte

### 1.2) Dashboards Badges
- Dashboard Collaborateur : vue des demandes personnelles
- Dashboard Manager : vue équipe, validations en attente
- Dashboard RH : vue globale, statistiques

---

## 2) Analyse du Formulaire HEURES SUPPLÉMENTAIRES

### 2.1) Types de Demandes Identifiés

#### **2.1.1) Demande Préalable (dmd-heure-*.png)**
- `dmd-heure-perso.png` → Demande personnelle
- `dmd-heure-manager.png` → Vue manager

**Champs probables** :
- Type (préalable)
- Période (dates, heures)
- Nombre d'heures
- Motif/justification
- Jours concernés

**Workflow** :
1. Création → 2. Validation Manager → 3. Validation RH → 4. Approbation → 5. Réalisation possible

#### **2.1.2) Réalisation/P pointage (saisie-heure-real-*.png)**
- `saisie-heure-real-collab.png` → Saisie collaborateur
- `saisie-heure-real-manager-*.png` → Validation manager (valid/refused/wait-rh)
- `saisie-heure-real-wait-mana.png` → En attente manager
- `saisie-heure-real-wait-rh.png` → En attente RH
- `saisie-heure-real-valid.png` → Validée
- `saisie-heure-real-refused.png` → Refusée

**Champs probables** :
- Lien vers demande préalable (si existe)
- Dates/heures réalisées
- Pointages détaillés
- Justifications (écarts vs préalable)
- Pièces justificatives

**Workflow** :
1. Saisie réalisation → 2. Validation Manager → 3. Validation RH → 4. Pointage RH → 5. Clôture (paiement)

#### **2.1.3) Pointage RH (pointage-heure-real-rh-*.png)**
- Saisie pointages RH
- Validation/refus final

**Champs probables** :
- Pointages officiels (GTA)
- Réconciliation avec demande
- Commentaires RH

#### **2.1.4) Statuts (heures-status-*.png)**
- Vue collaborateur
- Vue manager/RH
- Statuts (en attente, validée, refusée, clôturée)

#### **2.1.5) Visualisation Détails (visu-dmd-heure-*.png)**
- Détails avec historique des validations
- Commentaires, pièces jointes

#### **2.1.6) Dashboards HeureSup**
- Dashboard Collaborateur : demandes préalables, réalisations
- Dashboard Manager : validations en attente, vue équipe
- Dashboard RH : pointages, validation finale

---

## 3) Compatibilité avec la Structure Unifiée

### 3.1) Mapping des Tables

#### **Table `formulaire`**

**Badges** :
```sql
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, schema_formulaire, regles) VALUES
('badge-nouveau-collab', 'Badge Nouveau Collaborateur', 'Demande de badge pour nouveau collaborateur', 'Badges', 10,
 '{"sections": [
   {"libelle": "Informations collaborateur", "champs": ["nom", "prenom", "service", "date_debut", "projet"]},
   {"libelle": "Accès", "champs": ["zones_acces", "horaires", "type_badge"]}
 ]}'::jsonb,
 '{"validation_manager": true, "validation_pcs": true, "ordre_validation": ["manager", "pcs"]}'::jsonb),

('badge-depart-collab', 'Badge Départ Collaborateur', 'Gestion badge à la sortie', 'Badges', 11,
 '{"sections": [
   {"libelle": "Informations", "champs": ["collaborateur", "date_depart", "prolongation", "rendu_badge"]}
 ]}'::jsonb,
 '{"validation_manager": true, "validation_pcs": true}'::jsonb),

('badge-perso-oubli', 'Badge Personnel Oublié', 'Demande gestion badge oublié', 'Badges', 12,
 '{"sections": [
   {"libelle": "Informations", "champs": ["date_oubli", "action_demandee"]}
 ]}'::jsonb,
 '{"validation_pcs": true}'::jsonb),

('badge-presta-new', 'Badge Nouveau Prestataire', 'Demande badge prestataire', 'Badges', 13,
 '{"sections": [
   {"libelle": "Prestataire", "champs": ["societe", "nom", "prenom", "mission", "date_debut", "date_fin"]},
   {"libelle": "Accès", "champs": ["zones_acces", "type_badge"]}
 ]}'::jsonb,
 '{"validation_manager": true, "validation_pcs": true}'::jsonb);
```

**Heures Sup** :
```sql
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, schema_formulaire, regles) VALUES
('heures-sup-prealable', 'Heures Supplémentaires - Demande Préalable', 'Demande préalable HS', 'Rémunération', 1,
 '{"sections": [
   {"libelle": "Période", "champs": ["date_debut", "date_fin", "jours_semaine"]},
   {"libelle": "Détails", "champs": ["nb_heures", "heures_detaillees", "motif"]},
   {"libelle": "Justification", "champs": ["justification", "piece_jointe"]}
 ]}'::jsonb,
 '{"validation_manager": true, "validation_rh": true, "ordre_validation": ["manager", "rh"]}'::jsonb),

('heures-sup-realisation', 'Heures Supplémentaires - Réalisation', 'Saisie réalisation HS', 'Rémunération', 2,
 '{"sections": [
   {"libelle": "Lien préalable", "champs": ["demande_prealable_id", "reference_prealable"]},
   {"libelle": "Réalisation", "champs": ["dates_realisees", "heures_realisees", "pointages", "ecarts"]},
   {"libelle": "Justification", "champs": ["justification_ecarts", "pieces_justificatives"]}
 ]}'::jsonb,
 '{"validation_manager": true, "validation_rh": true, "pointage_rh": true, "ordre_validation": ["manager", "rh", "pointage_rh"]}'::jsonb);
```

#### **Table `demande` - Exemples Badges**

```sql
-- Exemple 1: Badge nouveau collaborateur
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees) VALUES
(10, 'AG001', 'AG009', 'en_validation',
 '{
   "type": "nouveau_collab",
   "nom": "Dupuis",
   "prenom": "Amélie",
   "service": "RH005",
   "date_debut": "2025-01-15",
   "zones_acces": ["Bureau", "Parking"],
   "horaires": "Standard",
   "projet": "Projet Innovation"
 }'::jsonb);

-- Exemple 2: Badge perdu collaborateur
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees) VALUES
(10, 'AG001', 'AG007', 'soumis',
 '{
   "type": "perdu",
   "motif_perte": "Perte/Vol",
   "date_perte": "2024-12-10",
   "numero_badge": "BADGE-12345",
   "action": "remplacement"
 }'::jsonb);

-- Exemple 3: Badge prestataire
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees) VALUES
(13, 'AG005', NULL, 'en_validation',
 '{
   "type": "prestataire",
   "societe": "TechCorp",
   "nom": "Martin",
   "prenom": "Jean",
   "mission": "Support IT",
   "date_debut": "2025-01-20",
   "date_fin": "2025-06-20",
   "zones_acces": ["IT", "Salle serveurs"],
   "type_badge": "temporaire"
 }'::jsonb);
```

#### **Table `demande` - Exemples Heures Sup**

```sql
-- Exemple 1: Demande préalable HS
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees, date_soumission) VALUES
(1, 'AG001', 'AG001', 'en_validation',
 '{
   "type": "prealable",
   "date_debut": "2024-12-20",
   "date_fin": "2024-12-27",
   "jours_semaine": ["lundi", "mardi", "mercredi"],
   "nb_heures": 12,
   "heures_detaillees": {
     "2024-12-20": 4,
     "2024-12-23": 4,
     "2024-12-24": 4
   },
   "motif": "Dossier client urgent - Dead-line 31/12"
 }'::jsonb,
 '2024-12-15 10:00:00');

-- Exemple 2: Réalisation HS (avec lien préalable)
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees, date_soumission) VALUES
(2, 'AG001', 'AG001', 'en_validation',
 '{
   "type": "realisation",
   "demande_prealable_id": 101,
   "reference_prealable": "HS-PRE-2024-001",
   "dates_realisees": ["2024-12-20", "2024-12-23", "2024-12-24"],
   "heures_realisees": {
     "2024-12-20": {"debut": "18:00", "fin": "22:00", "nb_heures": 4},
     "2024-12-23": {"debut": "18:00", "fin": "22:00", "nb_heures": 4},
     "2024-12-24": {"debut": "18:00", "fin": "22:00", "nb_heures": 4}
   },
   "pointages_gta": {
     "2024-12-20": {"entree": "09:00", "sortie": "22:15"},
     "2024-12-23": {"entree": "09:00", "sortie": "22:10"},
     "2024-12-24": {"entree": "09:00", "sortie": "22:05"}
   },
   "ecarts": {
     "2024-12-20": {"ecart": 0, "justification": null},
     "2024-12-23": {"ecart": 0, "justification": null},
     "2024-12-24": {"ecart": 0, "justification": null}
   },
   "total_heures": 12
 }'::jsonb,
 '2024-12-28 09:00:00');

-- Exemple 3: Réalisation HS sans préalable
INSERT INTO demande (formulaire_id, code_agent_demandeur, code_agent_concerne, statut, donnees) VALUES
(2, 'AG002', 'AG002', 'brouillon',
 '{
   "type": "realisation_sans_prealable",
   "dates_realisees": ["2024-12-18"],
   "heures_realisees": {
     "2024-12-18": {"debut": "18:00", "fin": "20:30", "nb_heures": 2.5}
   },
   "motif_urgence": "Incident critique à résoudre",
   "pointages_gta": {
     "2024-12-18": {"entree": "09:00", "sortie": "20:35"}
   }
 }'::jsonb);
```

#### **Table `valideur_demande` - Exemples**

```sql
-- Badge nouveau collaborateur : Manager puis PCS
INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, statut) VALUES
(101, 'AG005', 'manager', 1, 'en_attente'),
(101, 'AG004', 'pcs', 2, 'en_attente');

-- HS Préalable : Manager puis RH
INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, statut) VALUES
(102, 'AG005', 'manager', 1, 'en_attente'),
(102, 'AG002', 'rh', 2, 'en_attente');

-- HS Réalisation : Manager, RH, puis Pointage RH
INSERT INTO valideur_demande (demande_id, code_agent_valideur, role_validation, ordre_validation, statut) VALUES
(103, 'AG005', 'manager', 1, 'en_attente'),
(103, 'AG002', 'rh', 2, 'en_attente'),
(103, 'AG002', 'pointage_rh', 3, 'en_attente');
```

#### **Table `document` - Pièces Jointes**

```sql
-- Documents pour HS
INSERT INTO document (demande_id, code_agent, nom_fichier, chemin_fichier, type_mime, type_document) VALUES
(102, 'AG001', 'justificatif_hs_prealable.pdf', '/uploads/demandes/102/justificatif.pdf', 'application/pdf', 'piece_jointe'),
(103, 'AG001', 'pointages_gta_2024-12.xlsx', '/uploads/demandes/103/pointages.xlsx', 'application/vnd.ms-excel', 'piece_jointe'),
(103, 'AG001', 'screenshot_gta_2024-12-20.png', '/uploads/demandes/103/screenshot.png', 'image/png', 'piece_jointe');
```

#### **Table `historique_demande` - Automatique via Trigger**

L'historique est créé automatiquement pour chaque changement de statut :
- Création → `brouillon`
- Soumission → `soumis` / `en_validation`
- Validation Manager → statut intermédiaire ou final
- Validation RH → statut final ou pointage
- Pointage RH → `valide` (clôture)
- Refus → `refuse`

#### **Table `notification` - Exemples**

```sql
-- Notification validation demandée (Manager)
INSERT INTO notification (code_agent_destinataire, type, titre, message, payload, lien_action) VALUES
('AG005', 'validation_requise', 'Badge à valider - Nouveau collaborateur',
 'Une demande de badge pour Amélie Dupuis nécessite votre validation.',
 '{"demande_id": 101, "type": "badge-nouveau-collab"}'::jsonb,
 '/demandes/101'),

('AG005', 'validation_requise', 'Heures Sup à valider - Demande préalable',
 'Eric Morel demande votre validation pour 12h HS préalables.',
 '{"demande_id": 102, "type": "heures-sup-prealable"}'::jsonb,
 '/demandes/102'),

('AG004', 'validation_requise', 'Badge à valider après Manager',
 'La demande de badge pour Amélie Dupuis est prête pour validation PCS.',
 '{"demande_id": 101, "type": "badge-nouveau-collab", "validation_precedente": "manager"}'::jsonb,
 '/demandes/101');
```

---

## 4) Démontration de Compatibilité

### 4.1) ✅ Structure Flexible avec JSONB

**Problème** : Les formulaires Badges et HeureSup ont des champs différents selon le type.

**Solution** : Le champ `donnees JSONB` dans la table `demande` permet de stocker :
- Des structures différentes selon le formulaire
- Des champs conditionnels (ex: `demande_prealable_id` seulement pour réalisation HS)
- Des données complexes (heures détaillées, pointages, écarts)

**Exemple** :
```sql
-- Structure Badge Nouveau Collab
{
  "type": "nouveau_collab",
  "nom": "...",
  "zones_acces": ["..."]
}

-- Structure HS Réalisation
{
  "type": "realisation",
  "demande_prealable_id": 101,
  "heures_realisees": {...},
  "pointages_gta": {...}
}
```

### 4.2) ✅ Workflow Multi-Étapes avec `valideur_demande`

**Problème** : Certaines demandes nécessitent plusieurs validations (Manager → RH → PCS).

**Solution** : La table `valideur_demande` avec `ordre_validation` permet :
- Chaîne de validation séquentielle
- Statut indépendant par valideur
- Gestion de l'ordre (1, 2, 3...)

**Badge Nouveau Collab** :
- Ordre 1: Manager (`en_attente`)
- Ordre 2: PCS (`en_attente` → devient `valide` après Manager)

**HS Préalable** :
- Ordre 1: Manager
- Ordre 2: RH

**HS Réalisation** :
- Ordre 1: Manager
- Ordre 2: RH
- Ordre 3: Pointage RH (action spécifique)

### 4.3) ✅ Schéma Formulaire Dynamique

**Problème** : Chaque formulaire a des champs différents.

**Solution** : Le champ `schema_formulaire JSONB` dans `formulaire` définit :
- Les sections et champs à afficher
- Les règles de validation côté UI
- La structure attendue des données

**Exemple Badge** :
```json
{
  "sections": [
    {"libelle": "Informations collaborateur", "champs": ["nom", "prenom"]},
    {"libelle": "Accès", "champs": ["zones_acces", "horaires"]}
  ]
}
```

### 4.4) ✅ Règles Métier dans `regles JSONB`

Le champ `regles` permet de définir :
- Les validations nécessaires (`validation_manager`, `validation_rh`, `validation_pcs`)
- L'ordre de validation (`ordre_validation`)
- Les prérequis (`prealable_requis` pour HS réalisation)

### 4.5) ✅ Historique et Traçabilité

**Trigger automatique** créant un historique pour chaque :
- Création de demande
- Changement de statut
- Modification des données (`donnees_avant`, `donnees_apres`)

Permet de tracer tout le cycle de vie des demandes Badges et HS.

### 4.6) ✅ Dashboards par Rôle

Les requêtes peuvent filtrer selon :
- `code_agent_demandeur` (mes demandes)
- `code_agent_valideur` (mes validations en attente)
- `code_agent_concerne` (demandes pour mon équipe)
- `role_validation` (manager, rh, pcs)

**Exemple Dashboard Manager** :
```sql
SELECT d.*, f.titre, v.statut as statut_validation
FROM demande d
JOIN formulaire f ON d.formulaire_id = f.id
LEFT JOIN valideur_demande v ON d.id = v.demande_id 
  AND v.code_agent_valideur = 'AG005' 
  AND v.role_validation = 'manager'
WHERE (d.code_agent_concerne IN (
    SELECT code_agent FROM agent WHERE code_service = 'MGT001'
  ) OR v.code_agent_valideur = 'AG005')
  AND d.est_supprime = FALSE
ORDER BY d.date_soumission DESC;
```

### 4.7) ✅ Liens entre Demandes (HS Préalable ↔ Réalisation)

**Problème** : HS Réalisation doit référencer le préalable.

**Solution** :
1. Option 1 : Stocker `demande_prealable_id` dans `donnees JSONB`
2. Option 2 : Créer une table de liaison (recommandé pour intégrité)

```sql
-- Table optionnelle pour liens explicites
CREATE TABLE lien_demande (
    id SERIAL PRIMARY KEY,
    demande_source_id INTEGER REFERENCES demande(id),
    demande_cible_id INTEGER REFERENCES demande(id),
    type_lien VARCHAR(50), -- 'prealable_realisation', 'proroge', etc.
    UNIQUE(demande_source_id, demande_cible_id)
);

-- Exemple
INSERT INTO lien_demande (demande_source_id, demande_cible_id, type_lien) VALUES
(102, 103, 'prealable_realisation');
```

### 4.8) ✅ Soft Delete

Les demandes peuvent être supprimées (soft delete) avec :
- `est_supprime = TRUE`
- `motif_suppression`, `commentaire_suppression`
- `code_agent_suppression`, `date_suppression`

Gère les erreurs de saisie sans perdre la traçabilité.

---

## 5) Schémas SQL Complets pour Badges et HS

### 5.1) Script d'Insertion Formulaires

```sql
-- ============================================
-- FORMULAIRES BADGES
-- ============================================

-- Badge Nouveau Collaborateur
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles) VALUES
('badge-nouveau-collab', 'Badge Nouveau Collaborateur', 'Demande de badge pour nouveau collaborateur', 'Badges', 10, 'badge',
 '{"sections": [
   {"libelle": "Informations collaborateur", "champs": ["nom", "prenom", "service", "date_debut", "fonction", "projet"]},
   {"libelle": "Accès demandés", "champs": ["zones_acces", "horaires", "type_badge", "duree"]},
   {"libelle": "Justification", "champs": ["motif", "piece_jointe"]}
 ]}'::jsonb,
 '{"validation_manager": true, "validation_pcs": true, "ordre_validation": ["manager", "pcs"], "duree_max": 365}'::jsonb),

-- Badge Départ Collaborateur
('badge-depart-collab', 'Badge Départ Collaborateur', 'Gestion badge à la sortie', 'Badges', 11, 'logout',
 '{"sections": [
   {"libelle": "Informations", "champs": ["collaborateur", "date_depart", "prolongation", "rendu_badge", "motif_prolongation"]}
 ]}'::jsonb,
 '{"validation_manager": true, "validation_pcs": true}'::jsonb),

-- Badge Personnel Oublié/Perdu
('badge-perso-oubli', 'Badge Personnel - Oubli/Perte', 'Gestion badge oublié ou perdu', 'Badges', 12, 'alert',
 '{"sections": [
   {"libelle": "Informations", "champs": ["date_oubli_perte", "numero_badge", "motif_perte", "action_demandee"]},
   {"libelle": "Justification", "champs": ["declaration", "piece_jointe"]}
 ]}'::jsonb,
 '{"validation_pcs": true}'::jsonb),

-- Badge Prestataire
('badge-presta-new', 'Badge Nouveau Prestataire', 'Demande badge prestataire', 'Badges', 13, 'briefcase',
 '{"sections": [
   {"libelle": "Prestataire", "champs": ["societe", "nom", "prenom", "mission", "date_debut", "date_fin", "contact_entreprise"]},
   {"libelle": "Accès", "champs": ["zones_acces", "type_badge", "duree_autorisation"]}
 ]}'::jsonb,
 '{"validation_manager": true, "validation_pcs": true}'::jsonb),

-- Badge Autre/Spécifique
('badge-autre-specifique', 'Badge Demande Spécifique', 'Demande badge cas particulier', 'Badges', 14, 'settings',
 '{"sections": [
   {"libelle": "Type de demande", "champs": ["type_specifique", "description", "justification"]},
   {"libelle": "Informations", "champs": ["beneficiaire", "dates", "motif"]}
 ]}'::jsonb,
 '{"validation_manager": true, "validation_pcs": true, "validation_rh": false}'::jsonb);

-- ============================================
-- FORMULAIRES HEURES SUP
-- ============================================

-- HS Demande Préalable
INSERT INTO formulaire (slug, titre, description, categorie, ordre_affichage, icone, schema_formulaire, regles) VALUES
('heures-sup-prealable', 'Heures Supplémentaires - Demande Préalable', 'Demande préalable HS', 'Rémunération', 1, 'clock',
 '{"sections": [
   {"libelle": "Période", "champs": ["date_debut", "date_fin", "jours_semaine", "type_periode"]},
   {"libelle": "Détails heures", "champs": ["nb_heures", "heures_detaillees", "horaires_previsionnels"]},
   {"libelle": "Justification", "champs": ["motif", "dossier_lie", "piece_jointe"]}
 ]}'::jsonb,
 '{"prealable": true, "validation_manager": true, "validation_rh": true, "ordre_validation": ["manager", "rh"], "max_heures_mois": 50}'::jsonb),

-- HS Réalisation
('heures-sup-realisation', 'Heures Supplémentaires - Réalisation', 'Saisie réalisation HS avec ou sans préalable', 'Rémunération', 2, 'check-circle',
 '{"sections": [
   {"libelle": "Lien préalable", "champs": ["demande_prealable_id", "reference_prealable", "sans_prealable"]},
   {"libelle": "Réalisation", "champs": ["dates_realisees", "heures_realisees", "pointages_gta", "ecarts_vs_prealable"]},
   {"libelle": "Justification", "champs": ["justification_ecarts", "motif_urgence", "pieces_justificatives"]}
 ]}'::jsonb,
 '{"validation_manager": true, "validation_rh": true, "pointage_rh": true, "ordre_validation": ["manager", "rh", "pointage_rh"], "accepte_sans_prealable": true}'::jsonb);
```

### 5.2) Table Optionnelle : Liens entre Demandes

```sql
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
```

---

## 6) Conclusion

### ✅ **COMPATIBILITÉ TOTALE**

La structure de base de données proposée peut **complètement** supporter :

1. **Badges** : Tous les types (collab, perso, presta, autre) avec leurs workflows spécifiques
2. **Heures Sup** : Demandes préalables et réalisations avec liens, multi-validations, pointages

### Points Clés de Compatibilité

| Fonctionnalité | Badges | Heures Sup | Structure Unifiée |
|----------------|--------|------------|-------------------|
| **Champs variables** | ✅ Par type | ✅ Préalable vs Réalisation | ✅ JSONB `donnees` |
| **Multi-validations** | ✅ Manager → PCS | ✅ Manager → RH → Pointage | ✅ `valideur_demande` |
| **Historique complet** | ✅ Oui | ✅ Oui | ✅ `historique_demande` (trigger) |
| **Pièces jointes** | ✅ Oui | ✅ Oui | ✅ Table `document` |
| **Dashboards rôle** | ✅ Oui | ✅ Oui | ✅ Requêtes filtrables |
| **Statuts variés** | ✅ Oui | ✅ Oui | ✅ Champ `statut` flexible |
| **Liens entre demandes** | ⚠️ Rare | ✅ Préalable ↔ Réalisation | ✅ Table `lien_demande` optionnelle |
| **Soft delete** | ✅ Oui | ✅ Oui | ✅ Colonnes dédiées |

### Recommandations

1. **Utiliser le champ `donnees JSONB`** pour toutes les données spécifiques par formulaire
2. **Créer la table `lien_demande`** pour gérer explicitement les liens HS préalable ↔ réalisation
3. **Définir les schémas dans `schema_formulaire`** pour génération dynamique des formulaires dans Convertigo
4. **Utiliser `regles JSONB`** pour valider les workflows et prérequis

**La structure est prête pour intégrer Badges et Heures Sup !** 🎯

