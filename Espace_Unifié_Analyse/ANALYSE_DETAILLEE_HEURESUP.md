# Analyse Détaillée du Formulaire Heures Supplémentaires

## 1. Prise de Connaissance du Formulaire

### 1.1. Types de Demandes Identifiés

D'après l'analyse des maquettes dans `HeureSup/`, deux types principaux de demandes :

#### **A. Demande Préalable** (`dmd-heure-*.png`)
- **Objectif** : Demander l'autorisation de faire des heures supplémentaires AVANT leur réalisation
- **Vues** : `dmd-heure-perso.png`, `dmd-heure-manager.png`

#### **B. Réalisation** (`saisie-heure-real-*.png`)
- **Objectif** : Saisir les heures supplémentaires RÉALISÉES (avec ou sans préalable)
- **Vues** : Multiples statuts (collab, manager-valid, manager-refused, wait-manager, wait-rh, valid, refused)

#### **C. Pointage RH** (`pointage-heure-real-rh-*.png`)
- **Objectif** : Pointage final et réconciliation avec GTA par les RH
- **Vues** : `pointage-heure-real-rh.png`, `pointage-heure-real-rh-valid.png`, `pointage-heure-real-rh-refused.png`

### 1.2. Espaces Utilisateurs

- **Dashboard Collaborateur** : Vue demandes personnelles
- **Dashboard Manager** : Validations en attente, vue équipe
- **Dashboard RH** : Pointages, validation finale
- **Dashboard Réalisation** : Saisies réalisations (collab, manager, rh)

---

## 2. Extraction des Colonnes Nécessaires et Types

### 2.1. Table : `heures_sup_prealable`

| Colonne | Type | Contraintes | Description | Exemple |
|---------|------|-------------|-------------|---------|
| `id` | SERIAL | PRIMARY KEY | Identifiant unique | 1 |
| `code_agent_demandeur` | VARCHAR(50) | NOT NULL, FK → agent | Agent qui fait la demande | 'AG001' |
| `code_agent_concerne` | VARCHAR(50) | FK → agent | Agent concerné (peut être différent si manager) | 'AG001' |
| `date_debut` | DATE | NOT NULL | Date début période HS | '2024-12-20' |
| `date_fin` | DATE | NOT NULL | Date fin période HS | '2024-12-27' |
| `jours_semaine` | TEXT[] | | Jours concernés (array) | ['lundi', 'mardi', 'mercredi'] |
| `type_periode` | VARCHAR(50) | | Type : 'Ponctuel' ou 'Récurrent' | 'Ponctuel' |
| `nb_heures_total` | NUMERIC(5,2) | NOT NULL, CHECK > 0 | Nombre total d'heures | 12.00 |
| `heures_detaillees` | JSONB | | Détail par jour : {"2024-12-20": 4, "2024-12-23": 4} | `{"2024-12-20": 4}` |
| `horaires_previsionnels` | TEXT | | Horaires prévisionnels (texte libre) | '18h-22h chaque jour' |
| `motif` | TEXT | NOT NULL | Motif de la demande | 'Dossier client urgent' |
| `dossier_lie` | VARCHAR(255) | | Référence dossier/projet | 'CLIENT-2024-001' |
| `statut_code` | VARCHAR(50) | NOT NULL, FK → statut | Statut actuel | 'en_validation' |
| `etape_actuelle` | INTEGER | NOT NULL DEFAULT 1 | Numéro étape workflow | 3 |
| `date_creation` | TIMESTAMP | DEFAULT NOW() | Date création | '2024-12-15 10:00:00' |
| `date_modification` | TIMESTAMP | DEFAULT NOW() | Date modification | '2024-12-16 09:00:00' |
| `date_soumission` | TIMESTAMP | | Date soumission | '2024-12-15 10:30:00' |
| `date_cloture` | TIMESTAMP | | Date clôture (approuvé) | NULL |
| `code_agent_creation` | VARCHAR(50) | FK → agent | Agent créateur | 'AG001' |
| `code_agent_modification` | VARCHAR(50) | FK → agent | Dernier modificateur | 'AG001' |
| `est_supprime` | BOOLEAN | DEFAULT FALSE | Soft delete | FALSE |
| `motif_suppression` | TEXT | | Motif suppression | NULL |
| `commentaire_suppression` | TEXT | | Commentaire suppression | NULL |
| `code_agent_suppression` | VARCHAR(50) | FK → agent | Agent suppresseur | NULL |
| `date_suppression` | TIMESTAMP | | Date suppression | NULL |

**Champs JSONB `heures_detaillees` Structure** :
```json
{
  "2024-12-20": 4,
  "2024-12-23": 4,
  "2024-12-24": 4
}
```

### 2.2. Table : `heures_sup_realisation`

| Colonne | Type | Contraintes | Description | Exemple |
|---------|------|-------------|-------------|---------|
| `id` | SERIAL | PRIMARY KEY | Identifiant unique | 1 |
| `heures_sup_prealable_id` | INTEGER | FK → heures_sup_prealable | Lien préalable (NULL si sans préalable) | 5 |
| `code_agent_demandeur` | VARCHAR(50) | NOT NULL, FK → agent | Agent qui saisit | 'AG001' |
| `code_agent_concerne` | VARCHAR(50) | FK → agent | Agent concerné | 'AG001' |
| `avec_prealable` | BOOLEAN | DEFAULT FALSE | Avec préalable ? | TRUE |
| `sans_prealable` | BOOLEAN | DEFAULT FALSE | Sans préalable (cas exceptionnel) | FALSE |
| `motif_urgence` | TEXT | | Motif urgence (si sans préalable) | 'Incident critique' |
| `dates_realisees` | DATE[] | NOT NULL | Dates réalisées (array) | ['2024-12-20', '2024-12-23'] |
| `heures_realisees` | JSONB | NOT NULL | Détail heures par jour | Voir structure ci-dessous |
| `total_heures` | NUMERIC(5,2) | NOT NULL, CHECK > 0 | Total heures réalisées | 12.25 |
| `pointages_gta` | JSONB | | Pointages GTA officiels | Voir structure ci-dessous |
| `ecarts_vs_prealable` | JSONB | | Écarts vs préalable (si avec préalable) | Voir structure ci-dessous |
| `justification_ecarts` | TEXT | | Justification des écarts | 'Client a appelé après 22h' |
| `statut_code` | VARCHAR(50) | NOT NULL, FK → statut | Statut actuel | 'en_validation' |
| `etape_actuelle` | INTEGER | NOT NULL DEFAULT 1 | Numéro étape workflow | 4 |
| `date_creation` | TIMESTAMP | DEFAULT NOW() | Date création | '2024-12-28 09:00:00' |
| `date_modification` | TIMESTAMP | DEFAULT NOW() | Date modification | '2024-12-29 10:00:00' |
| `date_soumission` | TIMESTAMP | | Date soumission | '2024-12-28 09:30:00' |
| `date_cloture` | TIMESTAMP | | Date clôture (paiement) | '2024-12-31 09:30:00' |
| `code_agent_creation` | VARCHAR(50) | FK → agent | Agent créateur | 'AG001' |
| `code_agent_modification` | VARCHAR(50) | FK → agent | Dernier modificateur | 'AG001' |
| `est_supprime` | BOOLEAN | DEFAULT FALSE | Soft delete | FALSE |
| `motif_suppression` | TEXT | | Motif suppression | NULL |
| `commentaire_suppression` | TEXT | | Commentaire suppression | NULL |
| `code_agent_suppression` | VARCHAR(50) | FK → agent | Agent suppresseur | NULL |
| `date_suppression` | TIMESTAMP | | Date suppression | NULL |

**Structure JSONB `heures_realisees`** :
```json
{
  "2024-12-20": {
    "debut": "18:00",
    "fin": "22:00",
    "nb_heures": 4
  },
  "2024-12-23": {
    "debut": "18:00",
    "fin": "22:15",
    "nb_heures": 4.25
  },
  "2024-12-24": {
    "debut": "18:00",
    "fin": "22:00",
    "nb_heures": 4
  }
}
```

**Structure JSONB `pointages_gta`** :
```json
{
  "2024-12-20": {
    "entree": "09:00",
    "sortie": "22:15"
  },
  "2024-12-23": {
    "entree": "09:00",
    "sortie": "22:15"
  },
  "2024-12-24": {
    "entree": "09:00",
    "sortie": "22:05"
  }
}
```

**Structure JSONB `ecarts_vs_prealable`** :
```json
{
  "2024-12-20": {
    "ecart": 0,
    "justification": null
  },
  "2024-12-23": {
    "ecart": 0.25,
    "justification": "Client a appelé après 22h"
  },
  "2024-12-24": {
    "ecart": 0,
    "justification": null
  }
}
```

### 2.3. Colonnes Transverses (via tables dédiées)

#### Table `piece_jointe`
| Colonne | Type | Description |
|---------|------|-------------|
| `id` | SERIAL | PK |
| `type_demande` | VARCHAR(50) | 'heures_sup_prealable' ou 'heures_sup_realisation' |
| `demande_id` | INTEGER | ID préalable ou réalisation |
| `nom_fichier` | VARCHAR(255) | Nom fichier |
| `chemin_fichier` | VARCHAR(500) | Chemin stockage |
| `type_mime` | VARCHAR(100) | Type MIME |
| `type_document` | VARCHAR(50) | 'justificatif', 'pointage_gta', 'declaration' |

---

## 3. Identification du Workflow

### 3.1. Workflow DEMANDE PRÉALABLE

**Nom des fichiers analysés** :
- `dmd-heure-perso.png` : Vue collaborateur
- `dmd-heure-manager.png` : Vue manager
- `visu-dmd-heure-perso-wait-manager.png` : En attente manager
- `visu-dmd-heure-perso-wait-rh.png` : En attente RH
- `visu-dmd-heure-perso-valid.png` : Validée
- `visu-dmd-heure-perso-refused.png` : Refusée
- `visu-dmd-heure-perso-closed.png` : Clôturée

#### Workflow Étape par Étape :

```
ÉTAPE 1: Création (BROUILLON)
├─ Action: Collaborateur crée la demande préalable
├─ Statut: brouillon
├─ Étape: 1
├─ Champs: Tous les champs remplissables
└─ Validations: Aucune

ÉTAPE 2: Soumission (SOUMIS)
├─ Action: Collaborateur soumet la demande
├─ Statut: soumis
├─ Étape: 2
├─ Validations créées: Manager (étape 3) + RH (étape 4)
└─ Notifications: Manager notifié

ÉTAPE 3: Validation Manager (EN_VALIDATION)
├─ Action: Manager valide ou refuse
├─ Statut: en_validation (si valide) ou refuse (si refusé)
├─ Étape: 3
├─ Rôle validateur: manager
├─ Conditions: 
│   ├─ Si VALIDE → Passage étape 4 (Notification RH)
│   └─ Si REFUSE → Statut = refuse, Clôture
└─ Notifications: 
    ├─ Si valide → RH notifié
    └─ Si refusé → Demandeur notifié

ÉTAPE 4: Validation RH (EN_VALIDATION)
├─ Action: RH valide ou refuse
├─ Statut: en_validation (si valide) ou refuse (si refusé)
├─ Étape: 4
├─ Rôle validateur: rh
├─ Conditions:
│   ├─ Si VALIDE → Statut = valide, Étape 5 (Approuvé)
│   └─ Si REFUSE → Statut = refuse, Clôture
└─ Notifications:
    ├─ Si valide → Demandeur notifié (préalable approuvé)
    └─ Si refusé → Demandeur notifié (refusé)

ÉTAPE 5: Approuvé (VALIDE)
├─ Action: Préalable approuvé - Réalisation possible
├─ Statut: valide
├─ Étape: 5
├─ Résultat: Le collaborateur peut maintenant créer une réalisation liée
└─ Lien possible: Création heures_sup_realisation avec heures_sup_prealable_id
```

**Diagramme Workflow Préalable** :
```
[1. Brouillon] → [2. Soumis] → [3. Manager] → [4. RH] → [5. Validé]
                                              ↓           ↓
                                           [Refusé]   [Approuvé]
```

### 3.2. Workflow RÉALISATION

**Nom des fichiers analysés** :
- `saisie-heure-real-collab.png` : Saisie collaborateur
- `saisie-heure-real-wait-mana.png` : En attente manager
- `saisie-heure-real-manager.png` : Vue manager
- `saisie-heure-real-manager-valid.png` : Validée par manager
- `saisie-heure-real-manager-refused.png` : Refusée par manager
- `saisie-heure-real-manager-wait-rh.png` : Manager validé, attente RH
- `saisie-heure-real-wait-rh.png` : En attente RH
- `saisie-heure-real-valid.png` : Validée
- `saisie-heure-real-refused.png` : Refusée
- `pointage-heure-real-rh.png` : Pointage RH
- `pointage-heure-real-rh-valid.png` : Pointage RH validé
- `pointage-heure-real-rh-refused.png` : Pointage RH refusé

#### Workflow Étape par Étape :

```
ÉTAPE 1: Création (BROUILLON)
├─ Action: Collaborateur crée la saisie réalisation
├─ Statut: brouillon
├─ Étape: 1
├─ Champs: 
│   ├─ Lien préalable (si avec_prealable = TRUE)
│   ├─ Dates réalisées
│   ├─ Heures réalisées (détail par jour)
│   ├─ Pointages GTA
│   └─ Justifications écarts
└─ Validations: Aucune

ÉTAPE 2: Soumission (SOUMIS)
├─ Action: Collaborateur soumet la réalisation
├─ Statut: soumis
├─ Étape: 2
├─ Validations créées: Manager (étape 3) + RH (étape 4) + Pointage RH (étape 5)
└─ Notifications: Manager notifié

ÉTAPE 3: Validation Manager (EN_VALIDATION)
├─ Action: Manager valide ou refuse
├─ Statut: en_validation (si valide) ou refuse (si refusé)
├─ Étape: 3
├─ Rôle validateur: manager
├─ Vérifications Manager:
│   ├─ Cohérence heures réalisées
│   ├─ Pointages GTA plausibles
│   └─ Justifications écarts (si avec préalable)
├─ Conditions:
│   ├─ Si VALIDE → Passage étape 4 (Notification RH)
│   └─ Si REFUSE → Statut = refuse, Clôture
└─ Notifications:
    ├─ Si valide → RH notifié
    └─ Si refusé → Demandeur notifié

ÉTAPE 4: Validation RH (EN_VALIDATION)
├─ Action: RH valide ou refuse
├─ Statut: en_validation (si valide) ou refuse (si refusé)
├─ Étape: 4
├─ Rôle validateur: rh
├─ Vérifications RH:
│   ├─ Conformité réglementaire
│   ├─ Vérification préalable (si existe)
│   └─ Analyse globale
├─ Conditions:
│   ├─ Si VALIDE → Passage étape 5 (Notification Pointage RH)
│   └─ Si REFUSE → Statut = refuse, Clôture
└─ Notifications:
    ├─ Si valide → Pointage RH notifié
    └─ Si refusé → Demandeur notifié

ÉTAPE 5: Pointage RH (EN_VALIDATION)
├─ Action: RH effectue le pointage final et réconciliation GTA
├─ Statut: en_validation
├─ Étape: 5
├─ Rôle validateur: pointage_rh
├─ Actions Pointage RH:
│   ├─ Réconciliation avec données GTA
│   ├─ Vérification pointages officiels
│   ├─ Validation données de paiement
│   └─ Commentaire pointage
├─ Conditions:
│   ├─ Si VALIDE → Statut = clos, Étape 6 (Paiement programmé)
│   └─ Si REFUSE → Statut = refuse, Clôture
└─ Notifications:
    ├─ Si valide → Demandeur notifié (paiement programmé)
    └─ Si refusé → Demandeur notifié (refus pointage)

ÉTAPE 6: Clôture (CLOS)
├─ Action: Paiement programmé
├─ Statut: clos
├─ Étape: 6
├─ Résultat: Les heures sont validées et le paiement sera effectué
└─ Lien préalable: Si avec préalable, le préalable peut être marqué comme "utilisé"
```

**Diagramme Workflow Réalisation** :
```
[1. Brouillon] → [2. Soumis] → [3. Manager] → [4. RH] → [5. Pointage RH] → [6. Clos]
                                          ↓       ↓           ↓
                                       [Refusé] [Refusé]   [Refusé]
                                                    ↓
                                            [Paiement programmé]
```

### 3.3. Cas Particuliers Identifiés

#### **Réalisation SANS Préalable** (Cas Exceptionnel)
- `sans_prealable` = TRUE
- `motif_urgence` obligatoire
- Workflow identique mais avec justification supplémentaire requise
- Peut être accepté ou refusé selon urgence justifiée

#### **Écarts vs Préalable**
- Si `avec_prealable` = TRUE
- Comparaison automatique heures prévues vs réalisées
- Champs `ecarts_vs_prealable` JSONB pour détails
- Justification obligatoire si écart significatif

---

## 4. Schéma de Validation avec Étapes

### 4.1. Table `validation_etape` pour Préalable

| demande_id | workflow_etape_id | etape_workflow | role_validation | ordre | statut_validation |
|------------|-------------------|----------------|-----------------|-------|-------------------|
| 1 | WE-3 | 3 | manager | 1 | en_attente / valide / refuse |
| 1 | WE-4 | 4 | rh | 2 | en_attente / valide / refuse |

### 4.2. Table `validation_etape` pour Réalisation

| demande_id | workflow_etape_id | etape_workflow | role_validation | ordre | statut_validation |
|------------|-------------------|----------------|-----------------|-------|-------------------|
| 2 | WE-3 | 3 | manager | 1 | en_attente / valide / refuse |
| 2 | WE-4 | 4 | rh | 2 | en_attente / valide / refuse |
| 2 | WE-5 | 5 | pointage_rh | 3 | en_attente / valide / refuse |

---

## 5. Règles Métier Identifiées

### 5.1. Préalable
- ✅ `nb_heures_total` doit être > 0
- ✅ `date_fin` >= `date_debut`
- ✅ Validation Manager obligatoire avant RH
- ✅ Si refusé à une étape, arrêt workflow
- ✅ Si validé, statut = 'valide', réalisation possible

### 5.2. Réalisation
- ✅ Si `avec_prealable` = TRUE, `heures_sup_prealable_id` obligatoire
- ✅ Si `sans_prealable` = TRUE, `motif_urgence` obligatoire
- ✅ `total_heures` doit être > 0
- ✅ `dates_realisees` non vide
- ✅ Si avec préalable, calcul automatique des écarts
- ✅ Pointage RH obligatoire avant clôture

### 5.3. Lien Préalable ↔ Réalisation
- ✅ Une réalisation peut être liée à un préalable
- ✅ Un préalable peut avoir plusieurs réalisations (si réparti sur plusieurs périodes)
- ✅ Réconciliation automatique des heures

---

## 6. Dashboards Identifiés

### 6.1. Dashboard Collaborateur
- Vue : `dashboard-heure-collab.png`, `dashboard-heure-real-collab.png`
- Contenu :
  - Mes demandes préalables (par statut)
  - Mes réalisations (par statut)
  - Actions à faire

### 6.2. Dashboard Manager
- Vue : `dashboard-heure-manager.png`, `dashboard-heure-real-manager.png`
- Contenu :
  - Validations en attente (équipe)
  - Vue globale équipe
  - Statistiques

### 6.3. Dashboard RH
- Vue : `dashboard-heure-rh.png`, `dashboard-heure-real-rh.png`
- Contenu :
  - Toutes les demandes à valider/pointer
  - Pointages à effectuer
  - Vue consolidée

---

## 7. Résumé des Colonnes par Table

### Table `heures_sup_prealable` (20 colonnes)
- Identifiant : id (SERIAL)
- Agents : code_agent_demandeur, code_agent_concerne, code_agent_creation, code_agent_modification
- Dates période : date_debut, date_fin, jours_semaine[]
- Heures : nb_heures_total (NUMERIC), heures_detaillees (JSONB), horaires_previsionnels
- Justification : motif (TEXT), dossier_lie
- Workflow : statut_code, etape_actuelle
- Dates système : date_creation, date_modification, date_soumission, date_cloture
- Soft delete : est_supprime, motif_suppression, commentaire_suppression, code_agent_suppression, date_suppression

### Table `heures_sup_realisation` (24 colonnes)
- Identifiant : id (SERIAL)
- Lien : heures_sup_prealable_id (FK)
- Agents : code_agent_demandeur, code_agent_concerne, code_agent_creation, code_agent_modification
- Type : avec_prealable, sans_prealable, motif_urgence
- Réalisation : dates_realisees (DATE[]), heures_realisees (JSONB), total_heures (NUMERIC)
- Pointages : pointages_gta (JSONB)
- Écarts : ecarts_vs_prealable (JSONB), justification_ecarts
- Workflow : statut_code, etape_actuelle
- Dates système : date_creation, date_modification, date_soumission, date_cloture
- Soft delete : est_supprime, motif_suppression, commentaire_suppression, code_agent_suppression, date_suppression

---

## 8. Workflow Complet Synthétisé

### Préalable : 5 étapes
1. **Brouillon** (statut: brouillon)
2. **Soumis** (statut: soumis) → Notification Manager
3. **Validation Manager** (statut: en_validation) → Notification RH si valide, Demandeur si refusé
4. **Validation RH** (statut: en_validation) → Statut = valide si approuvé, refuse si refusé
5. **Approuvé** (statut: valide) → Réalisation possible

### Réalisation : 6 étapes
1. **Brouillon** (statut: brouillon)
2. **Soumis** (statut: soumis) → Notification Manager
3. **Validation Manager** (statut: en_validation) → Notification RH si valide, Demandeur si refusé
4. **Validation RH** (statut: en_validation) → Notification Pointage RH si valide, Demandeur si refusé
5. **Pointage RH** (statut: en_validation) → Statut = clos si validé, refuse si refusé
6. **Clos** (statut: clos) → Paiement programmé

---

**Document créé le** : 2024  
**Version** : 1.0  
**Basé sur** : Analyse maquettes HeureSup/

