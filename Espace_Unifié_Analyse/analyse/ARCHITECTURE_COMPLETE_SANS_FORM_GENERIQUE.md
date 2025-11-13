# Espace Unifié URSSAF — Architecture complète (sans formulaire générique)

## Vision

**Espace Unifié** est un hub RH centralisé permettant de :
- Gérer des workflows RH internes (Heures Supplémentaires, Badges, Demandes diverses)
- Accéder et interconnecter des applications externes (Securrsafe, GTA, Paie, etc.)
- Offrir un dashboard unifié avec KPI et backlog agrégés

**Principe architectural** : Architecture simple et lisible
- Tables communes transverses (utilisateurs, pièces jointes, traçabilité, workflow)
- Tables dédiées par formulaire (une table = un formulaire spécifique)
- Extensibilité : Ajouter un nouveau formulaire = créer ses tables dédiées + réutiliser les tables communes

---

## Modules de l'application

1. **Module Heures** : Heures Supplémentaires (HS)
2. **Module Badges** : Badges collaborateur et prestataire
3. **Module Demandes RH** : Demandes diverses (mobilité, temps partiel, interventions, etc.)
4. **Module Connecteurs** : Accès et intégration avec applications externes
5. **Module Dashboard** : Vue agrégée KPI + backlog

---

## 1. Tables communes (transverses)

### 1.1 Utilisateurs

```sql
CREATE TABLE utilisateurs (
  id VARCHAR(64) PRIMARY KEY,
  courriel VARCHAR(256) UNIQUE NOT NULL,
  nom VARCHAR(128) NOT NULL,
  prenom VARCHAR(128) NOT NULL,
  role VARCHAR(32) NOT NULL,  -- collaborateur | manager | rh | prestataire
  date_creation TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_utilisateurs_role ON utilisateurs(role);
CREATE INDEX idx_utilisateurs_courriel ON utilisateurs(courriel);
```

### 1.2 Pièces jointes (polymorphique)

```sql
CREATE TABLE pieces_jointes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_formulaire VARCHAR(64) NOT NULL,   -- 'HS' | 'BADGE' | 'MOBILITE' | ...
  id_formulaire UUID NOT NULL,            -- id dans la table dédiée
  nom_fichier VARCHAR(256) NOT NULL,
  type_mime VARCHAR(64) NOT NULL,
  taille BIGINT NOT NULL,
  cle_stockage VARCHAR(512) NOT NULL,    -- URL ou clé S3/storage
  date_creation TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_pj_formulaire ON pieces_jointes(type_formulaire, id_formulaire);
CREATE INDEX idx_pj_date ON pieces_jointes(date_creation);
```

### 1.3 Événements workflow (traçabilité fonctionnelle)

```sql
CREATE TABLE evenements_workflow (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_formulaire VARCHAR(64) NOT NULL,   -- 'HS' | 'BADGE' | 'MOBILITE' | ...
  id_formulaire UUID NOT NULL,            -- id dans la table dédiée
  etat_depart VARCHAR(64),                 -- NULL si création
  etat_arrivee VARCHAR(64) NOT NULL,      -- draft | en_attente_manager | en_attente_rh | valide | refuse | cloture
  action VARCHAR(64) NOT NULL,            -- soumettre | valider | refuser | commenter | clore | annuler
  par_utilisateur VARCHAR(64) NOT NULL,
  donnees JSONB,                          -- {commentaire, motif_refus, etc.}
  date_creation TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_evt_flow_formulaire ON evenements_workflow(type_formulaire, id_formulaire);
CREATE INDEX idx_evt_flow_etat ON evenements_workflow(etat_arrivee);
CREATE INDEX idx_evt_flow_date ON evenements_workflow(date_creation);
```

### 1.4 Journal de traçabilité (audit technique)

```sql
CREATE TABLE journal_tracabilite (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur VARCHAR(64) NOT NULL,
  action VARCHAR(64) NOT NULL,            -- creer | modifier | supprimer | consulter
  ressource VARCHAR(64) NOT NULL,        -- 'HS' | 'BADGE' | 'CONNECTEUR' | ...
  id_ressource UUID NOT NULL,
  avant JSONB,                            -- État avant modification
  apres JSONB,                            -- État après modification
  date_creation TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_journal_ressource ON journal_tracabilite(ressource, id_ressource);
CREATE INDEX idx_journal_utilisateur ON journal_tracabilite(id_utilisateur);
CREATE INDEX idx_journal_date ON journal_tracabilite(date_creation);
```

---

## 2. Module Heures Supplémentaires (HS)

### 2.1 Table principale : Demandes HS

```sql
CREATE TABLE hs_demande (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur VARCHAR(64) NOT NULL REFERENCES utilisateurs(id),
  date_heure DATE NOT NULL,
  heures_normales DECIMAL(4,2) NOT NULL CHECK (heures_normales >= 0 AND heures_normales <= 24),
  heures_supplementaires DECIMAL(4,2) NOT NULL DEFAULT 0 CHECK (heures_supplementaires >= 0 AND heures_supplementaires <= 8),
  etat_courant VARCHAR(64) NOT NULL DEFAULT 'en_attente_manager',
  date_creation TIMESTAMP NOT NULL DEFAULT now(),
  date_modification TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_hs_utilisateur ON hs_demande(id_utilisateur);
CREATE INDEX idx_hs_etat ON hs_demande(etat_courant);
CREATE INDEX idx_hs_date ON hs_demande(date_heure);
CREATE INDEX idx_hs_date_creation ON hs_demande(date_creation);
```

### 2.2 Commentaires HS (optionnel)

```sql
CREATE TABLE hs_commentaire (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_hs UUID NOT NULL REFERENCES hs_demande(id) ON DELETE CASCADE,
  auteur VARCHAR(64) NOT NULL,
  message TEXT NOT NULL,
  date_creation TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_hs_commentaire ON hs_commentaire(id_hs);
CREATE INDEX idx_hs_commentaire_date ON hs_commentaire(date_creation);
```

### 2.3 Exemples de flux HS

#### Création d'une demande
```sql
-- 1. Créer la demande
INSERT INTO hs_demande (id_utilisateur, date_heure, heures_normales, heures_supplementaires)
VALUES ('user123', '2024-12-15', 7.0, 2.0)
RETURNING id;  -- Retourne : <id_hs>

-- 2. Enregistrer l'événement de création
INSERT INTO evenements_workflow (
  type_formulaire, 
  id_formulaire, 
  etat_depart, 
  etat_arrivee, 
  action, 
  par_utilisateur
)
VALUES ('HS', '<id_hs>', NULL, 'en_attente_manager', 'soumettre', 'user123');

-- 3. Journaliser (optionnel)
INSERT INTO journal_tracabilite (
  id_utilisateur,
  action,
  ressource,
  id_ressource,
  apres
)
VALUES ('user123', 'creer', 'HS', '<id_hs>', '{"date_heure":"2024-12-15","heures_normales":7.0}'::jsonb);
```

#### Validation Manager → RH
```sql
-- 1. Mettre à jour l'état
UPDATE hs_demande
SET etat_courant = 'en_attente_rh', date_modification = now()
WHERE id = '<id_hs>';

-- 2. Enregistrer l'événement
INSERT INTO evenements_workflow (
  type_formulaire,
  id_formulaire,
  etat_depart,
  etat_arrivee,
  action,
  par_utilisateur,
  donnees
)
VALUES ('HS', '<id_hs>', 'en_attente_manager', 'en_attente_rh', 'valider', 'manager001', '{"commentaire":"OK validé"}'::jsonb);
```

#### Refus RH
```sql
-- 1. Mettre à jour l'état
UPDATE hs_demande
SET etat_courant = 'refuse', date_modification = now()
WHERE id = '<id_hs>';

-- 2. Enregistrer l'événement (motif obligatoire)
INSERT INTO evenements_workflow (
  type_formulaire,
  id_formulaire,
  etat_depart,
  etat_arrivee,
  action,
  par_utilisateur,
  donnees
)
VALUES ('HS', '<id_hs>', 'en_attente_rh', 'refuse', 'refuser', 'rh001', '{"motif":"Heures non justifiées selon les règles internes"}'::jsonb);
```

#### Ajout d'une pièce jointe
```sql
INSERT INTO pieces_jointes (
  type_formulaire,
  id_formulaire,
  nom_fichier,
  type_mime,
  taille,
  cle_stockage
)
VALUES ('HS', '<id_hs>', 'justificatif_heures.pdf', 'application/pdf', 123456, 's3://bucket/hs/justificatif_123.pdf');
```

---

## 3. Module Badge Collaborateur

### 3.1 Table principale : Demandes Badge

```sql
CREATE TABLE badge_demande (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur VARCHAR(64) NOT NULL REFERENCES utilisateurs(id),
  nom_collaborateur VARCHAR(128) NOT NULL,
  prenom_collaborateur VARCHAR(128) NOT NULL,
  courriel_collaborateur VARCHAR(256) NOT NULL,
  etat_courant VARCHAR(64) NOT NULL DEFAULT 'en_attente_manager',
  date_creation TIMESTAMP NOT NULL DEFAULT now(),
  date_modification TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_badge_utilisateur ON badge_demande(id_utilisateur);
CREATE INDEX idx_badge_etat ON badge_demande(etat_courant);
CREATE INDEX idx_badge_date_creation ON badge_demande(date_creation);
```

### 3.2 Accès Badge (table spécifique)

```sql
CREATE TABLE badge_acces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_badge UUID NOT NULL REFERENCES badge_demande(id) ON DELETE CASCADE,
  zone VARCHAR(64) NOT NULL,
  niveau_acces VARCHAR(32) NOT NULL,
  date_debut DATE NOT NULL,
  date_fin DATE
);

CREATE INDEX idx_badge_acces ON badge_acces(id_badge);
CREATE INDEX idx_badge_acces_zone ON badge_acces(zone);
```

### 3.3 Exemples de flux Badge

#### Création d'une demande Badge
```sql
-- 1. Créer la demande
INSERT INTO badge_demande (id_utilisateur, nom_collaborateur, prenom_collaborateur, courriel_collaborateur)
VALUES ('user789', 'Dupont', 'Jean', 'jean.dupont@urssaf.fr')
RETURNING id;  -- Retourne : <id_badge>

-- 2. Enregistrer l'événement
INSERT INTO evenements_workflow (
  type_formulaire,
  id_formulaire,
  etat_depart,
  etat_arrivee,
  action,
  par_utilisateur
)
VALUES ('BADGE', '<id_badge>', NULL, 'en_attente_manager', 'soumettre', 'user789');

-- 3. Ajouter les accès (si nécessaires)
INSERT INTO badge_acces (id_badge, zone, niveau_acces, date_debut, date_fin)
VALUES 
  ('<id_badge>', 'Zone_A', 'N3', CURRENT_DATE, CURRENT_DATE + INTERVAL '365 days'),
  ('<id_badge>', 'Zone_B', 'N2', CURRENT_DATE, CURRENT_DATE + INTERVAL '365 days');
```

#### Validation finale RH
```sql
-- 1. Mettre à jour l'état
UPDATE badge_demande
SET etat_courant = 'valide', date_modification = now()
WHERE id = '<id_badge>';

-- 2. Enregistrer l'événement
INSERT INTO evenements_workflow (
  type_formulaire,
  id_formulaire,
  etat_depart,
  etat_arrivee,
  action,
  par_utilisateur
)
VALUES ('BADGE', '<id_badge>', 'en_attente_rh', 'valide', 'valider', 'rh001');
```

---

## 4. Module Connecteurs externes

### 4.1 Catalogue des connecteurs

```sql
CREATE TABLE connecteur (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(64) UNIQUE NOT NULL,    -- SECURRSAFE | GTA | PAIE | ...
  libelle VARCHAR(128) NOT NULL,
  description TEXT,
  type VARCHAR(32) NOT NULL,           -- rest | soap | file | webhook
  actif BOOLEAN NOT NULL DEFAULT TRUE,
  date_creation TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_connecteur_code ON connecteur(code);
CREATE INDEX idx_connecteur_actif ON connecteur(actif);
```

### 4.2 Comptes connecteurs (authentification)

```sql
CREATE TABLE compte_connecteur (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_connecteur UUID NOT NULL REFERENCES connecteur(id) ON DELETE CASCADE,
  type_auth VARCHAR(32) NOT NULL,      -- oauth2 | key | basic | jwt
  secrets JSONB NOT NULL,               -- {client_id, client_secret, token_url, ...}
  scopes TEXT[],
  date_creation TIMESTAMP NOT NULL DEFAULT now(),
  date_modification TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_compte_connecteur ON compte_connecteur(id_connecteur);
```

### 4.3 Cache KPI connecteurs

```sql
CREATE TABLE cache_kpi_connecteur (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_connecteur UUID NOT NULL REFERENCES connecteur(id) ON DELETE CASCADE,
  type_kpi VARCHAR(64) NOT NULL,       -- badges_en_attente | heures_traitees | ...
  valeur DECIMAL(10,2) NOT NULL,
  date_calcul TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_cache_kpi_connecteur ON cache_kpi_connecteur(id_connecteur, type_kpi);
CREATE INDEX idx_cache_kpi_date ON cache_kpi_connecteur(date_calcul);
```

### 4.4 Exemple d'utilisation

```sql
-- Enregistrer un connecteur Securrsafe
INSERT INTO connecteur (code, libelle, description, type)
VALUES ('SECURRSAFE', 'Securrsafe', 'Application de gestion des badges', 'rest');

-- Ajouter les credentials
INSERT INTO compte_connecteur (id_connecteur, type_auth, secrets, scopes)
SELECT 
  id,
  'oauth2',
  '{"client_id":"xxx","client_secret":"yyy","token_url":"https://..."}'::jsonb,
  ARRAY['badges:read', 'badges:write']
FROM connecteur WHERE code = 'SECURRSAFE';

-- Cache un KPI récupéré
INSERT INTO cache_kpi_connecteur (id_connecteur, type_kpi, valeur)
SELECT 
  id,
  'badges_en_attente_rh',
  15
FROM connecteur WHERE code = 'SECURRSAFE';
```

---

## 5. Module Dashboard (agrégation)

### 5.1 Éléments KPI

```sql
CREATE TABLE element_kpi (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type_kpi VARCHAR(64) NOT NULL,       -- heures_en_attente_manager | badges_valides_mois | ...
  libelle VARCHAR(128) NOT NULL,
  valeur DECIMAL(10,2) NOT NULL,
  unite VARCHAR(32),                    -- 'unite' | 'euros' | 'jours' | ...
  scope_role VARCHAR(32),               -- collaborateur | manager | rh | all
  source VARCHAR(64) NOT NULL,         -- interne:HS | interne:BADGE | ext:SECURRSAFE
  date_calcul TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_kpi_type ON element_kpi(type_kpi);
CREATE INDEX idx_kpi_source ON element_kpi(source);
CREATE INDEX idx_kpi_scope ON element_kpi(scope_role);
CREATE INDEX idx_kpi_date ON element_kpi(date_calcul);
```

### 5.2 Éléments Backlog

```sql
CREATE TABLE element_backlog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  titre VARCHAR(256) NOT NULL,
  source VARCHAR(64) NOT NULL,         -- interne:HS | interne:BADGE | ext:SECURRSAFE
  id_source VARCHAR(128),              -- id côté source (optionnel)
  assigne_a VARCHAR(64),               -- NULL si non assigné
  etat VARCHAR(64) NOT NULL,
  echeance TIMESTAMP,
  lien VARCHAR(512),                   -- URL pour accéder à l'élément
  scope_role VARCHAR(32),              -- collaborateur | manager | rh | all
  date_creation TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_backlog_source ON element_backlog(source);
CREATE INDEX idx_backlog_assigne ON element_backlog(assigne_a);
CREATE INDEX idx_backlog_etat ON element_backlog(etat);
CREATE INDEX idx_backlog_scope ON element_backlog(scope_role);
CREATE INDEX idx_backlog_echeance ON element_backlog(echeance);
```

### 5.3 Exemple d'agrégation

```sql
-- Calculer KPI : Heures en attente manager (interne)
INSERT INTO element_kpi (type_kpi, libelle, valeur, unite, scope_role, source)
SELECT 
  'heures_en_attente_manager',
  'Heures supplémentaires en attente de validation Manager',
  COUNT(*),
  'unite',
  'manager',
  'interne:HS'
FROM hs_demande
WHERE etat_courant = 'en_attente_manager';

-- Calculer KPI : Badges en attente (depuis connecteur)
INSERT INTO element_kpi (type_kpi, libelle, valeur, unite, scope_role, source)
SELECT 
  'badges_en_attente_rh',
  'Badges en attente RH (Securrsafe)',
  valeur,
  'unite',
  'rh',
  'ext:SECURRSAFE'
FROM cache_kpi_connecteur
WHERE id_connecteur = (SELECT id FROM connecteur WHERE code = 'SECURRSAFE')
  AND type_kpi = 'badges_en_attente_rh';

-- Créer backlog : Tâches HS à traiter (manager)
INSERT INTO element_backlog (titre, source, id_source, assigne_a, etat, scope_role, lien)
SELECT 
  'Demande HS du ' || TO_CHAR(date_heure, 'DD/MM/YYYY'),
  'interne:HS',
  id::text,
  NULL,
  etat_courant,
  'manager',
  '/heures/' || id::text
FROM hs_demande
WHERE etat_courant = 'en_attente_manager';
```

---

## 6. RBAC (Rôles et Permissions)

### 6.1 Rôles définis

| Rôle | Actions disponibles |
|------|---------------------|
| **collaborateur** | Créer ses propres demandes (HS, Badge, etc.)<br>Consulter ses demandes en cours<br>Ajouter des commentaires<br>Annuler ses demandes (si état = en_attente_manager) |
| **manager** | Consulter les demandes de son équipe<br>Valider/Refuser les demandes (niveau 1)<br>Ajouter des commentaires<br>Voir le dashboard équipe |
| **rh** | Consulter toutes les demandes<br>Valider/Refuser les demandes (niveau final)<br>Clôturer les demandes<br>Voir le dashboard global<br>Gérer les connecteurs |

### 6.2 Logique de permissions (application)

Les permissions sont gérées au niveau applicatif selon le rôle :

```sql
-- Exemple : Vérifier si un manager peut valider une demande HS
SELECT EXISTS (
  SELECT 1
  FROM hs_demande hs
  JOIN utilisateurs u ON hs.id_utilisateur = u.id
  WHERE hs.id = '<id_hs>'
    AND hs.etat_courant = 'en_attente_manager'
    AND u.role = 'manager'  -- Vérification au niveau applicatif
);
```

---

## 7. API (endpoints proposés)

### 7.1 Module Heures

- `GET /api/heures` : Liste des demandes HS (filtrée par rôle)
- `GET /api/heures/:id` : Détail d'une demande HS
- `POST /api/heures` : Créer une demande HS
- `POST /api/heures/:id/valider` : Valider une demande (manager/rh)
- `POST /api/heures/:id/refuser` : Refuser une demande (motif obligatoire)
- `POST /api/heures/:id/clore` : Clôturer une demande (rh)
- `POST /api/heures/:id/commenter` : Ajouter un commentaire
- `POST /api/heures/:id/pieces-jointes` : Ajouter une pièce jointe

### 7.2 Module Badges

- `GET /api/badges` : Liste des demandes Badge
- `GET /api/badges/:id` : Détail d'une demande Badge
- `POST /api/badges` : Créer une demande Badge
- `POST /api/badges/:id/valider` : Valider une demande
- `POST /api/badges/:id/refuser` : Refuser une demande
- `GET /api/badges/:id/acces` : Liste des accès d'un badge

### 7.3 Module Dashboard

- `GET /api/dashboard/kpi` : Liste des KPI (filtrés par rôle)
- `GET /api/dashboard/backlog` : Liste des éléments backlog
- `GET /api/dashboard/kpi/source/:source` : KPI d'une source spécifique

### 7.4 Module Connecteurs

- `GET /api/connecteurs` : Liste des connecteurs disponibles
- `GET /api/connecteurs/:code/carte` : Carte d'accès (si autorisé)
- `POST /api/connecteurs/:code/sync` : Forcer la synchronisation KPI (admin)

---

## 8. Guide d'extension : Ajouter un nouveau formulaire

Pour ajouter un nouveau formulaire (ex: Mobilité), suivre ce pattern :

### Étape 1 : Créer la table principale

```sql
CREATE TABLE mobilite_demande (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur VARCHAR(64) NOT NULL REFERENCES utilisateurs(id),
  date_debut DATE NOT NULL,
  date_fin DATE,
  type_mobilite VARCHAR(64) NOT NULL,  -- velo | covoiturage | transport_commun
  site_accueil VARCHAR(128),
  etat_courant VARCHAR(64) NOT NULL DEFAULT 'en_attente_manager',
  date_creation TIMESTAMP NOT NULL DEFAULT now(),
  date_modification TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX idx_mobilite_utilisateur ON mobilite_demande(id_utilisateur);
CREATE INDEX idx_mobilite_etat ON mobilite_demande(etat_courant);
```

### Étape 2 : Créer les tables annexes (si nécessaire)

```sql
CREATE TABLE mobilite_detail (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_mobilite UUID NOT NULL REFERENCES mobilite_demande(id) ON DELETE CASCADE,
  jour_semaine VARCHAR(16) NOT NULL,
  trajet_km DECIMAL(6,2),
  date_creation TIMESTAMP NOT NULL DEFAULT now()
);
```

### Étape 3 : Utiliser les tables communes

- `evenements_workflow` : Pour tracer les changements d'état (type_formulaire = 'MOBILITE')
- `pieces_jointes` : Pour les documents justificatifs
- `journal_tracabilite` : Pour l'audit technique

### Étape 4 : Créer les endpoints API

- `POST /api/mobilite`
- `GET /api/mobilite/:id`
- `POST /api/mobilite/:id/valider`
- etc.

---

## 9. États et transitions standardisés

### États possibles

- `draft` : Brouillon (non soumis)
- `en_attente_manager` : En attente de validation manager
- `en_attente_rh` : En attente de validation RH
- `valide` : Validé par RH
- `refuse` : Refusé (manager ou RH)
- `cloture` : Clôturé et traité

### Actions possibles

- `soumettre` : Soumettre une demande (draft → en_attente_manager)
- `valider` : Approuver (en_attente_manager → en_attente_rh ou en_attente_rh → valide)
- `refuser` : Refuser (avec motif obligatoire dans `donnees`)
- `commenter` : Ajouter un commentaire (sans changement d'état)
- `clore` : Clôturer (valide → cloture)
- `annuler` : Annuler par le demandeur (si état = en_attente_manager)

---

## 10. Requêtes utiles

### Dashboard Manager : Demandes de l'équipe en attente

```sql
SELECT 
  'HS' as type,
  hs.id,
  u.nom || ' ' || u.prenom as demandeur,
  hs.date_heure,
  hs.heures_supplementaires,
  hs.date_creation
FROM hs_demande hs
JOIN utilisateurs u ON hs.id_utilisateur = u.id
WHERE hs.etat_courant = 'en_attente_manager'
  AND u.role = 'collaborateur'  -- Filtrer par équipe si nécessaire
ORDER BY hs.date_creation DESC
LIMIT 20;
```

### Historique complet d'une demande

```sql
SELECT 
  evt.date_creation,
  evt.etat_depart,
  evt.etat_arrivee,
  evt.action,
  evt.par_utilisateur,
  evt.donnees->>'commentaire' as commentaire,
  evt.donnees->>'motif' as motif_refus
FROM evenements_workflow evt
WHERE evt.type_formulaire = 'HS'
  AND evt.id_formulaire = '<id_hs>'
ORDER BY evt.date_creation;
```

### Statistiques par mois (HS)

```sql
SELECT 
  DATE_TRUNC('month', date_creation) as mois,
  etat_courant,
  COUNT(*) as nombre,
  SUM(heures_supplementaires) as total_heures_sup
FROM hs_demande
WHERE date_creation >= NOW() - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', date_creation), etat_courant
ORDER BY mois DESC, etat_courant;
```

---

## Conclusion

Cette architecture offre :
- **Simplicité** : Tables dédiées par formulaire, lisibles par tous
- **Cohérence** : Tables communes réutilisables (workflow, pièces jointes, traçabilité)
- **Extensibilité** : Ajout d'un formulaire = nouvelles tables + réutilisation des briques communes
- **Interopérabilité** : Connecteurs externes + dashboard agrégé
- **Traçabilité complète** : Événements workflow + journal d'audit

Idéal pour une dizaine de formulaires avec un schéma clair et maintenable.
