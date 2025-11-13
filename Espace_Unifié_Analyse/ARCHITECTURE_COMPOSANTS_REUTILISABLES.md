# Architecture : Bibliothèque de Composants Réutilisables

## 📋 Vision et principe

**Principe** : Une seule application Espace Unifié + bibliothèque de composants formulaires préconstruits

Au lieu de créer chaque formulaire from scratch, on **développe une fois un composant réutilisable** que l'on peut ensuite appeler partout dans l'application comme une **brique Lego**.

---

## 1. Structure du projet

### 1.1 Organisation des dossiers

```
Espace_Unifie/
├── Connectors/                    # Connexions externes
│   └── ANAIS
├── Sequences/                     # Logique backend
│   ├── Commun/                    # Séquences transverses
│   │   ├── get_user_context      # Récupère contexte utilisateur
│   │   ├── save_audit_log        # Traçabilité
│   │   └── get_notifications     # Notifications
│   ├── Badge/                     # Séquences dédiées Badge
│   │   ├── save_badge_request
│   │   ├── get_badge_request
│   │   ├── update_badge_status
│   │   └── list_badge_requests
│   ├── HeureSup/                  # Séquences dédiées Heures Sup
│   │   ├── save_heure_sup
│   │   ├── get_heure_sup
│   │   └── validate_heure_sup
│   └── Parking/                   # Séquences dédiées Parking
│       ├── save_parking
│       └── get_parking
├── Transactions/                  # Accès BDD
│   ├── badge_demande_insert
│   ├── badge_demande_select
│   └── ...
├── References/                    # Projets externes référencés
└── Application/
    └── NgxApp/
        ├── Styles/                # Design System global
        │   ├── tokens.css         # Couleurs, espacements, etc.
        │   ├── components.css     # Styles composants communs
        │   └── layout.css         # Grilles, containers
        ├── Components/            # 🎯 BIBLIOTHÈQUE DE COMPOSANTS
        │   ├── Forms/             # Composants formulaires complets
        │   │   ├── FormulaireBadge/
        │   │   │   ├── component.xml
        │   │   │   ├── properties.json
        │   │   │   └── README.md
        │   │   ├── FormulaireHeureSup/
        │   │   │   ├── component.xml
        │   │   │   ├── properties.json
        │   │   │   └── README.md
        │   │   └── FormulaireParking/
        │   ├── Inputs/            # Composants champs de formulaire
        │   │   ├── ChampTexte/
        │   │   ├── ChampDate/
        │   │   ├── ChampSelect/
        │   │   ├── ChampFichier/
        │   │   └── ChampNombre/
        │   ├── Layout/            # Mise en page
        │   │   ├── Container/
        │   │   ├── Card/
        │   │   ├── Grid/
        │   │   └── Section/
        │   ├── Actions/           # Boutons et actions
        │   │   ├── BoutonSubmit/
        │   │   ├── BoutonCancel/
        │   │   ├── BoutonSaveDraft/
        │   │   └── BoutonDelete/
        │   ├── États/             # Affichage d'états
        │   │   ├── BadgeStatut/
        │   │   ├── Loader/
        │   │   ├── MessageErreur/
        │   │   └── MessageSucces/
        │   └── Navigation/        # Navigation
        │       ├── Breadcrumb/
        │       ├── Tabs/
        │       └── Pagination/
        ├── Pages/                 # Pages utilisant les composants
        │   ├── home.xml
        │   ├── navigation.xml
        │   ├── badge-create.xml   # → utilise FormulaireBadge
        │   ├── badge-edit.xml     # → utilise FormulaireBadge
        │   ├── badge-view.xml     # → utilise FormulaireBadge
        │   ├── heures-sup-create.xml
        │   ├── heures-sup-edit.xml
        │   └── mes-demandes.xml
        └── Menus/                 # Navigation principale
```

---

## 2. Design System : Fondation

### 2.1 Tokens de design (tokens.css)

```css
/* Couleurs */
:root {
    /* Primaires */
    --color-primary: #0066CC;
    --color-primary-light: #6699FF;
    --color-primary-dark: #004499;
    
    /* Secondaires */
    --color-secondary: #00CC66;
    --color-secondary-light: #66FF99;
    
    /* États */
    --color-success: #00CC66;
    --color-warning: #FFCC00;
    --color-error: #CC0000;
    --color-info: #0066CC;
    
    /* Neutres */
    --color-text: #333333;
    --color-text-light: #666666;
    --color-border: #CCCCCC;
    --color-background: #F5F5F5;
    --color-white: #FFFFFF;
    
    /* Espacements */
    --spacing-xs: 4px;
    --spacing-sm: 8px;
    --spacing-md: 16px;
    --spacing-lg: 24px;
    --spacing-xl: 32px;
    
    /* Bordures */
    --border-radius-sm: 2px;
    --border-radius-md: 4px;
    --border-radius-lg: 8px;
    
    /* Typographie */
    --font-family: 'Segoe UI', Arial, sans-serif;
    --font-size-xs: 12px;
    --font-size-sm: 14px;
    --font-size-md: 16px;
    --font-size-lg: 18px;
    --font-size-xl: 24px;
    
    /* Ombres */
    --shadow-sm: 0 1px 2px rgba(0,0,0,0.1);
    --shadow-md: 0 2px 4px rgba(0,0,0,0.1);
    --shadow-lg: 0 4px 8px rgba(0,0,0,0.15);
}
```

---

## 3. Composants de base : Inputs

### 3.1 ChampTexte (composant de base)

**Fichier** : `Components/Inputs/ChampTexte/component.xml`

```xml
<!-- 
    Composant : ChampTexte
    Description : Champ texte réutilisable avec validation
    Usage : <ChampTexte label="Nom" required="true" value="{nom}" onChange="handleChange"/>
-->
<Component name="ChampTexte">
    <!-- Propriétés (props) -->
    <Properties>
        <Property name="label" type="string" required="true">Libellé du champ</Property>
        <Property name="value" type="string">Valeur par défaut</Property>
        <Property name="placeholder" type="string">Texte d'aide</Property>
        <Property name="required" type="boolean" default="false">Champ obligatoire</Property>
        <Property name="readOnly" type="boolean" default="false">Lecture seule</Property>
        <Property name="error" type="string">Message d'erreur</Property>
        <Property name="onChange" type="callback">Callback changement valeur</Property>
    </Properties>
    
    <!-- Événements -->
    <Events>
        <Event name="componentDidMount">
            <SetVariable name="internalValue" value="{props.value}"/>
        </Event>
        
        <Event name="inputValueChange">
            <SetVariable name="internalValue" value="{event.value}"/>
            <If condition="{props.onChange} != null">
                <Call callback="{props.onChange}" value="{event.value}"/>
            </If>
        </Event>
    </Events>
    
    <!-- Rendu -->
    <Render>
        <Container style="margin-bottom: var(--spacing-md);">
            <!-- Label -->
            <Label style="
                display: block;
                font-weight: 500;
                color: var(--color-text);
                margin-bottom: var(--spacing-xs);
                font-size: var(--font-size-sm);
            ">
                {props.label}
                <If condition="{props.required} == true">
                    <Span style="color: var(--color-error);"> *</Span>
                </If>
            </Label>
            
            <!-- Input -->
            <Input 
                value="{internalValue}"
                placeholder="{props.placeholder}"
                readonly="{props.readOnly}"
                style="
                    width: 100%;
                    padding: var(--spacing-sm) var(--spacing-md);
                    border: 1px solid var(--color-border);
                    border-radius: var(--border-radius-md);
                    font-size: var(--font-size-md);
                    font-family: var(--font-family);
                    <If condition="{props.error} != null">
                        border-color: var(--color-error);
                    </If>
                "
                onChange="inputValueChange"
            />
            
            <!-- Message d'erreur -->
            <If condition="{props.error} != null">
                <Paragraph style="
                    color: var(--color-error);
                    font-size: var(--font-size-sm);
                    margin-top: var(--spacing-xs);
                ">
                    {props.error}
                </Paragraph>
            </If>
        </Container>
    </Render>
</Component>
```

### 3.2 ChampDate

```xml
<Component name="ChampDate">
    <Properties>
        <Property name="label" type="string" required="true"/>
        <Property name="value" type="date"/>
        <Property name="required" type="boolean" default="false"/>
        <Property name="minDate" type="date"/>
        <Property name="maxDate" type="date"/>
        <Property name="onChange" type="callback"/>
    </Properties>
    
    <Render>
        <Container style="margin-bottom: var(--spacing-md);">
            <Label>{props.label} {props.required ? '*' : ''}</Label>
            <DatePicker 
                value="{props.value}"
                min="{props.minDate}"
                max="{props.maxDate}"
                style="
                    width: 100%;
                    padding: var(--spacing-sm) var(--spacing-md);
                    border: 1px solid var(--color-border);
                    border-radius: var(--border-radius-md);
                "
                onChange="{props.onChange}"
            />
        </Container>
    </Render>
</Component>
```

### 3.3 ChampFichier

```xml
<Component name="ChampFichier">
    <Properties>
        <Property name="label" type="string" required="true"/>
        <Property name="maxSize" type="number" default="5242880"/> <!-- 5MB -->
        <Property name="allowedTypes" type="array"/> <!-- ['pdf', 'png', 'jpg'] -->
        <Property name="onUpload" type="callback"/>
    </Properties>
    
    <Render>
        <Container style="margin-bottom: var(--spacing-md);">
            <Label>{props.label}</Label>
            <FileUpload 
                maxSize="{props.maxSize}"
                allowedTypes="{props.allowedTypes}"
                onUpload="{props.onUpload}"
                style="
                    padding: var(--spacing-md);
                    border: 2px dashed var(--color-border);
                    border-radius: var(--border-radius-md);
                    text-align: center;
                    cursor: pointer;
                "
            />
        </Container>
    </Render>
</Component>
```

---

## 4. Composants d'actions

### 4.1 BoutonSubmit

```xml
<Component name="BoutonSubmit">
    <Properties>
        <Property name="label" type="string" default="Soumettre"/>
        <Property name="loading" type="boolean" default="false"/>
        <Property name="disabled" type="boolean" default="false"/>
        <Property name="onClick" type="callback" required="true"/>
    </Properties>
    
    <Render>
        <Button 
            onclick="{props.onClick}"
            disabled="{props.disabled or props.loading}"
            style="
                padding: var(--spacing-md) var(--spacing-lg);
                background: var(--color-primary);
                color: var(--color-white);
                border: none;
                border-radius: var(--border-radius-md);
                font-size: var(--font-size-md);
                font-weight: 600;
                cursor: {props.disabled ? 'not-allowed' : 'pointer'};
                opacity: {props.disabled ? 0.5 : 1};
                box-shadow: var(--shadow-sm);
            "
        >
            <If condition="{props.loading} == true">
                <Loader size="small" color="white"/>
            </If>
            <Else>
                {props.label}
            </Else>
        </Button>
    </Render>
</Component>
```

---

## 5. Composites : Formulaires complets

### 5.1 FormulaireBadge (composant principal) ⭐

**Fichier** : `Components/Forms/FormulaireBadge/component.xml`

```xml
<!-- 
    Composant : FormulaireBadge
    Description : Formulaire complet de demande de badge
    Usage : <FormulaireBadge mode="create" onSubmit="handleSubmit"/>
-->
<Component name="FormulaireBadge">
    <!-- Propriétés -->
    <Properties>
        <Property name="mode" type="string" default="create">
            <!-- create | edit | view -->
        </Property>
        <Property name="badgeId" type="string">
            <!-- ID du badge (si mode=edit ou view) -->
        </Property>
        <Property name="onSubmit" type="callback">
            <!-- Callback après soumission réussie -->
        </Property>
        <Property name="onCancel" type="callback">
            <!-- Callback annulation -->
        </Property>
    </Properties>
    
    <!-- Variables internes -->
    <Variables>
        <Variable name="badgeData" type="object" default="{}"/>
        <Variable name="loading" type="boolean" default="false"/>
        <Variable name="errors" type="object" default="{}"/>
    </Variables>
    
    <!-- Événements -->
    <Events>
        <!-- Chargement initial -->
        <Event name="componentDidMount">
            <If condition="{props.mode} == 'edit' or {props.mode} == 'view'">
                <Call sequence="Badge.get_badge_request">
                    <Parameters>
                        <Parameter name="badgeId" value="{props.badgeId}"/>
                    </Parameters>
                    <OnResponse>
                        <SetVariable name="badgeData" value="{response.data}"/>
                    </OnResponse>
                    <OnError>
                        <SetVariable name="errors.load" value="Erreur lors du chargement"/>
                    </OnError>
                </Call>
            </If>
            <Else>
                <!-- Mode création : pré-remplir avec données utilisateur -->
                <Call sequence="Commun.get_user_context">
                    <OnResponse>
                        <SetVariable name="badgeData.code_agent_demandeur" value="{response.data.code_agent}"/>
                        <SetVariable name="badgeData.organisation" value="{response.data.organisation}"/>
                    </OnResponse>
                </Call>
            </Else>
        </Event>
        
        <!-- Changement de valeur -->
        <Event name="handleFieldChange">
            <Parameters>
                <Parameter name="fieldName"/>
                <Parameter name="value"/>
            </Parameters>
            <SetVariable 
                name="badgeData.{event.fieldName}" 
                value="{event.value}"
            />
        </Event>
        
        <!-- Validation -->
        <Event name="validateForm">
            <SetVariable name="errors" value="{}"/>
            <SetVariable name="isValid" value="true"/>
            
            <!-- Validation nom -->
            <If condition="{badgeData.nom_collaborateur} == null or length({badgeData.nom_collaborateur}) < 2">
                <SetVariable name="errors.nom" value="Le nom est requis (minimum 2 caractères)"/>
                <SetVariable name="isValid" value="false"/>
            </If>
            
            <!-- Validation prénom -->
            <If condition="{badgeData.prenom_collaborateur} == null or length({badgeData.prenom_collaborateur}) < 2">
                <SetVariable name="errors.prenom" value="Le prénom est requis (minimum 2 caractères)"/>
                <SetVariable name="isValid" value="false"/>
            </If>
            
            <!-- Validation email -->
            <If condition="{badgeData.email_collaborateur} == null or NOT matches({badgeData.email_collaborateur}, '@')">
                <SetVariable name="errors.email" value="Un email valide est requis"/>
                <SetVariable name="isValid" value="false"/>
            </If>
            
            <Return value="{isValid}"/>
        </Event>
        
        <!-- Soumission -->
        <Event name="handleSubmit">
            <!-- 1. Validation -->
            <Call event="validateForm">
                <OnResult>
                    <If condition="{result} == false">
                        <Return/> <!-- Arrêter si invalide -->
                    </If>
                </OnResult>
            </Call>
            
            <!-- 2. Loading -->
            <SetVariable name="loading" value="true"/>
            
            <!-- 3. Sauvegarde -->
            <Call sequence="Badge.save_badge_request">
                <Parameters>
                    <Parameter name="nom" value="{badgeData.nom_collaborateur}"/>
                    <Parameter name="prenom" value="{badgeData.prenom_collaborateur}"/>
                    <Parameter name="email" value="{badgeData.email_collaborateur}"/>
                    <Parameter name="code_agent_demandeur" value="{badgeData.code_agent_demandeur}"/>
                    <Parameter name="organisation" value="{badgeData.organisation}"/>
                </Parameters>
                <OnResponse>
                    <!-- 4. Succès -->
                    <SetVariable name="loading" value="false"/>
                    
                    <!-- Audit log -->
                    <Call sequence="Commun.save_audit_log">
                        <Parameters>
                            <Parameter name="action" value="badge_created"/>
                            <Parameter name="resource" value="badge"/>
                            <Parameter name="resourceId" value="{response.data.id}"/>
                        </Parameters>
                    </Call>
                    
                    <!-- Callback parent -->
                    <If condition="{props.onSubmit} != null">
                        <Call callback="{props.onSubmit}" data="{response.data}"/>
                    </If>
                    
                    <!-- Navigation -->
                    <Navigate page="mes-demandes"/>
                </OnResponse>
                <OnError>
                    <!-- 5. Erreur -->
                    <SetVariable name="loading" value="false"/>
                    <SetVariable name="errors.submit" value="Erreur lors de la sauvegarde"/>
                </OnError>
            </Call>
        </Event>
        
        <!-- Annulation -->
        <Event name="handleCancel">
            <If condition="{props.onCancel} != null">
                <Call callback="{props.onCancel}"/>
            </If>
            <Navigate page="home"/>
        </Event>
    </Events>
    
    <!-- Rendu -->
    <Render>
        <Container style="max-width: 800px; margin: 0 auto; padding: var(--spacing-xl);">
            
            <!-- En-tête -->
            <Header style="margin-bottom: var(--spacing-xl);">
                <H1 style="
                    font-size: var(--font-size-xl);
                    color: var(--color-text);
                    margin-bottom: var(--spacing-sm);
                ">
                    <If condition="{props.mode} == 'create'">
                        Nouvelle demande de badge
                    </If>
                    <ElseIf condition="{props.mode} == 'edit'">
                        Modifier la demande de badge
                    </ElseIf>
                    <Else>
                        Demande de badge
                    </Else>
                </H1>
                <Paragraph style="color: var(--color-text-light);">
                    Complétez les informations ci-dessous pour créer une demande de badge
                </Paragraph>
            </Header>
            
            <!-- Erreur globale -->
            <If condition="{errors.submit} != null">
                <MessageErreur 
                    message="{errors.submit}"
                    style="margin-bottom: var(--spacing-lg);"
                />
            </If>
            
            <!-- Formulaire -->
            <Form style="background: var(--color-white); padding: var(--spacing-xl); border-radius: var(--border-radius-lg); box-shadow: var(--shadow-md);">
                
                <!-- Section : Informations demandeur -->
                <Section style="margin-bottom: var(--spacing-xl);">
                    <H2 style="
                        font-size: var(--font-size-lg);
                        color: var(--color-text);
                        margin-bottom: var(--spacing-md);
                        border-bottom: 2px solid var(--color-primary);
                        padding-bottom: var(--spacing-sm);
                    ">
                        Informations du demandeur
                    </H2>
                    
                    <ChampTexte 
                        label="Organisation"
                        value="{badgeData.organisation}"
                        readOnly="true"
                        style="background: var(--color-background);"
                    />
                </Section>
                
                <!-- Section : Informations collaborateur -->
                <Section style="margin-bottom: var(--spacing-xl);">
                    <H2 style="
                        font-size: var(--font-size-lg);
                        color: var(--color-text);
                        margin-bottom: var(--spacing-md);
                        border-bottom: 2px solid var(--color-primary);
                        padding-bottom: var(--spacing-sm);
                    ">
                        Informations du collaborateur
                    </H2>
                    
                    <ChampTexte 
                        label="Nom"
                        required="true"
                        value="{badgeData.nom_collaborateur}"
                        error="{errors.nom}"
                        onChange="handleFieldChange('nom_collaborateur', event.value)"
                        readOnly="{props.mode} == 'view'"
                    />
                    
                    <ChampTexte 
                        label="Prénom"
                        required="true"
                        value="{badgeData.prenom_collaborateur}"
                        error="{errors.prenom}"
                        onChange="handleFieldChange('prenom_collaborateur', event.value)"
                        readOnly="{props.mode} == 'view'"
                    />
                    
                    <ChampEmail 
                        label="Email"
                        required="true"
                        value="{badgeData.email_collaborateur}"
                        error="{errors.email}"
                        onChange="handleFieldChange('email_collaborateur', event.value)"
                        readOnly="{props.mode} == 'view'"
                    />
                </Section>
                
                <!-- Actions -->
                <Section style="
                    display: flex;
                    gap: var(--spacing-md);
                    justify-content: flex-end;
                    margin-top: var(--spacing-xl);
                    padding-top: var(--spacing-lg);
                    border-top: 1px solid var(--color-border);
                ">
                    <If condition="{props.mode} != 'view'">
                        <BoutonCancel 
                            onClick="handleCancel"
                        />
                        <BoutonSubmit 
                            label="Soumettre"
                            loading="{loading}"
                            onClick="handleSubmit"
                        />
                    </If>
                </Section>
            </Form>
        </Container>
    </Render>
</Component>
```

---

## 6. Utilisation dans les pages

### 6.1 Page création de badge

**Fichier** : `Pages/badge-create.xml`

```xml
<Page name="badge-create">
    <Events>
        <Event name="handleBadgeSubmitted">
            <Parameters>
                <Parameter name="data"/>
            </Parameters>
            <!-- Afficher un message de succès -->
            <ShowToast message="Demande de badge créée avec succès" type="success"/>
        </Event>
    </Events>
    
    <Render>
        <Container>
            <!-- Navigation breadcrumb -->
            <Breadcrumb 
                items="[
                    {label: 'Accueil', url: '/home'},
                    {label: 'Demandes', url: '/mes-demandes'},
                    {label: 'Nouveau badge', url: '/badge-create'}
                ]"
            />
            
            <!-- Utilisation du composant -->
            <FormulaireBadge 
                mode="create"
                onSubmit="handleBadgeSubmitted"
            />
        </Container>
    </Render>
</Page>
```

### 6.2 Page édition de badge

**Fichier** : `Pages/badge-edit.xml`

```xml
<Page name="badge-edit">
    <Events>
        <Event name="componentDidMount">
            <!-- Récupérer l'ID depuis l'URL -->
            <SetVariable name="badgeId" value="{route.params.id}"/>
        </Event>
    </Events>
    
    <Render>
        <Container>
            <FormulaireBadge 
                mode="edit"
                badgeId="{badgeId}"
                onSubmit="handleBadgeSubmitted"
            />
        </Container>
    </Render>
</Page>
```

---

## 7. Séquences backend

### 7.1 Badge.save_badge_request

```xml
<!-- Sequence: Badge.save_badge_request -->
<Sequence name="save_badge_request">
    <Parameters>
        <Parameter name="nom" type="string" required="true"/>
        <Parameter name="prenom" type="string" required="true"/>
        <Parameter name="email" type="string" required="true"/>
        <Parameter name="code_agent_demandeur" type="string" required="true"/>
        <Parameter name="organisation" type="string"/>
    </Parameters>
    
    <!-- Validation -->
    <If condition="{nom} == null or length({nom}) < 2">
        <Return error="Le nom doit contenir au moins 2 caractères"/>
    </If>
    
    <!-- Insertion BDD -->
    <Transaction name="badge_demande_insert">
        <Parameters>
            <Parameter name="nom_collaborateur" value="{nom}"/>
            <Parameter name="prenom_collaborateur" value="{prenom}"/>
            <Parameter name="email_collaborateur" value="{email}"/>
            <Parameter name="code_agent_demandeur" value="{code_agent_demandeur}"/>
            <Parameter name="organisation" value="{organisation}"/>
            <Parameter name="etat_courant" value="en_attente_manager"/>
        </Parameters>
        <OnResponse>
            <Return data="{response.data}" badgeId="{response.data.id}"/>
        </OnResponse>
        <OnError>
            <Return error="Erreur lors de la sauvegarde"/>
        </OnError>
    </Transaction>
</Sequence>
```

---

## 8. Avantages de cette architecture

### ✅ Cohérence UX garantie
- Tous les formulaires utilisent les mêmes composants de base
- Design system appliqué uniformément
- UX uniforme pour tous les formulaires

### ✅ Développement rapide
```
Créer un nouveau formulaire = 30 minutes
1. Copier FormulaireBadge
2. Adapter les champs
3. Créer les séquences backend
4. C'est prêt !
```

### ✅ Maintenance simplifiée
- Correction de bug dans ChampTexte = tous les formulaires corrigés
- Changement de design = appliqué partout
- Versioning centralisé

### ✅ Tests unitaires possibles
- Tester chaque composant isolément
- Tests d'intégration sur les formulaires
- Coverage élevée

### ✅ Performance optimale
- Un seul bundle
- Pas de chargement multiple
- Optimisations globales

---

## 9. Comparaison Iframe vs Composants

| Aspect | Iframe | Composants |
|--------|--------|------------|
| **Cohérence UX** | ⚠️ Dépend du design system | ✅ 100% garantie |
| **Performance** | ⚠️ Chargement multiple | ✅ Single bundle |
| **Développement** | ⏱️ Temps normal | ⚡ Ultra rapide |
| **Maintenance** | ⚠️ Modifications dispersées | ✅ Centralisée |
| **Indépendance** | ✅ Totale | ⚠️ Couplé à l'app |
| **Équipes** | ✅ Plusieurs équipes | ⚠️ 1-3 devs max |

---

## 10. Exemple complet : Workflow

```
1. Développeur crée FormulaireBadge (1 fois, 2h)
   ↓
2. Développeur crée page badge-create.xml (15min)
   ↓
3. Utilisateur ouvre /badge-create
   ↓
4. La page charge FormulaireBadge
   ↓
5. Utilisateur remplit et soumet
   ↓
6. Sequence save_badge_request sauvegarde en BDD
   ↓
7. Redirection vers mes-demandes
   ↓
8. ✅ Terminé !
```

---

## Conclusion

**Architecture composants réutilisables = Architecture idéale pour Espace Unifié**

✅ **Cohérence UX** maximale  
✅ **Développement** rapide  
✅ **Maintenance** simplifiée  
✅ **Performance** optimale  
✅ **Évolutivité** facile  

**Parfait pour** : Petite à moyenne équipe, MVP rapide, cohérence UX critique

