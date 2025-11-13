# Architecture Convertigo : Espace Unifié avec Iframe et Séquences

## 📋 Texte de démonstration

### Ce que cette architecture permet de faire

Imaginons qu'**Eric**, collaborateur URSSAF, se connecte à **Espace Unifié** le matin pour faire une demande de badge pour un nouveau collaborateur.

1. **Eric ouvre Espace Unifié** → Le shell (application conteneur) charge avec sa navigation principale, son dashboard et tous les formulaires disponibles.

2. **Il clique sur "Demande de Badge"** → Le shell ouvre automatiquement une nouvelle page qui **embarque via un iframe** l'application `Formulaire_Badge` (une application autonome développée séparément).

3. **Le formulaire se charge** → Au moment du chargement (`pageDidEnter`), le formulaire appelle la séquence `get_in_session` du shell pour récupérer :
   - Qui est Eric (code agent, nom, organisation)
   - Ses droits (collaborateur, pas manager)
   - Son contexte (service, préférences)

4. **Le formulaire pré-remplit automatiquement** → Le nom du demandeur (Eric) est déjà rempli, son organisation aussi. Il n'a plus qu'à saisir les infos du nouveau collaborateur.

5. **Eric remplit et soumet** → Le formulaire sauvegarde via ses propres séquences backend (accès à la BDD PostgreSQL) et met à jour la session shell avec `set_in_session` : "Dernière action : création badge".

6. **Navigation fluide** → Eric peut ensuite cliquer sur "Heures Sup" → Le shell charge le formulaire d'heures sup dans un autre iframe, qui récupère aussi son contexte automatiquement.

**Le tout fonctionne comme des WebParts SharePoint** : chaque module est indépendant, peut être développé et déployé séparément, mais offre une expérience utilisateur unifiée grâce à la gestion de session centralisée.

---

## 1. Vision et contexte

**Espace Unifié** est une application hub RH centralisée construite avec **Convertigo NGX Builder** qui permet de :
- Centraliser l'accès aux formulaires RH (Heures Sup, Badges, etc.)
- Intégrer des applications formulaire autonomes via des iframes
- Gérer l'état et la communication via des **séquences Convertigo**
- Offrir une expérience unifiée similaire aux **WebParts SharePoint**

**Principe architectural** : Architecture micro-frontend avec embedding via iframes
- **Shell Application** (Espace_Unifie) : conteneur principal avec navigation et gestion de session
- **Form Applications** (Formulaire_Badge, etc.) : applications autonomes embarquées
- **Séquences** : logique métier backend et communication inter-applications

---

## 2. Architecture globale

### 2.1 Structure des projets Convertigo

```
Espace_Unifie (Shell Application)
├── Sequences
│   ├── get_in_session    : Récupère le contexte utilisateur et la session
│   └── set_in_session    : Stocke des données dans la session globale
└── Application
    └── NgxApp
        └── Pages
            └── Page (Root)
                └── Content
                    └── iframe
                        ├── @src = http://localhost:43438/path-to-xfirst
                        ├── @width = 100%
                        ├── @height = 100%
                        └── @frameborder = 0

Formulaire_Badge (Autonome)
└── Application
    └── NgxApp
        └── Pages
            └── Page
                ├── Events
                │   └── pageDidEnter
                │       └── Call (Espace_Unifie.get_in_session)
                └── Content
                    ├── H1: "Formulaire demande de badge"
                    └── Form #formSample
                        └── Controls (inputs, buttons)
```

### 2.2 Rôles des composants

| Composant | Rôle | Responsabilités |
|-----------|------|-----------------|
| **Espace_Unifie** | Shell / Hub | Navigation principale, gestion session, hôte des iframes, authentification SSO |
| **Formulaire_Badge** | Module autonome | Formulaire dédié, logique métier propre, appel séquences shell |
| **get_in_session** | Sequence | Récupère contexte utilisateur (profil, droits, préférences) depuis le shell |
| **set_in_session** | Sequence | Stocke des données partagées entre shell et modules |
| **iframe** | Conteneur | Embarque l'application formulaire dans le shell |

---

## 3. Fonctionnement détaillé

### 3.1 Cycle de chargement d'un formulaire

#### Étape 1 : Navigation utilisateur
```
Utilisateur clique sur "Demande de Badge" dans Espace_Unifie
    ↓
Shell charge la page correspondante
```

#### Étape 2 : Chargement de l'iframe
```xml
<!-- Dans la page du Shell -->
<iframe 
    src="http://localhost:43438/formulaire-badge"
    width="100%" 
    height="100%" 
    frameborder="0">
</iframe>
```
- L'application `Formulaire_Badge` est chargée dans un conteneur iframe
- Elle conserve son contexte d'exécution autonome
- Communication possible via `postMessage` ou séquences Convertigo

#### Étape 3 : Initialisation du formulaire
```xml
<!-- Event pageDidEnter du Formulaire_Badge -->
<Event name="pageDidEnter">
    <Call sequence="Espace_Unifie.get_in_session">
        <Parameters>
            <!-- Paramètres optionnels -->
        </Parameters>
    </Call>
</Event>
```
- Au chargement de la page (`pageDidEnter`)
- Le formulaire appelle `get_in_session` du shell pour récupérer :
  - Code utilisateur connecté
  - Profil et rôles (collaborateur, manager, RH)
  - Préférences utilisateur
  - Contexte de navigation

#### Étape 4 : Réponse de la séquence
```javascript
// Dans get_in_session (exemple de logique)
{
    "code_agent": "AG001",
    "nom": "Morel",
    "prenom": "Eric",
    "role": "collaborateur",
    "organisation": "URSSAF Caisse Nationale",
    "code_service": "RH001",
    "session_id": "abc123xyz"
}
```

#### Étape 5 : Utilisation dans le formulaire
```
Formulaire pré-remplit les champs avec les données utilisateur
    ↓
Utilisateur saisit le reste du formulaire
    ↓
Soumission via les séquences propres du Formulaire_Badge
```

#### Étape 6 : Communication retour (optionnel)
```xml
<!-- Mise à jour de la session par le formulaire -->
<Call sequence="Espace_Unifie.set_in_session">
    <Parameters>
        <Parameter name="last_form_used" value="badge"/>
        <Parameter name="last_action_date" value="2024-12-15"/>
    </Parameters>
</Call>
```

---

## 4. Séquences Convertigo

### 4.1 get_in_session

**Objectif** : Fournir le contexte utilisateur aux modules embarqués

**Signature** :
```sql
-- Pas de paramètres requis, utilise la session Convertigo active
```

**Retour** :
```json
{
    "success": true,
    "data": {
        "code_agent": "AG001",
        "nom": "Morel",
        "prenom": "Eric",
        "email": "eric.morel@urssaf.fr",
        "role": "collaborateur",
        "organisation": "URSSAF Caisse Nationale",
        "code_service": "RH001",
        "session_id": "abc123xyz",
        "timestamp": "2024-12-15T10:30:00Z"
    }
}
```

**Implémentation suggérée** :
```sql
-- Réclure le code_agent de la session Convertigo
SELECT 
    a.code_agent,
    a.nom,
    a.prenom,
    a.email,
    a.organisation,
    a.code_service,
    -- Récupérer le rôle depuis la session Convertigo ou ANAIS
    app.current_user as code_agent,
    -- Autres données de contexte
    CURRENT_TIMESTAMP as timestamp
FROM agent a
WHERE a.code_agent = app.current_user
  AND a.actif = TRUE
LIMIT 1;
```

### 4.2 set_in_session

**Objectif** : Stocker des données partagées dans la session globale

**Signature** :
```sql
-- Paramètres dynamiques selon les besoins
```

**Exemple d'utilisation** :
```xml
<Call sequence="Espace_Unifie.set_in_session">
    <Parameters>
        <Parameter name="key" value="last_form_used"/>
        <Parameter name="value" value="badge"/>
        <Parameter name="key2" value="last_action_date"/>
        <Parameter name="value2" value="2024-12-15T10:30:00Z"/>
    </Parameters>
</Call>
```

**Implémentation suggérée** :
```sql
-- Stocker dans des variables de session Convertigo
-- Convertigo gère automatiquement la session via app variables
```

---

## 5. Patterns de communication

### 5.1 Pattern 1 : Appel de séquence (recommandé)

**Avantages** :
- Native Convertigo, pas de configuration CORS
- Sécurisé via gestion de session Convertigo
- Type-safe et déboggable

**Cas d'usage** :
- Récupération de contexte utilisateur
- Partage de préférences
- Traçabilité d'actions

**Exemple** :
```xml
<Event name="btnSubmitClick">
    <Call sequence="Formulaire_Badge.save_badge_request">
        <Parameters>
            <Parameter name="nom_collab" value="{form.nom_collab}"/>
            <Parameter name="code_agent_demandeur" value="{session.code_agent}"/>
        </Parameters>
        <OnResponse>
            <!-- Gérer la réponse -->
            <Call sequence="Espace_Unifie.set_in_session">
                <Parameters>
                    <Parameter name="last_action" value="badge_created"/>
                </Parameters>
            </Call>
        </OnResponse>
    </Call>
</Event>
```

### 5.2 Pattern 2 : postMessage (cross-origin)

**Avantages** :
- Communication asynchrone bidirectionnelle
- Isolation forte entre shell et modules

**Cas d'usage** :
- Notifications temps réel
- Synchronisation d'état complexe

**Exemple** :
```javascript
// Dans Formulaire_Badge (iframe)
window.parent.postMessage({
    type: 'FORM_SUBMITTED',
    payload: { formId: 'badge', status: 'success' }
}, 'http://espace-unifie.urssaf.fr');

// Dans Espace_Unifie (parent)
window.addEventListener('message', (event) => {
    if (event.data.type === 'FORM_SUBMITTED') {
        // Traiter l'événement
    }
});
```

### 5.3 Pattern 3 : URL parameters

**Avantages** :
- Simple pour passer des paramètres initiaux
- Deep linking possible

**Cas d'usage** :
- Ouverture directe d'un formulaire pré-rempli
- Partage de liens vers des demandes spécifiques

**Exemple** :
```html
<iframe src="http://formulaire-badge?mode=edit&id=123"></iframe>
```

---

## 6. Architecture complète : Shell + Modules

### 6.1 Projet Espace_Unifie (Shell)

#### Structure minimale
```
Espace_Unifie
├── Sequences
│   ├── get_in_session
│   ├── set_in_session
│   ├── get_user_permissions
│   └── log_audit_event
├── Transactions (liens BDD)
│   ├── agent_lookup
│   └── notification_fetch
└── Application
    └── NgxApp
        ├── Menus (Navigation principale)
        ├── Pages
        │   ├── home (Dashboard)
        │   ├── formulaire-heures-sup (Page avec iframe HS)
        │   ├── formulaire-badge (Page avec iframe Badge)
        │   ├── formulaire-parking (Page avec iframe Parking)
        │   └── mes-demandes (Liste agrégée)
        └── Styles (Design system commun)
```

#### Page type avec iframe
```xml
<Page name="formulaire-badge">
    <Header>
        <Title>Demande de Badge</Title>
        <Button onclick="navigateBack()">Retour</Button>
    </Header>
    <Content>
        <iframe 
            src="http://localhost:43438/formulaire-badge"
            width="100%" 
            height="100%" 
            frameborder="0"
            id="badge-form-iframe">
        </iframe>
    </Content>
    <Footer>
        <Label>Aide • Support • FAQ</Label>
    </Footer>
</Page>
```

### 6.2 Projets Formulaire_X (Modules autonomes)

#### Exemple : Formulaire_Badge

```
Formulaire_Badge
├── Sequences
│   ├── save_badge_request
│   ├── get_badge_request
│   ├── submit_badge_for_validation
│   └── get_badge_status
├── Transactions (liens BDD)
│   ├── badge_demande_insert
│   ├── badge_demande_update
│   └── badge_demande_select
└── Application
    └── NgxApp
        ├── Pages
        │   ├── badge-create (Formulaire de création)
        │   └── badge-detail (Vue détaillée)
        └── Styles
```

#### Initialisation depuis le shell
```xml
<Page name="badge-create">
    <Events>
        <Event name="pageDidEnter">
            <!-- 1. Récupérer le contexte depuis le shell -->
            <Call sequence="Espace_Unifie.get_in_session">
                <OnResponse>
                    <!-- 2. Pré-remplir le formulaire -->
                    <SetVariable name="code_agent" value="{response.code_agent}"/>
                    <SetVariable name="user_role" value="{response.role}"/>
                    
                    <!-- 3. Adapter l'UI selon le rôle -->
                    <If condition="{response.role} == 'collaborateur'">
                        <!-- Mode création -->
                    </If>
                    <If condition="{response.role} == 'manager'">
                        <!-- Mode validation -->
                    </If>
                </OnResponse>
            </Call>
        </Event>
    </Events>
    
    <Content>
        <H1>Formulaire demande de badge</H1>
        <Form id="formBadge">
            <Controls>
                <!-- Champs du formulaire -->
            </Controls>
        </Form>
    </Content>
</Page>
```

---

## 7. Avantages de cette architecture

### 7.1 Pour le développement

| Avantage | Détail |
|----------|--------|
| **Indépendance** | Chaque formulaire est un projet Convertigo autonome |
| **Déploiement découplé** | Mise à jour d'un formulaire sans impacter les autres |
| **Réutilisabilité** | Les formulaires peuvent être réutilisés en dehors d'Espace_Unifie |
| **Isolation** | Bug dans un formulaire n'affecte pas les autres |
| **Équipes parallèles** | Plusieurs équipes peuvent développer en parallèle |

### 7.2 Pour l'utilisateur

| Avantage | Détail |
|----------|--------|
| **Expérience unifiée** | Navigation cohérente, design system commun |
| **Performance** | Chargement à la demande, pas de gros bundle |
| **Persistance** | Session maintenue lors de la navigation |
| **SSO** | Authentification unique via le shell |
| **Traçabilité** | Audit centralisé des actions |

### 7.3 Pour la maintenance

| Avantage | Détail |
|----------|--------|
| **Simplicité** | Architecture claire, responsabilités séparées |
| **Extensibilité** | Ajout facile de nouveaux formulaires |
| **Tests** | Tests unitaires par module, tests d'intégration shell |
| **Versioning** | Gestion de versions indépendante par formulaire |
| **Rollback** | Retour arrière sans impact global |

---

## 8. Comparaison avec les alternatives

### 8.1 vs Monolithe

| Aspect | Convertigo Iframe | Monolithe |
|--------|-------------------|-----------|
| **Scalabilité** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Time-to-market** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Maintenance** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Cohérence UX** | ⭐⭐⭐⭐⭐ (design system) | ⭐⭐⭐⭐⭐ |
| **Complexité initiale** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

### 8.2 vs SharePoint WebParts

| Aspect | Convertigo Iframe | SharePoint WebParts |
|--------|-------------------|---------------------|
| **Isolation** | ⭐⭐⭐⭐⭐ (iframe) | ⭐⭐⭐⭐ |
| **Customisation** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Coûts licences** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Dépendances** | ⭐⭐⭐⭐⭐ (autonome) | ⭐⭐⭐ (SharePoint) |
| **Performance** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## 9. Évolutions possibles

### 9.1 Court terme

- **Ajout de formulaires** : Formulaire_HeuresSup, Formulaire_Parking, etc.
- **Notifications temps réel** : postMessage pour alertes
- **Cache local** : Stockage des données fréquentes
- **Design tokens** : Variables CSS partagées

### 9.2 Moyen terme

- **Web Components** : Remplacer iframe par Custom Elements
- **Module Federation** : Webpack 5 pour chargement dynamique
- **Dashboard agrégé** : Vue consolidée depuis plusieurs modules
- **API Gateway** : Centralisation des appels backend

### 9.3 Long terme

- **Microservices backend** : Services dédiés par domaine
- **Event-driven** : Architecture basée événements (Kafka/RabbitMQ)
- **Offline-first** : Service Workers, PWA avancées
- **Multi-tenant** : Support de plusieurs organisations

---

## 10. Exemple d'implémentation complète

### 10.1 Schéma de base de données (référentiel commun)

```sql
-- Utilisateurs (référentiel commun)
CREATE TABLE agent (
    code_agent VARCHAR(50) PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    organisation VARCHAR(100),
    code_service VARCHAR(50),
    actif BOOLEAN DEFAULT TRUE
);

-- Demandes Badge (module dédié)
CREATE TABLE badge_demande (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    id_utilisateur VARCHAR(64) NOT NULL REFERENCES agent(code_agent),
    nom_collaborateur VARCHAR(128) NOT NULL,
    prenom_collaborateur VARCHAR(128) NOT NULL,
    email_collaborateur VARCHAR(256) NOT NULL,
    etat_courant VARCHAR(64) NOT NULL DEFAULT 'en_attente_manager',
    date_creation TIMESTAMP NOT NULL DEFAULT now(),
    date_modification TIMESTAMP NOT NULL DEFAULT now()
);

-- Événements workflow (commun)
CREATE TABLE evenements_workflow (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_formulaire VARCHAR(64) NOT NULL,
    id_formulaire UUID NOT NULL,
    etat_depart VARCHAR(64),
    etat_arrivee VARCHAR(64) NOT NULL,
    action VARCHAR(64) NOT NULL,
    par_utilisateur VARCHAR(64) NOT NULL,
    donnees JSONB,
    date_creation TIMESTAMP NOT NULL DEFAULT now()
);
```

### 10.2 Séquences Convertigo

#### get_in_session (Shell)
```javascript
// Pseudo-code Convertigo Sequence
function get_in_session() {
    var code_agent = app.current_user;
    
    // Query BDD
    var result = executeQuery(
        "SELECT * FROM agent WHERE code_agent = ? AND actif = TRUE",
        [code_agent]
    );
    
    if (result.length > 0) {
        return {
            success: true,
            data: {
                code_agent: result[0].code_agent,
                nom: result[0].nom,
                prenom: result[0].prenom,
                email: result[0].email,
                organisation: result[0].organisation,
                code_service: result[0].code_service,
                session_id: app.session_id,
                timestamp: new Date().toISOString()
            }
        };
    } else {
        return {
            success: false,
            error: "Utilisateur non trouvé"
        };
    }
}
```

#### save_badge_request (Formulaire_Badge)
```javascript
// Pseudo-code Convertigo Sequence
function save_badge_request(params) {
    var badge_id = executeQuery(
        "INSERT INTO badge_demande (id_utilisateur, nom_collaborateur, prenom_collaborateur, email_collaborateur) VALUES (?, ?, ?, ?) RETURNING id",
        [
            params.code_agent_demandeur,
            params.nom_collab,
            params.prenom_collab,
            params.email_collab
        ]
    );
    
    // Traçabilité
    executeQuery(
        "INSERT INTO evenements_workflow (type_formulaire, id_formulaire, etat_arrivee, action, par_utilisateur) VALUES (?, ?, ?, ?, ?)",
        ['BADGE', badge_id, 'en_attente_manager', 'soumettre', params.code_agent_demandeur]
    );
    
    return {
        success: true,
        data: { id: badge_id }
    };
}
```

### 10.3 Interface utilisateur

#### Shell Navigation
```xml
<Page name="home">
    <Content>
        <Menu>
            <Item onclick="navigateTo('formulaire-heures-sup')">
                <Icon name="clock"/>
                Heures Supplémentaires
            </Item>
            <Item onclick="navigateTo('formulaire-badge')">
                <Icon name="badge"/>
                Demande de Badge
            </Item>
            <Item onclick="navigateTo('mes-demandes')">
                <Icon name="list"/>
                Mes Demandes
            </Item>
        </Menu>
    </Content>
</Page>
```

#### Formulaire Badge (dans l'iframe)
```xml
<Page name="badge-create">
    <Events>
        <Event name="pageDidEnter">
            <Call sequence="Espace_Unifie.get_in_session">
                <OnResponse>
                    <SetVariable name="userContext" value="{response.data}"/>
                </OnResponse>
            </Call>
        </Event>
        
        <Event name="btnSubmitClick">
            <Call sequence="Formulaire_Badge.save_badge_request">
                <Parameters>
                    <Parameter name="code_agent_demandeur" value="{userContext.code_agent}"/>
                    <Parameter name="nom_collab" value="{form.nom}"/>
                    <Parameter name="prenom_collab" value="{form.prenom}"/>
                    <Parameter name="email_collab" value="{form.email}"/>
                </Parameters>
                <OnResponse>
                    <ShowAlert message="Demande créée avec succès"/>
                    <Navigate page="mes-demandes"/>
                </OnResponse>
            </Call>
        </Event>
    </Events>
    
    <Content>
        <H1>Formulaire demande de badge</H1>
        <Form id="formBadge">
            <Label>Demandeur : {userContext.nom} {userContext.prenom}</Label>
            <Input name="nom" placeholder="Nom du collaborateur" required/>
            <Input name="prenom" placeholder="Prénom du collaborateur" required/>
            <Input name="email" type="email" placeholder="Email" required/>
            <Button id="btnSubmit">Soumettre</Button>
        </Form>
    </Content>
</Page>
```

---

## 11. Bonnes pratiques

### 11.1 Sécurité

- ✅ **SSO centralisé** : Authentification uniquement dans le shell
- ✅ **HTTPS partout** : Communication sécurisée
- ✅ **Validation serveur** : Double vérification backend
- ✅ **Audit logs** : Traçabilité complète des actions
- ✅ **Permissions granulaires** : RBAC via ANAIS

### 11.2 Performance

- ✅ **Lazy loading** : Chargement à la demande des iframes
- ✅ **Cache local** : Session Convertigo + localStorage
- ✅ **Compression** : Assets optimisés
- ✅ **Monitoring** : Temps de chargement trackés

### 11.3 Expérience utilisateur

- ✅ **Feedback visuel** : Loaders, messages d'erreur clairs
- ✅ **Navigation fluide** : Transitions smooth
- ✅ **Design system** : Cohérence visuelle
- ✅ **Accessibilité** : WCAG AA minimum

---

## 12. Conclusion

L'architecture **Convertigo Iframe + Séquences** offre :
- ✅ **Flexibilité** : Développement et déploiement indépendants
- ✅ **Simplicité** : Pattern éprouvé (WebParts-like)
- ✅ **Scalabilité** : Ajout facile de modules
- ✅ **Maintenabilité** : Responsabilités séparées
- ✅ **Cohérence** : Expérience utilisateur unifiée

Cette approche est **idéale** pour :
- Migrations progressives
- Équipes multiples
- Formulaires métiers variés
- Systèmes legacy à préserver

---

**Document vivant** : À mettre à jour avec :
- Schémas d'architecture détaillés (C4)
- Contrats API formels
- Guides de déploiement
- Tests d'intégration

