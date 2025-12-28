# ZNC

ZNC est un bouncer IRC (IRC bouncer). Il reste connecté aux serveurs IRC même quand vous êtes hors ligne, et garde en mémoire les messages manqués (buffer) pour vous les rejouer à votre connexion.

## Connexion via WeeChat

Pour se connecter à votre instance ZNC depuis WeeChat :

### 1. Créer le réseau
```weechat
/server add znc znc-irc.${DOMAIN}/444
```

### 2. Configurer les identifiants
```weechat
/set irc.server.znc.password <username>:<pasword>
```

### 3. Activer l'autoconnect
```weechat
/set irc.server.znc.autoconnect on
```

### 4. Désactiver la vérification TLS
```weechat
/set irc.server.znc.tls_verify off
/save
```

### 5. Se connecter
```weechat
/connect znc
```
