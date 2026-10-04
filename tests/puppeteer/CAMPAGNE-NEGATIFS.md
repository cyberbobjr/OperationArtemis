# Suite de la campagne : autorisations et abandon

Mise à jour gameplay demandée pendant la campagne : la quarantaine est désormais plafonnée à **une heure de jeu** avec ou sans dossier ; incident du détenu à 30 minutes. [Modification et validations](reports/QUARANTAINE-UNE-HEURE.md). Les réussites obtenues avant le redémarrage concernent l’ancien code. Reprendre 13 puis 14 après redémarrage complet ; ne pas refaire les chapitres ni forcer la progression.

Les cas 28 (expiration naturelle de l’autorisation), 13/24 (entrée/abandon de l’ancien code) et 26 (test positif avec infection temporaire nettoyée) ont réussi dans la seconde partie dédiée. Le cas 27 utilise `{depositDossier=true}` : dépôt puis ramassage réels du même document. La lecture du dossier a été volontairement différée en 07.

La partie `2026-10-03_18-48-28` est terminée, acte 4. Conserver ses rapports et sa sauvegarde. Aucun reset debug de progression, copie de sauvegarde personnelle ou retour forcé à l'acte III.

Créer une nouvelle partie solo dédiée nommée `PZPuppet_Artemis_Negatifs`, mêmes mods et version 42.21, personnage lettré et non sourd, stérilisation désactivée pour ces tests. Le préfixe du nom est accepté par les gardes sans troisième argument testSave. Un redémarrage complet charge aussi la correction du moteur sur les assertions attendues; les 58 tests hors jeu ne la valident pas encore dans le jeu.

Première commande, uniquement dans cette nouvelle partie :

```lua
PZPuppet.runFile("OperationArtemis/01_chargement_carnet.lua",{playerIndex=0})
```

Le moteur et les scénarios sont déjà installés. Fermer la console et laisser le jeu tourner; attendre chaque rapport avant la commande suivante. Rejouer 01 à 08 par les véritables actions pour acquérir l'acte III. Le déplacement de préparation debug déjà documenté pour la base/les archives ne complète pas les objectifs. Les reprises `resume=true` des anciennes tentatives ne doivent pas être recopiées dans cette nouvelle partie.

Ensuite, 28 obtient lui-même réellement une autorisation `cleared` par le menu du poste et reste hors de l'enclos. Il relève l'échéance réelle, attend son dépassement sans changement d'horloge, puis vérifie entrée supprimée, portail reverrouillé et absence de victoire. Le délai maximal est 1 200 secondes actives, configurable; aucune période de quarantaine complète n'est attendue. Il a réussi en jeu en 225,034 secondes sur cette partie. Le paramètre `prepareEntry=false` conserve l'ancien usage avec autorisation déjà acquise.

Après 28, 13 puis 24 ont réussi sur l’ancien code : véritable entrée et abandon. Le positif 26 a ensuite réussi avec `{infectionFixture=true}` : infection réelle temporaire préparée sur le personnage, véritable test du poste, refus, portail verrouillé et nettoyage. La variante 27 nécessite un dépôt réel du dossier, puis son ramassage par le callback vanilla de l’objet au sol. Ne pas exécuter 19 avant de décider de sacrifier la route C de cette partie : sa frappe ferme irréversiblement le checkpoint.

Les appels valides hélicoptère et passeur étaient bloqués par MOD-09. Le correctif ciblé a été autorisé et appliqué le 2026-10-04 ; [contrôles et limites](reports/RADIO-FIX-20261004.md). Les routes/fins avec le code corrigé demeurent non exécutées. Nouvelle campagne prévue dans `PZPuppet_Artemis_Helicoptere`, puis partie distincte pour le passeur. Aucune intégration optionnelle ne peut être annoncée testée sans le mod et ses conditions réels.
