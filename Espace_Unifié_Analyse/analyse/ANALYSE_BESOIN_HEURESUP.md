# Analyse des Besoins - Module Heures Supplémentaires (HeureSup)

## 📋 Table des Matières

1. [Contexte et Objectifs](#contexte-et-objectifs)
2. [Acteurs et Rôles](#acteurs-et-rôles)
3. [Fonctionnalités Principales](#fonctionnalités-principales)
4. [Workflow de Validation](#workflow-de-validation)
5. [États et Statuts](#états-et-statuts)
6. [Cas d'Usage Détaillés](#cas-dusage-détaillés)
7. [Composants et Interface Utilisateur](#composants-et-interface-utilisateur)
8. [Règles Métier](#règles-métier)
9. [Besoins Techniques](#besoins-techniques)
10. [Priorités d'Implémentation](#priorités-dimplémentation)

---

## Contexte et Objectifs

### Objectif Général

Le module **Heures Supplémentaires (HeureSup)** permet aux agents URSSAF de saisir, suivre et valider leurs heures supplémentaires au travers d'un workflow hiérarchique (Collaborateur → Manager → RH).

### Problématiques Résolues

- ✅ **Centralisation** : Toutes les demandes d'heures supplémentaires dans un seul espace
- ✅ **Traçabilité** : Historique complet des saisies et validations
- ✅ **Transparence** : Visibilité claire sur l'état d'avancement de chaque demande
- ✅ **Validation hiérarchique** : Circuit de validation structuré et automatique
- ✅ **Motivation des refus** : Obligation de justifier un refus
- ✅ **Communication** : Système de commentaires et notifications

### Bénéfices Attendus

- **Gain de temps** : Réduction de 60% du temps de traitement des heures supp
- **Conformité** : Respect des contraintes légales sur les heures supplémentaires
- **Autonomie** : Les collaborateurs peuvent consulter l'état de leurs demandes en temps réel
- **Traçabilité** : Audit trail complet pour la conformité et la gestion RH

---

## Acteurs et Rôles

### 👤 Collaborateur

**Profil** : Agent URSSAF déclarant des heures supplémentaires

**Permissions** :
- Saisir ses heures réelles et supplémentaires
- Consulter l'état de ses demandes
- Voir l'historique complet de ses heures
- Annuler une demande en attente (soumis à validation)

**Tableaux de bord** :
- Dashboard personnel des heures (`dashboard-heure-collab.png`)
- Vue des heures réelles (`dashboard-heure-real-collab.png`)

### 👔 Manager

**Profil** : Responsable hiérarchique en charge de valider les heures de son équipe

**Permissions** :
- Consulter toutes les demandes de son équipe
- Valider ou refuser les demandes de collaborateurs
- Ajouter un commentaire avant validation
- Motiver un refus
- Consulter les statistiques de son équipe

**Tableaux de bord** :
- Dashboard équipe (`dashboard-heure-manager.png`)
- Vue des heures réelles équipe (`dashboard-heure-real-manager.png`)

### 🏢 RH

**Profil** : Service RH responsable de la validation finale et de la comptabilisation

**Permissions** :
- Consulter toutes les demandes de l'organisation
- Validation finale des heures supplémentaires
- Pointage et comptabilisation finale
- Visualisation des statistiques globales
- Export des données pour paie

**Tableaux de bord** :
- Dashboard global (`dashboard-heure-rh.png`)
- Vue des heures réelles globales (`dashboard-heure-real-rh.png`)

---

## Fonctionnalités Principales

### 1. Saisie des Heures

#### Interface de Saisie (`saisie-heure-real-collab.png`)

**Champs obligatoires** :
- **Date** : Date de la prestation
- **Heures normales** : Nombre d'heures travaillées normalement
- **Heures supplémentaires** : Nombre d'heures supplémentaires (optionnel)

**Caractéristiques** :
- Format numérique avec décimaux (ex: 3.5 heures)
- Validation côté client et serveur
- Calcul automatique du total (heures normales + heures supp)
- Enregistrement en historique

#### Formulaire

```typescript
interface DemandeHeure {
  id: string
  userId: string
  date: string
  heures: number                    // Heures normales
  heuresSup: number                 // Heures supplémentaires
  statut: StatutDemande             // Statut de la demande
  commentaire?: string              // Commentaire collaborateur
  motifRefus?: string               // Motif du refus (si refusé)
  createdAt: string                 // Date de création
  updatedAt: string                 // Date de dernière modification
}
```

### 2. Workflow de Validation

Le workflow suit un circuit hiérarchique à **3 niveaux** :

```
Collaborateur → Manager → RH → Comptabilisation
```

**Étapes détaillées** :

1. **Saisie par le Collaborateur**
   - Statut initial : `en_attente_manager`
   - Notification automatique au manager

2. **Validation Manager**
   - Option 1 : Validation ✅
     - Statut : `en_attente_rh`
     - Notification RH
   - Option 2 : Refus ❌
     - Statut : `refuse`
     - Motif obligatoire
     - Notification collaborateur

3. **Validation RH**
   - Option 1 : Validation finale ✅
     - Statut : `valide`
     - Comptabilisation pour la paie
     - Notification collaborateur
   - Option 2 : Refus ❌
     - Statut : `refuse`
     - Motif obligatoire
     - Notification collaborateur

4. **Clôture**
   - Statut : `cloture`
   - Traitement terminé

### 3. Visualisation des Demandes

Chaque acteur voit ses demandes avec un affichage adapté :

#### Badges de Statut

Affichage visuel du statut avec badges colorés :
- 🟡 **En attente** : Badge jaune
- 🟢 **Validé** : Badge vert
- 🔴 **Refusé** : Badge rouge
- ⚫ **Clôturé** : Badge gris

#### États Visuels par Acteur

**Collaborateur** :
- `visu-dmd-heure-collab-wait-manager.png` - En attente manager
- `visu-dmd-heure-collab-wait-rh-manager.png` - En attente RH après validation manager
- `visu-dmd-heure-collab-wait-rh.png` - En attente RH
- `visu-dmd-heure-collab-valid-manager.png` - Validé par manager
- `visu-dmd-heure-collab-valid-rh.png` - Validé par RH
- `visu-dmd-heure-collab-refus-manager.png` - Refusé par manager
- `visu-dmd-heure-collab-refused-rh.png` - Refusé par RH
- `visu-dmd-heure-collab-closed-manager.png` - Clôturé
- `visu-dmd-heure-collab-closed-rh.png` - Clôturé

**Manager** :
- Visualisation équipe avec filtres
- Actions de validation en masse

**RH** :
- Vue globale de l'organisation
- Statistiques et reporting

### 4. Actions sur les Demandes

#### Commentaires (`heures-supp-popup-comment.png`)

Tous les acteurs peuvent ajouter des commentaires à une demande :
- **Collaborateur** : Justification ou contexte
- **Manager** : Notes pour équipe ou RH
- **RH** : Instructions ou décisions

#### Motifs de Refus (`refus-heures-popup.png`)

**Obligatoire** lors d'un refus :
- Champs texte libre
- Historique conservé dans la demande
- Motif visible par le demandeur

#### Annulation (`cancel-hsupp-popup.png`)

**Collaborateur** peut annuler :
- Uniquement si statut `en_attente_manager` (pas encore traité)
- Confirmation requise
- Notification manager
- Historique conservé

#### Transmission de Dossier (`transmettre-dossier-popup.png`)

**Manager/RH** peut transmettre :
- Vers un autre service
- Avec historique complet
- Notifications automatiques

### 5. Recherche et Filtres

**Filtres disponibles** :
- Par période (date de début / fin)
- Par statut
- Par collaborateur (Manager/RH uniquement)
- Recherche textuelle

### 6. Pointages RH (`pointage-heure-real-rh.png`)

**RH** peut :
- Consulter tous les pointages
- Valider ou refuser les pointages (`pointage-heure-real-rh-valid.png` / `pointage-heure-real-rh-refused.png`)
- Effectuer la comptabilisation finale

---

## Workflow de Validation

### Workflow Complet

```
┌─────────────────────────────┐
│   Collaborateur : Saisie    │
│   Statut: en_attente_man    │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│    Manager : Décision       │
│    ✓ Valide  /  ✗ Refuse   │
└────────────┬────────────────┘
             │
      ┌──────┴──────┐
      │             │
      ▼             ▼
┌─────────┐    ┌──────────┐
│ Valide  │    │  Refuse  │
│→ att RH │    │→ FIN     │
└────┬────┘    └──────────┘
     │
     ▼
┌─────────────────────────────┐
│     RH : Validation Finale  │
│     ✓ Valide  /  ✗ Refuse   │
└────────────┬────────────────┘
             │
      ┌──────┴──────┐
      │             │
      ▼             ▼
┌─────────┐    ┌──────────┐
│ Validé  │    │  Refusé  │
│→ Closed │    │→ FIN     │
└────┬────┘
     │
     ▼
┌─────────┐
│ Cloturé │
└─────────┘
```

### Détails par Statut

| Statut | Définition | Peut être modifié par | Actions possibles |
|--------|------------|----------------------|-------------------|
| `en_attente_manager` | Soumis par collaborateur | Collaborateur (annuler) | Manager : Valider/Refuser |
| `en_attente_rh` | Validé par manager | - | RH : Valider/Refuser |
| `valide` | Validé par RH | RH | RH : Clôturer |
| `refuse` | Refusé (manager ou RH) | - | Consultable uniquement |
| `cloture` | Traitement terminé | - | Consultation historique |

---

## États et Statuts

### Type de Statut

```typescript
export type StatutDemande = 
  | 'en_attente_manager'   // En attente de validation manager
  | 'en_attente_rh'        // En attente de validation RH
  | 'valide'               // Validé
  | 'refuse'               // Refusé
  | 'cloture'              // Clôturé
```

### Affichage des Statuts

#### Collaborateur (`heures-status-collab.png`)

- Badges de statut selon l'état de la demande
- Indicateur visuel du circuit de validation en cours

#### Manager/RH (`heures-status-manager-rh.png`)

- Vue agrégée des demandes de l'équipe
- Indicateur de charge de travail (nombre de demandes en attente)

#### Heures Réelles

- **Collaborateur** : `heures-status-reel-collab.png`
- **RH** : `heures-status-reel-rh.png`
- Affichage des heures réelles vs prévues

---

## Cas d'Usage Détaillés

### Cas 1 : Nouvelle Saisie d'Heures Supplémentaires

**Acteur** : Collaborateur

**Scénario** :
1. Collaborateur clique sur "Nouvelle demande"
2. Formulaire s'affiche (`saisie-heure-real-collab.png`)
3. Saisie :
   - Date : 15/12/2024
   - Heures normales : 7h
   - Heures supp : 2h
4. Clique sur "Soumettre"
5. **Résultat** :
   - Demande créée avec statut `en_attente_manager`
   - Notification envoyée au manager
   - Message de confirmation affiché

**Interface** : `saisie-heure-real-collab.png`

### Cas 2 : Validation Manager

**Acteur** : Manager

**Scénario 2A : Validation**
1. Manager consulte son tableau de bord
2. Voit la demande en attente
3. Clique sur "Valider"
4. Optionnel : Ajoute un commentaire (`heures-supp-popup-comment.png`)
5. **Résultat** :
   - Statut passe à `en_attente_rh`
   - Notification RH
   - Notification collaborateur

**Scénario 2B : Refus**
1. Manager consulte la demande
2. Clique sur "Refuser"
3. **Motif obligatoire** (`refus-heures-popup.png`)
4. Saisie du motif : "Heures non justifiées"
5. **Résultat** :
   - Statut passe à `refuse`
   - Motif envoyé au collaborateur
   - Demande clôturée pour le manager

**Interface Manager** : `saisie-heure-real-manager.png`, `saisie-heure-real-manager-valid.png`, `saisie-heure-real-manager-refused.png`

### Cas 3 : Annulation par le Collaborateur

**Acteur** : Collaborateur

**Scénario** :
1. Collaborateur consulte ses demandes
2. Voit une demande en `en_attente_manager`
3. Clique sur "Annuler" (`cancel-hsupp-popup.png`)
4. Confirmation requise
5. **Résultat** :
   - Demande supprimée ou archivée
   - Notification annulation au manager

**Interface** : `cancel-hsupp-popup.png`

### Cas 4 : Validation RH et Pointage

**Acteur** : RH

**Scénario** :
1. RH consulte le dashboard global
2. Voit toutes les demandes en `en_attente_rh`
3. Consulte les pointages (`pointage-heure-real-rh.png`)
4. **Validation finale** :
   - Valide les heures supplémentaires
   - Effectue le pointage final
   - Clôture la demande
5. **Résultat** :
   - Statut : `valide` puis `cloture`
   - Heures comptabilisées pour la paie
   - Notification collaborateur

**Interface** : `pointage-heure-real-rh.png`, `pointage-heure-real-rh-valid.png`, `pointage-heure-real-rh-refused.png`

### Cas 5 : Consultation de l'Historique

**Acteur** : Collaborateur / Manager / RH

**Scénario** :
1. Accès à l'historique des demandes
2. Filtres par période, statut, agent
3. Recherche textuelle
4. Export possible (Excel/PDF)

**Interface** : Dashboard avec tableaux de données

---

## Composants et Interface Utilisateur

### Composants Principaux

#### 1. Formulaire de Saisie

**Fichier** : `saisie-heure-real-collab.png`

**Composants** :
- Champ date (picker de calendrier)
- Champ heures normales (input numérique)
- Champ heures supp (input numérique)
- Bouton Soumettre
- Bouton Annuler

#### 2. Badges de Statut

**Fichier** : `badge-status.png`

**Code** :
```tsx
<Badge
  className={
    statut === 'valide'
      ? 'bg-green-100 text-green-800'
      : statut === 'refuse'
      ? 'bg-red-100 text-red-800'
      : statut.startsWith('en_attente')
      ? 'bg-yellow-100 text-yellow-800'
      : 'bg-gray-100 text-gray-800'
  }
>
  {statut.replace('_', ' ')}
</Badge>
```

#### 3. Popups / Modals

**Commentaire** : `heures-supp-popup-comment.png`
- Champ texte multi-lignes
- Bouton Enregistrer
- Bouton Annuler

**Motif de refus** : `refus-heures-popup.png`
- Champ texte (obligatoire)
- Bouton Valider le refus
- Bouton Annuler

**Annulation** : `cancel-hsupp-popup.png`
- Message de confirmation
- Bouton Confirmer
- Bouton Annuler

#### 4. Collapsible (Affichage conditionnel)

**Info utilisateur** : `collapsible-user-info.png`
- Informations sur l'agent (nom, service, etc.)

**Info demande** : `collapsible-demande-info.png`
- Détails de la demande (date de création, dernier modifié, etc.)

**Pointages agent** : `collapsible-pointages-agent.png`
- Pointages personnels

**Pointages généraux** : `collapsible-pointages.png`
- Pointages de l'équipe ou global

#### 5. Delta Heures

**Composant** : `delta-hours.png`

Affichage de la différence entre :
- Heures prévues
- Heures réelles
- Delta (positif/négatif)

#### 6. Tables de Données

**Composant** : `Table.png`

Fonctionnalités :
- Tri par colonne
- Filtrage
- Recherche
- Pagination
- Export Excel/PDF

### Conteneurs Standards

**Date Container** : `date container.png`
- Sélecteur de date standardisé

**Partner Container** : `Partner container.png`
- Gestion des prestataires

---

## Règles Métier

### Règle 1 : Validation Hiérarchique Obligatoire

**Description** : Les heures supplémentaires doivent passer par manager ET RH
**Exception** : Aucune
**Contrainte** : Impossible de contourner un niveau

### Règle 2 : Motif de Refus Obligatoire

**Description** : Un refus doit TOUJOURS être motivé
**Validation** : Champ motif ne peut pas être vide
**Audit** : Motif enregistré dans l'historique

### Règle 3 : Annulation par Collaborateur

**Description** : Un collaborateur peut annuler SA propre demande
**Condition** : Uniquement si statut = `en_attente_manager`
**Action** : Impossible d'annuler si déjà traité par manager

### Règle 4 : Notification Systématique

**Description** : Notification à chaque changement de statut
**Destinataires** :
- Collaborateur : Tous les changements
- Manager : Nouvelles demandes de son équipe
- RH : Demandes validées par manager

### Règle 5 : Traçabilité Complète

**Description** : Toutes les actions sont tracées
**Enregistrement** :
- Date/heure
- Acteur
- Action
- Statut avant/après
- Commentaire (si applicable)

### Règle 6 : Validation des Heures

**Description** : Format numérique avec décimales
**Contrainte** : Min 0, Max 24h par jour
**Précision** : 0.5 heure (30 min)

### Règle 7 : Décompte Delta

**Description** : Calcul automatique du total
**Formule** : Total = Heures normales + Heures supp
**Affichage** : Indicateur visuel du delta (`delta-hours.png`)

### Règle 8 : Délais de Validation

**Description** : (À définir avec RH)
**Suggestion** :
- Manager : 3 jours ouvrés
- RH : 5 jours ouvrés
**Action** : Rappel automatique si dépassé

---

## Besoins Techniques

### Architecture

#### Base de Données

**Table** : `heures_sup`

```sql
CREATE TABLE heures_sup (
  id VARCHAR PRIMARY KEY,
  user_id VARCHAR NOT NULL,
  date DATE NOT NULL,
  heures DECIMAL(4,2) NOT NULL,       -- Heures normales
  heures_sup DECIMAL(4,2) NOT NULL,   -- Heures supplémentaires
  statut VARCHAR NOT NULL,
  commentaire TEXT,
  motif_refus TEXT,
  created_at TIMESTAMP,
  updated_at TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);
```

**Index** :
- `user_id` + `date` : Recherche rapide
- `statut` : Filtrage par état
- `created_at` : Tri chronologique

#### API Endpoints

**Collaborateur** :
- `GET /api/heures` - Liste des demandes
- `POST /api/heures` - Créer une demande
- `PUT /api/heures/:id` - Modifier (si en attente)
- `DELETE /api/heures/:id` - Annuler (si en attente)

**Manager** :
- `GET /api/heures/equipe` - Demandes de l'équipe
- `PUT /api/heures/:id/valider` - Valider
- `PUT /api/heures/:id/refuser` - Refuser avec motif

**RH** :
- `GET /api/heures/all` - Toutes les demandes
- `PUT /api/heures/:id/valider` - Validation finale
- `PUT /api/heures/:id/cloturer` - Clôturer
- `GET /api/heures/stats` - Statistiques

#### Notifications

**Système** : Notification push ou email

**Cas de notification** :
1. Nouvelle demande → Manager
2. Validation manager → RH et Collaborateur
3. Refus manager → Collaborateur
4. Validation RH → Collaborateur
5. Refus RH → Collaborateur
6. Clôture → Collaborateur

### Sécurité

#### Permissions par Rôle

```typescript
const permissions = {
  collaborateur: {
    read: ['own_heures'],
    write: ['create_heures', 'edit_pending_heures'],
    delete: ['delete_pending_heures']
  },
  manager: {
    read: ['equipe_heures'],
    write: ['validate_heures', 'refuse_heures', 'comment_heures']
  },
  rh: {
    read: ['all_heures'],
    write: ['validate_heures', 'refuse_heures', 'close_heures']
  }
}
```

#### Validation Côté Serveur

- Tous les champs obligatoires vérifiés
- Format des heures validé
- Permissions vérifiées à chaque action
- Protection CSRF

### Performance

#### Optimisation

- **Lazy loading** : Chargement progressif des demandes
- **Pagination** : 20 demandes par page
- **Cache** : Cache Redis pour statistiques
- **Index DB** : Index optimisés pour les requêtes fréquentes

#### Monitoring

- Temps de réponse des APIs
- Taux de validation/refus
- Volume de demandes par période
- Alertes si dépassement de seuils

---

## Priorités d'Implémentation

### Phase 1 : MVP (Minimum Viable Product) 🔴 CRITIQUE

**Objectif** : Fonctionnelité de base opérationnelle

**Fonctionnalités** :
1. ✅ Saisie des heures (Collaborateur)
2. ✅ Affichage des demandes avec statuts
3. ✅ Workflow de validation Manager → RH
4. ✅ Badges de statut visuels
5. ✅ Motif de refus obligatoire
6. ✅ Notifications de base

**Durée estimée** : 2 semaines

### Phase 2 : Enrichissement 🟡 IMPORTANT

**Objectif** : Améliorer l'expérience utilisateur

**Fonctionnalités** :
1. Système de commentaires
2. Annulation par collaborateur
3. Recherche et filtres avancés
4. Dashboard avec statistiques
5. Export Excel/PDF

**Durée estimée** : 1 semaine

### Phase 3 : Optimisation 🟢 SOUHAITABLE

**Objectif** : Performance et fonctionnalités avancées

**Fonctionnalités** :
1. Validation en masse (Manager)
2. Rappels automatiques par email
3. Historique complet avec audit trail
4. Dashboard RH avec KPI
5. Intégration paie (export automatique)

**Durée estimée** : 1 semaine

### Phase 4 : Analytics et Reporting 🔵 FUTUR

**Objectif** : Pilotage par les données

**Fonctionnalités** :
1. Statistiques détaillées (graphiques)
2. Tendances par période/service
3. Alertes préventives
4. Reporting avancé pour RH

**Durée estimée** : 1 semaine

---

## Conclusion

Le module **Heures Supplémentaires** est un composant central de l'Espace Unifié URSSAF. Il répond aux besoins critiques de :

✅ **Traçabilité** : Circuit de validation clair et auditable
✅ **Autonomie** : Collaborateurs suivent en temps réel
✅ **Conformité** : Respect des règles RH et légales
✅ **Efficacité** : Réduction du temps de traitement

### Points Clés à Retenir

1. **Workflow hiérarchique** : Collaborateur → Manager → RH
2. **Motif obligatoire** pour tous les refus
3. **Notifications systématiques** à chaque étape
4. **Traçabilité complète** pour audit
5. **Interface intuitive** adaptée à chaque rôle

### Prochaines Étapes

1. Validation des maquettes avec les utilisateurs finaux
2. Prototypage rapide de l'interface
3. Tests utilisateurs (collaborateurs, managers, RH)
4. Développement en phases selon priorités
5. Formation des utilisateurs

---

*Document généré à partir de l'analyse des maquettes et du code existant - Espace Unifié URSSAF*

