# Architecture Base de Données Modulaire

## Vision Architecture Modulaire vs Structure Unifiée

### Approche Modulaire (Nouvelle)
- **Tables dédiées par domaine** : `heures_sup`, `badge` (structure relationnelle)
- **Tables transverses** : `statut`, `traceabilite`, `piece_jointe`, `workflow_etape`
- **Avantages** : 
  - Structure plus claire et typée
  - Requêtes SQL plus simples
  - Intégrité référentielle forte
  - Performance améliorée (index sur colonnes réelles)

### Approche Unifiée (Actuelle)
- **Table générique** : `demande` avec JSONB flexible
- **Avantages** :
  - Extensible sans migration
  - Un seul modèle pour tous formulaires

## Architecture Modulaire Proposée

```
┌─────────────────────────────────────────────────────────────┐
│                    TABLES FONDAMENTALES                      │
├─────────────────────────────────────────────────────────────┤
│  agent, formulaire, organisation, service                   │
└─────────────────────────────────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
         ▼                ▼                ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  HEURES_SUP  │  │    BADGE     │  │  FORMULAIRE  │
│  (dédiée)    │  │  (dédiée)    │  │  (catalogue) │
└──────────────┘  └──────────────┘  └──────────────┘
         │                │
         └────────┬───────┘
                  │
    ┌─────────────┼─────────────┐
    ▼             ▼             ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│  STATUT  │ │ TRACABILITE│ │ PIECE_  │
│          │ │            │ │ JOINTE  │
└──────────┘ └──────────┘ └──────────┘
    │             │             │
    └─────────────┴─────────────┘
                  │
         ┌────────┴────────┐
         ▼                 ▼
  ┌──────────┐      ┌──────────┐
  │ VALIDATION│      │ WORKFLOW │
  │           │      │   ETAPE  │
  └──────────┘      └──────────┘
```

## Structure Détaillée

### 1. Tables Fondamentales

#### `agent`
Référence vers ANAIS (inchangé)

#### `formulaire`
Catalogue des formulaires (simplifié, sans JSONB complexe)

#### `organisation`, `service`
Tables référentielles pour organisation

### 2. Tables Domaines Métier

#### `heures_sup`
Table dédiée aux demandes d'heures supplémentaires avec :
- Colonnes spécifiques (pas JSONB)
- Type de demande (préalable, réalisation)
- Lien préalable ↔ réalisation explicite
- Pointages détaillés

#### `badge`
Table dédiée aux demandes de badges avec :
- Colonnes spécifiques par type
- Type badge (collab, perso, presta, autre)
- Informations collaborateur/prestataire

### 3. Tables Transverses

#### `statut`
Référentiel centralisé des statuts possibles

#### `traceabilite`
Table centralisée pour traçabilité de toutes les actions

#### `piece_jointe`
Table dédiée pour pièces jointes (séparée de document)

#### `workflow_etape`
Référentiel des étapes de workflow par formulaire

#### `validation_etape`
Gestion des validations avec étapes

#### `notification`
Notifications (inchangée)

## Avantages de cette Architecture

1. **Clarté** : Chaque domaine a sa table
2. **Performance** : Index sur colonnes réelles vs JSONB
3. **Intégrité** : Contraintes SQL natives
4. **Requêtes simples** : Pas de parsing JSONB
5. **Extensibilité** : Facile d'ajouter des tables pour nouveaux domaines

