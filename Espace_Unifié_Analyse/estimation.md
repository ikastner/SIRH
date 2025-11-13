# Estimation Jours-Homme - Espace Unifié URSSAF

## Méthodologie
- **Base** : Durée en jours par tâche (colonne Duree_Jours)
- **Parallélisation** : Tâches "Oui" peuvent être faites en parallèle (réduction -40%)
- **Hypothèse** : 5 jours ouvrables/semaine

## Estimation par Sprint

### Sprint 1 : Infrastructure (20 j-h)
- Setup projet: 5j → 3j-h (parallélisable)
- Config BDD: 5j → 3j-h (parallélisable)
- Architecture: 6j → 6j-h (bloquant)
- Auth ANAIS: 5j → 3j-h (parallélisable)
- Gestion rôles: 5j → 5j-h

### Sprint 2 : Tables Transverses (14 j-h)
- Tables statut: 5j → 3j-h
- Traceabilité: 5j → 3j-h
- Validations: 5j → 5j-h
- Notifications: 4j → 3j-h

### Sprint 3 : Badges Collab 1 (17 j-h)
- Table badge: 3j → 3j-h
- Formulaire nouveau: 5j → 3j-h
- Formulaire départ: 5j → 3j-h
- Workflow: 5j → 5j-h
- Tests: 4j → 3j-h

### Sprint 4 : Badges Collab 2 (18 j-h)
- Badge perdu: 4j → 3j-h
- Badge HS: 4j → 3j-h
- Accès spécifique: 4j → 3j-h
- Badge perso: 6j → 6j-h
- Dashboard collab: 5j → 3j-h

### Sprint 5 : Badges Prestataires (25 j-h)
- Presta nouveau: 5j → 3j-h
- Presta autres: 7j → 7j-h
- Autre spécifique: 4j → 3j-h
- Dashboard manager: 4j → 3j-h
- Dashboard RH: 4j → 3j-h
- Release v1.0.0: 6j → 6j-h

### Sprint 6 : HS Préalable (20 j-h)
- Table préalable: 3j → 3j-h
- Formulaire: 5j → 3j-h
- Workflow: 5j → 5j-h
- Séquence: 5j → 3j-h
- Validations: 5j → 3j-h
- Dashboard: 5j → 3j-h

### Sprint 7 : HS Réalisation 1 (20 j-h)
- Table réalisation: 3j → 3j-h
- Lien préalable: 4j → 3j-h
- Formulaire: 5j → 3j-h
- Saisie heures: 5j → 5j-h
- Pointages GTA: 5j → 3j-h
- Calcul écarts: 5j → 3j-h

### Sprint 8 : HS Réalisation 2 (31 j-h)
- Workflow: 5j → 5j-h
- Valid Manager: 5j → 3j-h
- Valid RH: 5j → 3j-h
- Pointage RH: 5j → 5j-h
- Réconciliation GTA: 5j → 3j-h
- Sans préalable: 5j → 3j-h
- Dashboard: 5j → 3j-h
- Release v1.1.0: 6j → 6j-h

### Sprint 9 : Notifications et Recherche (20 j-h)
- Centre notifs: 5j → 5j-h
- Notifs workflow: 5j → 3j-h
- Préférences: 4j → 3j-h
- Recherche globale: 6j → 6j-h
- Filtres avancés: 5j → 3j-h

### Sprint 10 : Dossier Agent (21 j-h)
- Dossier vue: 3j → 3j-h
- Interface: 5j → 3j-h
- Historique: 5j → 3j-h
- Favoris: 4j → 3j-h
- Export: 4j → 3j-h
- Release v1.2.0: 6j → 6j-h

### Sprint 11 : Apps Externes (15 j-h)
- Catalogue apps: 5j → 5j-h
- O'Buro: 5j → 3j-h
- Autres apps: 6j → 4j-h
- Suivi usage: 4j → 3j-h

### Sprint 12 : Finalisation (29 j-h)
- Optimisations: 5j → 5j-h
- Tests E2E: 7j → 7j-h
- Doc utilisateur: 5j → 3j-h
- Doc technique: 5j → 3j-h
- Formation: 4j → 3j-h
- Release v1.3.0: 8j → 8j-h

## RÉCAPITULATIF

### Total Jours-Homme : 250 jours-homme

### Par Phase
- Phase 1 (Infrastructure): 34 j-h
- Phase 2 (Badges): 60 j-h
- Phase 3 (Heures Sup): 71 j-h
- Phase 4 (Transversal): 41 j-h
- Phase 5 (Finalisation): 44 j-h

### Scénarios d'Équipe
- 2 développeurs : ~6-7 mois (250 j-h / 2 = 125 j/dev)
- 3 développeurs : ~5-6 mois (250 j-h / 3 = 83 j/dev)
- 4 développeurs + Tech Lead : ~4-5 mois

### Estimation Prudente (avec buffer 20%)
**Total recommandé : 300 jours-homme**