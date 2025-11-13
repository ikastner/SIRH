# Résumé Atelier Espace Unifié SIRH

**Participants :** Dhaker SOUI, Youssoupha DIAKHATE, Romain ALEXANDRE  
**Durée :** ~1h01  
**Sujet :** Architecture et conception de l'Espace Unifié SIRH

---

## 1. Contexte du projet

### Objectif principal
Créer un **espace unifié SIRH** qui centralise tous les services RH pour les agents de l'URSSAF :
- Point d'entrée unique pour tous les outils et formulaires RH
- Regroupement des applications actuellement dispersées
- Expérience utilisateur cohérente et simplifiée

### Problématiques actuelles identifiées
- **Dispersion des outils** : les agents ne savent pas où trouver les services (canopée, GTA, pratique RH, etc.)
- **Navigation complexe** : besoin d'appeler les gestionnaires pour savoir où aller
- **Multiplicité des interfaces** : chaque outil a son propre design et ses propres accès
- **Manque de visibilité** : pas de vue consolidée des demandes à traiter (validations, backlog)

---

## 2. Architecture technique proposée

### 2.1 Trois approches possibles identifiées

#### ❌ Approche 1 : API inter-projets
- Créer des API pour chaque formulaire
- Consommer les API dans le projet global
- **Rejeté** : trop de complexité supplémentaire

#### ❌ Approche 2 : iFrames
- Embarquer les applications via iframes
- **Expérimenté mais déconseillé** par Dhaker :
  - Problèmes de cycle de vie (DOM chargé après iframe)
  - Risques de décalage d'UI
  - Aymen (expert Convertigo) a confirmé : "non, non, s'il te plaît, on fait pas ça"
  - Technologie des années 90-2000

#### ✅ Approche 3 : Shared Components (RETENUE)
- Utiliser des **composants partagés Convertigo**
- Créer un projet "compound UI" = Store de composants réutilisables
- Chaque formulaire = projet Convertigo avec ses propres transactions et séquences

---

### 2.2 Architecture modulaire retenue

```
Projet Espace_Unifie (Shell/Chapeau)
├── Pages principales
├── Navigation globale
└── Référencement des projets formulaires

Projet Compound_UI (Store de composants)
├── Composants de base (inputs, boutons, etc.)
└── Éléments UI réutilisables

Projet SIRH_Demande_Badge (Formulaire autonome)
├── Composants formulaire (récupère depuis Compound_UI)
├── Transactions backend
├── Séquences métier
└── Pages spécifiques

Projet SIRH_Heures_Sup (Formulaire autonome)
├── Composants formulaire
├── Transactions backend
├── Séquences métier
└── Pages spécifiques

[... autres formulaires ...]
```

### 2.3 Avantages de l'architecture retenue

**Modularité** :
- Chaque formulaire = projet Convertigo fullstack indépendant
- Possibilité de déployer un seul formulaire sans impacter les autres
- Projet global = simple référencement des projets formulaires

**Maintenance** :
- Évolutions sur un formulaire = accès direct au projet concerné
- Isolation des modifications
- Pas de risque de régression croisée

**Sécurité** :
- Accès Git granulaire par projet
- Un prestataire peut n'avoir accès qu'au projet d'un seul formulaire
- Le référencement dans le projet global ne donne pas accès au sous-projet

**Équipes** :
- Plusieurs développeurs peuvent travailler en parallèle
- Pas de conflit de code entre formulaires
- Facilite la collaboration

---

## 3. Périmètre fonctionnel

### 3.1 Formulaires à développer dans Convertigo

Les formulaires suivants seront développés dans le nouvel espace unifié :
- **Demande de badge**
- **Heures supplémentaires**
- **Télétravail**
- **Temps compensatoire**
- **Parking**
- **Mobilités durables**
- **Demande de mobilier**
- **Intervention technique**
- Autres formulaires identifiés dans les ateliers

### 3.2 Applications externes à intégrer

**Applications Convertigo existantes** :
- O'Buro : gestion administrative et paie
- ODAM : outils de développement
- Du RP : autre application (à transformer en composants partagés si possible)

**Applications non-Convertigo** (liens externes) :
- **GTA** : gestion des temps et absences
  - Module badgeuse
  - Module déclaration de temps
  - Module validation des demandes
- **Pratique RH** : formulaires nationaux
  - Déclaration enfant en charge
  - Modification complémentaire santé
  - Demandes diverses
  - Attestations
- **2AP** : frais de déplacement
- **Cytalan** : entretiens individuels
- **GPEC** : gestion des carrières
  - Entretiens
  - Formation
  - Référentiel emplois
- **Cafit** : covoiturage
- **Boussole numérique** : orientation dans les outils

### 3.3 Stratégie d'intégration des applications externes

**Pour les applications exposant des API** :
- Consommer les API pour afficher les backlogs dans l'espace unifié
- Exemple : afficher dans le dashboard manager "5 demandes d'absence à valider"
- Clic sur la notification → redirection vers l'application source

**Pour les applications sans API** :
- Regrouper par grande rubrique (ex: "Ma situation personnelle")
- Créer des liens directs vers les pages de l'application
- Redirection vers le portail externe

**Nouvelles applications Convertigo** :
- Développer directement selon l'architecture composants partagés
- Exemple : Gestion de conflit (à venir)
- Intégration native dans l'espace unifié

---

## 4. Interface utilisateur

### 4.1 Page d'accueil / Dashboard

**Vue par profil** :
- **Collaborateur** : ses demandes, ses actions
- **Manager** : demandes de l'équipe à valider, backlog
- **Gestionnaire RH** : vue globale, tous les formulaires

**Demandes en cours vs traitées** :
- **Demandes en cours** : tous les statuts non finalisés (brouillon, en validation, etc.)
- **Demandes traitées** : validées, refusées, clôturées

**Backlog agrégé** :
- Affichage du nombre de demandes à traiter par type
- Exemple manager : "120 demandes de télétravail à valider"
- Clic → accès direct à la liste des demandes

### 4.2 Navigation

**Point d'entrée unique** :
- Menu principal avec toutes les applications
- Recherche globale
- Favoris

**Navigation interne** :
- Utilisateur reste dans l'écosystème SIRH
- Pas de sortie vers des liens externes sauf pour applications non-Convertigo

**Applications externes** :
- Soit iframe (si pertinent et design cohérent)
- Soit lien externe vers l'application (nouvelle fenêtre ou même onglet)
- Soit API pour afficher uniquement les données pertinentes dans l'espace unifié

### 4.3 Chatbot / Assistant

Intégration d'un chatbot RH :
- Aide à la navigation
- Orientation vers le bon service
- Basé sur les travaux déjà réalisés (à récupérer)

---

## 5. Décisions techniques

### 5.1 Architecture backend

**Transactions et séquences** :
- Chaque projet formulaire contient ses propres transactions et séquences
- Option "projet fullstack" : front + back dans le même projet Convertigo
- Référencement dans le projet global : pas de duplication de code

**Base de données** :
- Formulaires développés dans l'espace unifié : écriture dans nos bases PostgreSQL
- Applications externes (GTA, pratique RH) : conservent leurs propres bases
- Pas d'écriture croisée entre les systèmes

### 5.2 Déploiement

**Modularité** :
- Déploiement par projet formulaire indépendant
- Exemple : déployer uniquement le projet "SIRH_Demande_Badge"
- Le projet global référence automatiquement la nouvelle version

**Évolutions** :
- Modification d'un formulaire = déploiement ciblé
- Pas de redéploiement global nécessaire
- Réduction des risques de régression

---

## 6. Contraintes et points d'attention

### 6.1 Intégration avec les applications existantes

**GTA (Gestion Temps et Absences)** :
- Problématique : l'URL ne change pas lors de la navigation interne (gestion en JS)
- Solution : impossible de faire des liens directs vers des sous-pages spécifiques
- Approche retenue : lien vers la page d'accueil + description des services disponibles

**Pratique RH** :
- Formulaires nationaux déjà en place
- Ne pas redévelopper ce qui existe
- Lister les services et rediriger vers l'application

**Cohérence visuelle** :
- Risque de décalage entre applications Convertigo et applications externes
- Design system à appliquer rigoureusement sur les formulaires développés

### 6.2 Gestion des doublons

**Rémunération** :
- Peut exister dans plusieurs applications
- Risque de confusion pour les utilisateurs
- Solution : si un service existe déjà dans l'espace unifié, ajouter une ligne "Autres services" qui redirige vers l'application externe

**Migration progressive** :
- Applications déjà développées (2AP, AT, Du RP, etc.) : liens externes
- Nouvelles applications : développement direct dans l'architecture composants
- Éviter de redévelopper ce qui fonctionne déjà

---

## 7. Prochaines étapes

### 7.1 Immédiat (avant prochain atelier mardi)

**Réflexion architecture** :
- Laisser le temps de la réflexion avant développement
- Éviter de développer puis tout casser après retours métier
- Valider l'architecture entre équipes techniques d'abord

**Maquettes** :
- Romain doit détailler le cheminement utilisateur
- Montrer comment les appels vers applications externes se matérialisent
- Clarifier la navigation pour les utilisateurs et le métier

**Documentation** :
- Documenter l'architecture retenue
- Expliquer les choix techniques (pourquoi pas d'iframe, etc.)
- Préparer la présentation au métier

### 7.2 Prochain atelier (mardi 10h30-11h00)

**Participants** : Dhaker, Youssoupha, Romain (sur site)

**Objectifs** :
- Valider l'architecture avec le métier
- Présenter les maquettes détaillées
- Confirmer le périmètre des formulaires
- Valider la stratégie d'intégration des applications externes

### 7.3 Projet parallèle (hors scope actuel)

**Projet scope** (Dakar) :
- Backend finalisé la semaine dernière
- Frontend démarré
- Dhaker impliqué sur cette partie

---

## 8. Finalités du projet

### 8.1 Objectifs métier

**Pour les collaborateurs** :
- ✅ Point d'entrée unique pour tous les services RH
- ✅ Navigation simplifiée, plus besoin d'appeler les gestionnaires
- ✅ Vue consolidée de toutes leurs demandes
- ✅ Accès rapide aux services les plus utilisés

**Pour les managers** :
- ✅ Dashboard avec backlog consolidé (toutes demandes à valider)
- ✅ Visibilité sur les demandes de l'équipe
- ✅ Validation centralisée (ne plus ouvrir 3 applications différentes)
- ✅ Notifications des actions à traiter

**Pour les gestionnaires RH** :
- ✅ Vue globale sur toutes les demandes
- ✅ Pilotage et statistiques
- ✅ Accès à tous les formulaires et applications

### 8.2 Objectifs techniques

**Architecture** :
- ✅ Modulaire : facilite la maintenance et les évolutions
- ✅ Scalable : ajout facile de nouveaux formulaires
- ✅ Sécurisée : accès granulaires par projet
- ✅ Performante : pas de surcharge liée aux iframes

**Développement** :
- ✅ Équipes en parallèle sur différents formulaires
- ✅ Déploiements indépendants par formulaire
- ✅ Réutilisation maximale via composants partagés
- ✅ Maintenabilité à long terme

**Qualité** :
- ✅ Cohérence UX grâce au design system (Compound UI)
- ✅ Moins de bugs grâce à l'isolation des modules
- ✅ Tests facilités par la modularité
- ✅ Documentation structurée

### 8.3 Bénéfices attendus

**Organisationnels** :
- Réduction des appels aux gestionnaires RH
- Gain de temps pour tous les profils
- Meilleure adoption des outils numériques
- Centralisation de la connaissance

**Utilisateurs** :
- Expérience unifiée et moderne
- Réduction de la charge cognitive (un seul outil à connaître)
- Autonomie accrue des agents
- Satisfaction utilisateur améliorée

**IT** :
- Réduction de la dette technique
- Industrialisation du développement de formulaires
- Facilité de maintenance et d'évolution
- Meilleure traçabilité et auditabilité

---

## 9. Citations clés de l'atelier

> **Dhaker** : "L'iframe, on l'a expérimenté et c'est faisable mais je le déconseille carrément. On l'a expérimenté et c'est faisable même sur l'authentification avec les sessions et tout, mais on le déconseille."

> **Dhaker** : "L'attirance de l'offre, c'est de regrouper. C'est pas juste un système de favoris comme sur canopée."

> **Youssoupha** : "C'est l'aéroport, j'arrive à l'aéroport mais après j'ai je peux pas aller n'importe où, c'est un hub."

> **Youssoupha** : "C'est pour ça que personne n'a réussi à le faire jusqu'à présent. Chacun fait un petit bout autonome quelque part."

> **Youssoupha** : "Alors moi ça me tient à cœur, c'est mon rêve de faire ce truc-là, mais bien."

> **Dhaker** : "C'est costaud comme projet." / **Romain** : "Eh oui, c'est costaud."

> **Dhaker** : "On va réaliser ton rêve."

---

## 10. Risques identifiés

### Risques techniques
- **Intégration applications externes** : URLs dynamiques, sessions, authentification croisée
- **Cohérence UX** : difficile de maintenir le même look & feel partout
- **Performance** : risque de lenteur si trop d'appels API externes
- **Sécurité** : gestion des accès entre projets, SSO

### Risques organisationnels
- **Périmètre large** : beaucoup d'applications à intégrer
- **Migration progressive** : cohabitation ancien/nouveau système
- **Formation utilisateurs** : changement d'habitudes
- **Résistance au changement** : certains préfèrent leurs outils actuels

### Mitigation
- ✅ Architecture modulaire permet une mise en place progressive
- ✅ Validation métier à chaque étape
- ✅ Temps de réflexion avant développement
- ✅ Équipe expérimentée et motivée

---

## Conclusion

L'atelier a permis de **valider l'architecture technique** de l'Espace Unifié SIRH basée sur des **composants partagés Convertigo**, en écartant définitivement la solution iframe.

Le projet est ambitieux mais l'équipe est consciente des enjeux et prend le temps nécessaire pour **bien concevoir avant de développer**, évitant ainsi les allers-retours coûteux.

La prochaine étape cruciale est la **validation avec le métier** prévue mardi, où les maquettes détaillées et le cheminement utilisateur seront présentés.

**Ce projet vise à réaliser le "rêve" d'un véritable hub RH centralisé pour l'URSSAF** 🎯

