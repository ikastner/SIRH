# Architecture Dashboard - Système Modulaire Complet

## 🎯 Vision globale

Une architecture en 3 couches pour une réutilisabilité maximale :

```
┌─────────────────────────────────────────────────────────────┐
│  EspaceUnifie_SIRH (Application principale)                │
│  ├── Pages (TDB, Applications, Page1)                      │
│  └── Layout (appLayoutComplete, favoris, footer, navbar)   │
└─────────────────────────────────────────────────────────────┘
                            ▼ utilise
┌─────────────────────────────────────────────────────────────┐
│  FRM_DemandeBadge_SIRH (Module métier)                     │
│  └── Composant TDB (Tableau de Bord complet)               │
└─────────────────────────────────────────────────────────────┘
                            ▼ utilise
┌─────────────────────────────────────────────────────────────┐
│  lib_component_SIRH (Bibliothèque réutilisable)            │
│  ├── statusBadge                                            │
│  ├── dashboardHeader                                        │
│  ├── roleTabs                                               │
│  ├── dashboardFilters                                       │
│  └── dashboardTable                                         │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Détail des composants

### Couche 1 : lib_component_SIRH (Briques de base)

**Composants atomiques réutilisables** :

1. **statusBadge** (`statusBadge.yaml`)
   - Badge de statut avec 4 variantes (warning/error/success/neutral)
   - Variables : `status`, `label`

2. **dashboardHeader** (`dashboardHeader.yaml`)
   - Header avec titre et breadcrumb
   - Variables : `title`, `breadcrumbIcon`, `breadcrumbText`

3. **roleTabs** (`roleTabs.yaml`)
   - Tabs de sélection de rôle avec état actif
   - Variables : `roles` (array), `activeRole`
   - Events : `onRoleClick`

4. **dashboardFilters** (`dashboardFilters.yaml`)
   - Container de filtres (recherche + 4 selects)
   - Events : `onSearch`, `onFilterChange`

5. **dashboardTable** (`dashboardTable.yaml`)
   - Tableau avec données dynamiques
   - Variables : `tableData` (array d'objets)
   - Events : `onRowClick`
   - **Utilise** : `statusBadge` pour chaque ligne

### Couche 2 : FRM_DemandeBadge_SIRH (Module métier)

**Composant TDB** (`TDB.yaml`)
- **Combine** tous les composants de lib_component_SIRH
- Structure complète du tableau de bord
- Variables : `title`, `breadcrumbText`, `tableData`
- Events : `onRoleChange`, `onRowClick`
- **Composition** :
  ```
  main.main-content
    └── section.dashboard-header-card
        ├── dashboardHeader
        └── roleTabs
    └── section.dashboard-content-card
        ├── dashboardFilters
        └── dashboardTable
  ```

### Couche 3 : EspaceUnifie_SIRH (Application finale)

**Page TDB** (`mobilePages/TDB.yaml`)
- **Utilise** : Composant TDB de FRM_DemandeBadge_SIRH
- **Layout** : appLayoutComplete (navbar, formulaires, modals)
- **Compléments** : favoris, footer
- **Données** : `badgesData` (9 demandes de test)
- **JavaScript** : Gestion dynamique du positionnement (main/footer)

## 🔗 Références de projet

### FRM_DemandeBadge_SIRH
```yaml
↓lib_component_ref [references.ProjectSchemaReference]: 
  projectName: lib_component_SIRH
```

### EspaceUnifie_SIRH
```yaml
↓lib_component_ref [references.ProjectSchemaReference]: 
  projectName: lib_component_SIRH
↓frm_badge_ref [references.ProjectSchemaReference]: 
  projectName: FRM_DemandeBadge_SIRH
```

## 📊 Format des données

**Structure d'un objet de tableau** :
```json
{
  "pourQui": "Victor Martin",
  "motif": "Accès spécifique",
  "siteEspace": "Acoss Montreuil WI",
  "locaux": "DSI La fabrique",
  "dateDemande": "01/05/2025",
  "statut": "En attente",
  "statutType": "warning"
}
```

**Types de statut disponibles** :
- `warning` → Badge orange "En attente"
- `error` → Badge rouge "Refusé"
- `success` → Badge vert "Validé"
- `neutral` → Badge gris "Clôturé"

## 🎨 Icônes copiées

**Dans les 3 projets** (`DisplayObjects/mobile/assets/dashboard/`) :
- `oeil.svg` - Icône "Voir"
- `icon25.svg` - Icône breadcrumb
- `icon26.svg` - Icône search
- `icon27.svg`, `icon28.svg`, `icon29.svg` - Icônes chevron
- `_24-px-calendar0.svg` - Icône calendrier

## 🚀 Utilisation

### Pour créer un nouveau tableau de bord (ex: Parking) :

1. **Dans lib_component_SIRH** : Pas de changement nécessaire (composants déjà créés)

2. **Dans FRM_Parking_SIRH** :
   ```yaml
   ↓TDB_Parking [ngx.components.UISharedRegularComponent]: 
     # Copier la structure de TDB.yaml
     # Adapter les variables (title, breadcrumbText)
   ```

3. **Dans EspaceUnifie_SIRH** :
   ```yaml
   ↓TDB_Parking [ngx.components.PageComponent]: 
     # Copier la structure de TDB.yaml
     # Changer le sharedcomponent vers FRM_Parking_SIRH.Application.NgxApp.TDB_Parking
     # Adapter les données (parkingData au lieu de badgesData)
   ```

## ✨ Avantages

1. **Réutilisabilité** : Composants atomiques réutilisables dans tous les tableaux de bord
2. **Maintenabilité** : Une modification dans lib_component_SIRH se répercute partout
3. **Modularité** : Chaque module métier (Badge, Parking, etc.) a son propre composant TDB
4. **Cohérence** : Design uniforme à travers toute l'application
5. **Testabilité** : Chaque composant peut être testé indépendamment

## 📋 Checklist de vérification

- ✅ Références de projet configurées (lib_component_SIRH, FRM_DemandeBadge_SIRH)
- ✅ Composants atomiques créés dans lib_component_SIRH
- ✅ Composant TDB créé dans FRM_DemandeBadge_SIRH
- ✅ Page TDB créée dans EspaceUnifie_SIRH
- ✅ Icônes copiées dans les 3 projets
- ✅ JSON de données sur une seule ligne (requis par Convertigo)
- ✅ IDs uniques et numériques uniquement
- ✅ Pas de lignes vides en fin de fichier

## 🔧 Prochaines étapes

1. Ouvrir les 3 projets dans Convertigo Studio
2. Tester la page TDB dans EspaceUnifie_SIRH
3. Vérifier que le tableau de bord s'affiche correctement
4. Adapter les couleurs/styles si nécessaire
5. Créer les composants pour les autres modules (Parking, Heures Supp, etc.)

---

**Version** : 1.0.0  
**Date** : Novembre 2025  
**Architecture** : Modulaire, réutilisable, maintenable

