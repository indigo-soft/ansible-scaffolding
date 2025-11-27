## ✨ Prettier (YAML)

Для єдиного стилю YAML використовується Prettier.

Встановлення (одноразово у репозиторій):

```bash
npm init -y
npm i -D prettier
```

Запуск форматування:

```bash
make fmt        # форматувати YAML (playbooks, inventory, group_vars, host_vars, roles)
make fmt-check  # перевірити формат без змін
```

VS Code (рекомендація):

```json
{
    "files.eol": "\n",
    "[yaml]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    }
}
```

Додатково: у репозиторії налаштовано `.gitattributes` для рядків LF.
